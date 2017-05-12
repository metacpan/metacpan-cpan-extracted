#! /usr/bin/perl -w

# $Id: Ddl.pl,v 1.13 2001/04/28 13:50:25 rvsutherland Exp $

use strict;

use DBI;
use DDL::Oracle;
use English;

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
                        dbh      => $dbh,
                        resize   => 1,
#                        view     => 'user',
#                        heading  => 0,
#                        prompt   => 0,
                      );

my $user = getlogin
        || scalar getpwuid($REAL_USER_ID)
        || undef;

print STDERR "Enter Action [CREATE]: ";
chomp( my $action = <STDIN> );
$action = "create" unless $action;

print STDERR "Enter Type    [TABLE]: ";
chomp( my $type = <STDIN> );
$type = "TABLE" unless $type;

print STDERR "Enter Owner [\U$user]: ";
chomp( my $owner = <STDIN> );
$owner = $user unless $owner;
die "\nYou must specify an Owner.\n" unless $owner;

print STDERR "Enter Name           : ";
chomp( my $name = <STDIN> );
die "\nYou must specify an object.\n"
   unless (
                $name
             or "\U$type" eq 'COMPONENTS'
             or "\U$type" eq 'SCHEMA'
          );

print STDERR "\n";

my $obj = DDL::Oracle->new(
                            type  => $type,
                            list  => [
                                       [
                                         $owner,
                                         $name,
                                       ]
                                     ]
                          );

my $sql;

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
    die "\n$0 doesn't know how to '$action'.\n";
} ;

print $sql;

# $Log: Ddl.pl,v $
# Revision 1.13  2001/04/28 13:50:25  rvsutherland
# Modified to facilitate the new type 'schema'.
#
# Revision 1.12  2001/03/31 18:27:42  rvsutherland
# Facilitated new object type 'components', which requires neither
# name nor owner.
#
# Revision 1.11  2001/03/20 01:49:51  rvsutherland
# Facilitated instance method 'show_space'
#
# Revision 1.10  2001/03/03 18:41:31  rvsutherland
# Added DESCRIPTION to pod.
#
# Revision 1.9  2001/01/27 16:21:44  rvsutherland
# Added NAME section to pod.
#
# Revision 1.8  2001/01/14 16:47:55  rvsutherland
# Nominal changes for version 0.32
#
# Revision 1.7  2001/01/07 16:43:56  rvsutherland
# Added COPYRIGHT
#
# Revision 1.6  2001/01/06 16:21:15  rvsutherland
# Facilitated 'compile' method
#
# Revision 1.5  2000/12/09 17:55:20  rvsutherland
# Re-added after CVS bug fixed.
#
# Revision 1.3  2000/11/11 07:48:59  rvsutherland
# Added CVS tags
#

=head1 NAME

ddl.pl - Generates DDL for a single, named object

=head1 DESCRIPTION

Calls DDL::Oracle for the DDL of a specified object.

=head1 AUTHOR

 Richard V. Sutherland
 rvsutherland@yahoo.com

=head1 COPYRIGHT

Copyright (c) 2000, 2001 Richard V. Sutherland.  All rights reserved.
This module is free software.  It may be used, redistributed, and/or
modified under the same terms as Perl itself.  See:

    http://www.perl.com/perl/misc/Artistic.html

=cut

