#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use DBD::SQLite;

my $dbfile = $ARGV[0] || die <<"USAGE";
Usage: $0 your_new_dbfile_name
	The eg site use dbfile as the databasename in the
	pkit_root directory.
USAGE

-e $dbfile and die <<"EXISTS_ALREADY";
$dbfile exists already. For security reason we do not overwrite it.
EXISTS_ALREADY

my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "", { AutoCommit => 1, PrintError => 1, RaiseError => 0 } )
  or die $DBI::errstr;

$dbh->do(
  q{
    CREATE TABLE pkit_user (
      user_id CHAR(8), login CHAR(255), email CHAR(255), passwd CHAR(255)
    )}
) or die $DBI::errstr;

$dbh->do(
  q{ 
    CREATE TABLE sessions (
      id char(32) not null primary key,
      a_session text
    )}
) or die $DBI::errstr;
$dbh->disconnect;

=pod

=head1 Create a dbfile with the tables pkit_user and sessions for use with DBD::SQLite.

=head1 Overview

This script creates a dbfile with the tables pkit_user and sessions for DBD::SQLite. 

=head1 Requirements

DBD::SQLite

=head1 Usage

  pkit_setup_sqlite_dbfile.pl dbfile
   
C<dbfile> is the name of your dbfile. The eg site use 'dbfile' as the dbfilename. And expect it in the pkit_root directory.

=head1 Description

The script creates the file C<your_dbfile> in the current directory and creates the tables pkit_user and sessions. Suitable for use with DBD::SQLite.

CREATE TABLE pkit_user (
      user_id CHAR(8), login CHAR(255), email CHAR(255), passwd CHAR(255)
)

CREATE TABLE sessions (
      id char(32) not null primary key,
      a_session text
)

This may be usefull if you start a application. In short it is the same that ./t/TEST -start-httpd or make test does for the eg site.

=head1 Example

  pkit_setup_sqlite_dbfile.pl dbfile

=head1 AUTHOR

  Boris Zentner bzm@2bz.de

