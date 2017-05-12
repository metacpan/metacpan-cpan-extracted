# -*- Mode: CPerl -*-
use Test::More tests=>21;
use DDC::Any;

##-- 1..4: CQAnd: perl only
my $qa = DDC::Any::CQTokExact->new('','a');
my $qb = DDC::Any::CQTokExact->new('','b');
my $qc = DDC::Any::CQTokExact->new('','c');
my $qand = DDC::Any::CQAnd->new($qa,$qb);
ok($qa && $qb && $qc, "CQAnd:args");
ok($qand, "CQAnd:obj");
like($qand->toString, qr/^\(\@'?a'? \&\& \@'?b'?\)$/, "CQAnd:str");
$qand->setDtr2($qc);
like($qand->toString, qr/^\(\@'?a'? \&\& \@'?c'?\)$/, "CQAnd:setDtr2:str");

##-- 5..7: CQOr: parsed
my $qor = DDC::Any->parse('a || b');
ok($qor, "CQOr:parse");
like($qor->getDtr1->toString, qr/^'?a'?$/, "CQOr:dtr1:str");
like($qor->getDtr2->toString, qr/^'?b'?$/, "CQOr:dtr2:str");

##-- 8..11: CQSeq
my $qseq = DDC::Any->parse('"@foo #2 @bar #=1 @{baz,bonk}"');
my $items = $qseq->getItems;
my $ops   = $qseq->getDistOps;
ok($qseq, "CQSeq:parse");
ok($items && UNIVERSAL::isa($items,'ARRAY') && @$items == 3, "CQSeq:items");
ok($ops   && UNIVERSAL::isa($ops,'ARRAY') && join(' ',@$ops) eq '< =', "CQSeq:ops");
$_ = '=' foreach (@$ops);
$qseq->setDistOps($ops);
ok(!(grep {$_ ne '='} @{$qseq->getDistOps||[]}), "CQSeq:ops:set");

##-- 12..14: CQSet
my $qset = DDC::Any->parse('@{blip,blop}');
my $vals = $qset->getValues;
ok($qset, "CQSet:parse");
is(join(' ', sort @{$vals||[]}), 'blip blop', "CQSet:vals");
$vals = [qw(a b c)];
$qset->setValues($vals);
is(join(' ', sort @{$qset->getValues||[]}), 'a b c', "CQSet:vals:set");

##-- 15..16: CQRegex
my $qre = DDC::Any->parse('/flip\.flop/');
ok($qre, "CQRegex:parse");
is($qre->getValue, "flip\\.flop", "CQRegex:value");

##-- 17..18: expanders
my $qx = DDC::Any->parse('foo |bar|baz');
ok($qx, "expanders:parse");
is(join(' ',@{$qx->getExpanders||[]}), 'bar baz', "expanders:chain");

##-- 19..21 : WITH aliases
my $qwith = DDC::Any->parse('foo &= bar');
ok($qwith && $qwith->isa('DDC::Any::CQWith'), "with:&=");

my $qwithor = DDC::Any->parse('foo |= bar');
ok($qwithor && $qwithor->isa('DDC::Any::CQWithor'), "withor:|=");

my $qwithout = DDC::Any->parse('foo != bar');
ok($qwithout && $qwithout->isa('DDC::Any::CQWithout'), "without:!=");


print "\n";

