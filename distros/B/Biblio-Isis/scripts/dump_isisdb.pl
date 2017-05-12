#!/usr/bin/perl -w

use strict;
use blib;

use Biblio::Isis 0.24;
use Getopt::Std;

BEGIN {
	eval "use Data::Dump";

	if (! $@) {
		*Dumper = *Data::Dump::dump;
	} else {
		use Data::Dumper;
	}
}

my %opt;
getopts('do:l:v', \%opt);

my $isisdb = shift @ARGV || die "usage: $0 [-v] [-o offset] [-l limit] [-d] /path/to/isis/BIBL\n";

my $isis = Biblio::Isis->new (
	isisdb => $isisdb,
	debug => $opt{'d'} ? 2 : 0,
	include_deleted => $opt{'v'},
#	read_fdt => 1,
	ignore_empty_subfields => $opt{'v'} ? 0 : 1,
);

print "rows: ",$isis->count,"\n\n";

my $min = $opt{o} || 1;
my $max = $isis->count;
$max = ( $min + $opt{l} - 1 ) if ($opt{l});

for my $mfn ($min .. $max) {
	print STDERR Dumper($isis->to_hash($mfn)),"\n" if ($opt{'d'});
	print $isis->to_ascii($mfn),"\n";

}

