use strict;
use warnings;
use Test::More;

use Data::Path::XS ':keywords';

# Round-trip tests
subtest 'round-trip: set then get' => sub {
    my $data = {};

    pathset $data, "/a/b/c", 'value';
    my $v = pathget $data, "/a/b/c";
    is($v, 'value', 'get returns what was set');

    pathset $data, "/users/0/name", 'Alice';
    my $name = pathget $data, "/users/0/name";
    is($name, 'Alice', 'mixed hash/array round-trip');
};

# Set, get, delete cycle
subtest 'set, get, delete cycle' => sub {
    my $data = {};

    pathset $data, "/config/debug", 1;
    is((pathget $data, "/config/debug"), 1, 'get after set');

    my $del = pathdelete $data, "/config/debug";
    is($del, 1, 'delete returns value');

    my $v = pathget $data, "/config/debug";
    is($v, undef, 'get after delete returns undef');
};

# Multiple operations
subtest 'multiple operations' => sub {
    my $data = {};

    # Build structure
    pathset $data, "/users/0/name", 'Alice';
    pathset $data, "/users/0/email", 'alice@test.com';
    pathset $data, "/users/1/name", 'Bob';
    pathset $data, "/users/1/email", 'bob@test.com';
    pathset $data, "/config/version", '1.0';

    # Verify
    is((pathget $data, "/users/0/name"), 'Alice', 'first user name');
    is((pathget $data, "/users/1/email"), 'bob@test.com', 'second user email');
    is((pathget $data, "/config/version"), '1.0', 'config value');

    # Modify
    pathset $data, "/users/0/name", 'Alicia';
    is((pathget $data, "/users/0/name"), 'Alicia', 'updated value');

    # Delete
    pathdelete $data, "/users/1";
    is((pathget $data, "/users/1"), undef, 'deleted user');
    is((pathget $data, "/users/0/name"), 'Alicia', 'other user preserved');
};

# Dynamic path operations
subtest 'dynamic path operations' => sub {
    my $data = {};

    for my $i (0..2) {
        my $path = "/items/$i";
        pathset $data, $path, $i * 10;
    }

    for my $i (0..2) {
        my $path = "/items/$i";
        my $v = pathget $data, $path;
        is($v, $i * 10, "dynamic get index $i");
    }

    my $del_path = "/items/1";
    my $del = pathdelete $data, $del_path;
    is($del, 10, 'dynamic delete');
};

# Constant vs dynamic paths produce same results
subtest 'constant vs dynamic equivalence' => sub {
    my $const_data = {};
    my $dyn_data = {};

    # Set with constant path
    pathset $const_data, "/a/b/c", 42;

    # Set with dynamic path
    my $path = "/a/b/c";
    pathset $dyn_data, $path, 42;

    is_deeply($const_data, $dyn_data, 'structures are identical');

    # Get
    my $const_v = pathget $const_data, "/a/b/c";
    my $dyn_v = pathget $dyn_data, $path;
    is($const_v, $dyn_v, 'get returns same value');

    # Delete
    my $const_del = pathdelete $const_data, "/a/b/c";
    my $dyn_del = pathdelete $dyn_data, $path;
    is($const_del, $dyn_del, 'delete returns same value');
    is_deeply($const_data, $dyn_data, 'structures still identical after delete');
};

# Complex nested structure
subtest 'complex nested structure' => sub {
    my $data = {};

    # Build a complex structure
    pathset $data, "/company/departments/0/name", 'Engineering';
    pathset $data, "/company/departments/0/employees/0/name", 'Alice';
    pathset $data, "/company/departments/0/employees/0/role", 'Developer';
    pathset $data, "/company/departments/0/employees/1/name", 'Bob';
    pathset $data, "/company/departments/0/employees/1/role", 'Manager';
    pathset $data, "/company/departments/1/name", 'Sales';
    pathset $data, "/company/departments/1/employees/0/name", 'Carol';

    # Verify structure
    is((pathget $data, "/company/departments/0/name"), 'Engineering', 'dept name');
    is((pathget $data, "/company/departments/0/employees/1/role"), 'Manager', 'deep nested');
    is((pathget $data, "/company/departments/1/employees/0/name"), 'Carol', 'second dept employee');

    # Modify deep value
    pathset $data, "/company/departments/0/employees/1/role", 'Senior Manager';
    is((pathget $data, "/company/departments/0/employees/1/role"), 'Senior Manager', 'modified deep');

    # Delete and verify
    pathdelete $data, "/company/departments/0/employees/0";
    is((pathget $data, "/company/departments/0/employees/0"), undef, 'deleted employee');
    is((pathget $data, "/company/departments/0/employees/1/name"), 'Bob', 'other employee preserved');
};

done_testing();
