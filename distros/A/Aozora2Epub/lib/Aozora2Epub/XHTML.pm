package Aozora2Epub::XHTML;
use strict;
use warnings;
use utf8;
use Aozora2Epub::CachedGet qw/http_get/;
use Aozora2Epub::XHTML::Tree;
use Aozora2Epub::Gensym;
use Aozora2Epub::File;
use HTML::Element;
use Encode::JISX0213;
use Encode qw/decode/;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw/title subtitle author
                             contents
                             bib_info notation_notes gaiji fig/);

our $VERSION = "0.04";

sub jisx0213_to_utf8 {
    my ($men, $ku, $ten) = @_;
    $ku += 0xa0;
    $ten += 0xa0;
    my $euc = join('', ($men == 2 ? chr(0x8f) : ()),
                   chr($ku), chr($ten));
    my $utf8 = decode('euc-jp-2004', $euc);
    return $utf8;
}

sub kindle_jis2chr {
    my ($men, $ku, $ten) = @_;

    # 半濁点付きカタカナ フ kindleだと2文字に見えるのなんとかならんか？
    return if $men == 1 && $ku == 6 && $ten == 88;

    # kindle font of these characters are broken.
    return if $men == 1 && $ku == 90 && $ten == 61;
    return if $men == 2 && $ku == 15 && $ten == 73;
    return jisx0213_to_utf8($men, $ku, $ten);
}

# kindle font of these characters are broken.
our %kindle_broken_font_unicode = map { $_ => 1 } (
    0x2152,
    0x2189,
    0x26bd,
    0x26be,
    0x3244,
);

our %kindle_ok_font_over0xffff = map { $_ => 1 } (
    0x20d58, 0x20e97, 0x20ed7, 0x210e4, 0x2124f, 0x2296b,
    0x22d07, 0x22e42, 0x22feb, 0x233fe, 0x23cbe, 0x249ad,
    0x24e04, 0x24ff2, 0x2546e, 0x2567f, 0x259cc, 0x2688a,
    0x279b4, 0x280e9, 0x28e17, 0x29170, 0x2a2b2,
);

sub kindle_unicode_hex2chr {
    my $unicode_hex = shift;
    my $unicode = hex($unicode_hex);

    return if $kindle_broken_font_unicode{$unicode};

    # kindle font is almost not avaliable in this range.
    return if $unicode > 0xffff && !$kindle_ok_font_over0xffff{$unicode};

    return chr($unicode);
}

sub _conv_gaiji_title_author {
    my ($unicode, $men, $ku, $ten) = @_;
    if ($unicode) {
        my $ch = kindle_unicode_hex2chr($unicode);
        return $ch if $ch;
        return;
    }
    my $ch = kindle_jis2chr(0+$men, 0+$ku, 0+$ten);
    return $ch if $ch;
    return;
}

sub conv_gaiji_title_author {
    my $s = shift;
    return $s unless $s;
    $s =~ s{(.［＃[^、］]*、(U\+([A-Fa-f0-9]+)|.*?(\d)-(\d+)-(\d+)).*?］)}
           {
               my $all = $1;
               my $ch = _conv_gaiji_title_author($3, $4, $5, $6);
               $ch ? $ch : $all;
           }esg;
    return $s
}

