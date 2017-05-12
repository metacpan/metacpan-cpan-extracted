# -*- cperl -*-
use Data::Dumper;
use strict;
use Test::More tests => 6;

# Check module loadability
BEGIN { use_ok("Biblio::Thesaurus"); }

# Check 'transitive closure' method
my $thesaurus = thesaurusLoad('t/02_empty.the');
ok($thesaurus);
ok(!exists($thesaurus->{PT}{a}{RT}));
ok(!exists($thesaurus->{PT}{c}{POF}));
ok(exists($thesaurus->{PT}{d}));
ok(exists($thesaurus->{PT}{ff}));


#print STDERR Dumper $thesaurus;
