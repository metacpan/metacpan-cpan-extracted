#!perl
use strict;
use Getopt::Long;
use DBIx::Spreadsheet;
use DBIx::RunSQL;

our $VERSION = '0.04';

# use File::Notify::Simple;
GetOptions();

my $file = $ARGV[0];
my $query = $ARGV[1];

#warn "Reading '$file'";
my $sheet = DBIx::Spreadsheet->new( file => $file );
my $dbh = $sheet->dbh;

DBIx::RunSQL->run(
    dbh => $dbh,
    sql => \$query,
);
