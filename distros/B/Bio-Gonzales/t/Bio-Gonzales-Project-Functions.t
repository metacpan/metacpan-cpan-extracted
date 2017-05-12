use warnings;
use 5.010;
use strict;

use Test::More;
use Data::Dumper;

BEGIN { use_ok('Bio::Gonzales::Project::Functions'); }

my @a = ( 0..10);
my $res = gonz_iterate(\@a, sub { [ $_[0], $_[1] * $_[1] ]} );

my @b_ref = map { $_ * $_ } @a;
$res = [ map { $_->[1] } sort { $a->[0] <=> $b->[0] } @$res ];

is_deeply($res, \@b_ref);
done_testing();
