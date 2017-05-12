#!perl -T

use strict;
use warnings;
use Test::More tests => 1;
use Acme::CPANAuthors;
use Acme::CPANAuthors::Chinese;

my $authors = Acme::CPANAuthors->new('Chinese');
my @ids      = $authors->id;
ok(grep { $_ eq 'FAYLAND' } @ids);

1;