#!/usr/bin/env perl

#-------------------------------------------------------------------------------
# NAME: LocalClient.t
# PURPOSE: test script for the LocalClient, Options, Thread, Init, File classes.
#          used in conjunction with Makefile.PL to test installation
#
# $Id: LocalClient.t,v 1.4 2003/11/18 19:45:46 rkh Exp $
#-------------------------------------------------------------------------------

use Bio::Prospect::Options;
use Bio::Prospect::LocalClient;
use Bio::Prospect::Thread;
use Bio::Prospect::Init;
use Bio::Prospect::File;
use Bio::Structure::IO;
use Bio::SeqIO;
use Test::More;
use warnings;
use strict;
use vars qw( $VERSION );

$VERSION = sprintf( "%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/ );

plan tests => 40;

my $fn = 't/SOMA_HUMAN.fa';
ok( -f $fn, "$fn valid" );

my $xfn = 't/SOMA_HUMAN.xml';
ok( -f $xfn, "$xfn valid" );

my @tnames = qw( 1alu 1bgc 1lki 1huw 1f6fa 1cnt3 1ax8 1evsa 1f45b );

ok( my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $fn ), "Bio::SeqIO::new('-file' => $fn)");

my $po = new Bio::Prospect::Options( ncpus=>1,seq=>1, svm=>1, global_local=>1, templates=>\@tnames );
ok( defined $po && ref($po) && $po->isa('Bio::Prospect::Options'), 'Bio::Prospect::Options::new' );

my $lc = new Bio::Prospect::LocalClient( {options=>$po} );
ok( defined $lc && ref($lc) && $lc->isa('Bio::Prospect::LocalClient'), 'Bio::Prospect::LocalClient::new' );

my $s = $in->next_seq();
ok( my $xml = $lc->xml( $s ),        'Bio::Prospect::LocalClient::xml' );
ok( my @threads = $lc->thread( $s ), 'Bio::Prospect::LocalClient::thread' );

# get threads from xml file.  compare some Threads from LocalClient and xml file.
my $pf = new Bio::Prospect::File;
ok( defined $pf && ref($pf) && $pf->isa('Bio::Prospect::File'), 'Bio::Prospect::File::new()' );
ok( $pf->open( "<$xfn" ), "open $xfn" );
my $cnt=0;
while( my $t = $pf->next_thread() ) {
  ok( defined $t && ref($t) && $t->isa('Bio::Prospect::Thread'), 'Bio::Prospect::Thread::new()' );

  ok( $threads[$cnt]->tname eq $t->tname,         "Bio::Prospect::LocalClient::tname eq " . $t->tname );
  ok( $threads[$cnt]->raw_score eq $t->raw_score, "Bio::Prospect::LocalClient::raw_score eq " . $t->raw_score );

  # test output_rasmol_script code.  use the provided 1alu.pdb processed pdb.  this obviates
  # the installer from having to generate the processed pdb files prior to running the
  # test suite.
  if ( $t->tname eq '1alu' ) {
    my $pdbf = 't/'.$t->tname.'.pdb';
    ok( defined $pdbf && -r $pdbf, "$pdbf valid" );

    my $pdb  = Bio::Structure::IO->new(-file => $pdbf, '-format' => 'pdb');
    ok( defined $pdb && ref($pdb) && $pdb->isa('Bio::Structure::IO'), 'Bio::Structure::IO' );

    ok( my $struc = $pdb->next_structure(), 'Bio::Structure::IO::next_structure()' );
    ok( $t->output_rasmol_script($struc), 'Bio::Prospect::Thread::output_rasmol_script' );
  }
  $cnt++;
}
