#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More tests => 11;
use IPC::Cmd qw(can_run);

BEGIN {
  use_ok( 'RNA' ) || print "Bail out! Cannot load Vienna RNA Perl module \n";
  use_ok( 'Bio::RNA::RNAaliSplit' ) || print "Bail out! Cannot load Bio::RNA::RNAaliSplit\n";
  use_ok( 'Bio::RNA::RNAaliSplit::Roles' ) || print "Bail out! Bio::RNA::RNAaliSplit::Roles\n";
  use_ok( 'Bio::RNA::RNAaliSplit::WrapAnalyseDists' ) || print "Bail out! Bio::RNA::RNAaliSplit::WrapAnalyseDists\n";
  use_ok( 'Bio::RNA::RNAaliSplit::WrapRNAalifold' ) || print "Bail out! Bio::RNA::RNAaliSplit::WrapRNAalifold\n";
  use_ok( 'Bio::RNA::RNAaliSplit::WrapRNAz' ) || print "Bail out! Bio::RNA::RNAaliSplit::WrapRNAz\n";
  use_ok( 'Bio::RNA::RNAaliSplit::WrapRscape' ) || print "Bail out! Bio::RNA::RNAaliSplit::WrapRscape\n";
}

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

