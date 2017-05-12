# -*- cperl -*-
use Data::Dumper;
use strict;
use Test::More tests => 13;

# Check module loadability
use Biblio::Thesaurus;
my $loaded = 1;
ok(1);

my $a = thesaurusLoad("t/a.the");
my $c = $a->appendThesaurus("t/b.the");

# print STDERR Dumper($c);

ok($c->isDefined("a"));
ok($c->isDefined("b"));
ok($c->isDefined("c"));

ok($c->isDefined("Aa"));
ok($c->isDefined("Ab"));
ok($c->isDefined("Ac"));

ok($c->isDefined("Ba"));
ok($c->isDefined("Bb"));
ok($c->isDefined("Bc"));

my @terms = $c->terms("c", "NT");
ok(grep {$_ eq "a"} @terms);
ok(grep {$_ eq "b"} @terms);
is(scalar(@terms), 2);


