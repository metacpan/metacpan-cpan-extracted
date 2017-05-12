#! /usr/bin/perl -w

# $Id: copy_user.pl,v 1.8 2001/04/28 13:49:32 rvsutherland Exp $

use strict;

use DBI;
use DDL::Oracle;

my $obj;
my $ddl;
my $old_sql;
my $new_sql;
my $old_user;
my $new_user;
my @users;

# This is a simple connection.  Modify it to suit your needs.
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
                      );

# Printing prompts to STDERR allows the output to be
# redirected to a file (a good idea, eh?) and still
# allows the user to see the prompts.

print STDERR "\nEnter Name of Existing User (the Template) : ";
chomp( $old_user = lc( <STDIN> ) );
die "\nYou must specify an Existing User.\n" unless $old_user;
print STDERR "\n";

$obj = DDL::Oracle->new(
                         type  => 'user',
                         list  => [
                                    [
                                      'n/a',
                                      $old_user,
                                    ]
                                  ]
                       );

$old_sql = $obj->create;   # Will FAIL unless $old_user exists!

while (1)
{
  print STDERR "Enter Name of New User or <ENTER> when done: ";
  chomp( $new_user = lc( <STDIN> ) );
  last unless $new_user;
  push @users, $new_user;
}
die "\nYou must specify at least one New User\n\n" unless @users;
print STDERR "\n";

foreach $new_user( @users )
{
  $new_sql = $old_sql;
  $new_sql =~ s/$old_user/$new_user/go;
  $new_sql =~ s/REM.*\n//go;

  {
    # If $old_user is a Passworded Account 
    # and if there is an arbitrary method of assigning
    # passwords to new users, this is a good place to
    # substitute the new password for the VALUES 'ABCDEF...'.

    # For example:
    my $password = $new_user;
    $new_sql =~ s/VALUES \S+/$password/go;
  }

  $ddl .= $new_sql;
}

print $ddl;

# $Log: copy_user.pl,v $
# Revision 1.8  2001/04/28 13:49:32  rvsutherland
# Changed password to be the new username.
#
# Revision 1.7  2001/03/03 18:41:31  rvsutherland
# Added DESCRIPTION to pod.
#
# Revision 1.6  2001/01/27 16:21:44  rvsutherland
# Added NAME section to pod.
#
# Revision 1.5  2001/01/14 16:47:55  rvsutherland
# Nominal changes for version 0.32
#
# Revision 1.4  2001/01/07 16:43:56  rvsutherland
# Added COPYRIGHT
#
# Revision 1.3  2000/11/11 07:48:59  rvsutherland
# Added CVS tags
#
# Revision 1.2  2000/11/11 00:20:42  rvsutherland
# Initial revision
#

=head1 NAME

copy_user.pl - Generates CREATE USER command(s)

=head1 DESCRIPTION

Generates the DDL to create a new user(s) with the identical privileges
of a named, existing user in the same database.

=head1 AUTHOR

 Richard V. Sutherland
 rvsutherland@yahoo.com

=head1 COPYRIGHT

Copyright (c) 2000, 2001 Richard V. Sutherland.  All rights reserved.
This module is free software.  It may be used, redistributed, and/or
modified under the same terms as Perl itself.  See:

    http://www.perl.com/perl/misc/Artistic.html

=cut

