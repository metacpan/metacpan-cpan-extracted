#!/usr/bin/env perl
# Test: Basic module loading for Concierge::Users

use v5.36;
use Test2::V0;
use File::Temp qw/ tempdir /;

# Test 1: Load main module
use Concierge::Users;
pass('Concierge::Users loaded');

# Test 2: Load Meta module
use Concierge::Users::Meta;
pass('Concierge::Users::Meta loaded');

# Test 3: Load all backend modules
use Concierge::Users::SQLite;
pass('Concierge::Users::SQLite loaded');

use Concierge::Users::File;
pass('Concierge::Users::File loaded');

use Concierge::Users::YAML;
pass('Concierge::Users::YAML loaded');

# Test 4: Check version constants
ok($Concierge::Users::VERSION, 'Concierge::Users has a version');
ok($Concierge::Users::Meta::VERSION, 'Concierge::Users::Meta has a version');

# Test 5: Check inheritance
my @isa = @Concierge::Users::ISA;
is(\@isa, ['Concierge::Users::Meta'], 'Concierge::Users inherits from Concierge::Users::Meta');

# Test 6: Check backend inheritance
my @db_isa = @Concierge::Users::SQLite::ISA;
is(\@db_isa, ['Concierge::Users::Meta'], 'SQLite backend inherits from Meta');

my @file_isa = @Concierge::Users::File::ISA;
is(\@file_isa, ['Concierge::Users::Meta'], 'File backend inherits from Meta');

my @yaml_isa = @Concierge::Users::YAML::ISA;
is(\@yaml_isa, ['Concierge::Users::Meta'], 'YAML backend inherits from Meta');

# Test 7: Check required methods exist in Users
my @users_methods = qw(
    setup
    new
    register_user
    get_user
    update_user
    list_users
    delete_user
);
can_ok('Concierge::Users', $_) for @users_methods;

# Test 8: Check backend methods exist
my @backend_methods = qw(
    configure
    new
    add
    fetch
    update
    list
    delete
    config
);
can_ok('Concierge::Users::SQLite', $_) for @backend_methods;
can_ok('Concierge::Users::File', $_) for @backend_methods;
can_ok('Concierge::Users::YAML', $_) for @backend_methods;

# Test 9: Check Meta methods exist
my @meta_methods = qw(
    init_field_meta
    get_field_definition
    get_field_validator
    get_field_hints
    validate_user_data
    parse_filter_string
    current_date
    current_timestamp
);
can_ok('Concierge::Users::Meta', $_) for @meta_methods;

done_testing();
