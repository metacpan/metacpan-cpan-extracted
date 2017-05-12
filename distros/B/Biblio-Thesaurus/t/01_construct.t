# -*- cperl -*-

use strict;
use Test::More tests => 31;

BEGIN { use_ok("Biblio::Thesaurus") }

# Thesaurus is an object of Biblio::Thesaurus type
my $the = thesaurusNew();
isa_ok($the, "Biblio::Thesaurus");

my @allterms;

# Empty thesaurus is really empty
@allterms = $the->allTerms;
is_deeply([@allterms], []);
ok(!$the->isDefined("foo"));

# Addiction really adds...
$the->addTerm("foo");
ok($the->isDefined("foo"));
ok(!$the->isDefined("bar"));

# deletion works
$the->addTerm("bar");
$the->deleteTerm("foo");
ok(!$the->isDefined("foo"));
ok($the->isDefined("bar"));

# term listing works
@allterms = $the->allTerms;
is_deeply([@allterms], [qw/bar/]);

# term listing gives all terms
$the->addTerm("foo");
@allterms = $the->allTerms;
is_deeply([sort @allterms], [qw/bar foo/]);

$the->addRelation("foo", "BT", "ugh");
@allterms = $the->allTerms;
is_deeply([sort @allterms], [qw/bar foo ugh/]);

$the->addRelation("foo", "BT", qw/zbr1 zbr2 zbr3 zbr4/);
@allterms = $the->allTerms;
is_deeply([sort @allterms], [qw/bar foo ugh zbr1 zbr2 zbr3 zbr4/]);

ok($the->hasRelation("foo", "BT", "zbr1"));
ok(!$the->hasRelation("foo", "XX", "zbr1"));
ok(!$the->hasRelation("foo", "BT", "zbr5"));
ok($the->hasRelation("foo","BT","ugh"));

$the->complete;
ok($the->hasRelation("ugh","NT","foo"));

$the->deleteRelation("foo","BT","ugh");
ok(!$the->hasRelation("foo","BT","ugh"));
ok(!$the->hasRelation("ugh","NT","foo"));

$the->addRelation("bar","SN","Uma scope note qualquer");
ok($the->hasRelation("bar","SN"));

$the->deleteRelation("bar","SN");
ok(!$the->hasRelation("bar","SN"));

$the->addRelation("bar","BT", "AA", "BB");
$the->complete;
ok($the->hasRelation("AA","NT","bar"));
ok($the->hasRelation("BB","NT","bar"));

my @rels = $the->relations("bar");
ok(!grep { $_ eq "_NAME_"} @rels);
ok(grep {$_ eq "BT"} @rels);

$the->deleteRelation("bar","BT");
ok(!$the->hasRelation("AA","NT","bar"));
ok(!$the->hasRelation("BB","NT","bar"));
ok(!$the->hasRelation("bar","BT","AA"));
ok(!$the->hasRelation("bar","BT","BB"));

$the->deleteRelation("bar","BT");
isa_ok($the, "Biblio::Thesaurus");

$the->deleteRelation("bar","BT","AA");
isa_ok($the, "Biblio::Thesaurus");



