# -*- Mode: CPerl -*-
use Test::More tests=>11;
use DDC::PP;

##-- 1..2: parse
my ($q,$qo);
ok(($q = DDC::PP->parse('foo #cntxt 5 #sep #in file #has[author,kant] #asc_date :c1,c2')), "qopts:parse");
ok(($qo=$q->getOptions), "qopts:options");

##-- 3..7: basic options
is($qo->getContextSentencesCount, 5, "qopts:cntxt");
ok($qo->getEnableBibliography, "qopts:bibl");
ok(!$qo->getDebugRank, "qopts:!debugrank");
ok($qo->getSeparateHits, "qopts:separate");
is(join(' ',@{$qo->getWithin||[]}), 'file', "qopts:within");

##-- 8..10: filters
my ($filters);
ok(($filters=$qo->getFilters) && @{$filters||[]}==2, "qopts:filters");
like($filters->[0]->toString, qr/^\#HAS(?:_FIELD)?\['?author'?,'?kant'?\]$/i, "qopts:filters[0]");
like($filters->[1]->toString, qr/^\#(?:ASC|LESS)(?:_BY)?_DATE$/i, "qopts:filters[1]");

##-- 11: corpora
my $corpora = $qo->getSubcorpora;
is(join(' ',@{$corpora||[]}), 'c1 c2', "qopts:corpora");

print "\n";

