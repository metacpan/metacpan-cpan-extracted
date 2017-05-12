#! /usr/bin/perl -w

# $Id: query.pl,v 1.4 2001/03/31 18:28:34 rvsutherland Exp $

use strict;

use DBI;
use DDL::Oracle;

my $aref;
my $sql;
my $sth;
my $stmt;

my  $dbh = DBI->connect(
                         "dbi:Oracle:",
                         "",
                         "",
                         {
                          PrintError => 0,
                          RaiseError => 1
                         }
                       );

DDL::Oracle->configure( 
                        dbh    => $dbh,
#                        resize => 0,
#                        view   => 'user',
                      );

print STDERR "Enter Action [CREATE]: ";
chomp( my $action = <STDIN> );
$action = "create" unless $action;

print STDERR "Enter Type    [TABLE]: ";
chomp( my $type = <STDIN> );
$type = "TABLE" unless $type;

print STDERR "Enter Name of File   : ";
chomp( my $file = <STDIN> );

die "\nYou must specify a File.\n"    unless    $file;
die "\nFile $file does not exist.\n"  unless -e $file;
die "\nFile $file is not readable.\n" unless -r $file;

open FILE, "< $file"    or die "\nCan't open $file: $!\n";

print STDERR "\n";

my @lines = <FILE>;

# Create statement, eliminating lines containing only a slash
# and eliminating any semi-colons
$stmt =  ( join "", grep !/^\/$/, @lines );
$stmt =~ s/\;//g;
$sth  =  $dbh->prepare( $stmt );
$sth->execute;
$aref =  $sth->fetchall_arrayref;

my $obj  = DDL::Oracle->new(
                             type  => $type,
                             list  => $aref,
                           );

if ( $action eq "drop" ){
    $sql = $obj->drop;
}
elsif ( $action eq "create" ){
    $sql = $obj->create;
}
elsif ( $action eq "resize" ){
    $sql = $obj->resize;
}
elsif ( $action eq "compile" ){
    $sql = $obj->compile;
}
elsif ( $action eq "show_space" ){
    $sql = $obj->show_space;
}
else{
    die "\nDon't know how to '$action'.\n";
} ;

print $sql;

# $Log: query.pl,v $
# Revision 1.4  2001/03/31 18:28:34  rvsutherland
# Facilitated new method 'show_space'.
#
# Revision 1.3  2001/01/27 16:21:44  rvsutherland
# Added NAME section to pod.
#
# Revision 1.2  2001/01/14 16:47:55  rvsutherland
# Nominal changes for version 0.32
#
# Revision 1.1  2001/01/07 16:42:45  rvsutherland
# Initial Revision
#

=head1 NAME

query.pl - Generates DDL for a specified list of objects.

=head1 DESCRIPTION

Uses DDL::Oracle to generate the DDL for a query provided in a file.
The query should select owner, name for a list of objects of the same
type (e.g., TABLE, INDEX, TABLESPACE, etc.).  The FROM and WHERE clauses
may be anything of the user's choice.

For example, the file might contain:

   SELECT
          owner
        , table_name
   FROM
          dba_tables
   WHERE
          tablespace_name = 'MY_TBLSP'    -- your mileage may vary

The file may contain SQL*Plus's traditional '/', and/or may contain a ';'

=head1 AUTHOR

 Richard V. Sutherland
 rvsutherland@yahoo.com

=head1 COPYRIGHT

Copyright (c) 2000, 2001 Richard V. Sutherland.  All rights reserved.
This module is free software.  It may be used, redistributed, and/or
modified under the same terms as Perl itself.  See:

    http://www.perl.com/perl/misc/Artistic.html

=cut

