#!perl

use strict;
use warnings;
use Test::More qw(no_plan);

our $pkg = 'DBIx::Migration::Directories::ConfigData';

use_ok($pkg);

ok($pkg->config('schema_dir'), 'config() method works');
ok(defined $pkg->feature('Pg'), 'feature() method works');
ok(
    $pkg->set_config('schema_dir', $pkg->config('schema_dir')),
    'set_config() method works'
);
ok(
    defined $pkg->set_feature('Pg', $pkg->feature('Pg')),
    'set_feature() method works'
);

is_deeply(
    [$pkg->config_names],
    ['schema_dir'],
    'config_names are correct'
);

is_deeply(
    [sort $pkg->feature_names],
    [qw(Pg SQLite2 mysql)],
    'feature_names are correct'
);

ok($pkg->write, 'write() method works');
