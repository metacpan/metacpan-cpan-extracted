#!/usr/bin/perl -w
# $Author: thladish $
# $Date: 2006/08/24 06:41:57 $
# $Revision: 1.6 $

use Bio::AlignIO;
use IO::File;
use Getopt::Long;
use Pod::Usage; 
use File::Temp qw( tempfile );
use File::Basename;
use Bio::NEXUS;
use strict;
use Data::Dumper;

  ####################
 # CVS version info #
####################
my $nada = "";
my $Id = "";
my $version = "$Id: align2nex.pl,v 1.6 2006/08/24 06:41:57 thladish Exp $nada"; 

  #################
 # cmd line args #
#################
my (%opts);
Getopt::Long::Configure("bundling"); # for short options bundling
GetOptions( \%opts, 
            'format|f=s', 
            'outfile|o=s', 
            'treefile|t=s',
	    'treename|n=s',
            'version|V', 
            'man', 
            'help|h',
          ) or pod2usage(2);

if ( $opts{ 'version' } ) { die "Version$version\n"; } 
pod2usage( -exitval => 0, verbose => 2 ) if $opts{ man };
pod2usage( 1 ) if !@ARGV or $opts{ help };

my ($infile,$outfile,$inputFormat,$tmpFH,$tmpFileName);
$infile = shift or die "specify infile as last argument on commandline"; 
$outfile = ( $opts{ 'outfile' } ? $opts{ 'outfile' } : 'out.nex' ); 
$inputFormat = ( $opts{ 'format' } ? $opts{ 'format' } : 'clustalw' ); 

($tmpFH,$tmpFileName) = tempfile( DIR => dirname($outfile) );
my $in  = Bio::AlignIO->new(-file => $infile,     '-format' => $inputFormat );
my $out = Bio::AlignIO->new( -fh => \*$tmpFH , '-format' => 'nexus' );
my ($aln,$seq); 

#20030904 - brendan - commented out while loop. we want to re-use the $aln string later
#if we put it in this while loop, it will be undef and we need to recreate the object.
#also from Bio::AlignIO perldoc, multiple alignments not supported by AlignIO.
#while ( $aln = $in->next_aln() ) { 
  $aln = $in->next_aln();
  $out->write_aln($aln);
#}

select($tmpFH);

  ###############
 # taxa block  #
###############

print "\n",
      "begin taxa;\n",
      "\tdimensions ntax=",$aln->no_sequences(),";\n",
      "\ttaxlabels\n";
  
foreach $seq ( $aln->each_seq() )
{
    print $seq->id,"\t";
}

print ";\nend;\n";


   ######################### 
  # convert file to our   #
 # standard nexus format #
#########################
close($tmpFH);
select \*STDOUT;
my $nexus = new Bio::NEXUS($tmpFileName);
#print STDOUT &Dumper($nexus);

$nexus->write("$outfile");
unlink($tmpFileName);


1;


=head1 NAME

align2nex.pl - translate an alignment into NEXUS format using BioPerl

=head1 SYNOPSIS

align2nex.pl [options] <infile> 

=head1 DESCRIPTION

Output the alignment in <infile> in NEXUS format.  This is dependent on 
BioPerl AlignIO modules.  I don't know how well it will work.  

=head1 OPTIONS

=over 8

=item B<-f, --format> 

The format of the input file.  One of { bl2seq, clustalw, emboss, fasta,
mase, mega, meme, msf, nexus, pfam, phylip, prodom, psi, selex, stockholm }.

=item B<-o, --outfile> 

The name of the output file.  Defaults to out.nex. 

=item B<-h, --help> 

Print a brief help message and exits.

=item B<--man> 

Print the manual page and exits.

=item B<-V, --version> 

Print the version information and exit.

=back

=head1 VERSION

$Id: align2nex.pl,v 1.6 2006/08/24 06:41:57 thladish Exp $

=head1 AUTHOR

Arlin Stoltzfus (stoltzfu@umbi.umd.edu)

=cut





