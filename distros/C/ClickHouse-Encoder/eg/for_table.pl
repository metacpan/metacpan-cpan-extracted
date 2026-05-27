#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use Data::Dumper;

# Usage: perl eg/for_table.pl [table_name]
my $table = shift // 'system.numbers';

print "Creating encoder for table: $table\n\n";

my $encoder = ClickHouse::Encoder->for_table($table,
    host     => 'localhost',
    port     => 9000,
    database => 'default',
    # user   => 'default',
    # password => '',
);

print "Detected columns:\n";
for my $col (@{$encoder->columns}) {
    printf "  %-20s %s\n", $col->[0], $col->[1];
}

print "\nEncoder ready for use.\n";
