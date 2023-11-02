use strict;
use warnings;
use Test::More;

use CPAN::Changes;

my $changes = CPAN::Changes->new;
$changes->add_release({ version => 1, note => 1 });
$changes->add_release({ version => 3, note => 2 });
$changes->add_release({ version => 2, note => 3 });
$changes->add_release({ version => 4, note => 4 });
$changes->add_release({ version => 3, note => 5 });
my @order = map { $_->note } $changes->releases;
is_deeply \@order, [ 1, 5, 3, 4 ];

done_testing;
