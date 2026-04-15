#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 'lib';

# Test required attributes
{
    package Test::Required;
    use Class::More;

    has name => (required => 1);
    has age  => (required => 1);
    has optional => ();
}

# Test required attributes enforcement
throws_ok { Test::Required->new() }
    qr/Required attribute .* not provided/,  # More flexible regex
    'Missing required attribute throws error';

# Test that we get an error when only one required attribute is provided
throws_ok { Test::Required->new(name => 'John') }
    qr/Required attribute .* not provided/,
    'Missing second required attribute throws error';

throws_ok { Test::Required->new(age => 25) }
    qr/Required attribute .* not provided/,
    'Missing first required attribute throws error';

lives_ok { Test::Required->new(name => 'John', age => 25) }
    'All required attributes provided';

my $required = Test::Required->new(name => 'John', age => 25);
is($required->name, 'John', 'Required attribute name set correctly');
is($required->age, 25, 'Required attribute age set correctly');

# Optional attributes DO get accessors
ok($required->can('optional'), 'Optional attribute has accessor');
is($required->optional, undef, 'Optional attribute is undef by default');

# Test default values
{
    package Test::Default;
    use Class::More;

    has name => (default => 'Unknown');
    has age  => (default => 18);
    has active => (default => 1);
}

my $default = Test::Default->new();
is($default->name, 'Unknown', 'String default works');
is($default->age, 18, 'Numeric default works');
is($default->active, 1, 'Boolean default works');

my $default_override = Test::Default->new(name => 'Known', age => 30);
is($default_override->name, 'Known', 'Default can be overridden');
is($default_override->age, 30, 'Numeric default can be overridden');

# Test default coderef
{
    package Test::DefaultCode;
    use Class::More;

    has timestamp => (default => sub { time });
    has computed => (default => sub {
        my ($self, $attrs) = @_;
        return ($attrs->{base} || 0) + 10;
    });
}

my $default_code = Test::DefaultCode->new();
ok($default_code->timestamp > 0, 'Coderef default works');
is($default_code->computed, 10, 'Coderef with constructor args works');

my $default_code_args = Test::DefaultCode->new(base => 5);
is($default_code_args->computed, 15, 'Coderef uses constructor args correctly');

done_testing;
