use v5.38;
use Test2::V0;

plan 3;

use CPANSEC::Admin;
pass 'CPANSEC::Admin loaded successfully';

ok my $app = CPANSEC::Admin->new, 'able to instantiate';
can_ok $app, 'run';