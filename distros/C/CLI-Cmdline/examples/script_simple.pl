#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper $Data::Dumper::Sortkeys = 1;
use CLI::Cmdline qw(parse);

# After parsing ./script1.pl -vvvx file.txt
# %opt will contain: (v => 3, h => 0, x => 1, config => '/etc/myapp.conf')
# @ARGV == ('file.txt')

my $switches = '-v -h|help -x';
my $options  = '-output -config -incl';

# only define options which have no default value 0 or '';
my %opt      = ( config  => '/etc/myapp.conf' );

CLI::Cmdline::parse(\%opt, $switches, $options) 
	or die "Try '$0 --help' for more information.\n";

# @ARGV should now contain only positional arguments
Usage()        if $#ARGV < 0 || $opt{h};

print Dumper(\%opt);

print "ARG = [".join('] [',@ARGV)."]\n";
exit 0;

sub Usage {
   print "Usage: $0 [options] <files...>\n";
   exit 1;
}