sub new {
    my ($class, $url) = @_;
    my $base = $url;
    $base =~ s{[^/]+\.html$}{}s;
    return $class->new_from_string(http_get($url), $base);
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
    if ($src =~ m{/(gaiji/\d-\d+/(\d)-(\d\d)-(\d\d)\.png)$}) {
        my $ch = kindle_jis2chr(0+$2, 0+$3, 0+$4);
        if ($ch) {
            $img->replace_with($ch);
            return;
        }
        $img->attr('src', "../$1");
        return $src;
    }
    # normal image
    $img->attr('src', "../images/$src");
    # find caption
    my $br = $img->right;
    return $src unless $br && $br->isa('HTML::Element') && $br->tag eq 'br';
    my $caption = $br->right;
    return $src unless $caption;
    return $src unless $caption->isa('HTML::Element');
    return $src unless $caption->tag eq 'span' && $caption->attr('class') =~ /caption/;
    $br->detach;
    $caption->detach;
    $caption->tag('figcaption');
    $img->replace_with(['figure', $img, $caption]);
    return $src;
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

    my ($title, $subtitle, $author,
        $bib_info, $notation_notes, @images);
    my @contents = Aozora2Epub::XHTML::Tree->new($self->{raw_content})
        ->process('h1.title', sub {
            $title = shift->as_text;
        })
        ->process('h2.subtitle', sub {
            $subtitle = shift->as_text;
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
            my $orig_src = _process_img($img);
            $orig_src and push @images, $orig_src;
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
        ->process('//div[contains(@style, "margin")]', => sub {
            my $div = shift;
            my $style = $div->attr('style');
            $style =~ s/margin-left/margin-top/sg;
            $style =~ s/margin-right/margin-bottom/sg;
            $div->attr('style', $style);
        })
        ->process('span.notes', sub {
            my $span = shift;
            my $note = $span->as_text;
            return unless $note =~ m{［＃[^\］]+?、([^\］]+)］};
            my $desc = $1;
            my $ch = do {
                if ($desc =~ /U\+([A-fa-f0-9]+)/) {
                    kindle_unicode_hex2chr($1);
                } elsif ($desc =~ /第\d水準(\d)-(\d+)-(\d+)/) {
                    kindle_jis2chr(0+$1, 0+$2, 0+$3);
                }
            };
            return unless $ch;

            # find nearest ※ and replace it to $ch
            my $left = $span->left;
            unless ($left->isa('HTML::Element')) {
                if ($left =~ s/※$/$ch/) {
                    $span->parent->splice_content($span->pindex - 1, 2, $left);
                }
                return;
            }
            if ($left->tag eq 'ruby') {
                my $rb = $left->find_by_tag_name('rb');
                my $s = $rb->as_text;
                if ($s =~ s/※/$ch/) {
                    $rb->replace_with(HTML::Element->new_from_lol([rb => $s]));
                    $span->delete;
                }
                return;
            }
        })
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
    $self->title(conv_gaiji_title_author($title));
    $self->subtitle(conv_gaiji_title_author($subtitle));
    $self->author(conv_gaiji_title_author($author));
    $self->contents(\@contents);
    $self->bib_info($bib_info || '');
    $self->notation_notes($notation_notes || '');
    $self->gaiji(\@gaiji);
    $self->fig(\@fig);
}

sub _is_chuuki {
    my $elem = shift;
    return $elem->isa('HTML::Element')
           && $elem->tag eq 'span'
           && $elem->attr('class') && $elem->attr('class') =~ /notes/;
}

sub _is_pagebreak {
    my $elem = shift;
    return _is_chuuki($elem) && $elem->as_text =~ /＃改丁|＃改ページ/;
}

sub _is_center_chuuki {
    my $elem = shift;
    return _is_chuuki($elem) && $elem->as_text =~ /＃ページの左右中央/;
}

sub split {
    my $self = shift;

    # ファイルを分割
    # <br/>*<h[123]>* / [#改ページ] / [#改丁]
    my @cur;
    my @files;
    my @contents = @{$self->contents};
    while (my $c = shift @contents) {
        unless ($c->isa('HTML::Element')) {
            push @cur, $c;
            next;
        }
        if (_is_pagebreak($c)) {
            push @files, [@cur] if @cur;
            @cur = ();
            next;
        }
        if ($c->tag =~ m{h[123]}) { # ファイルを区切る
            # 直前の<br/>あるいは空白文字は新しいファイルにいれる
            my @newcur;
            my $last_elem = pop @cur;
            while ($last_elem
                   && (_is_empty($last_elem)
                       || _is_center_chuuki($last_elem))) {
                push @newcur, $last_elem unless _is_center_chuuki($last_elem);
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

                if (_is_pagebreak($c1)) {
                    push @files, [@newcur] if @newcur;
                    @newcur = ();
                    last;
                }

                unless (_is_empty($c1)
                        || $c1->tag =~ m{h[123]}) {
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

sub _dump_elem {
    my ($e, $no_nl) = @_;

    if (ref $e eq 'ARRAY') {
        for my $x (@$e) {
            _dump_elem($x, 1);
        }
        print STDERR "\n";
        return;
    }
    
    my $str;
    unless ($e->isa('HTML::Element')) {
        $str = $e;
    } else {
        $str = $e->as_HTML('<>&', undef, {});
    }
    print STDERR "!E!$str", $no_nl ? " " : "\n";
}

1;

__END__
