#!perl -T
use 5.010;
use strict;
use warnings;
use Test2::V0;
use IPC::Cmd qw(can_run);

use ok 'RNA';
use ok 'Bio::RNA::RNAaliSplit';
use ok 'Bio::RNA::RNAaliSplit::Roles';
use ok 'Bio::RNA::RNAaliSplit::WrapAnalyseDists';
use ok 'Bio::RNA::RNAaliSplit::WrapRNAalifold';
use ok 'Bio::RNA::RNAaliSplit::WrapRNAz';
use ok 'Bio::RNA::RNAaliSplit::WrapRscape';

diag( "Testing Vienna RNA $RNA::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit $Bio::RNA::RNAaliSplit::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit::FileDir $Bio::RNA::RNAaliSplit::Roles::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit::WrapAnalyseDists $Bio::RNA::RNAaliSplit::WrapAnalyseDists::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit::WrapRNAalifold $Bio::RNA::RNAaliSplit::WrapRNAalifold::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit::WrapRNAz $Bio::RNA::RNAaliSplit::WrapRNAz::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit::WrapRscape $Bio::RNA::RNAaliSplit::WrapRscape::VERSION, Perl $], $^X" );


ok( defined(can_run('AnalyseDists')), 'Bail out! AnalyseDists not found');
ok( defined(can_run('RNAalifold')), 'Bail out! RNAalifold not found');
ok( defined(can_run('RNAz')), 'Bail out! RNAz not found');
ok( defined(can_run('R-scape')), 'Bail out! R-scape not found');

done_testing;
