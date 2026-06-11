use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('DBI');
    use_ok('DBD::D1');
}

my $drh = DBI->install_driver('D1');
isa_ok($drh, 'DBI::dr', 'driver handle');
