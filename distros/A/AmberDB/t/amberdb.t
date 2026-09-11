#!/usr/bin/perl

# t/02-flatdb.t - Tests for AmberDB

use 5.016000;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

# ---------------------------------------------------------------------------
use_ok('AmberDB') or BAIL_OUT('Cannot load AmberDB');

# ---------------------------------------------------------------------------
subtest 'AmberDB - VERSION' => sub {
    plan tests => 1;
    ok( defined $AmberDB::VERSION, 'VERSION is defined' );
};

# ---------------------------------------------------------------------------
subtest 'AmberDB - can() checks' => sub {
    my @expected_methods = qw(
        new insert_id modify_id update_id modify_list update_list delete_id read_id read_all read_list
        table_read table_write table_close
        recs_get recs_put recs_del recs_exist recs_keys recs_scan
        exist_id exist_list
    );
    plan tests => scalar @expected_methods;
    for my $method (@expected_methods) {
        can_ok( 'AmberDB', $method );
    }
};

# ---------------------------------------------------------------------------
subtest 'AmberDB::Base' => sub {
    plan tests => 2;
    use_ok('AmberDB::Base');
    is( $AmberDB::Base::VERSION, $AmberDB::VERSION, 'Base VERSION matches AmberDB VERSION' );
};

subtest 'AmberDB::Array' => sub {
    plan tests => 1;
    use_ok('AmberDB::Array');
};

subtest 'AmberDB::Locale' => sub {
    plan tests => 1;
    use_ok('AmberDB::Locale');
};

subtest 'AmberDB::Base::Schema' => sub {
    plan tests => 1;
    use_ok('AmberDB::Base::Schema');
};

subtest 'AmberDB::Base::Encoder' => sub {
    plan tests => 1;
    use_ok('AmberDB::Base::Encoder');
};

subtest 'AmberDB::Tools' => sub {
    plan tests => 1;
    use_ok('AmberDB::Tools');
};

done_testing();
