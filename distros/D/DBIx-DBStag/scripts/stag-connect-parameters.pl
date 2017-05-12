#!/usr/local/bin/perl

# cjm@fruitfly.org

# currently assumes Pg

use strict;
use Carp;
use DBIx::DBStag;
use Data::Stag qw(:all);
use Data::Dumper;
use Getopt::Long;

my $h = {};

my $dbname = '';
my $term;
my @hist = ();

GetOptions(
           "dbname|d=s"=>\$dbname,
          );

my $db = shift || $dbname;
# parent dbh
my $sdbh = 
  DBIx::DBStag->new;

my $resource = $sdbh->resources_hash->{$db};
my $pstr = '';
if ($resource) {
    my $loc = $resource->{loc};
    if ($loc =~ /(\w+):(\S+)\@(\S+)/) {
        $pstr = "-h $3 $2";
    }
    if (!$pstr) {
        print STDERR "Could not resolve: $db [from $loc]\n";
        exit 1;
    }
}
else {
    print STDERR "No such resource: $db\n";
    exit 1;
}

print $pstr;
exit 0;

__END__

=head1 NAME 

stag-connect-parameters.pl

=head1 SYNOPSIS

  alias db='stag-connect-parameters.pl -d'
  psql `db mydb`

=head1 DESCRIPTION

Looks up the connection parameters for a logical dbname in the metadata file pointed at by DBSTAG_DBIMAP_FILE

See L<selectall_xml.pl> for more on this mapping

=head2 ARGUMENTS

=head3 -d B<DBNAME>

This is either a DBI locator or the logical name of a database in the
DBSTAG_DBIMAP_FILE config file

=cut
