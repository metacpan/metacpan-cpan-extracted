package Daizu::Plugin::PodArticle;
use warnings;
use strict;

use Pod::Parser;
use Daizu::Util qw( add_xml_elem );

# TODO - according to the perlpodspec I have to insert an HTML comment
# containing the name and version number of my POD translator.

=head1 NAME

Daizu::Plugin::PodArticle - a plugin for publishing Perl POD documentation on websites

=head1 DESCRIPTION

This plugin adds the ability for Daizu CMS to load content from POD files
(or Perl code containing POD documentation).  Once this module has parsed
the file it provides Daizu with the content in XHTML format (as a DOM
structure), and from then on it can be treated as a normal article.

With this module loaded it should be possible to publish Perl documentation
simply by adding the files containing POD to the repository, marking them
as being articles like any other, and giving them a C<svn:mime-type>
property with the value 'text/x-perl'.

=head1 CONFIGURATION

To turn on this plugin, include the following in your Daizu CMS configuration
file:

=for syntax-highlight xml

    <plugin class="Daizu::Plugin::PodArticle" />

=head1 POD EXTENSIONS

This module understands the following non-standard POD features, which
will be ignored by all other POD processeors:

=over

=item Syntax highlighting

If you want an indented block of text to be syntax highlighted (showing
colour-coding to make code samples or whatever easier to read), you can
include a command like the following before the indented block:

=for syntax-highlight pod

    =for syntax-highlight perl

        my $foo = 'this perl code will be syntax colored.'

This requires the L<Daizu::Plugin::SyntaxHighlight> plugin to be
enabled too.

Each of these C<=for> commands will only affect a single indented
block (whichever one is found next).  Blank lines in blocks won't
break them up; the syntax highlighting will last up until the next
thing which isn't indented (a command or a normal paragraph).

=item The fold

You can get the same effect as the special C<daizu:fold> element gives
in XHTML articles using the following markup:

=for syntax-highlight pod

    =for daizu-fold

