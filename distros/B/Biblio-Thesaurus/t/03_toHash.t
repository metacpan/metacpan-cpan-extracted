#!perl

use strict;
use warnings;

use Biblio::Thesaurus;
use Data::Dumper;
use Test::More tests => 4;

my $the = thesaurusLoad('t/b.the');

my $hash = $the->toHash("NT");

is(ref($hash), "HASH", "Is a hash reference");

is($hash->{b}{Bb}, "b::Bb");
is($hash->{b}{Ba}, "b::Ba");
is($hash->{b}{Bc}, "b::Bc");
