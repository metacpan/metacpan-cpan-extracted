# -*- cperl -*-
use Data::Dumper;
use strict;
use Test::More tests => 2;

# Check module loadability
use Biblio::Thesaurus;
my $loaded = 1;
ok(1);

my $obj = thesaurusMultiLoad("examples/animals1.iso", "examples/animals2.iso");
ok($obj);
