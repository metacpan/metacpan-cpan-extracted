#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper $Data::Dumper::Sortkeys = 1;
use CLI::Cmdline qw(parse);

my $switches = '-v|verbose -q|quiet --help --dry-run -force|f';
my $options  = '-input|i -output -mode -tag';
my %opt      = ( v => 1, mode => 'normal', tag => [] );   # tag = multiple tags allowed

CLI::Cmdline::parse(\%opt, $switches, $options) 
	or die "Try '$0 --help' for more information. ARGV = @ARGV\n";

#  --- check if ARGV is filled or help is required
Usage()        if $#ARGV < 0 || $opt{help};
die "Error: --input is required. See $0 --help for usage.\n"   if ($opt{input} eq '');

my $verbosity = $opt{v} - $opt{q};
print "Starting processing (verbosity $verbosity)...\n" if $verbosity > 0;

print Dumper(\%opt);
print "ARG = [".join('] [',@ARGV)."]\n";
exit 0;

sub Usage {
    print <<"USAGE";
Usage  : $0 [options] --input=FILE [files...]
Options:
  -v|verbose                Increase verbosity (repeatable)
  -q|quiet                  Suppress normal output
  --dry-run                 Show what would be done
  -f|force                  Force operation even if risky
  --input=FILE              Input file (required)
  --output=FILE             Output file (optional)
  --mode=MODE               Processing mode, default: $opt{mode}
  --tag=TAG                 Add a tag (multiple allowed)
  --help                    Show this help message

Example:
  $0 --input=data.csv -vvv file1.txt
  $0 --input=data.csv --tag=2026 --tag=final -vv file1.txt
  $0 --input=data.csv -quiet  file1.txt
  $0 -input=data.csv -dry-run file1.txt   # not a long tag with =
  $0 -input data.csv -vf file1.txt
  $0 -vfi data.csv file1.txt
  $0 -vif data.csv file1.txt              # option not at the end
  $0 file1.txt                            # missing input error
  $0 --help

USAGE
    exit 1;
}
