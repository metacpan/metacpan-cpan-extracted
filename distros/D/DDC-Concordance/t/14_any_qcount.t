# -*- Mode: CPerl -*-
use Test::More tests=>18;
use DDC::Any;

##-- 1..3: sample, sort
my ($q);
$q = DDC::Any->parse('count(foo) #sample[10] #by[textClass~s/::.*$//,date/10] #asc_key');
ok($q, "qcount:parse");
is($q->getSample, 10, "qcount:sample");
is($q->getSort, DDC::Any::LessByCountKey, "qcount:sort");

##-- 4..11: keys
my $keys = $q->getKeys;
ok($keys->CanCountByFile, 				"qcount:keys:byfile");
is($keys->getExprs->[0]->getSrc->getLabel, 'textClass',	"qcount:keys[0]:src:label");
is($keys->getExprs->[0]->getPattern, '::.*$',		"qcount:keys[0]:pattern");
is($keys->getExprs->[0]->getReplacement,'', 		"qcount:keys[0]:replacement");
is($keys->getExprs->[0]->getModifiers, '', 		"qcount:keys[0]:modifiers");
ok(!$keys->getExprs->[0]->getIsGlobal, 			"qcount:keys[0]:!isGlobal");
is($keys->getExprs->[1]->getLabel, 'date', 		"qcount:keys[1]:label");
is($keys->getExprs->[1]->getSlice, 10,	 		"qcount:keys[1]:slice");

##-- reference-counting woes:
##   + just incrementing refcounts when setting child objects isn't enough:
##     we really need to ensure ensure that each descendant has AT LEAST as many references
##     as each of its ancestors...
my $key = DDC::Any::CQCountKeyExprConstant->new('0');
$keys->PushKey($key);
SKIP: {
  skip('no refcnt tests for DDC::Any via DDC::PP', 1) if ($DDC::Any::WHICH eq 'DDC::PP');
  ok($key && $key->refcnt==$keys->refcnt+1, "qcount:PushKey:refcnt");
}
undef $key; ##-- segfaults if refcnt failed

##-- 13..18: context-count
$q = DDC::Any->parse('count($l=foo =1) #by[$w =1] #desc_count');
ok($q, "qcount:ctx:parse");
ok(!$q->getKeys->CanCountByFile, "qcount:ctx:!countbyfile");
ok($q->HasMatchId, "qcount:ctx:HasMatchId:");
$key = $q->getKeys->getExprs->[0];
is($key->getIndexName, 'w', "qcount:ctx:key:IndexName");
is($key->getMatchId, 1, "qcount:ctx:key:MatchId");
is($key->getOffset, 0, "qcount:ctx:key:Offset");

print "\n";

