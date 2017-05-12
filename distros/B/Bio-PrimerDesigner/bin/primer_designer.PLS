#!perl

# $Id: primer_designer.PLS,v 1.1 2004/03/04 23:28:37 kclark Exp $

use Config;
use File::Basename qw(basename dirname);
use File::Spec::Functions;

my $dir = dirname($0);
$file   = shift || catfile( $dir, basename( $0, '.PL','.PLS' ) );

open OUT, ">$file" or die "Can't write to file '$file': $!";

my $startperl = $Config{'startperl'} ne '#!perl'
  ? $Config{'startperl'}
  : "#!$Config{'perlpath'}";

print OUT "$startperl\n";
print OUT <<'NOGROK';

=head1 NAME 

primer_designer.pl -- command-line interface Bio::PrimerDesigner

=head1 SYNOPSIS

    ./primer_designer.pl [options] [dna_sequence or file]

  Options:

  -p|--program   Program (default "primer3")
  -n|--number    Number of primer sets to return (default "5")
  -b|--binary    Path to binary executable (default "/usr/local/bin")
  -m|--method    "local" or "remote" (default "local")
  -u|--url       URL of remote primer3/e-PCR system
                (default "aceserver.biotech.ubc.ca/cgi-bin/primer_designer.cgi")
  --list-aliases Print alias list to primer3 input options and exit
  --list-params  Print a list of primer3/e-PCR input options and exit
  -h|--help      Print help and exit

=head1 DESCRIPTION

This script tests/demonstrates the Bio::PrimerDesigner interface to
primer3 and e-PCR.  It can be used with a local installation of the
unix binaries or remotely via an HTTP/CGI request.

=cut

use strict;

use Bio::PrimerDesigner;
use Getopt::Long;
use Pod::Usage;

$| = 1;

my ( $program, $num_primers, $binary_path, $method, $url, $list_aliases, 
    $list_params, $list_designers, $show_help );

GetOptions(
    'd|designer:s'   => \$program,
    'n|number:i'     => \$num_primers,
    'b|binary:s'     => \$binary_path,
    'm|method:s'     => \$method,
    'u|url:s'        => \$url,
    'list-aliases'   => \$list_aliases,
    'list-params'    => \$list_params,
    'h|help'         => \$show_help,
) or pod2usage(2);

pod2usage(2) if $show_help;

#
# Create Bio::PrimerDesigner object.
#
my $pd   =  Bio::PrimerDesigner->new( 
    program     => $program,
    method      => $method,
    url         => $url,
    binary_path => $binary_path,
) or die Bio::PrimerDesigner->error;

#
# List paramaters to primer design program.
#
if ( $list_params ) {
    my $title = $program . ' Parameters:';
    print join "\n", $title, '-' x length $title, $pd->list_params, '';
    print "\n";
}
  
#
# List aliased keys to primer design program and exit.
#
if ( $list_aliases ) {
    my %alias_list = ( $pd->list_aliases );

    my $longest = 0;
    for my $length ( map { length $_ } keys %alias_list ) {
        $longest = $length if $length > $longest;
    }

    my @aliases;
    for my $key ( sort keys %alias_list ) {
        my $length = length $key;
        my $space  = ' ' x ( $longest - $length + 5 );
        push @aliases, "$key$space$alias_list{$key}";
    }

    my $header = 'Primer3 Parameter';
    my $space  = ' ' x ( $longest - length( $header ) + 5 );
    my $title  = "$header${space}Bio::PrimerDesigner Alias";
    unshift @aliases, $title, '-' x length $title;

    print join "\n", @aliases, '';
    exit;
}

#
# Get the DNA sequence from somewhere.
#
chomp (my $dna = <DATA>);

$num_primers ||= 5;
my $length    = length $dna;
my $seqID     = "C02D5.1";

#
# Define Bio::PrimerDesigner parameters
# in this case I use aliased keys
# the primer3 Boulder IO keys are also valid
#
my %params    = (
    num       => $num_primers, 
    seq       => $dna,  
    sizerange => '500-600',                      
    target    => '5001,200',                     
    excluded  => '1,4500 5500,'.($length-5500-1),
    id        => $seqID                          
);

