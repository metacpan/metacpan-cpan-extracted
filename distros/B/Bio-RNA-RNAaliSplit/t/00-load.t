#-*-Perl-*-
use Test2::V0;
use IPC::Cmd qw(can_run);

use ok 'RNA';
diag( "Testing Vienna RNA $RNA::VERSION, Perl $], $^X" );

ok( defined(can_run('AnalyseDists')), 'Bail out! AnalyseDists not found');
ok( defined(can_run('RNAalifold')), 'Bail out! RNAalifold not found');
ok( defined(can_run('RNAz')), 'Bail out! RNAz not found');
ok( defined(can_run('R-scape')), 'Bail out! R-scape not found');

done_testing;
