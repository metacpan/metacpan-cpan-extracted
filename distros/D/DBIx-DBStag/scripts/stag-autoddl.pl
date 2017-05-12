#!/usr/local/bin/perl -w

=head1 NAME 

stag-autoddl.pl

=head1 SYNOPSIS

  stag-autoddl.pl -parser XMLAutoddl -handler ITextWriter file1.txt file2.txt

  stag-autoddl.pl -parser MyMod::MyParser -handler MyMod::MyWriter file.txt

=head1 DESCRIPTION

script wrapper for the Data::Stag modules

=over ARGUMENTS

=item -help|h

shows this document

=item -p|parser FORMAT

FORMAT is one of xml, sxpr or itext, or the name of a perl module

xml assumed as default

=item -w|writer FORMAT

FORMAT is one of xml, sxpr or itext, or the name of a perl module

This is only used if transforms are required on the data to turn it
into relational form; the transformed xml (or other stag format) is
stored in the file specified by -t

=item -link|l NODE_NAME

this node name will be used as a linking table

multiple linking nodes can be set:

 -l foo2bar -l x2y -l bim2bum


=item -t TRANSFORMED_FILE_NAME

the transformed input file is written here

=back

=cut



use strict;

use Carp;
use Data::Stag qw(:all);
use DBIx::DBStag;
use FileHandle;
use Getopt::Long;

my $parser = "";
my $handler = "";
my $mapf;
my $tosql;
my $toxml;
my $toperl;
my $debug;
my $help;
my @link = ();
my $ofn;
GetOptions(
           "help|h"=>\$help,
           "parser|format|p=s" => \$parser,
           "handler|writer|w=s" => \$handler,
           "xml"=>\$toxml,
           "perl"=>\$toperl,
           "debug"=>\$debug,
           "link|l=s@"=>\@link,
	   "transform|t=s"=>\$ofn,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}

my $db = DBIx::DBStag->new;

my $fn = shift @ARGV;
die "max 1 file" if @ARGV;
autoddl($fn);

sub autoddl {
    my $fn = shift;
    
    my $tree = 
      Data::Stag->parse($fn, 
                        $parser);
    my $ddl = $db->autoddl($tree, \@link);
    my $transforms = $db->source_transforms;
    if (@$transforms) {
	foreach (@$transforms) {
	    print STDERR "-- SOURCE REQUIRES TRANSFORM: $_->[0] => $_->[1]\n";
	}
	if (!$ofn) {
	    print STDERR "-- $fn requires transforms; consider running with -transform\n";
	}
	else {
	    $tree->transform(@$transforms);
	    my $W = $tree->getformathandler($handler || 'xml');
	    my $ofh = FileHandle->new(">$ofn") || die("cannot write transformed file $ofn");
	    $W->fh($ofh);
#	    $W->fh(\*STDOUT);
	    $tree->events($W);
	    $ofh->close;
	}
    }
    print $ddl;
}