#
# Design the primers.
#
my $result = $pd->design( %params );

#
# Did it work? 
#
die ("Some sort of primer3 error\n", $result->raw_output)
    unless $result && $result->left; 

#
# Initialize e-PCR object
#
$method   ||= 'local';
my $epcr    = Bio::PrimerDesigner->new( 
    program => 'epcr', 
    method  => $method
) or die Bio::PrimerDesigner->error;

#                                                                               
# List paramaters for epcr program and exit.
#
if ( $list_params ) {
    my $title = 'e-PCR Parameters:';
    print join "\n", $title, '-' x length $title, 
                     $epcr->list_params, '';
    exit;
}

my $header = "Primers designed using $method primer3/e-PCR"
            ." installation";
my $hline = '-' x length $header;

print "\n$hline\n$header\n$hline\n\nPrimer",
      (" " x 14), "\tF/R\t5' Coord  Pair-qual\n";

for ( 1 .. $num_primers ) {
    my %params = ( seq => $dna,
                   left => $result->left($_),
           right => $result->right($_),
                   permute => 1
         );
         
    my $epcr_result = $epcr->design( %params )
      or die $epcr->error;
    
    print 
        "Set $_\n", $result->left($_),
        "\t F \t", $result->startleft($_), 
        "\n", $result->right($_),
        "\t R \t", $result->startright($_),
        "\t", $result->qual($_)."\n",
        "\ne-PCR products: ", $epcr_result->products, "\n";
         
    for my $prod ( 1 .. $epcr_result->products ) {
        print 
        "product $prod: start->", $epcr_result->start($prod), 
        "  end->", $epcr_result->stop($prod), " size->", 
        $epcr_result->size($prod), "bp\n\n";
    }
}

=pod

=head1 AUTHOR

Copyright (C) 2003-4 Sheldon McKay E<lt>smckay@bcgsc.bc.caE<gt>,
                   Ken Y. Clark E<lt>kclark@cpan.orgE<gt>.

=head1 SEE ALSO

Bio::PrimerDesigner.

=cut

