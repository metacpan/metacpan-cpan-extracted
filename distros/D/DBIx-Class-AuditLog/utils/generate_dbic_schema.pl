#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Class::Schema::Loader qw< make_schema_at >;

$| = 1;

make_schema_at(
    'AuditTest::Schema',
    {
        debug           => 1,
        dump_directory  => '../lib/',
        qualify_objects => 1,
        
    },
    [   'DBI:mysql:dbname=audit_test;host=localhost;port=3306',
        'root',
        'Pa55..',
        { RaiseError => 1, PrintError => 0 },
    ]
);

1;
