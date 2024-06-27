use strict;
use warnings;
use utf8;
use Test::More;
use Test::Base;
use Aozora2Epub;
use Aozora2Epub::Gensym;
use lib qw/./;
use t::Util;

plan tests => 1 * blocks;

sub drop_nlsp {
    my $s = shift;
    $s =~ s/\n *//sg;
    $s =~ s/\n$//sg;
    $s;
}

filters {
    html => 'chomp',
    expected => 'yaml',
};

run {
    my $block = shift;
    Aozora2Epub::Gensym->reset_counter;
    
    my $doc = Aozora2Epub->new($block->html, no_fetch_assets=>1);
    my $got = [ map { $_->as_html } @{$doc->files} ];
    is_deeply($got,
              [ map { drop_nlsp($_) } @{$block->expected} ],
              $block->name);
};

__DATA__

=== beginning br
--- html
<br/><br />あいうえお
--- expected
- あいうえお
--- note
本の先頭の<br/>の連続は削除される。

=== o-midashi
--- html
あ<br/>
<h3 class="o-midashi">
  <a class="midashi_anchor" id="midashi001">見出し</a>
</h3>
あいう
--- expected
- あ
- <br /><h3 class="o-midashi" id="midashi001">見出し</h3> あいう

=== naka-midashi
--- html
あ<br/>
<h4 class="naka-midashi">
  <a class="midashi_anchor" id="midashi001">見出し</a>
</h4>
あいう
--- expected
- あ<br /><h4 class="naka-midashi" id="midashi001">見出し</h4> あいう

=== ko-midashi
--- html
あ<br/>
<h5 class="ko-midashi">
  <a class="midashi_anchor" id="midashi001">見出し</a>
</h5>
あいう
--- expected
- あ<br /><h5 class="ko-midashi" id="midashi001">見出し</h5> あいう
--- note
小見出しは別のxhmlにファイル分割しない

=== mado-ko-midashi
--- html
<br/>
<h5 class="mado-ko-midashi">
  <a class="midashi_anchor" id="midashi001">見出し</a>
</h5>
あいう
--- expected
- <h5 class="mado-ko-midashi" id="midashi001">見出し</h5> あいう
--- note
小見出しは別のxhmlにファイル分割しない

=== h1 h2 h3
--- html
<h1 id="h1">header1</h1>
<h2 id="h11">header1-1</h2>
<h3 id="h111">header1-1-1</h3>aaa<br />
<h2 id="h12">header1-2</h2>
<h3 id="h121">header1-2-1</h3>bbb<br />
--- expected
- |
  <h1 id="h1">header1</h1>
  <h2 id="h11">header1-1</h2>
  <h3 id="h111">header1-1-1</h3>aaa
- |
  <br /><h2 id="h12">header1-2</h2>
  <h3 id="h121">header1-2-1</h3>bbb<br />
--- note
連続する<h[123]では一度しかファイル分割しない

=== h1 elem h2 h3
--- html
<h1 id="h1">header1</h1>
<div style="margin-left: 4em">あああ</div>
<h2 id="h11">header1-1</h2>
<h3 id="h111">header1-1-1</h3>aaa<br />
--- expected
- |
  <h1 id="h1">header1</h1>
  <div style="margin-top: 4em">あああ</div>
- |
  <h2 id="h11">header1-1</h2>
  <h3 id="h111">header1-1-1</h3>aaa<br />

=== dokuritu tobira
--- html
あ
<span class="notes">［＃改丁］</span><br />
<span class="notes">［＃ページの左右中央］</span><br />
<br />
<br />
<div class="jisage_7" style="margin-left: 7em"><h3 class="o-midashi"><a class="midashi_anchor" id="midashi260">昭和十八年</a></h3></div>
<br />
<br />
<span class="notes">［＃改丁］</span><br />
<br />いうえ
--- expected
- 'あ '
- '<br /><br /><br /><br /><h3 class="o-midashi" id="midashi260" style="text-indent: 7em">昭和十八年</h3><br /><br />'
- <br /><br />いうえ

=== jisage
--- html
<br />
<div class="jisage_2" style="margin-left: 2em">
  <h3 class="o-midashi"><a class="midashi_anchor" id="midashi560">先生と私</a></h3>
</div>
<br />
--- expected
- '<h3 class="o-midashi" id="midashi560" style="text-indent: 2em">先生と私</h3><br />'

=== figure with caption
--- html
<img class="illustration" src="fig4990_07.png" alt="XXX のキャプション付きの図" /><br />
<span class="caption">XXX</span><br />
--- expected
- |
  <figure>
    <img alt="XXX のキャプション付きの図" class="illustration" src="../images/fig4990_07.png" />
    <figcaption class="caption">XXX</figcaption>
  </figure>
  <br />

=== jisage
--- html
<div style="margin-left: 3em">あいうえお</div>
--- expected
- '<div style="margin-top: 3em">あいうえお</div>'

=== chitsuki
--- html
<div style="margin-right: 3em">あいうえお</div>
--- expected
- '<div style="margin-bottom: 3em">あいうえお</div>'

=== kei-kakomi
--- html
<div style="width: 8em">あああ</div>
--- expected
- '<div style="height: 8em">あああ</div>'
