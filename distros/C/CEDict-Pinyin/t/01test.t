use strict;
use warnings;
use Test::More 'no_plan';
use CEDict::Pinyin;

my @good = ("ji2 - rui4 cheng2", "xi'an", "dian4 nao3, yuyan2", "kongzi");
my @bad  = ("123", "not pinyin", "gu1 gu1 fsck4 fu3");
my $py   = CEDict::Pinyin->new;

for (@good) {
	$py->setSource($_);
	ok($py->isPinyin, "correctly validated good pinyin");
  print "pinyin: " . $py->getSource . "\n";
  print "parts: " . join(', ', @{$py->getParts}) . "\n";
}

for (@bad) {
	$py->setSource($_);
	ok(!$py->isPinyin, "correctly invalidated bad pinyin");
  print "pinyin: " . $py->getSource . "\n";
  print "parts: " . join(', ', @{$py->getParts}) . "\n";
}
