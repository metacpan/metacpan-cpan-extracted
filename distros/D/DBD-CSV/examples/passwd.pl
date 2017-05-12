#!/usr/bin/perl

use strict;
use warnings;

use DBI;

my $dbh = DBI->connect ("DBI:CSV:");
   $dbh->{csv_tables}{passwd} = {
    sep_char     => ":",
    quote_char   => undef,
    escape_char  => undef,
    file         => "/etc/passwd",
    col_names    => [qw( login password uid gid realname directory shell )],
    };
my $sth = $dbh->prepare ("SELECT * FROM passwd");
   $sth->execute;
my %fld;
my @fld = @{$sth->{NAME_lc}};
$sth->bind_columns (\@fld{@fld});
while ($sth->fetch) {
    printf "%-14s %5d %5d %-25.25s %-14.14s %s\n",
	@fld{qw( login uid gid realname shell directory )};
    }
