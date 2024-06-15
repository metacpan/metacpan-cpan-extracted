use strict;
use warnings;
use utf8;
use Test::More;
use Test::Base;
use Aozora2Epub;
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
    my $doc = Aozora2Epub->new($block->html, no_fetch_assets=>1);
    my $got = [ map { $_->as_html } @{$doc->files} ];
    is_deeply($got,
              [ map { drop_nlsp($_) } @{$block->expected} ],
              $block->name);
};

__DATA__

=== o-midashi
--- html
<br/>
<h3 class="o-midashi">
  <a class="midashi_anchor" id="midashi001">見出し</a>
</h3>
あいう
--- expected
- <h3 class="o-midashi" id="midashi001">見出し</h3> あいう

=== naka-midashi
--- html
<br/>
<h4 class="naka-midashi">
  <a class="midashi_anchor" id="midashi001">見出し</a>
</h4>
あいう
--- expected
- <h4 class="naka-midashi" id="midashi001">見出し</h4> あいう

=== ko-midashi
--- html
<br/>
<h5 class="ko-midashi">
  <a class="midashi_anchor" id="midashi001">見出し</a>
</h5>
あいう
--- expected
- <h5 class="ko-midashi" id="midashi001">見出し</h5> あいう
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
<h1>header1</h1><h2>header1-1</h2><h3>header1-1-1</h3>aaa<h2>header1-2</h2><h3>header1-2-1</h3>bbb
--- expected
- <h1 id="g000000004">header1</h1><h2 id="g000000005">header1-1</h2><h3 id="g000000007">header1-1-1</h3>aaa
- <h2 id="g000000006">header1-2</h2><h3 id="g000000008">header1-2-1</h3>bbb
--- note
連続する<h[123]では一度しかファイル分割しない


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

=== gaiji
--- html
<img src="../../../gaiji/1-84/1-84-77.png" alt="※(「てへん＋劣」、第3水準1-84-77)" class="gaiji" />
--- expected
- <img alt="※(「てへん＋劣」、第3水準1-84-77)" class="gaiji" src="../gaiji/1-84/1-84-77.png" />

