use strict;
use warnings;
use utf8;
use Test::More;
use Test::Base;
use Aozora2Epub;
use Aozora2Epub::Gensym;
use lib qw/./;
use t::Util;

sub drop_nlsp {
    my $s = shift;
    $s =~ s/\n *//sg;
    $s;
}

filters {
    html => 'chomp',
    name => 'yaml',
    id => 'yaml',
    title => 'yaml',
    file => 'yaml',
    subsection => 'yaml',
};

run {
    my $block = shift;
    Aozora2Epub::Gensym->reset_counter;
    my $aozora = Aozora2Epub->new($block->html);
    my $toc = $aozora->toc;

    for my $k (qw/id title file/) {
        no strict 'refs';
        my $expected = $block->$k;
        next unless $expected;
        my @got = map { $_->{$k} } @$toc;
        is_deeply(\@got, $expected, $block->name . " ". $k);
    }
    # subsection
    my $ss_list = $block->subsection;
    for my $ss (@$ss_list) {
        my $parent = $ss->{parent};
        my $subsections = $toc->[$ss->{parent}]->{children};
        my @got = map { { id => $_->{id}, title => $_->{title}, file => $_->{file} } }
                      @$subsections;
        is_deeply(\@got, $ss->{expected}, $block->name . " subsection of section $parent");
    }
};

done_testing;

__DATA__

=== h4 only
--- html
<div class="jisage_6" style="margin-left: 6em">
  <h4 class="naka-midashi"><a class="midashi_anchor" id="midashi10">いち</a></h4>
</div>
あいう
<div class="jisage_6" style="margin-left: 6em">
  <h4 class="naka-midashi"><a class="midashi_anchor" id="midashi11">に</a></h4>
</div>
えお
--- title
- いち
- に
--- file
- g000000000
- g000000000
--- id
- midashi10
- midashi11

=== h3 only
--- html
<div class="jisage_6" style="margin-left: 6em">
  <h3 class="o-midashi"><a class="midashi_anchor" id="midashi10">いち</a></h3>
</div>
あいう
<div class="jisage_6" style="margin-left: 6em">
  <h3 class="o-midashi"><a class="midashi_anchor" id="midashi11">に</a></h3>
</div>
えお
--- title
- いち
- に
--- file
- g000000000
- g000000001
--- id
- midashi10
- midashi11

=== h3 and h4
--- html
<div class="jisage_4" style="margin-left: 6em">
  <h3 class="o-midashi"><a class="midashi_anchor" id="midashi10">いち</a></h3>
</div>
<div class="jisage_6" style="margin-left: 6em">
  <h4 class="o-midashi"><a class="midashi_anchor" id="midashi10-1">いちのいち</a></h4>
</div>
あいう
<div class="jisage_6" style="margin-left: 6em">
  <h4 class="o-midashi"><a class="midashi_anchor" id="midashi10-2">いちのに</a></h4>
</div>
かきく
<div class="jisage_4" style="margin-left: 6em">
  <h3 class="o-midashi"><a class="midashi_anchor" id="midashi11">に</a></h3>
</div>
えお
--- title
- いち
- に
--- file
- g000000000
- g000000001
--- id
- midashi10
- midashi11
--- subsection
- parent: 0
  expected:
    - title: いちのいち
      id: midashi10-1
      file: g000000000
    - title: いちのに
      id: midashi10-2
      file: g000000000
- parent: 1
  expected: []

=== h4 - h3
--- html
<h4 id="h001">head1</h4>
<h3 id="h002">head2</h3>
<h3 id="h003">head3</h3>
--- title
- head1
- head2
- head3
--- id
- h001
- h002
- h003
