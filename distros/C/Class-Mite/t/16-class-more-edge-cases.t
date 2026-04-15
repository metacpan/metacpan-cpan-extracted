#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

# Test 1: Complex default sub that uses other attributes
{
    package Test::ComplexDefault;
    use Class::More;

    has first_name => (required => 1);
    has last_name  => (required => 1);
    has full_name  => (default => sub {
        my ($self) = @_;
        return $self->first_name . ' ' . $self->last_name;
    });
}

my $complex = Test::ComplexDefault->new(
    first_name => 'John',
    last_name  => 'Doe'
);
is($complex->full_name, 'John Doe', 'Complex default sub works');

# Test 2: Default sub with constructor arguments
{
    package Test::DefaultWithArgs;
    use Class::More;

    has base => (default => 0);
    has doubled => (default => sub {
        my ($self, $attrs) = @_;
        return ($attrs->{base} || 0) * 2;
    });
}

my $with_args = Test::DefaultWithArgs->new(base => 5);
is($with_args->doubled, 10, 'Default sub with constructor args');

# Test 3: Boolean attributes
{
    package Test::Boolean;
    use Class::More;

    has is_active => (default => 1);
    has is_admin  => (default => 0);
}

my $bool = Test::Boolean->new();
is($bool->is_active, 1, 'Boolean true default');
is($bool->is_admin, 0, 'Boolean false default');

# Test 4: Undefined and empty defaults
{
    package Test::Undefined;
    use Class::More;

    has undef_attr => (default => undef);
    has empty_attr  => (default => '');
    has zero_attr   => (default => 0);
}

my $undef = Test::Undefined->new();
ok(!defined $undef->undef_attr, 'Undefined default works');
is($undef->empty_attr, '', 'Empty string default works');
is($undef->zero_attr, 0, 'Zero default works');

# Test 5: Chained defaults
{
    package Test::Chained;
    use Class::More;

    has counter => (default => sub { 0 });

    has next_counter => (default => sub {
        my ($self) = @_;
        return ($self->counter // 0) + 1;
    });
}

my $chained = Test::Chained->new();
is($chained->counter, 0, 'Chained default - counter');
is($chained->next_counter, 1, 'Chained default - next_counter');

done_testing;
