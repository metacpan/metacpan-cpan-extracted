#!/usr/bin/env perl
# Detect schema drift and emit the alter table statements to fix it.
# Fetch the live table DDL with show create table, parse it, diff the
# columns against the schema the application expects, and turn the
# diff into alter statements - drops, modifies, adds, in that order.
#
# This prints the migration SQL; it does not apply it (review first).
#
# Usage:
#     perl eg/schema_migrate.pl --host=db --port=8123 --table=events

use strict;
use warnings;
use Getopt::Long;
use HTTP::Tiny;
use ClickHouse::Encoder;

my ($host, $port, $table) = ('127.0.0.1', 8123, 'events');
GetOptions('host=s' => \$host, 'port=i' => \$port, 'table=s' => \$table)
    or die "bad options\n";

# The schema the application currently expects.
my @desired = (
    ['id',      'UInt64'],
    ['name',    'LowCardinality(String)'],
    ['ts',      'DateTime'],
    ['payload', 'String'],
);

# Fetch the live table definition. show create table over the HTTP
# interface returns the DDL as a single TabSeparated field, so the
# embedded newlines arrive backslash-escaped - unescape them before
# handing the text to parse_create_table.
my $query = "show create table $table";
$query    =~ s/([^A-Za-z0-9_.~-])/sprintf('%%%02X', ord $1)/ge;
my $resp  = HTTP::Tiny->new(timeout => 10)
    ->get("http://$host:$port/?query=$query");
die "show create failed (status $resp->{status}): $resp->{content}\n"
    unless $resp->{success};
(my $ddl = $resp->{content}) =~ s/\\n/\n/g;
$ddl =~ s/\\t/\t/g;

my $live = ClickHouse::Encoder->parse_create_table($ddl);
print "live table: $live->{table} (engine ", $live->{engine} // '?', ")\n";

# Diff live vs. desired, then render the migration.
my $diff  = ClickHouse::Encoder->schema_diff($live->{columns}, \@desired);
my $stmts = ClickHouse::Encoder->apply_schema_diff($diff, table => $table);

if (@$stmts) {
    print "-- migration for $table --\n";
    print "$_;\n" for @$stmts;
} else {
    print "schema is up to date - no migration needed\n";
}
