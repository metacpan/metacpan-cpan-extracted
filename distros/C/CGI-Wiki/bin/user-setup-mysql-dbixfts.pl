#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use CGI::Wiki::Setup::DBIxFTSMySQL;

my ($dbname, $dbuser, $dbpass, $help);
GetOptions("name=s" => \$dbname,
           "user=s" => \$dbuser,
           "pass=s" => \$dbpass,
           "help"   => \$help,);

unless (defined($dbname)) {
    print "You must supply a database name with the --name option\n";
    print "further help can be found by typing 'perldoc $0'\n";
    exit 1;
}

if ($help) {
    print "Help can be found by typing 'perldoc $0'\n";
    exit 0;
}

CGI::Wiki::Setup::DBIxFTSMySQL::setup($dbname, $dbuser, $dbpass);

=head1 NAME

user-setup-mysql-dbixfts - set up a DBIx::FullTextSearch backend for CGI::Wiki

=head1 SYNOPSIS

  user-setup-mysql-dbixfts --name mywiki \
                           --user wiki  \
                           --pass wiki  \

=head1 DESCRIPTION

Takes three arguments:

=over 4

=item name

The database name.

=item user

The user that connects to the database. It must have permission
to create and drop tables in the database.

=item pass

The user's database password.

=back

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2002 Kake Pugh.  All Rights Reserved.

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Wiki>, L<CGI::Wiki::Setup::DBIxFTSMySQL>

=cut

1;
