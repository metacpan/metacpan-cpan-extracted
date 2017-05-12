#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More tests => 10;
use IPC::Cmd qw(can_run);

BEGIN {
  use_ok( 'RNA' ) || print "Bail out! Cannot load Vienna RNA Perl module \n";
  use_ok( 'Bio::RNA::RNAaliSplit' ) || print "Bail out! Cannot load Bio::RNA::RNAaliSplit\n";
  use_ok( 'Bio::RNA::RNAaliSplit::FileDir' ) || print "Bail out! Bio::RNA::RNAaliSplit::FileDir\n";
  use_ok( 'Bio::RNA::RNAaliSplit::WrapAnalyseDists' ) || print "Bail out! Bio::RNA::RNAaliSplit::WrapAnalyseDists\n";
  use_ok( 'Bio::RNA::RNAaliSplit::WrapRNAalifold' ) || print "Bail out! Bio::RNA::RNAaliSplit::WrapRNAalifold\n";
  use_ok( 'Bio::RNA::RNAaliSplit::WrapRNAz' ) || print "Bail out! Bio::RNA::RNAaliSplit::WrapRNAz\n";
}

diag( "Testing Vienna RNA $RNA::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit $Bio::RNA::RNAaliSplit::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit::FileDir $Bio::RNA::RNAaliSplit::FileDir::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit::WrapAnalyseDists $Bio::RNA::RNAaliSplit::WrapAnalyseDists::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit::WrapRNAalifold $Bio::RNA::RNAaliSplit::WrapRNAalifold::VERSION, Perl $], $^X" );
diag( "Testing Bio::RNA::RNAaliSplit::WrapRNAz $Bio::RNA::RNAaliSplit::WrapRNAz::VERSION, Perl $], $^X" );


ok( defined(can_run('AnalyseDists')), 'Bail out! AnalyseDists not found');
ok( defined(can_run('RNAalifold')), 'Bail out! RNAalifold not found');
ok( defined(can_run('RNAz')), 'Bail out! RNAz not found');
ok( defined(can_run('R-scape')), 'Bail out! R-scape not found');

