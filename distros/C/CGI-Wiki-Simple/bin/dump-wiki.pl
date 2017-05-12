#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Spec;
use CGI::Wiki::Simple::Setup;


my ($dbname, $dbtype, $dbuser, $dbpass, $help, $clear, $force_update );
GetOptions( "dbname=s"         => \$dbname,
		        "dbtype=s"				 => \$dbtype,
		        "dbuser:s"				 => \$dbuser,
		        "dbpass:s"				 => \$dbpass,
            "help"           => \$help,
           );

unless (defined($dbtype)) {
    print "You must supply a database type with the --dbtype option\n";
    print "further help can be found by typing 'perldoc $0'\n";
    exit 1;
}

unless (defined($dbname)) {
    print "You must supply a database name with the --dbname option\n";
    print "further help can be found by typing 'perldoc $0'\n";
    exit 1;
}

if ($help) {
    print "Help can be found by typing 'perldoc $0'\n";
    exit 0;
}

my %dbargs = ( dbname => $dbname, dbtype => $dbtype, dbuser => $dbuser, dbpass => $dbpass );
my $store = CGI::Wiki::Simple::Setup::get_store(setup => 0, clear => 0, nocontent => 1, silent => 1, %dbargs );
my @nodes = $store->list_all_nodes();
my $node;
for $node (@nodes) {
  print "__NODE__\n";
  print "Title: ", $node,"\n";
  my %node = $store->retrieve_node($node);
  print $node{content};
  print "\n" unless $node{content} =~ m!\n$!;
};

=head1 NAME

dump-wiki - dump a wiki to STDOUT

=head1 SYNOPSIS

  # dump a SQLite wiki

  dump-wiki --dbtype sqlite --dbname mywiki.db

  # dump a MySQL wiki into the file wiki.txt

  dump-wiki --dbtype mysql --dbname mywiki --dbuser wiki --dbpass secret >wiki.txt

=head1 DESCRIPTION

Takes two mandatory arguments:

=over 4

=item dbtype

The type of the database. Possible values are C<pg> (for Postgres),
C<mysql> for MySQL and C<sqlite> for SQLite.

=item dbname

The name of the file to store the SQLite database in.  It will be
created if it doesn't already exist.

=back

and up to two optional parameters:

=over 4

=item dbuser

The username for the database.

=item dbpass

The password for the database.

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

