#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 'lib';

# Test 1: Basic has functionality
{
    package ComprehensiveTest::Basic;
    use Class::More;

    has name => ();
    has age  => ();

    sub BUILD {
        my ($self) = @_;
        $self->{initialized} = 1;
    }
}

my $basic = ComprehensiveTest::Basic->new(name => 'Alice', age => 25);
is($basic->name, 'Alice', 'Basic attribute accessor works');
is($basic->age, 25, 'Second attribute works');
is($basic->{initialized}, 1, 'BUILD method called');

# Test 2: Required attributes
{
    package ComprehensiveTest::Required;
    use Class::More;

    has name => (required => 1);
    has optional => ();
}

throws_ok { ComprehensiveTest::Required->new() } qr/Required attribute 'name' not provided/,
    'Required attribute throws error when missing';

lives_ok { ComprehensiveTest::Required->new(name => 'Bob') }
    'Required attribute works when provided';

my $required = ComprehensiveTest::Required->new(name => 'Bob');
is($required->name, 'Bob', 'Required attribute set correctly');

# Test 3: Default values
{
    package ComprehensiveTest::Default;
    use Class::More;

    has name => (default => 'Unknown');
    has count => (default => 0);
}

my $default = ComprehensiveTest::Default->new();
is($default->name, 'Unknown', 'String default works');
is($default->count, 0, 'Numeric default works');

my $default_override = ComprehensiveTest::Default->new(name => 'Known');
is($default_override->name, 'Known', 'Default can be overridden');

# Test 4: Default coderef
{
    package ComprehensiveTest::DefaultSub;
    use Class::More;

    has timestamp => (default => sub { time });
    has computed => (default => sub {
        my ($self, $attrs) = @_;
        return ($attrs->{base} || 0) + 10;
    });
}

my $default_sub = ComprehensiveTest::DefaultSub->new();
ok($default_sub->timestamp > 0, 'Coderef default works');
is($default_sub->computed, 10, 'Coderef with no args works');

my $default_sub_args = ComprehensiveTest::DefaultSub->new(base => 5);
is($default_sub_args->computed, 15, 'Coderef with args works');

# Test 5: Inheritance with attributes
{
    package ComprehensiveTest::Parent;
    use Class::More;

    has parent_attr => (default => 'parent');

    sub parent_method { 'from_parent' }
}

{
    package ComprehensiveTest::Child;
    use Class::More;
    extends 'ComprehensiveTest::Parent';

    has child_attr => (default => 'child');
}

my $child = ComprehensiveTest::Child->new();
is($child->parent_attr, 'parent', 'Inherited attribute works');
is($child->child_attr, 'child', 'Child attribute works');
is($child->parent_method, 'from_parent', 'Inherited method works');

# Test 6: Mixed required and default
{
    package ComprehensiveTest::Mixed;
    use Class::More;

    has required_attr => (required => 1);
    has default_attr  => (default => 'default_value');
    has optional_attr => ();
}

throws_ok { ComprehensiveTest::Mixed->new(default_attr => 'test') }
    qr/Required attribute 'required_attr' not provided/,
    'Required still enforced with defaults';

my $mixed = ComprehensiveTest::Mixed->new(required_attr => 'provided');
is($mixed->required_attr, 'provided', 'Required attribute set');
is($mixed->default_attr, 'default_value', 'Default attribute set');
ok(!exists $mixed->{optional_attr}, 'Optional attribute not set');

# Test 7: Accessor methods
{
    package ComprehensiveTest::Accessor;
    use Class::More;

    has value => ();
}

my $accessor = ComprehensiveTest::Accessor->new(value => 'initial');
is($accessor->value, 'initial', 'Getter works');

$accessor->value('modified');
is($accessor->value, 'modified', 'Setter works');

# Test 8: BUILD order with inheritance
{
    package ComprehensiveTest::BuildA;
    use Class::More;

    has value => (default => '');

    sub BUILD {
        my ($self) = @_;
        $self->{value} .= 'A';
    }
}

