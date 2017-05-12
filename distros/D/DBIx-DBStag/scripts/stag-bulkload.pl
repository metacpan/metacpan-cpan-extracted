#!/usr/local/bin/perl -w

# POD docs at end

use strict;

use Carp;
use Data::Stag qw(:all);
use DBIx::DBStag::SimpleBulkload;
use Getopt::Long;

my $parser = "";
my $handler = "";
my $debug;
my $help;
my $loadrecord;
GetOptions(
           "help|h"=>\$help,
           "parser|format|p=s" => \$parser,
           "handler|writer|w=s" => \$handler,
           "loadrecord|l=s" => \$loadrecord,
           "debug"=>\$debug,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}


my @files = @ARGV;
foreach my $fn (@files) {

    $handler = DBIx::DBStag::SimpleBulkload->new;
    $handler->load_on_event($loadrecord) if $loadrecord;
    my @pargs = (-file=>$fn, -format=>$parser, -handler=>$handler);
    if ($fn eq '-') {
	if (!$parser) {
	    $parser = 'xml';
	}
	@pargs = (-format=>$parser, -handler=>$handler, -fh=>\*STDIN);
    }
    my $tree = 
      Data::Stag->parse(@pargs);

}
exit 0;

__END__

=head1 NAME 

stag-bulkload.pl - creates bulkload SQL for input data

=head1 SYNOPSIS

  # convert XML to IText
  stag-bulkload.pl -l person file1.xml file2.xml

  # use a custom parser/generator and a custom writer/generator
  stag-bulkload.pl -p MyMod::MyParser file.txt

=head1 DESCRIPTION

Creates bulkload SQL statements for an input file

Works only with certain kinds of schemas, where the FK relations make
a tree (not a graph); i.e. the only FKs are to the parent

You do not need a connection to the DB

It is of no use for incremental loading - it assumes integer surrogate
promary keys and starts these from 1

=head1 ARGUMENTS

=over

=item -p|parser FORMAT

FORMAT is one of xml, sxpr or itext, or the name of a perl module

xml assumed as default

=item -l|loadrecord NODE

adds a COMMIT statement after the INSERTs for this node

=back


=head1 SEE ALSO

L<Data::Stag>

L<DBIx::DBStag>


=cut

