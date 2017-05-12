#!/usr/bin/perl -w

use Getopt::Std;
use BioX::SeqUtils::RandomSequence;

getopts('hy:l:a:c:t:g:s:');  
check_opts();

my $randomizer = BioX::SeqUtils::RandomSequence->new({ l => $opt_l, 
                                                       y => $opt_y,
                                                       a => $opt_a,
                                                       c => $opt_c,
                                                       g => $opt_g,
                                                       t => $opt_t,
                                                       s => $opt_s });
my $seq = $randomizer->rand_seq();
if ( $seq =~ m/^ARRAY/ ) { print join( ', ', @{ $seq } ), "\n"; }
else                     { print $seq, "\n"; }

exit;

sub usage { print "   USAGE: " . __FILE__ . " -l<length> -y<type> -a<rate> -c<rate> -g<rate> -t<rate> -s<codon_table>\n"; exit; }

sub defaults { $opt_a = $opt_c = $opt_g = $opt_t = 1; }

sub check_opts {
	if ( $opt_h )  { usage($opt_h); }
	if ( !$opt_a or !$opt_c or !$opt_g or !$opt_t ) { defaults(); }
	if ( !$opt_l ) { $opt_l = 2; }
	if ( !$opt_y ) { $opt_y = '2'; }
	if ( !$opt_s ) { $opt_s = 1; }
}

__END__

Option a	+int	        frequency of nucleotide A
Option c	+int	        frequency of nucleotide C
Option g	+int	        frequency of nucleotide G
Option l	+int	        length 
Option t	+int	        frequency of nucleotide T
Option s	+int (1-6,9-15)	codon table
Option y	2,d,r,p,s	type (nucleotide, protein, set)