__DATA__
cagagttaaagagaaaactgataattttttttccatctttctcctcacttgtgaataaactaaacgcatttctgtggacgttccaagtgtaatatgagagttgttttcatttggaaatgcgggaatatattgaatcttccattagatgttcaggaatatataaatacgttgtctgctctgaaaattcacacggaaaatctaaaaattgtcaaattatagatttcattctcaaatgactatataacattttatttttgcaatttcttttcaattaggaaacatttcaaaaagctacgttgtttttcacattcaaaatgattactgtcggtgcgttcattttccgagtttttccaatttcacgcttgctcttcttcgtaaaaaactcgtaatttagaaattgtgtctagatcaaaaaaaaaattttctgagcaatcctgaatcaggcatgctctctaaacaactctcagatatctgagatatgggaagcaaattttgagaccttactagttataaaaatcattaaaaatcaacgccgacagtttctcacagaaacttaaaccgaaaaatcccaacgaagacttcagctcttttttctttgaaatttgagacaaaggcccgttctattgtctttccgactcacatcgttcattaataaatcgttctttcttctacttcattcatcaatttcctcttgaccagagagagtccctactcttgaagctcctcttctttactcttttcttacttacgcacaaaaagtctctctatcactgcgtctctctatccatctcttctacatgtcacttgtcgtctctgcgcctctataacacgtaacaatctctaccttcaagttctctagtcacctgtcttcgtctataccttttgccacgaaaattactacgtagaagctgtcctattgtaaagatgaaacagtttgaagagaaattggatgattgtgatctattggtctcagaatttgatggatttcttttccatgttttcaattttaacgtctatattcttacctaggtactcataattttaactttgtttatatttttataaacttataagttacaatttttaaatcagttaacaacttcctataatcaaattgtattctattttttttggcacaaacacatataaatgtccaaatatttgcgcacgagtcacccctctccactcatttgccgcccaattttgacgttttcttccttgcacattttgacagcatttctaatttcaggaaattcttcatatatcaattggtcagtcacaattatcctcctcattcttggactttacgcctgtcatcgatttttgaacatgaagaagttgactcgagatgcacaggaaccacttttacgtgagtttttaaagattttttttttgaaaattgatgtcttgcattttatttagctcactggatagtagaaaaaatattttttttatctatttgaaaatcaaatgtgttaaaaaaatatttttggagaaaaataactgaaagctcctttctgaattattgttttattattaaacatttgttttcttctaactttatgttttttaatgttttttttttactttttaaatcctgaattattttgtgaaaattcaaacagtttcatttttaaaatttcaaaccctgataaaaagttcaatatttttcactgaactttaatttttttaaaagtttatgaaaatttcctatgaaattaagttcagaagttttttagctcatatccgcccctccacaaggaataaaattcgaaaatatatttatggaactatttttattttatcaatttttctcctttatcgatcactgaacagtccagacacatcaaaacacggaattggcagaaatggagatgtaagttttgagatttattgcaacaaataatttacaaaataatttcagtttattgaatatgagccaaaagcaggacccacgataaaagagcctgtagagaatatagttaaattggacgtttatatggaagcacagtgtccggatacatctaggtgagcagttagtaattaaattaatttaatatttgatttattttaagatttttccgtcaacaacttaaaaaagcgtgggatattctaggaaggctaaatcgaatcgaattgaatgtaattccatttggaaaagcgaggtgtacagagaaaggaaacgatttcgagtgagttttttttgttaattgattttaaatctgatcataaaatattgcagatgtcaatgtcagcatggtccgacagaatgtcagattaatcaattaatgaattgtgtcattgatcgatttgggtttccacatagatatttgccaggtgttttgtgtatgcagggaaaatattcattagatgaggcaatgaaatgtgttactgagaattatccatctgaatatgaaaggtatgtattttgtgccgtaaatgcatagttagaccaacgaatactttttaaaatcatacgaaatatattttcatatattatcactgaatataatagttaatgaaagagtaatgctcatttttcagttcaactttatttttcaaagaatattgaattttagaatgcgtgaatgtgcatcaggaactcgaggtcgccgccttcttgctctttccggacagaaaactgcatcactaactccagcaattgacttcattccctggattgttattaatggttcacgtaactcggatgctctttatgatctaacacagaatgtctgtgaagcaatgcaaccaatgccatctgcatgcaaagattacttacgttcattacaataatcacatcttttacgggttgacttttcgtcttatagttttttttaaaatacaattggtgtctatctatgagtgcctttcacaactcggcgggtcctaaaattgtttattatatttatttaaatttttgttgtagtttgtgttagtgtgactaacttattgtgttaattttcttaaaaagaacgttttttattaaaataaaaagttgcaaattgtaaaagtttgtgtttatcacattatgatattttgggcaattgtgaggatctattaaaaatttataaatctctttgacagtgtgtgggaaaaataagttatttttagcttctgatattttctaggattaacagaaaaaacagcaaatttcaggtatacccgcttgccagttcgtgatcaactccagtgttttccaaaaaaacaaatctacccttccccagcttcagatgttacaaactcgataaaatttgtttcagaaacatctcttcagtgtgaccacaaactagtctttcgcttccttttaacaacaaaaaatggaaaaagaaggagggatttacaagaggctacgacgatacgaatgaatgaaaacgatttgatgcaatcagctgctgcttctgcatttgccattcaatttgtcacctttctgccaaatttacacgatctgttttgagtgtggactttttgaaagtttaaaccacttttcgtcaatttttaaatgatgtttttacttcagtttttattattttgttttgcaaaaaatatttcagtatgcctgcattttttaaatatttaaagtttgattttttttaacatccaagtagaaatgatagctcacctactccaactaaattttgaccaacaactgtcacttctatatttgaagacataattaacataaatcttgaatttttgaagtaattttaatgtctgaacatcttgttttgaatcttgtttttttgccgaaaaatttgaagaaaaaagaaactgaaatattgcaaacatcgccagaatgcagacggtagggttgaataagatagagggcattgaaccctttctaattttctgttttgcaaattattttacagtaggtctgaacttcacagtttcatggtacgcccaatttttaacttcttttttgaattcaaattttctaaactacattatcgatttccatgaaaacagttgcattaacttcctctgaccattccaagaatttctggcttaccaaccgacatcactcttgccccctcgtcattaagccgtaattgatagcgacaaaaaaaaagaaaagccggctattttaatcgaatcttcttcatttgagaatggagggtgctacttgaatgggtgacaattgactcgtgaaattcttctttatcttttctccttatttttctcagaatttcttcatcatccacttttttggagtttcaaatgttaattgcaatctgtctcattttggtagtcatttggaaaacacgggggaggcgataacaggaagcttaagggatagacatacacttgcaattgtcgaaaaagcgatatctttaacgattattacgattctttcagtgtgacgtaatcctaatcagtttatttttattttttctgaaagcttcttttacgaattgcgcaattaatagtgtcagtagaaaaggcataatttttgaagaatatgccaaaatatgtaaaccctctccgttaatagcagtagctagtgatctagactatatgcaatacacactagttgtccaattgaaacaggtatccacaatattcacgatttttgaagtgtgatgtattagataatcctatcattttttcctcatcggccagtactttttttgttgttatttttgcaatatcctccgctttttattgttttcctattcacacctgtatttgattctggtttcccaaaaagaacaggcatagtttttgcgttgggaactggttttatttcagcatatcttctcatttctcaaccagaattagaaacatttttagaacaatcacatttatagcctaaatttttactaaaaatatctgaaaaacatgatatacactttgtagaatttttgaaaataatatccgcctatccatgatttaaccttattattcgaaatctgtgagattcctcaaagtagaaacataaaatttcaggcacaacacaaaagtcggaactcaattaaaatcgaataccctgtttgagatggcgtttctggctcgtaaaacgtcttctctcctaccagccaccacatcctctacagtcaagcatatgatctacgatgaaccacattttgcaatgcagaacagtttggcaaaacttatcaaagagaaaataaacccaaatgttgcacaatgggaaaagagtggaagatatccagcacattttgtgttcaaaatgcttggacaacttggagtatttgcggtgaataagcctgtaggtgaggatacttattttaaagaaaaaattttggaagttgaaaattattgaagactatggtgggactggtcgagattttgcaatgtcaatagcaatagctgaacaaattggagcagttgattgtggatcgattccaatgtcagtcatggttcaaagtgacatgagtactcctgctcttgcacaatttggtgagttctataaaacttatactgtaacttaattgatatatcaggctccgattcactccgcaatcgctttcttcgtccttcaatcaatggtgatctagttagttcaattgcagtctccgaaccacatgcaggatcagatgtatccgcaattcgcacacatgcccgtcggtacggcagcgacttgataataaatggctcaaaaatgtggataacaaatggagatcaggcagattgggcatgtgttctagtaaatacttcaaatgcgaaaaatttgcacaaaaataagtcgctggtgtgtattccactggactcaattggtgtacatcgatcaactccgttggataaattaggaatgagaagctccgatacagttcaactattttttgaagatgttagggtgagtttcttaaaatgatctacggcccctttaaccaattttaataaataattcaatgttcatttcaatcgaatcatttttcaggttccctcgtcatacataataggcgaagaaggacgtggatttgcatatcaaatgaatcaattcaatgatgagcgccttgtaacagttgctgttgggcttctcccacttcaaaaatgtataaatgagacgattgagtatgcaagagaacgattaatatttggaaagacacttctcgatcagcaatatgttcaatttcggttagccgagttggaggctgaactggaggcaacccgttctttgctctatcgaacagtgctggcacgttgccaaggcgaggatgtgagcatgttgactgcgatggcgaaattgaaaattggaagactggcaagaaaagttactgatcagtgtctacaggtgaggcgtttttgttctaaaatatacaaaaaattctcaaaatatgtatataaatcacttgtaatattctccatattagacttgaatattccttgctcttctttgtcagattatatctcggttgtatttgtttttatgaaaacaaaattgccaactaacaaaatttgtgcaaaataatttgctttattttggatgttgaactttttttgatgaaattaagacaaccgagatataaacagtcaaagtatagcaatgcaaggataattcggtatatgtttttgtgatccctccagtggcagtttttcataacttgatggtttttttatagaaatgaattggaataacgctaaagcttcattattaatattctcttaatttcagatctggggaggtgctggatatctgaatgacaatggaatatcgagagccttcagagatttccgtatattttcgattggcgctggttgcgatgaagttatgatgcagattattcataaaacacagtccaaaaggcaacagaaaagaatttgagaacatttttaaatgttatatttgtaaatacgaaaataaaatgcaattgtactgaaaacgataaaaataaaacagcgaaaaagtcatattgtatagaatttggcacgtatatctacaaccagtttctagtgacccaggtatcttgaagtaagtattcaatgaatcaattcaagttattatatttatatttgtccgcatcggaaggaaagcgcaaagaagtttctctctccgcctcatcaaattttttgtgtttgcatttcaaaaatgactgcaatgaaacgcgaattactgcgagtaagtaaagttagttttgatagaaactactgtatgagaaaaccggttgaaaagtaaagatgagcagcagtatttcatggaaaaaagagggagacaacaagagacggagtatataaggtgtcatggatgctccgagagtgtttacttctttgtttcaattttcacacttttcattcttttcattctttttgtttttcacaattatttagcagatcggtaactttttgctttgataatttcatagatactttcgaatcgaaattaattttcaaattagcctacagtaattttgctctcatctctgagttctagatcatgtttcaatttaccgaaagtgtttacacaagttaccaagaaaacaaaaaattcaagtttccgaaaattatcaaatgtttatcaaaaaggtcctatgatgtttaaaacaatttttcaaacttccagaaaaattttaacttactgtttcttgagcgtttacagtaactccggtgtttccagtaggcatagcttaccttgaaagcaggcaggcgaaaatttctctagaccaaccagaataacttactttattgctaagttgaatcaaacaattttgtaaaaaaaacgaattttggaatcatgatccctattcaagcttctagttgctggtcagctaggttttgggtttttttttggaaaaatattcaaaaaacatttatataatagttagaattaacattttttgataaaacctcgacatttttgttttgtctgaaaaaataggaaaatcttacgtttttcgaaaaaacccgtgctcgtgaaaagtatgtcctctgagagaagtaatgtttcatctgaccagttgcaactttctgtgtgcacattcttttgataaaatggtatcacagatctattctaaaagccaacatctaaattctttgctctatctttatcagttgatacggatcttctcatctcattcgcccacaatcttcccatactaattcatcaaacccacttgtaaatatacgcgcggttgatcaaaatttgtgtgtgttatggcacattgtgcaaatagttttaccacacttacatacttcaactcaaacctttgaggagtttgacagagagatggaaagatagtctgcaaacggcagatttttgaagtttcaccgctgtccatctaattttaggtatttttcggaatcttttgcaggacgttatcatctatctttcccgttatcaattagtcataattatccaattagtggcagttgttagaagaaataggtaatatgcataatagtgtcatttgccattggccacctccaccaaactttcgattatgccgttttccgttttctgtgtgtttcttcgtccttcctcatcatttctcattcgcttttttttcttcccatcttttccaacatgtcgcactaagagtgaccaaaaaacctttcaaattttgcgtgttctttcggtctttccggaagggacaaaaatcaaaacgacactggaattatgaactcatccattttccactttaaaagttgaaaaaagtaaacagcggggttattgtggtttgatctcttttaaaaatcagttaaatataggagtcaagacctcaatgagcactcttcaagatatggttctactagactcaacttgaagattttcaagagttctggagactttttcaaggctactgctttcaagcttcagaattttaaacattttggaaataatcttaaactggagttcaatagccaattgagcaatttgttataacgtttttttcttaattttttaaattagaatcagtgtaaatttataagtttcaaaattagttttgcacttatctttgggcgttactgaattttttacgtggtgaaccttgagaaaaaattctaaggcttctaattgagaaaactaatttaaattccgctcccaggagttaccaattttaatacgtttccaaaaaattaaatattcttcgaatctcatttttaaagtttccatttggcacaaaccacaataatttaagtaagacgtttgatctatgccgtagtttgtgtacttcaacgtttatccttaagtacctaggcccgtgtttttacagctctgctctttatcggtacatactgttctctgtctttattgatagaaattttgaaaaatgcaacaatatggtatctatcaggtcgtcccataagtttttgtacttttttaaaactttttgaacaagttctaaactgacagaacaaaatcgaatcttttataaatgcgcatgtatagtatgtactacttgtcaaaatttttatgcgttatttcaatatcctcctgataacaatcacggaaaccagagccacaaatagcgacatacccaaataatgggaggtgttttccttcgtcctgctattcacagggaatttatcaatgaacatgaaaacatagtattagtaaagataatgattcaaaatacatgttcagtatggttaaaattatcattagcacttattagccgttttggacgtggactatttggctcatgtttatcaagcactgagtgaacatcttcatggaataatttctcactaaaagtgatgggattattttgattgttgtttctaattttatataacaatacttgcatagtacaaatacaaacttcgttttacttgctgatttctcaatcataaattagaagcccaacactataaatgtcgggtatcacatgaggttggccatgtagattgtttgaacgaagaggccaccagtaaagtttgttaatttatttatgatacatatatccacttctaaataacactagacttaattatctatctttcattccgaggactaaatggaccaatatatgcttcaatcactcctataggcaattgttaaaagtacaaaatagtgtggttacaatgttctcaattataacatctccccatgactgaaaaaattaaatttttttaaaattttgactgcacatgatgtgcacttatcgtaaacatacacgatgcacccgttccattcccagcggcttcacaggaatcaaaaactcgggcgccatatttaattggcctcaacaattgtgtttagctacagtagtttttccggaatagttatactaaatttaaaattatttaaaacaagagtgtggaagcatctacttgacagtatatattaaccattactttaagctctgggtggtgtagaacaaactccagaaggaatggtgtaaaaagctgattctatagttactcgtttttctaaacaaccgcgggggcctgggatgccagagttatgttgcaataaggtgacaagttggtgacatgctaccactaatataaaatcttagaattgtccgaaaaagttttgggaataattcgaaaaaaagtacaaaaacttatgggacgacctgataggatatatgttaaaaactatttttgaaaaaatattttattttgaacaatgaaataaggttcctgcctcaaggtttctttttgacgcgaactccgatgacattttaattatcaaacggtctaagtgaaaatttattggacaactctttagttgaagtgcactttaggagcaggcatacatgaaggcgtgaggcaggcgtaggtcgcttacgaggcagacaatttttaaaaaaatcaccatccttttgtactaataaacactctctaaaagtttgcaatgttgtctcccaacacgaaaagttcaatcaacttctgcactcaatttttttgcaagatgacccatttgattcaagggggttaccagtagacttacctgcaaaaaaacagtattcgtgcataaatccatcaaaatgaagtgtgcgtcttcttcttagtttccgtctcccgttgtttcttaatgtatacagaagatgtacggggcagcagcagcagaaaaaagatttgcgtacaccaaacacatcaaaacgatatgcgtgaaatgagcgaatcgtccgcattctccccttttttctttcaattttcaaggagagagaaaactctgtgagacagtgaagaagtggggttttgactggaaaagaagaagaagaagaagaagaagaagaagaagaagaactgattcttatctgagttccgacgacgattccaccgttttttggtctggtcttctttcctccgcttcttcttcttctacttctcttttcacgtctttctcatatttggttgtttttcaagttttgaactctttctactacatacttttcacatgtacctttaaaaaactcataattcattttccaatgtgttgaaaactactgtaactgcttaaaagtcagaaacagtaacgaaactattttcatgataaaatcaaaaattgtttcgattcgaaaatgtttttatatactcgacatgtgtgtacatgtgtaaaccagtcgtttcaaaaattttacaaaaaaatgtaaagaaactgttcagtgatcagtatgctccagcttcttagtttcttagtttctaggacttcacacactgcctgccttcaaactaccgcctattaacatttattccggtcgctcttttgtatttattgaggaaatcaactactgtagttttttaaaaattaatttattgatttggcaatttttctttttttttcaagattcaaaaataagaaattgtattttactcaccattattcaaaaaacttgatgaaatgtttaaattttatggtaaatgatcaaaactaat
NOGROK
close OUT or die "Can't write file '$file': $!\n";
