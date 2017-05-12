#!/usr/bin/perl
# $Id$

use strict;
use warnings FATAL => 'all';
use DBI;

my %create_tables = (
  pkit_user => q{
    CREATE TABLE pkit_user (
      user_id CHAR(8), login CHAR(255), email CHAR(255), passwd CHAR(255)
    )},
  sessions => q{ 
    CREATE TABLE sessions (
      id char(32) not null primary key,
      a_session text
    )}
);

sub table_exists {
  my ( $dbh, $table ) = @_;
  eval {
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 1;
    $dbh->do(qq{SELECT * FROM $table WHERE 1 = 0 });
  };
  return !$@;
}

my @driver_names = DBI->available_drivers();
@driver_names || die "You have NO drivers available!\n" . "Please install at least DBD::SQLite or others from CPAN.\n";

if ( @ARGV != 4 ) {
  my $usage =
    "Usage: $0 driver dbName userName auth\n" . "For the example site, use the following:\n" . qq{$0 SQLite dbfile "" ""\n};
  if (@driver_names) {
    $usage .= "You have the following installed drivers available:\n@driver_names\n";
  }
  else {
    $usage .= "You have NO drivers available!\n" . "Please install at least DBD::SQLite or others from CPAN.\n";
  }
  die $usage;
}

my ( $driver, $data_source, $username, $auth ) = @ARGV;

unless ( grep( /^$driver$/, @driver_names ) ) {
  my $msg =
      "Driver '$driver' is not in the "
    . "list of installed drivers!\n"
    . "You have the following installed drivers available:\n@driver_names\n";
  die $msg;
}

my $dbh =
  DBI->connect( "dbi:$driver:dbname=$data_source", $username, $auth, { AutoCommit => 1, PrintError => 1, RaiseError => 0 } )
  or die $DBI::errstr;

for my $table ( keys %create_tables ) {
  unless ( table_exists( $dbh, $table ) ) {
    $dbh->do( $create_tables{$table} ) or die $DBI::errstr;
  }
  else {
    print "Skip existing table $table\n";
  }
}
$dbh->disconnect;

=pod

=head1 NAME

pkit_setup_db.pl

=head1 SYNOPSIS

This script creates the tables, pkit_user and sessions in the specified
database.

=head1 REQUIREMENTS

A DBD driver that matches the specified database. In the case of the
Apache::PageKit example, DBD::SQLite is required.

=head1 USAGE

pkit_setup_db.pl driver dbName userName auth

=over

=item -

C<driver> is the name of the DBD driver that matches the database
being used.

=item -

C<dbName> is the name of the database. When using file-based
databases, as with for instance SQLite, it will be the file name.

=item -

C<userName> is the user name that will be used to login and create
the tables in the database.

=item -

C<auth> is the authentication string needed to log into the database.

=back

=head1 DESCRIPTION

The script logs into the specified database using the specified
user name and authentication string. It then creates the tables
pkit_user and sessions.


CREATE TABLE pkit_user (
	user_id CHAR(8), login CHAR(255), email CHAR(255), passwd CHAR(255)
)

CREATE TABLE sessions (
      id char(32) not null primary key,
      a_session text
)


This may be useful for starting an application, using Apache::PageKit.

=head1 EXAMPLES

  pkit_setup_db.pl dbfile "" ""
  pkit_setup_db.pl pagekit "" ""
  pkit_setup_db.pl pagekit pageusr 'Q#Se$Re;w'

=head1 BUGS

=head1 NOTES

For the Apache::PageKit demo, the SQLite driver must be used.
The script will produce the database file in the cwd.

=head1 CREDITS

  Boris Zentner <bzm@2bz.de>, for the initial script,
  pkit_setup_sqlite_dbfile.pl, where this script was copied
  and modified from.

=head1 AUTHOR

  Pieter du Preez <pdupreez@sodoz.com>

