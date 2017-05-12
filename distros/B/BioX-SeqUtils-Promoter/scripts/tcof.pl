#!/usr/bin/perl -w

use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Tools::Run::Alignment::TCoffee;

#added gaps in alignment via matrix 'glitch'
#'OUTPUT' => clustalw
# Build a tcoffee alignment factory

#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'OUTFILE' => p_hexr );
#@params = ('ktuple' => 2, 'matrix' => 'Blosum', 'OUTFILE' => b_hexr );
#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 10, 'OUTFILE' => p_GO10_hexr );
#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 10, 'GAPEXT' => 2, 'OUTFILE' => p_GO10GE2_hexr );
#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 25, 'OUTFILE' => p_GO25_hexr );

#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'OUTFILE' => p_nrab1000 );
#@params = ('ktuple' => 2, 'matrix' => 'Blosum', 'OUTFILE' => b_nrab1000 );
#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 10, 'OUTFILE' => p_GO10_nrab1000 );
#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 25, 'OUTFILE' => p_GO25_nrab1000 );

#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'OUTFILE' => p9_nrab1000 );
#@params = ('ktuple' => 2, 'matrix' => 'Blosum', 'OUTFILE' => b9_nrab1000 );
#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 10, 'OUTFILE' => p9_GO10_nrab1000 );

#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'OUTFILE' => p22_nrab1000 );
#@params = ('ktuple' => 2, 'matrix' => 'Blosum', 'OUTFILE' => b22_nrab1000 );
#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 10, 'OUTFILE' => p22_GO10_nrab1000 );
#@params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 25, 'OUTFILE' => p22_GO25_nrab1000 );


@params = ('ktuple' => 2, 'matrix' => 'Pam', 'GAPOPEN' => 10, 'GAPEXT' => 2, 'OUTFILE' => p22_rab1000_80);
$factory = Bio::Tools::Run::Alignment::TCoffee->new(@params);


# Pass the factory a list of sequences to be aligned.
#$inputfilename = 'nrab1000.txt';
#$inputfilename = 'hexr.fasta';

$inputfilename = '../data/rab1000_80_22.txt';
#$inputfilename = '9seq.fa';
#$inputfilename = '22seq.fa';
# $aln is a SimpleAlign object.
$aln = $factory->align($inputfilename);


exit;




