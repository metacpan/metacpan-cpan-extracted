package Chandra::Markdown;

use strict;
use warnings;
use Object::Proto::Sugar -constants;
use Markdown::Simple;
use Search::Trigram;
use Chandra::Element;

our $VERSION = '0.02';

has app         => (is_ro, req);
has gfm         => (is_ro, default => 1);
has hard_breaks => (is_ro, default => 0);
has highlight   => (is_ro, default => 1);
has id          => (is_ro, default => 'chandra-markdown');
has css         => (is_ro, default => 1);
has _renderer   => (is_rw, lzy, bld);
has _dir_routes => (is_rw, darray);
has _index      => (is_rw, lzy, bld);
has _index_meta => (is_rw, darray);  # [{doc_id, route, title}]

sub _build__renderer {
    my ($self) = @_;
    Markdown::Simple->new({
        gfm         => $self->gfm,
        hard_breaks => $self->hard_breaks,
        highlight   => $self->highlight,
    });
}

sub _build__index {
    Search::Trigram->new;
}

sub BUILD {
    my ($self) = @_;
    $self->app->css(_css()) if $self->css;
}

sub render {
    my ($self, $markdown) = @_;
    return Chandra::Element->new({ tag => 'div', class => 'chandra-markdown' })->render
        unless defined $markdown;
    my $html = $self->_renderer->render($markdown);
    Chandra::Element->new({ tag => 'div', class => 'chandra-markdown', raw => $html })->render;
}

sub set {
    my ($self, $markdown) = @_;
    my $id  = $self->id;
    my $esc = _js_escape($self->render($markdown));
    $self->app->eval(
        "var _e=document.getElementById('$id');"
      . "if(_e){_e.innerHTML='$esc';}"
      . "else{document.body.innerHTML='$esc';}"
    );
    return $self;
}

sub append {
    my ($self, $markdown) = @_;
    my $id  = $self->id;
    my $esc = _js_escape($self->render($markdown));
    $self->app->eval(
        "var _e=document.getElementById('$id');"
      . "if(_e){_e.innerHTML+='$esc';}"
      . "else{document.body.innerHTML+='$esc';}"
    );
    return $self;
}

sub render_dir {
    my ($self, $dir, %opts) = @_;
    my $recursive  = exists $opts{recursive}  ? $opts{recursive}  : 0;
    my $base_route = exists $opts{base_route} ? $opts{base_route} : '/docs';
    my $nav_id     = exists $opts{nav_id}     ? $opts{nav_id}     : 'chandra-markdown-nav';
    my $sort_by    = exists $opts{sort}       ? $opts{sort}       : 'alpha';
    my $index_file = exists $opts{index}      ? $opts{index}      : 'index.md';

    (my $index_stem = $index_file) =~ s/\.md$//i;

    my @files = _collect_md_files($dir, $recursive);
    @files = $sort_by eq 'mtime'
        ? sort { (stat $a)[9] <=> (stat $b)[9] } @files
        : sort @files;

    my @entries;
    for my $file (@files) {
        my $title = _extract_title($file);
        (my $rel  = $file) =~ s{^\Q$dir\E/?}{};
        $rel      =~ s/\.md$//i;
        my $route = $rel eq $index_stem ? $base_route : "$base_route/$rel";

        # Index the file content for search
        my $content = do {
            open my $fh, '<:utf8', $file or last;
            local $/; scalar <$fh>;
        };
        if (defined $content) {
            my $doc_id = $self->_index->add("$title\n$content");
            push @{ $self->_index_meta }, {
                doc_id => $doc_id,
                route  => $route,
                title  => $title,
                text   => $content,
            };
        }

        $self->app->route($route => sub {
            open my $fh, '<:utf8', $file
                or return Chandra::Element->new({ tag => 'p', data => "Cannot read $file" })->render;
            local $/;
            $self->render(scalar <$fh>);
        });

        push @{ $self->_dir_routes }, $route;
        push @entries, { route => $route, title => $title, rel => $rel };
    }

    my $tree = _entries_to_tree(\@entries);
    my $nav  = Chandra::Element->new({ tag => 'nav', id => $nav_id });
    my $ul   = Chandra::Element->new({ tag => 'ul' });
    _nav_tree_html($tree, $ul);
    $nav->add_child($ul);
    return $nav->render;
}

