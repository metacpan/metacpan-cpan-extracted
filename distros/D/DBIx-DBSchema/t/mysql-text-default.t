#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 2;

use_ok 'DBIx::DBSchema::Column';

my $col = DBIx::DBSchema::Column->new({
    name    => 'bar',
    type    => 'text',
    default => "'bat'"
});

my $sql = $col->line("DBI:mysql:test");
diag "Generated: $sql";
unlike $sql, qr/default/i, "column bar doesn't have a default";