{
    package ComprehensiveTest::BuildB;
    use Class::More;
    extends 'ComprehensiveTest::BuildA';

    sub BUILD {
        my ($self) = @_;
        $self->{value} .= 'B';
    }
}

{
    package ComprehensiveTest::BuildC;
    use Class::More;
    extends 'ComprehensiveTest::BuildB';

    sub BUILD {
        my ($self) = @_;
        $self->{value} .= 'C';
    }
}

my $build_test = ComprehensiveTest::BuildC->new();
is($build_test->{value}, 'ABC', 'BUILD methods called in correct order (parent-first)');

# Test 9: Multiple inheritance with attributes
{
    package ComprehensiveTest::Multi1;
    use Class::More;

    has multi1 => (default => 'from_multi1');
}

{
    package ComprehensiveTest::Multi2;
    use Class::More;

    has multi2 => (default => 'from_multi2');
}

{
    package ComprehensiveTest::MultiChild;
    use Class::More;
    extends qw(ComprehensiveTest::Multi1 ComprehensiveTest::Multi2);

    has child_attr => (default => 'child');
}

my $multi = ComprehensiveTest::MultiChild->new();
is($multi->multi1, 'from_multi1', 'Multiple inheritance attr 1');
is($multi->multi2, 'from_multi2', 'Multiple inheritance attr 2');
is($multi->child_attr, 'child', 'Multiple inheritance child attr');

# Test 10: Complex default sub that uses other attributes
{
    package ComprehensiveTest::ComplexDefault;
    use Class::More;

    has first_name => (required => 1);
    has last_name  => (required => 1);
    has full_name  => (default => sub {
        my ($self) = @_;
        return $self->first_name . ' ' . $self->last_name;
    });
}

my $complex = ComprehensiveTest::ComplexDefault->new(
    first_name => 'John',
    last_name  => 'Doe'
);
is($complex->full_name, 'John Doe', 'Complex default sub works');

# Test 11: Default sub with constructor arguments
{
    package ComprehensiveTest::DefaultWithArgs;
    use Class::More;

    has base => (default => 0);
    has doubled => (default => sub {
        my ($self, $attrs) = @_;
        return ($attrs->{base} || 0) * 2;
    });
}

my $with_args = ComprehensiveTest::DefaultWithArgs->new(base => 5);
is($with_args->doubled, 10, 'Default sub with constructor args');

# Test 12: Boolean attributes
{
    package ComprehensiveTest::Boolean;
    use Class::More;

    has is_active => (default => 1);
    has is_admin  => (default => 0);
}

my $bool = ComprehensiveTest::Boolean->new();
is($bool->is_active, 1, 'Boolean true default');
is($bool->is_admin, 0, 'Boolean false default');

# Test 13: Undefined and empty defaults
{
    package ComprehensiveTest::Undefined;
    use Class::More;

    has undef_attr => (default => undef);
    has empty_attr  => (default => '');
    has zero_attr   => (default => 0);
}

my $undef = ComprehensiveTest::Undefined->new();
ok(!defined $undef->undef_attr, 'Undefined default works');
is($undef->empty_attr, '', 'Empty string default works');
is($undef->zero_attr, 0, 'Zero default works');

# Test 14: Chained defaults
{
    package ComprehensiveTest::Chained;
    use Class::More;

    has counter => (default => sub { 0 });

    has next_counter => (default => sub {
        my ($self, $attrs) = @_;
        # Use the counter value from attributes if available, otherwise from the object or default to 0
        my $current_counter = exists $attrs->{counter} ? $attrs->{counter} :
                             (defined $self->{counter} ? $self->{counter} : 0);
        return $current_counter + 1;
    });
}

my $chained = ComprehensiveTest::Chained->new();
is($chained->counter, 0, 'Chained default - counter');
is($chained->next_counter, 1, 'Chained default - next_counter');

done_testing;
