#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Spec;
use CGI::Wiki::Simple::Setup;


my ($dbname, $dbtype, $dbuser, $dbpass, $help, $clear, $force_update, $nodeball );
GetOptions( "dbname=s"         => \$dbname,
            "dbtype=s"         => \$dbtype,
            "dbuser:s"         => \$dbuser,
            "dbpass:s"         => \$dbpass,
            "nodeball:s"       => \$nodeball,
            "help"           => \$help,
            "clear"          => \$clear,
            "force"          => \$force_update,
           );

unless (defined($dbname)) {
    print "You must supply a database name with the --name option\n";
    print "further help can be found by typing 'perldoc $0'\n";
    exit 1;
}

if ($help) {
    print "Help can be found by typing 'perldoc $0'\n";
    exit 0;
}

my %dbargs = (
  dbtype => $dbtype,
  dbname => $dbname,
  dbuser => $dbuser,
  dbpass => $dbpass,
);
CGI::Wiki::Simple::Setup::setup( clear => $clear, force => $force_update, %dbargs );

if ($nodeball) {
  my $store = CGI::Wiki::Simple::Setup::get_store(%dbargs);
  print "Loading nodeball '$nodeball'\n";
  CGI::Wiki::Simple::Setup::load_nodeball( store => $store, force => $force_update, %dbargs, file => $nodeball );
};

=head1 NAME

simple-user-setup-sqlite - set up a wiki together with default content

=head1 SYNOPSIS

  # Set up or update the storage backend, leaving any existing data intact.
  # Useful for upgrading from old versions of CGI::Wiki to newer ones with
  # more backend features.

  simple-user-setup-sqlite --name mywiki.db

  # Overwrite the nodes with the default contents

  simple-user-setup-sqlite --name mywiki --clear

  # Clear out any existing data and set up a fresh backend from scratch.

  simple-user-setup-sqlite --name mywiki.db --clear

=head1 DESCRIPTION

Takes one mandatory argument:

=over 4

=item name

The name of the file to store the SQLite database in.  It will be
created if it doesn't already exist.

=back

and up to two optional flags:

=over 4

=item clear

Wipes out all preexisting data within your wiki. This is great
while you are testing and playing around, and fatal unless you
have good backups.

=item force

Overwrites already existing nodes with the content from this
file. This is still great while you are playing around and not
totally fatal, but good backups are still advisable.

=back

=head1 AUTHOR

Max Maischein (corion@cpan.org)

=head1 COPYRIGHT

     Copyright (C) 2003 Max Maischein.  All Rights Reserved.

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Wiki::Simple>

=cut

