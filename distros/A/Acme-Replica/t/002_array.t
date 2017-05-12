use strict;
use warnings;
use Test::More tests => 3;

use Acme::Replica;

my @array = qw/hoge fuga/;
my @replica = replica_of( \@array );
is($replica[0], pack('H2', '1c') . 'hoge');
is($replica[1], pack('H2', '1c') . 'fuga');
is(@replica, 2);
