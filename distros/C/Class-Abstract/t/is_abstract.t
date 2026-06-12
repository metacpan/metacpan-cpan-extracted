#!/usr/bin/perl
# t/is_abstract.t -- tests for the is_abstract() utility method.

use strict;
use warnings;

BEGIN { unshift @INC, 'lib' }

use Test::Most;
use Scalar::Util qw(blessed);

my %config = (
	abstract_pkg  => 'IA::AbstractBase',
	concrete_pkg  => 'IA::Concrete',
	grandchild    => 'IA::GrandChild',
	second_abst   => 'IA::SecondAbstract',
);

use Class::Abstract;

{
	package IA::AbstractBase;
	use parent -norequire, 'Class::Abstract';
}

{
	package IA::Concrete;
	our @ISA = ('IA::AbstractBase');
	sub new {
		my ($class) = @_;
		return $class->SUPER::new;
	}
}

{
	package IA::GrandChild;
	our @ISA = ('IA::Concrete');
}

# A second abstract class: explicitly opts in via use parent.
{
	package IA::SecondAbstract;
	use parent -norequire, 'Class::Abstract', 'IA::AbstractBase';
}

diag 'is_abstract() tests' if $ENV{TEST_VERBOSE};

# ---------------------------------------------------------------------------
# is_abstract() on directly abstract classes.
# ---------------------------------------------------------------------------

subtest 'is_abstract() returns 1 for directly abstract classes' => sub {
	plan tests => 3;

	is( IA::AbstractBase->is_abstract, 1,
		'AbstractBase->is_abstract = 1 (use parent form)' );

	is( IA::SecondAbstract->is_abstract, 1,
		'SecondAbstract->is_abstract = 1 (explicit use parent)' );

	is( Class::Abstract->is_abstract, 1,
		'Class::Abstract itself reports is_abstract = 1' );
};

# ---------------------------------------------------------------------------
# is_abstract() on concrete classes.
# ---------------------------------------------------------------------------

subtest 'is_abstract() returns 0 for concrete classes' => sub {
	plan tests => 2;

	is( IA::Concrete->is_abstract, 0,
		'Concrete->is_abstract = 0 (inherits from abstract, not abstract itself)' );

	is( IA::GrandChild->is_abstract, 0,
		'GrandChild->is_abstract = 0 (two levels removed from abstract base)' );
};

# ---------------------------------------------------------------------------
# is_abstract() called on a blessed instance.
# ---------------------------------------------------------------------------

subtest 'is_abstract() on a blessed instance uses ref() for the check' => sub {
	plan tests => 2;

	my $obj = IA::Concrete->new;
	ok blessed($obj), 'IA::Concrete->new returned a blessed ref';

	is( $obj->is_abstract, 0,
		'$concrete_obj->is_abstract = 0 (checks ref($obj) = IA::Concrete)' );
};

# ---------------------------------------------------------------------------
# is_abstract() is inherited via MRO -- can be called on any subclass.
# ---------------------------------------------------------------------------

subtest 'is_abstract() is inherited by all subclasses via MRO' => sub {
	plan tests => 2;

	ok( IA::Concrete->can('is_abstract'),
		'IA::Concrete inherits is_abstract via MRO' );

	ok( IA::GrandChild->can('is_abstract'),
		'IA::GrandChild inherits is_abstract via MRO' );
};

# ---------------------------------------------------------------------------
# isa() vs is_abstract(): isa cannot distinguish direct-abstract.
# ---------------------------------------------------------------------------

subtest 'isa() cannot distinguish direct-abstract vs transitive' => sub {
	plan tests => 3;

	# All three have Class::Abstract in their MRO.
	ok( IA::AbstractBase->isa('Class::Abstract'),
		'AbstractBase->isa(Class::Abstract) = 1 (direct)' );

	ok( IA::Concrete->isa('Class::Abstract'),
		'Concrete->isa(Class::Abstract) = 1 (transitive -- not directly abstract!)' );

	ok( IA::GrandChild->isa('Class::Abstract'),
		'GrandChild->isa(Class::Abstract) = 1 (transitive)' );

	# Use is_abstract() to get the right answer.
};

done_testing;
