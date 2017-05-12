#!/usr/local/bin/perl -w


=head1 NAME 

stag-eval

=head1 SYNOPSIS

  stag-eval '' file2.xml

=head1 DESCRIPTION

=head1 ARGUMENTS

=cut


use strict;

use Data::Stag qw(:all);
use Getopt::Long;


use strict;

use Carp;
use Data::Stag qw(:all);
use Getopt::Long;

my $parser = "";
my $handler = "";
my $mapf;
my $tosql;
my $toxml;
my $toperl;
my $debug;
my $help;
my @interpose = ();
my @regexps = ();
my @delete = ();
my @add = ();
my $lc;
my $merge;
GetOptions(
           "help|h"=>\$help,
           "parser|format|p=s" => \$parser,
           "handler|writer|w=s" => \$handler,
           "interpose|i=s@" => \@interpose,
           "add|a=s@" => \@add,
           "delete|d=s@" => \@delete,
	   "regexp|re|r=s@"=> \@regexps,
           "xml"=>\$toxml,
           "perl"=>\$toperl,
           "lc"=>\$lc,
           "debug"=>\$debug,
	   "merge=s"=>\$merge,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}


my $e = shift @ARGV;
my @files = @ARGV;

foreach my $fn (@files) {
    my $tree = Data::Stag->parse($fn);
    my @subtrees = $tree->find($e);
    print $_->xml foreach  (@subtrees);
}
