package Aozora2Epub;
use utf8;
use strict;
use warnings;
use Aozora2Epub::Gensym;
use Aozora2Epub::CachedGet qw/http_get/;
use Aozora2Epub::Epub;
use Aozora2Epub::XHTML;
use URI;
use HTML::Escape qw/escape_html/;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw/files title author epub bib_info notation_notes/);

our $VERSION = '0.03';

our $AOZORA_GAIJI_URI = URI->new("https://www.aozora.gr.jp/gaiji/");

sub _base_url {
    my $base = shift;
    $base =~ s{[^/]+\.html$}{}s;
    return $base;
}

sub _get_content {
    my $xhtml = shift;
    if ($xhtml =~ m{/card\d+\.html$}) { # 図書カード
        unless ($xhtml =~ m{^https?://}) { # $xhtml shuld be \d+/card\d+.html
            $xhtml = "https://www.aozora.gr.jp/cards/$xhtml";
        }
        my $text = http_get($xhtml);
        my $tree = Aozora2Epub::XHTML::Tree->new($text);
        my $xhtml_url;
        $tree->process('//a[text()="いますぐXHTML版で読む"]' => sub {
            $xhtml_url = shift->attr('href');
        });
        my $xhtml_uri = URI->new($xhtml_url)->abs(URI->new($xhtml));
        return _get_content($xhtml_uri->as_string);
    }
    if ($xhtml =~ m{/files/\d+_\d+\.html$}) { # XHTML
        unless ($xhtml =~ m{^https?://}) { # $xhtml shuld be \d+/files/xxx_xxx.html
            $xhtml = "https://www.aozora.gr.jp/cards/$xhtml";
        }
        my $text = http_get($xhtml);
        return ($text, _base_url($xhtml));
    }
    # XHTML string
    return (qq{<div class="main_text">$xhtml</div>}, undef);
}

sub new {
    my ($class, $content, %options) = @_;
    my $self =  bless {
        files => [],
        epub => Aozora2Epub::Epub->new,
        title => undef,
        author => undef,
        bib_info => '',
        notation_notes => '',
    }, $class;
    $self->append($content, %options, title=>'') if $content;
    return $self;
}

sub append {
    my ($self, $xhtml_like, %options) = @_;

    my ($xhtml, $base_url) = _get_content($xhtml_like);
    my $doc = Aozora2Epub::XHTML->new_from_string($xhtml);

    unless ($options{no_fetch_assets}) {
        for my $path (@{$doc->gaiji}) {
            my $x = URI->new($path)->abs($AOZORA_GAIJI_URI);
            my $png = http_get(URI->new($path)->abs($AOZORA_GAIJI_URI));
            $self->epub->add_gaiji($png, $path);
        }
        my $base_uri = URI->new($base_url);
        for my $path (@{$doc->fig}) {
            my $png = http_get(URI->new($path)->abs($base_uri));
            $self->epub->add_image($png, $path);
        }
    }
    my @files = $doc->split;
    my $part_title;
    unless (defined $options{title}) {
        $part_title = $doc->title;
    } elsif ($options{title} eq '') {
        $part_title = undef;
    } else {
        $part_title = $options{title};
    }
    if ($files[0] && $part_title) {
        my $title_level = $options{title_level} || 2;
        my $tag = "h$title_level";
        $files[0]->insert_content([ $tag, { id => gensym }, $part_title ]);
    }
    push @{$self->files}, @files;
    $self->title or $self->title($doc->title);
    $self->author or $self->author($doc->author);
    $self->add_bib_info($part_title, $doc->bib_info);
    $self->add_notation_notes($part_title, $doc->notation_notes);
}

sub add_bib_info {
    my ($self, $part_title, $bib_info) = @_;

    $self->bib_info(join('',
                         $self->bib_info,
                         "<br/>",
                         ($part_title
                          ? (q{<h5 class="bib">}, escape_html($part_title), "</h5>")
                          : ()),
                         $bib_info));
}

sub add_notation_notes {
    my ($self, $part_title, $notes) = @_;

    $self->notation_notes(join('',
                               $self->notation_notes,
                               "<br/>",
                               ($part_title
                                ? (q{<h5 class="n-notes">}, escape_html($part_title), "</h5>")
                                : ()),
                               $notes));
}

sub _make_content_iterator {
    my $files = shift;

    my @files = @$files;
    my $file = shift @files;
    my @content = @{$file->content};
    my $last;

    return (
        sub { # get next element
            if ($last) {
                my $x = $last;
                undef $last;
                return $x;
            }
            my $elem = shift @content;
            unless ($elem) {
                $file = shift @files;
                return unless $file;
                @content = @{$file->content};
                $elem = shift @content;
            }
            return { elem=>$elem, file=>$file->name };
        },
        sub { $last  = shift; } # putback
    );
}

sub _toc {
    my ($level, $next, $putback) = @_;

    my @cur;
    while (my $c = $next->()) {
        my $e = $c->{elem};
        next unless $e->isa('HTML::Element');
        my $tag = $e->tag;
        my ($lev) = ($tag =~ m{h(\d)});
        next unless $lev;
        if ($lev > $level) {
            $putback->($c);
            my $children = _toc($lev, $next, $putback);
            if ($cur[-1] && $cur[-1]->{level} < $lev) {
                $cur[-1]->{children} = $children;
            } else {
                push @cur, @{$children};
            }
            next;
        }
        if ($lev < $level) {
            $putback->($c);
            return \@cur;
        }
        push @cur, {
            name => gensym,
            level => $lev,
            id => $e->attr('id'),
            title => $e->as_text,
            file => $c->{file},
        };
    }
    return \@cur;
}

sub toc {
    my $self = shift;
    my ($next, $putback) = _make_content_iterator($self->{files});
    return _toc(1, $next, $putback);
}

sub to_epub {
    my ($self, %options) = @_;

    my $epub_filename = $options{output};
    $epub_filename ||= $self->title . ".epub";

    if ($options{cover}) {
        $self->epub->set_cover($options{cover});
    }
    $self->epub->build_from_doc($self);

    $self->epub->save($epub_filename);
}

sub as_html {
    my $self = shift;
    return join('', map { $_->as_html } @{$self->files});
}
1;
__END__

=encoding utf-8

=head1 NAME

Aozora2Epub - Convert Aozora Bunko XHTML to EPUB

=head1 SYNOPSIS

  use Aozora2Epub;

  my $book = Aozora2Epub->new("https://www.aozora.gr.jp/cards/000262/files/48074_40209.html");
  $book->to_epub;

  # 合本の作成
  $book = Aozora2Epub->new();
  $book->append("000879/card179.html"); # 藪の中
  $book->append("000879/card127.html"); # 羅生門
  $book->title('芥川竜之介作品集');
  $book->to_epub;


=head1 DESCRIPTION

Aozora2Epub は青空文庫のXHTML形式の本をEPUBに変換するモジュールです。

簡単に合本を生成するためのインタフェースも提供しています。

=head1 METHODS

=head2 new

  my $book = Aozora2Epub->new($book_url);
  my $book = Aozora2Epub->new($xhtml_string);
  my $book = Aozora2Epub->new(); # 空のドキュメントを作る

C<$bool_url>で指定した青空文庫の本を読み込みます。
あるいは、文字列として指定された整形式のXHTMLを本の内容として読み込みます。

本は以下のいずれかの形式で指定します。
いずれも、URL先頭の C<https://www.aozora.gr.jp/cards/>の部分を省略することが可能です。

=over 4

=item 図書カードのURL

青空文庫の図書カードのURLです。以下に例を示します。

  https://www.aozora.gr.jp/cards/001569/card59761.html
  
  001569/card59761.html # URLの先頭部分を省略

=item XHTMLのURL

青空文庫のXHTMLファイルのURLです。以下に例を示します。

  https://www.aozora.gr.jp/cards/001569/files/59761_74795.html
  
  001569/files/59761_74795.html # URLの先頭部分を省略

=back

=head2 append

  $book->append($book_url);
  $book->append($book_url, title=>"第2部");
  $book->append($book_url, title=>"第2部", title_level=>1); # <h1>第2部</h1>を付加
  $book->append($xhtml_string);

指定した本の内容を追加します。本の指定方法はC<new>メソッドと同じです。

追加される本のタイトルが、追加される本の内容の先頭に C<< <h2>タイトル</h2> >> という形で付加されます。
C<title>オプションによって、このタイトルを指定することができます。
C<< title=>'' >>とすると、ヘッダ要素を追加しません。
C<title_level>オプションで、付加されるヘッダ要素のレベルを変更することができます。

=head2 title

  $book->title; # タイトルを取得
  $book->title('随筆集'); # タイトルを設定

タイトルを取得/設定します。

=head2 S<author>

  $book->author; # 著者を取得
  $book->author('山田太郎'); # 著者を設定

著者を取得/設定します。

=head2 bib_info

  $book->bib_info; # 奥付の内容を取得
  $book->bib_info(undef); # 奥付を消去

奥付の内容を取得/設定します。
C<undef>を設定して奥付を消去すると、EPUBに奥付が含まれなくなります。

=head2 to_epub

  $book->to_epub();
  $book->to_epub(output=>'my.epub', cover=>'mycover.jpg');

EPUBを出力します。オプションは以下の通りです。

=over 4

=item output

出力するEPUBファイルのパスを指定します。デフォルトはC<本のタイトル.epub>です。

=item cover

表紙のイメージファイルを指定します。JPEGファイルでなければなりません。
指定しない場合は、表紙イメージを持たないEPUBが出力されます。

=back

=head2 as_html

  my $html = $book->as_html;

本の内容をHTMLで返します。

=head1 合本の作成

最もシンプルなのは、合本に含めたい本をC<append>で連結して行くことです。

  my $book = Aozora2Epub->new();
  $book->append("000879/card179.html"); # 藪の中
  $book->append("000879/card127.html"); # 羅生門
  $book->title('芥川竜之介作品集');
  $book->to_epub;

タイトルはほとんどの場合、明示的に設定することになるでしょう。
上記の例でタイトルを設定しなかった場合、合本のタイトルは最初の本のタイトル、つまり「藪の中」になります。

以下は、少し凝った例です。

  my $book = Aozora2Epub->new();
  $book->title('春夏秋冬料理王国');

  # 青空文庫の本のタイトルは "「春夏秋冬　料理王国」序にかえて" なので、タイトルを変更する
  $book->append("001403/card59653.html", title=>'序にかえて');

  $book->append(q{<h1 class="tobira">料理する心</h1>}); # 中扉を入れる
  $book->append("001403/card54984.html"); # 道は次第に狭し
  $book->append("001403/card50009.html"); # 料理の第一歩
  $book->append(q{<h1 class="tobira">お茶漬の味</h1>});   # 中扉を入れる
  $book->append("001403/card54975.html"); # 納豆の茶漬
  $book->append("001403/card54976.html"); # 海苔の茶漬

  # 青空文庫の本のタイトルは "小生のあけくれ" なので変更する。
  # 「お茶漬の味」のサブセクションにならない様に title_level も指定する
  $book->append("001403/card49981.html", title=>'あとがき',
                title_level=>1);
  $book->to_epub;

上記のコードは、以下の構造のepubを出力します。

  序にかえて
  料理する心
    道は次第に狭し
    料理の第一歩
  お茶漬の味
    納豆の茶漬け
    海苔
  あとがき

=head1 青空文庫ファイルのキャッシュ

青空文庫からファイルを取得する際に、C<~/.aozora2epub> にキャッシュします。
これは環境変数 C<AOZORA2EPUB_CACHE> で指定したディレクトリに変更することができます。

キャッシュされたファイルは30日間有効で、それを過ぎると自動的に削除されます。

=head1 AUTHOR

Yoshimasa Ueno E<lt>saltyduck@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2024- Yoshimasa Ueno

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<aozora2epub>

L<青空文庫|https://www.aozora.gr.jp/>

=cut
