#!/usr/bin/perl -w

use Getopt::Std;
use BioX::SeqUtils::RandomSequence;

getopts('hl:a:c:t:g:s:');  
check_opts();

my $randomizer = BioX::SeqUtils::RandomSequence->new({ l => $opt_l, 
                                                       a => $opt_a,
                                                       c => $opt_c,
                                                       g => $opt_g,
                                                       t => $opt_t,
                                                       s => $opt_s });
print join( ', ', @{ $randomizer->rand_pro_set() } ), "\n";

exit;

sub usage { print "   USAGE: " . __FILE__ . " -l<length> -a<rate> -c<rate> -g<rate> -t<rate> -s<codon_table>\n"; exit; }

sub defaults { $opt_a = $opt_c = $opt_g = $opt_t = 1; }

sub check_opts {
	if ( $opt_h )  { usage($opt_h); }
	if ( !$opt_a or !$opt_c or !$opt_g or !$opt_t ) { defaults(); }
	if ( !$opt_l ) { $opt_l = 2; }
	if ( !$opt_s ) { $opt_s = 1; }
}

