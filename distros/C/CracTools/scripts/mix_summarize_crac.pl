#!/usr/bin/perl -w

# Author Anthony Boureux <Anthony.boureux@univ-montp2.fr>
# 
# Mix summary results from crac, and create table and graph

=head1 NAME

mix_summarize_crac - a script to outline % locations per library

=head1 SYNOPSIS


Usage: 
  mix_summarize_crac [options] file1 file2 file3

Main option :

  -globalonly      	- Show only global mapping values
  -explainedsonly   - Show only explained mapping values
  -output filename  - the filename the stats are written (STDOUT by default)
  -namecolumns 'columns header'   - Split filename with /-/, and set header columns (ex: Exp-Nb-lib)
  -separator char                 - Separator (default -) to use to split filename and namecolumns
  -verbose value                  - verbose mode (2=DEBUG)

  -help             - help / usage
  -man              - print man page

=head1 DESCRIPTION

This script will create a report with statistic data.

The options are:

  -namecolumns 'columns header'   - Split filename with /-/, and set header columns (ex: Exp-Nb-lib)
  -separator char                 - Separator (default -) to use to split filename and namecolumns
  -verbose value                  - verbose mode (2=DEBUG)

=head1 AUTHOR

Anthony Boureux <Anthony.boureux@univ-montp2.fr>

=head1 TODO

  - generate a %mapping.. graph

=cut


use strict;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use File::Basename;

my $DEBUG = 0;
my $man = 0;
my $help = 0;
my $verbose = 0;
	
my $output;# = \*STDOUT; not good for getoptions
my %patterns = (
	'global' => ['Single', 'Duplication', 'Multiple', 'None'],
	'explained' => ['Explainable', 'Repetition', 'Normal', 'Almost-Normal', 'Sequence-Errors', 'SNV', 'Short-Indel', 'Splice', 'Weak-Splice', 'Chimera', 'Bio-Undetermined', 'Undetermined']
);

my $extension='';
my $sumonly = 0;
my $globalonly = '';
my $explainedonly = '';
my $namecolumns = '';
my $separator = '-';

GetOptions(
	'output:s'	=> \$output,
	'globalonly' => \$globalonly,
	'explainedonly' => \$explainedonly,
	'namecolumns:s' => \$namecolumns,
	'separator:s' => \$separator,
	'verbose:i'		=> \$verbose,
	'help|?'	=> \$help,
	'man'		=> \$man
	   )
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

$DEBUG=1 if ($verbose == 2);

pod2usage(1) if (! @ARGV);

my %reads; # reads hash
my @header_sup; # store supplemental header

# open all summary files
foreach my $file (@ARGV) {
	pod2usage(-message => "Can't read the file $file", -exitstatus => 1, -verbose => 1) if (! -r $file);
	print "doing file $file\n" if ($DEBUG);
	my $cmd = "<$file";
	if ($file =~/gz$/) {
		$cmd = "zcat $file |";
	}
	open(FH, $cmd) or die "Can't read summary file: $file\n";
	my @alllines = <FH>;
	my $contents = join('', @alllines);
	print STDERR $contents, "\n" if ($DEBUG);
	# TODO: should find the key:value to increase speed
	foreach my $type (keys %patterns) {
		foreach my $pattern (@{$patterns{$type}}) {
			print STDERR "pat= $pattern\n" if ($DEBUG);
			if ($contents =~ /$pattern: (\d+)/ism and defined($1)) {
			  $reads{$file}{$type}{$pattern} = $1;
      		} else {
        		$reads{$file}{$type}{$pattern} = 0;
      		}
			print STDERR "val=", $reads{$file}{$type}{$pattern}, "\n" if ($DEBUG);
		}
	}
  my $total_analyze = 0;
  if ($contents =~ /Total number of reads analyzed: (\d+)/ism and defined($1)) {
    $total_analyze = $1;
  }
	# calculate total
	foreach my $type (keys %{$reads{$file}}) {
		my $total = 0;
		foreach my $pattern (keys %{$reads{$file}{$type}}) {
			$total += $reads{$file}{$type}{$pattern};
		}
		$reads{$file}{$type}{'Total Reads analyzed'} = $total_analyze;
    print STDERR "Save $total_analyze in total reads analyzed\n" if ($DEBUG);
		$reads{$file}{$type}{'Sum reads mapped'} = $total;
		push @header_sup, 'Sum reads mapped', 'Total Reads analyzed' if (!@header_sup);
	}

	close FH;
}

#open output files
my ($file_output, $output_dir) = ('output', '');
my $fhout;
if (defined $output) {
	($file_output, $output_dir) = fileparse($output);
	open ($fhout,">$output.sum") or die "Can't write in summary in file: $output.sum\n";
} else {
	$fhout = \*STDOUT;
}

# generate header columns if split filename
my @nameheader = ();
if ($namecolumns) {
	@nameheader = split(/$separator/, $namecolumns);
}
# generate each columns for each line
my %out;
foreach my $file (sort keys %reads) {
	my @namecols = ();	
	if ($namecolumns) {
		# remove extension before
		my ($filewoext) = ($file =~ /(.*?)\./); 
		@namecols = split(/$separator/, $filewoext);
	}
	foreach my $type (keys %{$reads{$file}}) {
		my @header = @{$patterns{$type}};
		push @header, @header_sup;
		$out{$type}{'header'} = "File\t".join("\t", @nameheader, @header)."\n";
		my @data;
		foreach my $pattern (@header) {
			push @data, $reads{$file}{$type}{$pattern};
		}
		$out{$type}{'data'} .= basename($file)."\t".join("\t", @namecols, @data)."\n";
	}
}

foreach my $type (keys %out) {
  # global summary
	next if ($globalonly and $type ne 'global');
  # explained summary
	next if ($explainedonly and $type ne 'explained');
	print $fhout '# ', uc($type), " data\n", $out{$type}{'header'}, $out{$type}{'data'} ;
}