This is not likely to be useful unless you're writing blog articles
in POD, in which case the content above the fold will be shown in
index pages (and possibly feeds, depending on how they're configured).

=item Page breaks

You can get the same effect as the special C<daizu:page> element gives
in XHTML articles using the following markup:

=for syntax-highlight pod

    =for daizu-page

Occurances of this will separate pages of content, allowing a long
document to be split into multiple pages for web publication.

=back

=head1 LINKS

TODO - describe the awful hackiness of the module-links.txt file, and
whatever other incompatibilities might be a problem.

=head1 METHODS

=over

=item Daizu::Plugin::PodArticle-E<gt>register($cms, $whole_config, $plugin_config, $path)

Called by Daizu CMS when the plugin is registered.  It registers the
L<load_article()|/$self-E<gt>load_article($cms, $file)> method as
an article loader for the MIME type 'text/x-perl'.

The configuration is currently ignored.

=cut

sub register
{
    my ($class, $cms, $whole_config, $plugin_config, $path) = @_;
    my $self = bless {}, $class;
    $cms->add_article_loader('text/x-perl', '', $self => 'load_article');
}

=item $self-E<gt>load_article($cms, $file)

Does the actual parsing of the POD content of C<$file> (which should
be a L<Daizu::File> object), and returns the approriate content and metadata.

Never rejects a file, and therefore always returns true.

=cut

sub load_article
{
    my ($self, $cms, $file) = @_;

    # Use .html URL for the actual article.
    # TODO - this is mostly or exactly the same as the code in PictureArticle.
    # TODO - it's also rather inefficient, because we're doing base_url when
    # saving the article anyway, in Daizu::File.
    my $article_url = '';
    my $base_url = $file->generator->base_url($file);
    if ($base_url !~ m!/$!) {
        $article_url = $file->{name};
        $article_url =~ s!\.[^./]+$!.html!
            or $article_url .= '.html';
    }

    # Publish the source code too, and link to it from the article.
    # Currently this is only done for .pm files, since that's useful for
    # documentation of Perl modules, but you don't necessarily want it for
    # general purpose documents.
    my @extra_url;
    my @extra_template;
    if ($file->{name} =~ /\.pm$/i) {
        push @extra_url, {
            url => $file->{name},
            type => 'text/x-perl',
            generator => 'Daizu::Gen',
            method => 'unprocessed',
        };
        push @extra_template, 'plugin/podarticle_extras.tt';
    }

    my $parser = Daizu::Plugin::PodArticle::Parser->new;
    $parser->{daizu_lists} = [];
    $parser->{first_cmd} = 1;

    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $body = $doc->createElementNS('http://www.w3.org/1999/xhtml', 'body');
    $doc->setDocumentElement($body);
    $parser->{daizu_curelem} = $body;

    open my $fh, '<', $file->data
        or die "error opening memory file: $!";
    $parser->parse_from_filehandle($fh);

    my ($title, $short_title);
    if (defined $parser->{doc_title}) {
        $title = $parser->{doc_title};
        $short_title = $1
            if $title =~ /^\s*(\S+)\s+-+\s/;
    }

    return {
        content => $doc,
        title => $title,
        short_title => $short_title,
        pages_url => $article_url,
        extra_urls => \@extra_url,
        extra_templates => \@extra_template,
    };
}

=back

=head1 Daizu::Plugin::PodArticle::Parser

This class is the subclass of L<Pod::Parser> used for parsing POD documents
into XHTML DOM documents.  It overrides the methods
L<command()|Pod::Parser/command()>,
L<textblock()|Pod::Parser/textblock()>, and
L<verbatim()|Pod::Parser/verbatim()>.

=cut

package Daizu::Plugin::PodArticle::Parser;
use base 'Pod::Parser';

use XML::LibXML;
use HTML::Entities qw( decode_entities );
use Carp::Assert qw( assert DEBUG );
use Daizu::Util qw( trim daizu_data_dir );
use Daizu;

sub _list_type
{
    my ($s) = @_;
    return 'ul' if $s eq '' || $s eq '*';
    return 'ol' if $s =~ /^1\.?$/;
    return 'dl';
}

{
    my $module_links;

    sub _module_links
    {
        if (!defined $module_links) {
            my $filename = daizu_data_dir('pod')->file('module-links.txt');
            open my $fh, '<', $filename
                or die "error loading '$filename': $!";

            $module_links = {};
            while (<$fh>) {
                next unless /\S/;
                next if /^\s*#/;

                my ($module, $url) = split ' ', $_;
                $module_links->{$module} = $url;
            }
        }

        return $module_links;
    }
}

sub _do_heading
{
    my ($self, $line_num, $level, @content) = @_;

    # Convert all-uppercase titles to title case.
    if (@content == 1 && $content[0] !~ /[a-z]/) {
        $content[0] = join ' ',
                      map { ucfirst lc $_ }
                      split ' ', $content[0];
    }

    my $elem = 'h' . ($level + 2);
    die "$line_num: heading 'head$level' missing title"
        unless @content;
    die "$line_num: heading between =over and =item"
        unless defined $self->{daizu_curelem};
    $self->{daizu_curelem}->appendChild(
        _elem($elem => @content),
    );
}

sub command
{
    my ($self, $cmd, $text, $line_num, $pod_para) = @_;
    _do_verbatim($self, $line_num)
        if defined $self->{daizu_verbatim};

    $text = trim($text);
    my $tree;

    if ($cmd eq 'head1' && $text eq 'NAME' && $self->{first_cmd}) {
        die "more than one 'NAME' paragraph at start of document"
            if $self->{done_title} || $self->{title_para_next};
        $self->{title_para_next} = 1;
        return;
    }
    $self->{first_cmd} = 0;

    $tree = _daizu_parse_text($self, $text, $line_num)
        unless $text eq '';

    if ($cmd =~ /^head([1234])$/) {
        _do_heading($self, $line_num, $1,
                    _flatten_parse_trees($tree->children));
    }
    elsif ($cmd eq 'item') {
        my $stack = $self->{daizu_lists};
        die "$line_num: =item outside list"
            unless @$stack;
        my $cur_list = $stack->[-1];

        my $list_type;
        if (defined $cur_list->{type}) {
            $list_type = $cur_list->{type};
        }
        else {
            # First item in new list.  Create the element for the list itself.
            $list_type = _list_type($text);
            $cur_list->{type} = $list_type;
            $cur_list->{elem} = XML::LibXML::Element->new($list_type);
            $cur_list->{old_curelem}->appendChild($cur_list->{elem});
        }

        # Add the previous list item element, unless it's an empty <dd>.
        $cur_list->{elem}->appendChild($self->{daizu_curelem})
            if defined $self->{daizu_curelem} &&
               $self->{daizu_curelem}->hasChildNodes;

        if ($list_type eq 'dl') {
            my $dt = _elem(dt => _flatten_parse_trees($tree->children));
            if (defined $text) {
                my $fragment = _fragment_id($text);
                my $a = XML::LibXML::Element->new('a');
                $a->setAttribute(id => _anchorify("item_$fragment"));
                $dt->insertBefore($a, $dt->firstChild);
            }
            $cur_list->{elem}->appendChild($dt);
        }

        my $item_type = $list_type eq 'dl' ? 'dd' : 'li';
        $self->{daizu_curelem} = XML::LibXML::Element->new($item_type);
    }
    elsif ($cmd eq 'over') {
        die "$line_num: can't have two consecutive =over commands"
            unless defined $self->{daizu_curelem};
        push @{$self->{daizu_lists}}, {
            old_curelem => $self->{daizu_curelem},
        };
        $self->{daizu_curelem} = undef;     # no element outside =item
    }
    elsif ($cmd eq 'back') {
        my $stack = $self->{daizu_lists};
        die "$line_num: =back without matching =over"
            unless @$stack;
        my $cur_list = $stack->[-1];
        die "$line_num: empty list"
            unless defined $cur_list->{type};

        # Add the previous list item element, unless it's an empty <dd>.
        $cur_list->{elem}->appendChild($self->{daizu_curelem})
            if $self->{daizu_curelem}->hasChildNodes;

        $self->{daizu_curelem} = $cur_list->{old_curelem};
        pop @$stack;
    }
    elsif ($cmd =~ /^(?:pod|cut|begin|end)$/) {
        # TODO - should do something with =begin and =end.
    }
    elsif ($cmd eq 'for') {
        my ($target, $args) = split ' ', $text, 2;
        if ($target eq 'syntax-highlight') {
            $self->{daizu_syncolor_filetype} = trim($args);
        }
        elsif ($target eq 'daizu-fold') {
            my $elem = XML::LibXML::Element->new('fold');
            $elem->setNamespace($Daizu::HTML_EXTENSION_NS, 'daizu');
            $self->{daizu_curelem}->appendChild($elem);
        }
        elsif ($target eq 'daizu-page') {
            my $elem = XML::LibXML::Element->new('page');
            $elem->setNamespace($Daizu::HTML_EXTENSION_NS, 'daizu');
            $self->{daizu_curelem}->appendChild($elem);
        }
        # TODO - what if it's something other than these?
    }
    elsif ($cmd eq 'encoding') {
        warn "$line_num: this processor can only read ASCII and UTF-8 text"
            unless $text =~ /^(?:ascii|utf-?8)$/i;
    }
    else {
        warn "$line_num: ignoring unknown command '$cmd'";
    }
}

# TODO - call this at the end of processing each file.
sub _do_verbatim
{
    my ($self, $line_num) = @_;

    die "$line_num: verbatim paragraph between =over and =item"
        unless defined $self->{daizu_curelem};

    # Strip off the indent common to all lines of the block.
    my $lines = $self->{daizu_verbatim};
    for (@$lines) {
        substr($_, 0, $self->{daizu_verbatim_min_indent}) = '';
    }

    my $elem;
    if ($self->{daizu_syncolor_filetype}) {
        $elem = XML::LibXML::Element->new('syntax-highlight');
        $elem->setNamespace($Daizu::HTML_EXTENSION_NS, 'daizu');
        $elem->setAttribute(filetype => $self->{daizu_syncolor_filetype});
        $self->{daizu_syncolor_filetype} = undef;
    }
    else {
        $elem = XML::LibXML::Element->new('pre');
    }

    $elem->appendChild(_text(join "\n", @$lines));

    $self->{daizu_curelem}->appendChild($elem);
    $self->{daizu_verbatim} = undef;
}

sub verbatim
{
    my ($self, $text, $line_num, $pod_para) = @_;

    if ($self->{title_para_next}) {
        _do_heading($self, $line_num, 1, 'Name');
        $self->{title_para_next} = 0;
    }

    # Strip leading and trailing whitespace, except for indent on first line.
    $text =~ s/^\s+\n//;
    $text =~ s/\s+\z//;

    my @lines = split /\r?\n/, $text;
    return unless @lines;       # Pod::Parser gives me empty verbatim blocks

    # Work out what the minimum amount of indentation was, so that the
    # common indentation can be stripped off.
    my $min_indent;
    for (@lines) {
        s/\s+\z//;
        warn "$line_num: POD indented with tabs"
            if s/\t/        /g;
        m!^( *)!;
        my $indent = length($1);
        $min_indent = $indent
            if !defined $min_indent || $indent < $min_indent;
    }

    if (defined $self->{daizu_verbatim}) {
        # This is another paragraph of a verbatim block we've already started.
        # Each paragraph should be separated by a single blank line.
        push @{$self->{daizu_verbatim}}, '', @lines;
        $self->{daizu_verbatim_min_indent} = $min_indent
            if $min_indent < $self->{daizu_verbatim_min_indent};
    }
    else {
        # This is the start of a new verbatim block.
        $self->{daizu_verbatim} = \@lines;
        $self->{daizu_verbatim_min_indent} = $min_indent;
    }
}

sub _text {
    my ($s) = @_;
    utf8::upgrade($s);
    return XML::LibXML::Text->new($s);
}

sub _elem
{
    my ($name, @children) = @_;
    my $elem = XML::LibXML::Element->new($name);
    _add_parsed_text_to_elem($elem, @children);
    return $elem;
}

{
    # This is derived from Pod::Html::fragment_id().
    my @HC;
    sub _fragment_id
    {
        local $_ = shift;

        # a method or function?
        return $1 if /(\w+)\s*\(/;
        return $1 if /->\s*(\w+)\s*\(?/;

        # a variable name?
        return $1 if /^([\$\@%*]\S+)/;

        # some pattern matching operator?
        return $1 if m!^(\w+/).*/\w*$!;

        # fancy stuff... like "do { }"
        return $1 if m!^(\w+)\s*{.*}$!;

        # honour the perlfunc manpage: func [PAR[,[ ]PAR]...]
        # and some funnies with ... Module ...
        return $1 if m{^([a-z\d_]+)(\s+[A-Z\d,/& ]+)?$};
        return $1 if m{^([a-z\d]+)\s+Module(\s+[A-Z\d,/& ]+)?$};

        # text? normalize!
        s/\s+/_/sg;
        s{(\W)}{
             defined( $HC[ord($1)] ) ? $HC[ord($1)]
                     : ( $HC[ord($1)] = sprintf( "%%%02X", ord($1) ) )
        }gxe;
        return substr($_, 0, 50);
    }
}

sub _anchorify
{
    my ($anchor) = @_;
    $anchor =~ s/\s+/ /g;
    $anchor =~ s/[-"?]//g;
    $anchor =~ s/\W/_/g;
    return lc $anchor;
}

my %SEQUENCE_HANDLER = (
    I => sub { _elem(i => @_) },
    B => sub { _elem(b => @_) },
    C => sub { _elem(code => @_) },
    L => sub {
        # TODO - markup in L<>, and escaping | and / won't work yet
        local $_ = '';
        for my $s (@_) {
            $_ .= ref($s) ? $s->textContent : $s;
        }
        $_ = trim($_);

        my ($label, $link, $fragment) = @_;
        if (m!^([^|/]+)$!s) {           # L<item>
            $label = $link = $1;
        }
        elsif (/^(https?:.+)$/is) {
            $label = $link = $1;
        }
        elsif (m!^([^|/]+)\|(https?:.+)$!is) {
            $label = $1;
            $link = $2;
        }
        elsif (m!^(.+)\|(.+)/(.+)$!s) { # L<label|module/item>
            $label = $1;
            $link = $2;
            $fragment = $3;
        }
        elsif (m!^(.+)\|/(.+)$!s) {     # L<label|/item>
            $label = $1;
            $fragment = $2;
        }
        elsif (m!^(.+)\|([^/]+)$!s) {   # L<label|module>
            $label = $1;
            $link = $2;
        }
        elsif (m!^(.+)/(.+)$!s) {       # L<module/item>
            $label = "\x{201C}$2\x{201D} in $1";
            $link = $1;
            $fragment = $2;
        }
        elsif (m!^/(.+)$!s) {           # L</item>
            $label = "\x{201C}$1\x{201D}";
            $fragment = $1;
        }
        else {
            warn "bad link L<$_>";
        }

        $label = trim($label);
        $link = trim($link);
        $fragment = trim($fragment);

        if (defined $link && $link !~ /^https?:/i) {
            my $module_links = _module_links();
            if (exists $module_links->{$link}) {
                $link = $module_links->{$link};
            }
            else {
                if ($link =~ /^([\w:]+)$/) {
                    # This may or may not work, depending on the module.
                    $link = "http://search.cpan.org/perldoc?$1";
                }
                else {
                    warn "bad link '$_' (no module link defined), ignoring";
                    return @_;
                }
            }
        }

        if (defined $fragment) {
            $fragment = 'item_' . _anchorify(_fragment_id($fragment));
            if (defined $link) {
                $link =~ s/#.*\z//;
                $link = "$link#$fragment";
            }
            else {
                $link = "#$fragment";
            }
        }

        my $elem = _elem('a', $label);
        $elem->setAttribute(href => $link);
        return $elem;
    },
    E => sub {
        local $_ = join '', map { ref($_) ? $_->nodeValue : $_ } @_;
        return "E<$_>" unless /\S/;      # invalid, treat as plain text
        return '<' if $_ eq 'lt';
        return '>' if $_ eq 'gt';
        return '|' if $_ eq 'verbar';
        return '/' if $_ eq 'sol';
        return chr(171) if $_ eq 'lchevron';    # legacy alias of laquo
        return chr(187) if $_ eq 'rchevron';    # legacy alias of raquo
        $_ = trim($_);
        return ord(oct($1)) if /^(0\d+)$/;
        return ord($1) if /^(\d+)$/;
        # Allow 'xFF' instead of '0xFF' because Pod::Html does.
        return ord(hex($1)) if /^0?x(\d+)$/i;
        return decode_entities("&$_;");
    },
    F => sub { _elem(i => @_) },
    S => sub {
        for my $val (@_) {
            if (ref $val) {
                for ($val->findnodes('//text()')) {
                    my $s = $_->nodeValue;
                    $s =~ s/\s+/\xA0/g;
                    $_->setData($s);
                }
            }
            else {
                $val =~ s/\s+/\xA0/g;
            }
        }
        return @_;
    },
    X => sub { @_ },
    Z => sub { '' },
);

sub _flatten_parse_trees {
    map { ref && $_->isa('Pod::ParseTree') ? ($_->children) : ($_) } @_
}

sub _daizu_parse_text
{
    my ($self, $text, $line_num) = @_;
    $text =~ s/\s+\z//;

    return $self->parse_text({
        -expand_seq => sub {
            my ($parser, $seq) = @_;
            my $cmd = $seq->cmd_name;
            if (exists $SEQUENCE_HANDLER{$cmd}) {
                my @expansion = $SEQUENCE_HANDLER{$cmd}->(
                    _flatten_parse_trees($seq->parse_tree->children),
                );
                return @expansion
                    if @expansion == 1;
                return Pod::ParseTree->new(\@expansion);
            }
            else {
                # The command isn't one we know, so just treat it as plain
                # text, but still interpret any nested sequences.
                return Pod::ParseTree->new([
                    $cmd,
                    $seq->left_delimiter,
                    $seq->parse_tree->children,
                    $seq->right_delimiter,
                ]);
            }
        },
    }, $text, $line_num);
}

sub _add_parsed_text_to_elem
{
    my $elem = shift;

    for my $value (@_) {
        $value = _text($value)
            unless ref $value;
        $elem->appendChild($value);
    }
}

sub textblock
{
    my ($self, $text, $line_num, $pod_para) = @_;
    _do_verbatim($self, $line_num)
        if defined $self->{daizu_verbatim};
    die "$line_num: text paragraph between =over and =item"
        unless defined $self->{daizu_curelem};

    my $tree = _daizu_parse_text($self, $text, $line_num);
    my @content = _flatten_parse_trees($tree->children);

    if ($self->{title_para_next}) {
        $self->{doc_title} = join '', @content;
        $self->{done_title} = 1;
        $self->{title_para_next} = 0;
        return;
    }

    # TODO - blockquote sometimes?
    my $elem = _elem(p => @content);
    $self->{daizu_curelem}->appendChild($elem);
}

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
