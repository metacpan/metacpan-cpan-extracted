#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;

use Bio::Gonzales::Align::IO::Stockholm;
use Bio::Gonzales::Seq::IO qw(faslurp);



my ($infile, $outfile) = @ARGV;
die "$infile is no file" unless(-f $infile);


my $seqs = faslurp($infile);


my $sto = Bio::Gonzales::Align::IO::Stockholm->new(
    file       => $outfile,
    mode       => '>',
    wrap       => 80,
    relaxed    => 1,
);

$sto->write_aln($seqs);

$sto->close;

