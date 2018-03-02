#!/usr/bin/env perl
# Last changed Time-stamp: <2018-01-10 16:18:47 mtw>
# -*-CPerl-*-
#
# A structural alignment evaluator
#
# usage: eval_alignment.pl -a myaln.stk --statistics RAFS
#

use version; our $VERSION = qv('0.05.3');
use strict;
use warnings;
use File::Basename;
use Bio::AlignIO;
use Bio::RNA::RNAaliSplit::WrapRscape;
use Bio::RNA::RNAaliSplit::WrapRNAz;
use Getopt::Long qw( :config posix_default bundling no_ignore_case );
use Data::Dumper;
use Pod::Usage;
use Path::Class;
use Carp;
use Cwd;

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#
#^^^^^^^^^^ Variables ^^^^^^^^^^^#
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#

my $show_version = 0;
my ($id,$stkfile,$alnfile,$logfile,$in,$out,$cwd,$bn);
my @odir = ();
my $handle=undef;
my $nofigures = 0;
my $outdir = "eval_result";
my $stat = "GTp";
my $have_logfile=0;
use diagnostics;

Getopt::Long::config('no_ignore_case');
pod2usage(-verbose => 1) unless GetOptions("a|aln=s"        => \$stkfile,
					   "s|statistic=s"  => \$stat,
					   "o|out=s"        => \$outdir,
					   "l|log=s"        => \&set_logfile,
					   "n|nofigures"    => sub{$nofigures = 1},
                                           "version"        => sub{$show_version = 1},
                                           "man"            => sub{pod2usage(-verbose => 2)},
                                           "help|h"         => sub{pod2usage(1)}
                                           );

if ($show_version == 1){
  print "eval_alignment.pl $VERSION\n";
  exit(0);
}


if ($have_logfile == 1){
  open($handle, ">", $logfile)
    || die "$0: can't open $logfile for appending: $!";
}
else{
  open($handle, ">&", STDOUT)
    || die "$0: can't open handle for STDOUT: $!";
}

@odir = split /\//, $outdir;
$cwd = getcwd();
unless (-f $stkfile){
  warn "Could not find input file provided via -a|-aln option";
  pod2usage(-verbose => 0);
}
$bn = basename($stkfile, ".stk");
$alnfile = file($cwd,$bn.".aln");
# convert Stockholm -> Clustal for RNAz
$in = Bio::AlignIO->new(-file   => $stkfile ,
			-format => "Stockholm");

$out = Bio::AlignIO->new(-file   => ">$alnfile" ,
			 -format => "ClustalW");

while ( my $aln = $in->next_aln ) {
    $out->write_aln($aln);
}

my $r = Bio::RNA::RNAaliSplit::WrapRscape->new(ifile => $stkfile,
					       statistic => $stat,
					       nofigures => $nofigures,
					       odir => \@odir,
					      );
#print Dumper($r);

my $z = Bio::RNA::RNAaliSplit::WrapRNAz->new(ifile => $alnfile,
					     odir => \@odir);
#print Dumper($z);

if ($r->cseq <= 1){ # stk file had only one sequence
  print $handle join("\t","-",$stkfile,"n/a"),"\n";
}
else{ # normal stk file
  my $hint = "-";
  my $prob=sprintf("%6.4f",$z->P);
  ($prob>0.9 && $r->TP>1) ? ($hint = "*") : ($hint = "-");
  print $handle join("\t",$hint,$stkfile,$prob,$r->statistic,$r->TP,$r->alen,$r->nbpairs,$r->nseq)."\n";
}





sub set_logfile {
  $logfile=$_[1];
  $have_logfile=1;
}

__END__

=head1 NAME

eval_alignment.pl - A structural alignment evaluator

=head1 SYNOPSIS

eval_alignment.pl [--aln|-a I<FILE>] [-out|-o I<DIR>] [--log|-l I<FILE>]
[--statistic|-s I<STRING>] [--nofigures] [options]

=head1 DESCRIPTION

This is a semi-automatic evaluator for RNA alignemnts. In employs
R-scape (http://eddylab.org/R-scape/) and RNAz
(https://www.tbi.univie.ac.at/software/RNAz) to classify structural
RNA alignments. It accepts a single multiple sequence alignment in
Stockholm format and runs R-scape and RNAz on it, determining
statistically significant covarying base pairs (SSCBP) and RNAz
classification parameters.

This tool prints the RNAz class probability, the applied R-scape
covariance statistic, the number of SSCBP, the lenth of the alignment,
as well as the number of base pairs and sequences to stdout. R-scapoe
and RNAz output files are written to a user-defined directory.

=head1 DISCLAIMER

This script employs a simple R-scape/RNAz warpper. As such, it does
not implement (and pass through) all R-scape/RNAz options.

Please ensure that R-scape >v0.6.1 is installed on your machine and
available for your Perl interpreter.

=head1 OPTIONS

=over

=item B<--aln|-a>

A multiple sequence alignment in Stockholm format.

=item B<--statistic|-s>

The covariation statistic used by R-scape. Allowed values are: 'GT',
'MI', 'MIr', 'MIg', 'CHI', 'OMES', 'RAF', 'RAFS'. Appending either 'p'
or 'a' to any of them calculates its average product correction and
average sum correction, respctively (e.g. GTp or GTa). See the R-scape
manual for details.

=item B<--nofigures|-n>

Turn off production of graphical R-scape output

=item B<--log|-l>

Specify log file; output is written to STDOUT unless specified

=item B<--version>

Show wrap-R-scape.pl version and exit

=back

=head1 SEE ALSO

The L<R-scape
manual|http://eddylab.org/software/rscape/R-scape_userguide.pdf> and
the L<R-scape
paper|http://eddylab.org/publications/RivasEddy16/RivasEddy16-preprint.pdf>.

=head1 AUTHOR

Michael T. Wolfinger E<lt>michael@wolfinger.euE<gt> and
E<lt>michael.wolfinger@univie.ac.atE<gt>

=cut
