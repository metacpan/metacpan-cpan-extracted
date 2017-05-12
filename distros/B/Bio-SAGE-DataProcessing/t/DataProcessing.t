#!/usr/bin/perl -T

use strict;
use warnings;
use Test::More tests => 15;

use lib './lib';
use_ok( 'Bio::SAGE::DataProcessing' );

my $sage = Bio::SAGE::DataProcessing->new();
isa_ok( $sage, 'Bio::SAGE::DataProcessing', 'Bio::SAGE::DataProcessing' );
ok( open( SEQ, "t/test.fasta" ), 'opening test.fasta' );
ok( open( SCO, "t/test.qual.fasta" ), 'opening test.qual.fasta' );

eval {
  local $SIG{__DIE__} = sub { fail( "processing died" ) };
  my $reads = $sage->process_library( *SEQ, *SCO );
  ok( $reads == 5, "processing test data" );
};

ok( close( SEQ ), 'closing test.fasta' );
ok( close( SCO ), 'closing test.qual.fasta' );

ok( $sage->get_enzyme() eq "CATG", "checking enzyme" );
isa_ok( $sage->get_protocol(), 'HASH', 'result of get_protocol()' );
ok( scalar( $sage->get_ditags() ) == 61, "checking ditags" );

eval {
  local $SIG{__DIE__} = sub { fail( "tag extraction died" ) };
  my @tags = $sage->get_tags();
  ok( scalar( @tags ) == 121, "extracting tags" );
};

my $pCounts = $sage->get_tagcounts();
ok( defined( $$pCounts{"CCTATCAGTA"} ) && $$pCounts{"CCTATCAGTA"} == 2, "checking tag counts" );

my $pHash = $sage->get_ditag_base_distribution();
ok( defined( $pHash->{1}->{'A'}->{'fwd'} ) && $pHash->{1}->{'A'}->{'fwd'} == 122, "checking ditag base distribution" );

my $pHash2 = $sage->get_ditag_length_distribution();
ok( defined( $pHash2->{30} ) && $pHash2->{30} == 28, "checking ditag length distribution" );

my $pHash3 = $sage->get_extra_base_calculation( "CCTATCAGTA" );
ok( defined( $pHash3->{1}->{30}->{'A'} ) && $pHash3->{1}->{30}->{'A'} == 1, "checking extra base calculation" );


