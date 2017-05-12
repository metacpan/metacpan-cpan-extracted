use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
BEGIN {
    use_ok( 'Data::FormValidator::Profile' );
}

###############################################################################
# Optional field
add_optional_field: {
    my $profile = Data::FormValidator::Profile->new();
    isa_ok $profile, 'Data::FormValidator::Profile';

    $profile->add( 'username' );
    my $results = $profile->profile();
    my $expect  = {
        optional    => [qw(username)],
        };
    is_deeply $results, $expect, 'added optional field';
}

###############################################################################
# Required field
add_required_field: {
    my $profile = Data::FormValidator::Profile->new();
    isa_ok $profile, 'Data::FormValidator::Profile';

    $profile->add( 'username',
        required => 1,
        );
    my $results = $profile->profile();
    my $expect  = {
        required    => [qw(username)],
        };
    is_deeply $results, $expect, 'added required field';
}

###############################################################################
# Existing field; should choke
add_existing_field: {
    my $profile = Data::FormValidator::Profile->new( required=>'username' );
    isa_ok $profile, 'Data::FormValidator::Profile';

    dies_ok { $profile->add('username') } 'chokes on existing field';
}

###############################################################################
# Default value
add_with_default_value: {
    my $profile = Data::FormValidator::Profile->new();
    isa_ok $profile, 'Data::FormValidator::Profile';

    $profile->add( 'action',
        default => 'cancel',
        );
    my $results = $profile->profile();
    my $expect  = {
        optional    => [qw(action)],
        defaults    => {
            action  => 'cancel',
            },
        };
    is_deeply $results, $expect, 'added with default value';
}

###############################################################################
# Dependencies
add_with_dependencies: {
    my $profile = Data::FormValidator::Profile->new();
    isa_ok $profile, 'Data::FormValidator::Profile';

    $profile->add( 'cc_no',
        dependencies => [qw(cc_exp_mon cc_exp_yr)],
        );
    my $results = $profile->profile();
    my $expect  = {
        optional        => [qw(cc_no)],
        dependencies    => {
            cc_no       => [qw(cc_exp_mon cc_exp_yr)],
            },
        };
    is_deeply $results, $expect, 'added with dependencies';
}

###############################################################################
# Filters
add_with_filter: {
    my $profile = Data::FormValidator::Profile->new();
    isa_ok $profile, 'Data::FormValidator::Profile';

    $profile->add( 'email',
        filters => [qw(trim lc email)],
        );
    my $results = $profile->profile();
    my $expect  = {
        optional        => [qw(email)],
        field_filters   => {
            email       => [qw(trim lc email)],
            },
        };
    is_deeply $results, $expect, 'added with field_filter';
}

###############################################################################
# Constraint methods
add_with_constraint_methods: {
    my $profile = Data::FormValidator::Profile->new();
    isa_ok $profile, 'Data::FormValidator::Profile';

    my $constraint = sub { 'foo' };
    $profile->add( 'email',
        constraints => $constraint,
        );
    my $results = $profile->profile();
    my $expect  = {
        optional    => [qw(email)],
        constraint_methods => {
            email   => $constraint,
            },
        };
    is_deeply $results, $expect, 'added with constraint_methods';
}

###############################################################################
# Constraint messages
add_with_constraint_messages: {
    my $profile = Data::FormValidator::Profile->new();
    isa_ok $profile, 'Data::FormValidator::Profile';

    my $constraint = sub { 'foo' };
    $profile->add( 'email',
        constraints => $constraint,
        msgs => {
            length_max => 'too big',
            },
        );
    my $results = $profile->profile();
    my $expect  = {
        optional    => [qw(email)],
        constraint_methods => {
            email   => $constraint,
            },
        msgs => {
            constraints => {
                length_max => 'too big',
                },
            },
        };
    is_deeply $results, $expect, 'added with constraint messages';
}

###############################################################################
# Complex add
complex_add: {
    my $profile = Data::FormValidator::Profile->new();
    isa_ok $profile, 'Data::FormValidator::Profile';

    my $filter     = sub { 'filter' };
    my $constraint = sub { 'constraint' };
    $profile->add( 'image',
        required    => 1,
        filters     => $filter,
        constraints => $constraint,
        msgs => {
            file_max_bytes => "too big",
            },
        );

    my $results = $profile->profile();
    my $expect  = {
        required => [qw(image)],
        field_filters => {
            image => $filter,
            },
        constraint_methods => {
            image => $constraint,
            },
        msgs => {
            constraints => {
                file_max_bytes => "too big",
                },
            },
        };
    is_deeply $results, $expect, 'complex add';
}