# ---------------------------------------------------------------
# Search
# ---------------------------------------------------------------

sub search {
    my ($self, $query, $limit) = @_;
    $limit //= 10;
    return [] unless $self->_index->doc_count;
    my $raw = $self->_index->search($query, $limit);
    my %by_id = map { $_->{doc_id} => $_ } @{ $self->_index_meta };
    return [
        map {
            my $m = $by_id{ $_->{doc_id} } // {};
            {
                route   => $m->{route} // '/',
                title   => $m->{title} // '',
                score   => $_->{score},
                snippet => _snippet($m->{text} // '', $query),
            }
        } @$raw
    ];
}

sub search_widget {
    my ($self, %opts) = @_;
    my $placeholder = exists $opts{placeholder} ? $opts{placeholder} : 'Search...';
    my $limit       = exists $opts{limit}       ? $opts{limit}       : 10;
    my $min_len     = exists $opts{min_length}  ? $opts{min_length}  : 2;

    $self->app->bind('__chandra_md_search', sub {
        my ($query) = @_;
        $query //= '';
        $query =~ s/^\s+|\s+$//g;

        if (length($query) < $min_len) {
            $self->app->navigate('/');
            return;
        }

        my $results = $self->search($query, $limit);
        my $html    = _render_search_results($query, $results);
        my $esc     = _js_escape($html);
        $self->app->dispatch_eval(
            "var _e=document.getElementById('chandra-content');"
          . "if(_e){_e.innerHTML='$esc';}"
          . "else{document.body.innerHTML='$esc';}"
          . "try{history.pushState({},'','/search');}catch(_){};"
        );
    });

    return _search_widget_html($placeholder);
}

sub _render_search_results {
    my ($query, $results) = @_;

    my $wrap = Chandra::Element->new({ tag => 'div', class => 'chandra-search-results' });

    unless (@$results) {
        my $empty = Chandra::Element->new({ tag => 'p', class => 'chandra-search-empty' });
        $empty->add_child(Chandra::Element->new({ tag => 'span', data => 'No results for ' }));
        $empty->add_child(Chandra::Element->new({ tag => 'strong', data => $query }));
        $empty->add_child(Chandra::Element->new({ tag => 'span', data => '.' }));
        $wrap->add_child($empty);
        return $wrap->render;
    }

    my $heading = Chandra::Element->new({ tag => 'h2', class => 'chandra-search-heading' });
    $heading->add_child(Chandra::Element->new({ tag => 'span', data => 'Results for ' }));
    $heading->add_child(Chandra::Element->new({ tag => 'em',   data => $query }));
    $wrap->add_child($heading);

    for my $r (@$results) {
        my $pct  = int($r->{score} * 100);
        my $item = Chandra::Element->new({ tag => 'div', class => 'chandra-search-result' });

        my $header = Chandra::Element->new({ tag => 'div', class => 'chandra-search-result-header' });
        $header->add_child(Chandra::Element->new({ tag => 'a', href => $r->{route}, data => $r->{title} }));
        $header->add_child(Chandra::Element->new({ tag => 'span', class => 'chandra-search-score', data => "$pct%" }));
        $item->add_child($header);

        if ($r->{snippet}) {
            $item->add_child(Chandra::Element->new({
                tag   => 'p',
                class => 'chandra-search-snippet',
                data  => $r->{snippet},
            }));
        }

        $wrap->add_child($item);
    }

    return $wrap->render;
}

sub _search_widget_html {
    my ($placeholder) = @_;

    my $wrap = Chandra::Element->new({ tag => 'div', class => 'chandra-search-wrap' });
    $wrap->add_child(Chandra::Element->new({
        tag          => 'input',
        type         => 'search',
        id           => 'chandra-md-search',
        placeholder  => $placeholder,
        autocomplete => 'off',
        spellcheck   => 'false',
    }));

    my $js = "(function(){"
           . "var _t,_i=document.getElementById('chandra-md-search');"
           . "if(!_i)return;"
           . "_i.addEventListener('input',function(){"
           . "clearTimeout(_t);var q=_i.value;"
           . "_t=setTimeout(function(){window.chandra.invoke('__chandra_md_search',[q]);},300);"
           . "});})();";

    return $wrap->render
         . Chandra::Element->new({ tag => 'script', raw => $js })->render;
}

# ---------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------

sub _collect_md_files {
    my ($dir, $recursive) = @_;
    opendir my $dh, $dir or return ();
    my @files;
    for my $entry (sort readdir $dh) {
        next if $entry =~ /^\./;
        my $path = "$dir/$entry";
        if    (-f $path && $entry =~ /\.md$/i) { push @files, $path }
        elsif ($recursive && -d $path)          { push @files, _collect_md_files($path, $recursive) }
    }
    closedir $dh;
    return @files;
}

sub _extract_title {
    my ($file) = @_;
    if (open my $fh, '<:utf8', $file) {
        while (<$fh>) {
            return $1 if /^#\s+(.+)/;
        }
    }
    (my $t = $file) =~ s{.*/}{};
    $t =~ s/\.md$//i;
    $t =~ s/[-_]/ /g;
    return ucfirst $t;
}

sub _snippet {
    my ($text, $query, $max) = @_;
    $max //= 140;
    return '' unless defined $text && length $text;

    # Strip markdown syntax for a readable plain-text snippet
    $text =~ s/^#{1,6}\s+//gm;   # headings
    $text =~ s/[*_`~]+//g;       # emphasis, code, strikethrough
    $text =~ s/\[([^\]]*)\]\([^)]*\)/$1/g;  # links
    $text =~ s/^\s*[-*+]\s+//gm; # list bullets
    $text =~ s/\n+/ /g;
    $text =~ s/^\s+|\s+$//g;

    # Find the first query word in the text (case-insensitive)
    my $pos = 0;
    for my $word (split /\s+/, $query) {
        next if length($word) < 3;
        my $idx = index(lc($text), lc($word));
        if ($idx >= 0) {
            $pos = $idx > 30 ? $idx - 30 : 0;
            last;
        }
    }

    my $snippet = substr($text, $pos, $max);
    $snippet    = "\x{2026}" . $snippet if $pos > 0;
    $snippet   .= "\x{2026}" if $pos + $max < length($text);
    return $snippet;
}

sub _entries_to_tree {
    my ($entries) = @_;
    my (@root, %buckets, @section_order);
    for my $e (@$entries) {
        my $slash = index($e->{rel}, '/');
        if ($slash < 0) {
            push @root, $e;
        } else {
            my $dir  = substr($e->{rel}, 0, $slash);
            my $rest = substr($e->{rel}, $slash + 1);
            unless (exists $buckets{$dir}) {
                push @section_order, $dir;
                $buckets{$dir} = [];
            }
            push @{$buckets{$dir}}, { %$e, rel => $rest };
        }
    }
    my %sections;
    $sections{$_} = _entries_to_tree($buckets{$_}) for @section_order;
    return { root => \@root, sections => \%sections, section_order => \@section_order };
}

sub _nav_tree_html {
    my ($tree, $ul) = @_;
    for my $e (@{$tree->{root}}) {
        my $li = Chandra::Element->new({ tag => 'li' });
        $li->add_child(Chandra::Element->new({
            tag  => 'a',
            href => $e->{route},
            data => $e->{title},
        }));
        $ul->add_child($li);
    }
    for my $dir (@{$tree->{section_order}}) {
        my $label = $dir;
        $label =~ s/[-_]/ /g;
        $label = join ' ', map { ucfirst } split /\s+/, $label;

        my $inner_ul = Chandra::Element->new({ tag => 'ul' });
        _nav_tree_html($tree->{sections}{$dir}, $inner_ul);

        my $details = Chandra::Element->new({ tag => 'details', open => '' });
        $details->add_child(Chandra::Element->new({ tag => 'summary', data => $label }));
        $details->add_child($inner_ul);

        my $li = Chandra::Element->new({ tag => 'li', class => 'chandra-nav-section' });
        $li->add_child($details);
        $ul->add_child($li);
    }
}

sub _js_escape {
    my ($str) = @_;
    $str =~ s/\\/\\\\/g;
    $str =~ s/'/\\'/g;
    $str =~ s/\r/\\r/g;
    $str =~ s/\n/\\n/g;
    return $str;
}


my $CSS = <<'END_CSS';
.chandra-markdown {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    font-size: 16px;
    line-height: 1.6;
    color: var(--chandra-text, #24292f);
    max-width: 860px;
    padding: 24px;
    box-sizing: border-box;
}
.chandra-markdown h1,
.chandra-markdown h2 { border-bottom: 1px solid var(--chandra-border, #d0d7de); padding-bottom: .3em; }
.chandra-markdown h1 { font-size: 2em; margin: .67em 0; }
.chandra-markdown h2 { font-size: 1.5em; }
.chandra-markdown h3 { font-size: 1.25em; }
.chandra-markdown code {
    font-family: 'SFMono-Regular', Consolas, monospace;
    font-size: .85em;
    background: var(--chandra-code-bg, #f6f8fa);
    padding: .2em .4em;
    border-radius: 3px;
}
.chandra-markdown pre {
    background: var(--chandra-code-bg, #f6f8fa);
    border-radius: 6px;
    padding: 16px;
    overflow: auto;
    line-height: 1.45;
}
.chandra-markdown pre code { background: none; padding: 0; }
.chandra-markdown .esh-k { color: var(--esh-keyword,  #cf222e); }
.chandra-markdown .esh-s { color: var(--esh-string,   #0a3069); }
.chandra-markdown .esh-c { color: var(--esh-comment,  #6e7781); font-style: italic; }
.chandra-markdown .esh-n { color: var(--esh-number,   #0550ae); }
.chandra-markdown .esh-p { color: var(--esh-preproc,  #8250df); }
.chandra-markdown .esh-r { color: var(--esh-regex,    #116329); }
.chandra-markdown .esh-v { color: var(--esh-variable, #953800); }
.chandra-markdown .esh-h { color: var(--esh-heredoc,  #0a3069); }
.chandra-markdown .esh-d { color: var(--esh-doc,      #6e7781); font-style: italic; }
.chandra-markdown .esh-g { color: var(--esh-tag,      #116329); }
.chandra-markdown .esh-a { color: var(--esh-attr,     #0550ae); }
.chandra-markdown blockquote {
    border-left: 4px solid var(--chandra-border, #d0d7de);
    color: var(--chandra-muted, #656d76);
    margin: 0;
    padding: 0 1em;
}
.chandra-markdown table { border-collapse: collapse; width: 100%; }
.chandra-markdown th,
.chandra-markdown td { border: 1px solid var(--chandra-border, #d0d7de); padding: 6px 13px; }
.chandra-markdown tr:nth-child(even) { background: var(--chandra-stripe, #f6f8fa); }
.chandra-markdown img { max-width: 100%; }
.chandra-markdown a { color: var(--chandra-link, #0969da); }
.chandra-markdown ul, .chandra-markdown ol { padding-left: 2em; }
.chandra-markdown input[type=checkbox] { margin-right: .5em; }

/* Search widget */
.chandra-search-wrap {
    padding: 10px 12px;
    border-top: 1px solid var(--chandra-border, #d0d7de);
}
.chandra-search-wrap input[type=search] {
    width: 100%;
    padding: 6px 10px;
    border: 1px solid var(--chandra-border, #d0d7de);
    border-radius: 6px;
    font-size: 13px;
    background: var(--chandra-bg, #ffffff);
    color: var(--chandra-text, #24292f);
    outline: none;
    -webkit-appearance: none;
}
.chandra-search-wrap input[type=search]:focus {
    border-color: var(--chandra-link, #0969da);
    box-shadow: 0 0 0 3px rgba(9,105,218,.15);
}

/* Search results */
.chandra-search-results {
    padding: 24px;
    max-width: 860px;
}
.chandra-search-heading {
    font-size: 1.1em;
    font-weight: 500;
    color: var(--chandra-muted, #57606a);
    margin-bottom: 20px;
    border-bottom: 1px solid var(--chandra-border, #d0d7de);
    padding-bottom: 12px;
}
.chandra-search-heading em { font-style: normal; color: var(--chandra-text, #24292f); }
.chandra-search-result {
    padding: 14px 0;
    border-bottom: 1px solid var(--chandra-border, #d0d7de);
}
.chandra-search-result-header {
    display: flex;
    align-items: baseline;
    gap: 10px;
    margin-bottom: 4px;
}
.chandra-search-result-header a {
    font-size: 15px;
    font-weight: 500;
    color: var(--chandra-link, #0969da);
    text-decoration: none;
    flex: 1;
}
.chandra-search-result-header a:hover { text-decoration: underline; }
.chandra-search-score {
    font-size: 11px;
    color: var(--chandra-muted, #57606a);
    background: var(--chandra-code-bg, #f6f8fa);
    padding: 2px 6px;
    border-radius: 10px;
    flex-shrink: 0;
}
.chandra-search-snippet {
    font-size: 13.5px;
    color: var(--chandra-muted, #57606a);
    line-height: 1.5;
    margin: 0;
}
.chandra-search-empty {
    color: var(--chandra-muted, #57606a);
    font-size: 14px;
    padding: 24px 0;
}

/* Hierarchical nav sections */
#chandra-markdown-nav .chandra-nav-section { list-style: none; }
#chandra-markdown-nav .chandra-nav-section > details > summary {
    display: flex;
    align-items: center;
    padding: 10px 16px 4px;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: .06em;
    text-transform: uppercase;
    color: var(--chandra-muted, #57606a);
    cursor: pointer;
    user-select: none;
    outline: none;
    list-style: none;
}
#chandra-markdown-nav .chandra-nav-section > details > summary::-webkit-details-marker { display: none; }
#chandra-markdown-nav .chandra-nav-section > details > summary::after {
    content: '\203A';
    margin-left: auto;
    font-size: 15px;
    display: inline-block;
    transition: transform 180ms;
    transform: rotate(90deg);
}
#chandra-markdown-nav .chandra-nav-section > details[open] > summary::after {
    transform: rotate(270deg);
}
#chandra-markdown-nav .chandra-nav-section > details > ul {
    list-style: none;
    margin: 0;
    padding: 0;
}
#chandra-markdown-nav .chandra-nav-section > details > ul > li > a {
    padding-left: 28px;
}
END_CSS

sub _css { $CSS }

1;

__END__

=head1 NAME

Chandra::Markdown - Render Markdown in Chandra apps

=head1 SYNOPSIS

    use Chandra::Markdown;

    my $md = Chandra::Markdown->new(app => $app);
    $md->set("# Hello\nThis is **Markdown**.");

    # Render to HTML string without updating the webview
    my $html = $md->render("# Hello");

    # Register routes for a docs directory + get nav HTML
    my $nav = $md->render_dir('docs', base_route => '/docs');

    # Add a search widget (registers the bind handler)
    my $search = $md->search_widget(placeholder => 'Search docs...');

=head1 METHODS

=head2 new(%opts)

C<app> is required. Available options:

=over 4

=item C<gfm> (default 1)

Enable GFM extensions: tables, strikethrough, task lists, autolinks, and raw
HTML sanitisation. Set to C<0> for strict CommonMark.

=item C<hard_breaks> (default 0)

Emit C<< <br /> >> for soft line breaks inside paragraphs.

=item C<highlight> (default 1)

Syntax-highlight fenced code blocks that carry a language tag (e.g.
C<< ```perl >>). Tokens are wrapped in C<< <span class="esh-X"> >> elements
styled by the injected CSS. Blocks with no language tag are unaffected.
Set to C<0> to emit plain HTML-escaped code.

=item C<id> (default C<chandra-markdown>)

DOM element id targeted by L</set> and L</append>.

=item C<css> (default 1)

Inject the built-in stylesheet (C<.chandra-markdown> layout rules plus
C<.esh-*> token colours) into the app on construction. Set to C<0> to
supply your own styles.

=back

=head2 render($markdown)

Convert C<$markdown> to HTML. Does not update the webview.

=head2 set($markdown) / append($markdown)

Render and set/append C<innerHTML> of the target element. Return C<$self>.

=head2 render_dir($dir, %opts)

Scan C<$dir> for C<*.md> files, register routes and index content for search.
Returns a C<< <nav> >> HTML string. Options: C<recursive>, C<base_route>,
C<nav_id>, C<sort>, C<index>.

=head2 search($query, $limit)

Search the index built by C<render_dir>. Returns an arrayref of
C<{route, title, score, snippet}> hashrefs, sorted by score descending.

=head2 search_widget(%opts)

Register the C<__chandra_md_search> invoke handler and return HTML for
the search input. Options: C<placeholder>, C<limit>, C<min_length>.
Embed the returned HTML in your layout.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

Artistic License 2.0

=cut
