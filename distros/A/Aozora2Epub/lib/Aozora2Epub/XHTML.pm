package Aozora2Epub::XHTML;
use strict;
use warnings;
use utf8;
use Aozora2Epub::XHTML::Tree;
use Aozora2Epub::Gensym;
use Aozora2Epub::File;
use HTML::Element;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw/title author content bib_info notation_notes gaiji fig/);

our $VERSION = '0.01';

sub new {
    my ($class, $url) = @_;
    my $base = $url;
    $base =~ s{[^/]+\.html$}{}s;
    return $class->new_from_string(get($url), $base);
}

sub new_from_string {
    my ($class, $html) = @_;
    my $self = bless { raw_content => $html }, $class;
    $self->process_doc();
    return $self;
}

sub _process_header {
    my $h = shift;

    # <hx><a id="xxx">ttt</a></hx> to <hx id="xxx">ttt</hx>
    # where hx is h1 h2 h3, h4, h5, etc
    my $anchor = $h->find_by_tag_name('a');
    if ($anchor) {
        my $id = $anchor->attr('id');
        $h->attr('id', $id);
        $anchor->replace_with($anchor->content_list);
    }
    $h->attr('id') or $h->attr('id', gensym);
    # <div class="jisage_*" style="margin-left: nn"><hx> to <hx style="text-indent: nn">
    # where hx is h3, h4, h5, etc
    my $parent = $h->parent;
    if ($parent && $parent->isa('HTML::Element')
        && $parent->tag('div')
        && $parent->attr('class')
        && $parent->attr('class') =~ m{jisage_\d+}) {
        my $indent = $parent->attr('style');
        $indent =~ s{margin-left:}{text-indent:};
        $indent .= " " . $h->attr('style') if $h->attr('style');
        $h->attr('style', $indent);
        $parent->replace_with($h);
    }
}

sub _process_img {
    my $img = shift;

    my $src = $img->attr('src');
    if ($src =~ m{/(gaiji/.+\.png)$}) {
        $img->attr('src', "../$1");
        return;
    }
    # normal image
    $img->attr('src', "../images/$src");
    # find caption
    my $br = $img->right;
    return unless $br->tag eq 'br';
    my $caption = $br->right;
    return unless $caption;
    return unless $caption->isa('HTML::Element');
    return unless $caption->tag eq 'span' && $caption->attr('class') =~ /caption/;
    $br->detach;
    $caption->detach;
    $caption->tag('figcaption');
    $img->replace_with(['figure', $img, $caption]);
}

sub _is_empty {
    my $elem = shift;
    unless ($elem->isa('HTML::Element')) {
        return $elem =~ /^\s+$/s;
    }
    return $elem->tag eq 'br';
}

sub process_doc {
    my $self = shift;

    my ($title, $author, $bib_info, $notation_notes, @images);
    my @contents = Aozora2Epub::XHTML::Tree->new($self->{raw_content})
        ->process('h1.title', sub {
            $title = shift->as_text;
        })
        ->process('h2.author', sub {
            $author = shift->as_text;
        })
        ->process('div.bibliographical_information', sub {
            my $bio = shift;
            my $hr = $bio->find_by_tag_name('hr');
            $hr->detach if $hr;
            $bib_info = $bio->as_HTML('<>&', undef, {});
            $bib_info =~ s{^<div class="bibliographical_information"><br /> }{}s;
            $bib_info =~ s{<br /><br /><br /></div>$}{}s;
        })
        ->process('body > div.notation_notes', sub {
            my $nn = shift;
            $notation_notes = $nn->as_HTML('<>&', undef, {});
        })
        ->select('div.main_text')
        ->children
        ->process('img', sub {
            my $img = shift;
            push @images, $img->attr('src');
            _process_img($img);
        })
        ->process('//div[contains(@style, "width")]', => sub {
            my $div = shift;
            my $style = $div->attr('style');
            $style =~ s/(?<![-\w])width:/height:/sg;
            $div->attr('style', $style);
        })
        ->process('h1', \&_process_header)
        ->process('h2', \&_process_header)
        ->process('h3', \&_process_header)
        ->process('h4', \&_process_header)
        ->process('h5', \&_process_header)
        #->process('span.notes', sub {
        #    print STDERR shift->as_HTML('&<>'),"\n";
        #})
        ->as_list;

    # 先頭の<br/>の連続は削除
    while ($contents[0] && _is_empty($contents[0])) { shift @contents; };

    my (@gaiji, @fig);
    for my $path (@images) {
        if ($path =~ m{gaiji/(.+\.png)$}) {
            push @gaiji, $1;
        } else {
            push @fig, $path;
        }
    }
    $self->{title} = $title;
    $self->{author} = $author;
    $self->{contents} = \@contents;
    $self->{bib_info} = $bib_info || '';
    $self->{notation_notes} = $notation_notes || '';
    $self->{gaiji} = \@gaiji;
    $self->{fig} = \@fig;
}

sub split {
    my $self = shift;

    # ファイルを分割
    # <br/>*<h[123]>* / [#改ページ] / [#改丁]
    my @cur;
    my @files;
    my @contents = @{$self->{contents}};
    while (my $c = shift @contents) {
        unless ($c->isa('HTML::Element')) {
            push @cur, $c;
            next;
        }
        if ($c->tag eq 'span' && $c->attr('class') =~ /notes/
            && $c->as_text =~ /＃改丁|＃改ページ/) {
            push @files, [@cur] if @cur;
            @cur = ();
            next;
        }
        if ($c->tag =~ m{h[123]}) { # ファイルを区切る
            # 直前の<br/>あるいは空白文字は新しいファイルにいれる
            my @newcur;
            my $last_elem = pop @cur;
            while ($last_elem && _is_empty($last_elem)) {
                push @newcur, $last_elem;
                $last_elem = pop @cur;
            }
            push @cur, $last_elem if $last_elem; # popしすぎた分は戻す
            push @files, [@cur] if @cur; # @curが空なら改ページ直後なので何もしない
            push @newcur, $c;
            # 連続する<h[123]では区切らない
            while (my $c1 = shift @contents) {
                unless ($c1->isa('HTML::Element')) {
                    push @newcur, $c1;
                    last;
                }
                unless (_is_empty($c1)
                        || $c->tag =~ m{h[123]}) {
                    push @newcur, $c1;
                    last;
                }
                push @newcur, $c1;
            }

            @cur = @newcur;
            next;
        }
        push @cur, $c;
    }
    push @files, [@cur] if @cur;
    return map { Aozora2Epub::File->new($_) } @files;
}

1;

__END__
