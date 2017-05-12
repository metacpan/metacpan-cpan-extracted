#!/usr/bin/env perl
use Modern::Perl '2012';
use FindBin qw($Bin);
use lib "$Bin/../lib";
use <% dist_module %>::Schema;
use <% dist_module %>::Util::Primer qw(prime_database);
my $schema = <% dist_module %>::Schema->connect("dbi:SQLite:dbname=$Bin/../<% dist_file %>.db")
  or die "Unable to connect\n";
say "Enter 'Y' to deploy the schema. This will delete all data in <% dist_file %>.db";
chomp(my $ui = <>);
die "Schema deployment aborted.\n" unless $ui eq 'Y';

# Specify the DB version in producer_args that are passed to
# SQL::Translator::Producer::* so they know that it's ok to generate
# "DROP TABLE IF EXISTS" instead of just "DROP TABLE", which would
# produce errors.

$schema->deploy(
    {   add_drop_table => 1,
        producer_args  => { postgres_version => '9.2', sqlite_version => '3.7' }
    }
);
prime_database($schema);
