use Test::More tests => 3;

use Archive::TAP::Peek; # we have checked this already in 00_load.t

my $peek_fail = Archive::TAP::Peek->new(
                    archive => 't/archives/fail_tests.tar.gz'
                );

can_ok($peek_fail, 'all_ok'); 

is( $peek_fail->all_ok(), undef, 'peek fail archive');


my $peek_fine = Archive::TAP::Peek->new(
                    archive => 't/archives/tests.tar.gz'
                );

ok( $peek_fine->all_ok(), 'peek fine archive');

