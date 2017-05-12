#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use DBIx::Simple::Class::Schema;

GetOptions(
  'h|?|help'        => \my $help,
  'n|namespace=s' => \my $namespace,
  'o|overwrite=i' => \my $overwrite,
  'd|dsn=s'         => \my $dsn,
  'u|user=s'        => \my $user,
  'p|password=s'    => \my $password,
  'l|lib_root=s'       => \my $lib,
  't|table=s' =>\my $table,
);
pod2usage(verbose=>2) if $help;
pod2usage(1) unless $dsn;

DBIx::Simple::Class::Schema->dbix(DBIx::Simple->connect($dsn, $user, $password));
DBIx::Simple::Class::Schema->load_schema(
  namespace => $namespace // do {
    my ($schema) = DBI->parse_dsn($dsn)
      || die("Can't parse DBI DSN! dsn=>'$dsn'");
    my ($schema_name) = $schema =~ m|=\W?(\w+)|x;

    #return of the do
    join '', map { ucfirst lc } split /_/, $schema_name;
  },
  table => $table||'%',         # $table or '%' - all tables from the current database
  type  => "'TABLE','VIEW'",    # make classes for tables and views
);

DBIx::Simple::Class::Schema->dump_schema_at(
  lib_root  => $lib       // './',
  overwrite => $overwrite // 0       #overwrite existing files?
) || die('Something went wrong! See above...');

=pod

=encoding UTF-8

=head1 NAME

dsc_dump_schema.pl - script to dump a schema from a database

=head1 SYNOPSIS

  #dump all tables
  dsc_dump_schema.pl --dsn DBI:mysql:database=mydb;host=127.0.0.1;mysql_enable_utf8=1 \
  -u me -p mypassword --overwrite 1 --lib_root ./lib

  #dump only the "users" table - using short options and choosing a namespace
  dsc_dump_schema.pl -dsn dbi:SQLite:database=etc/ado.sqlite -n Ado::Model -l lib -t users
  
  dsc_dump_schema.pl -? #for more help
  
=head1 DESCRIPTION

This is a helper script to dump L<DBIx::Simple::Class> based classes from
an existing database. Currently it is known to work with mysql and SQLite databases.

You can then edit those classes, add methods and customise the checks for the accepted 
table fields in each of the dumped classes. You can also use these classes ASIS to 
access and update table rows in an object oriented fashion.

=head1 OPTIONS

=head2 --help|-h|? 

More verbose help screen

=head2 --dsn|-d

The connection string you would pass to C<DBI-E<gt>connect()> 
when connecting to your database.

=head2 --user|-u

Username for the database.

  --username myuser@somehost

=head2 --password|-p

  --password mysecret

Password for the database.

=head2 --namespace|-n

Base class namespace used for your schema. Optional.
If not passed it will be guessed from the schema name:

  my_dbname -> MyDbname

  --namespace MyModel

=head2 --overwrite|-o

If there are alreday dumped classed to the desired location on the
filesystem they will be ovwerwritten.

  --overwrite 1

=head2 --lib_root|-l

Directory path in which the classes will be dumped. The directory must exist.
It will not be created.

=head2 --table|-t

This option allows you to specify a table name. In some cases after modifying 
some table you may need to dump a class only for this table.
B<Note! When a table is specified the base (schema) class is not generated!>

  #only table users
  -t users

  #all tables starting with "shop"
  -t shop%

=head1 SEE ALSO

L<DBIx::Simple::Class>, L<DBIx::Simple>, 
L<DBIx::Simple::Class::Schema>,
L<Mojolicious::Plugin::DSC>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Красимир Беров (Krasimir Berov).

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

See http://www.opensource.org/licenses/artistic-license-2.0 for more information.

=cut
