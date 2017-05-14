#!/usr/local/bin/perl -w

package rr;

use strict;
use vars qw($VERSION);

use strict;
use Getopt::Std;
use XML::Dumper;
use DBI;
use DBIx::Recordset;

use Business::ReportWriter::Pdf;

$VERSION = '0.01';

sub processReport {
  my ($outfile, $report) = @_;
  my $db = initDb( $report->{database} );
  my @list = getList($db, $report->{search});
  endDb($db);
  my $s = new Business::ReportWriter::Pdf();
  my $head;
#use Data::Dumper;print Dumper \@list;
  $s -> processReport($outfile, $report, $head, \@list);

#  $s -> pageHeader( %{ $report{page}{header} } );
#  $s -> breaks( %{ $report{breaks} } );
#  $s -> fields( fields => [ @{ $report{fields} } ] );
#  $s -> printList(list => [ @list ]);
#  $s -> printDoc(file => $outfile);
}

sub help {
  print<<EOT
Syntax: rr.pl -cfh
            -c Config File
            -f Output File
            -h This help
EOT
}

sub main {
  my %opts;
  getopt('cfh', \%opts);
  if ($opts{h} || !$opts{c} || !(-r $opts{c})) {
    help();
    exit
  }
  my $outfile = $opts{f} || 'out.pdf';
  my $conffile = $opts{c};
  my $xml = new XML::Dumper;
  my $report = $xml -> xml2pl($conffile);
  processReport($outfile,  $report);
}

sub initDb {
  my $parms = shift;
  my $dbtype = $parms->{dbtype};
  my $dbname = $parms->{dbname};
  my $host = $parms->{host};
  my $username = $parms->{username};
  my $password = $parms->{password};
  my $schema = $parms->{schema};
  my $db = DBI->connect("dbi:$dbtype:dbname=$dbname;host=$host",
    "$username", "$password")
    or die("Unable to connect to $dbname");
  $db -> do ("SET search_path TO $schema, public") if $schema;
  return $db;
}

sub getList {
  my ($db, $parms) = @_;
  $parms->{'!DataSource'} = $db;
#$DBIx::Recordset::Debug = 4;
  my $set = DBIx::Recordset -> Search ( { %$parms } );
  my @list;
  while (my $rec = $$set -> Next) {
    push @list, { ( %$rec ) };
  }
  return @list;
}

sub endDb {
  my $db = shift;
  $db->disconnect;
}

main();
