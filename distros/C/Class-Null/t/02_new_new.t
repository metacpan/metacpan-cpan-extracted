use strict;
use warnings;
use Test::More tests => 1;
use Class::Null;
my $o = Class::Null->new->new;
isa_ok($o, 'Class::Null');
