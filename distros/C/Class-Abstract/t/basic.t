#!/usr/bin/perl
# t/basic.t -- core enforcement tests for Class::Abstract.
#
# Tests both usage forms (use parent and use Class::Abstract) and verifies
# that direct instantiation of abstract classes croaks while concrete
# subclasses and SUPER::new chains work correctly.

use strict;
use warnings;

BEGIN { unshift @INC, 'lib' }

use Test::Most;
use Readonly;
use Scalar::Util qw(blessed);

# ---------------------------------------------------------------------------
# Configuration -- no magic strings or numbers
# ---------------------------------------------------------------------------

my %config = (
	abstract_via_parent  => 'BT::AbstractViaParent',
	abstract_via_use     => 'BT::AbstractViaUse',
	concrete_child       => 'BT::ConcreteChild',
	concrete_grandchild  => 'BT::ConcreteGrandchild',
	concrete_of_use      => 'BT::ConcreteOfUse',
	multi_abstract       => 'BT::MultiAbstract',
	concrete_of_multi    => 'BT::ConcreteOfMulti',
	obj_key              => 'name',
	obj_val              => 'Rex',
);

# ---------------------------------------------------------------------------
# Fixture packages
# ---------------------------------------------------------------------------
# All fixtures are at file scope so Perl compiles them before tests run.
# No use_ok here -- Class::Abstract must be loaded at compile time.

use Class::Abstract;    # needed so the CHECK-less module is available

# Abstract via use parent.
{
	package BT::AbstractViaParent;
	use parent -norequire, 'Class::Abstract';
	# No new() -- inherits Class::Abstract::new via MRO.
}

# Abstract via "use Class::Abstract" (import form).
{
	package BT::AbstractViaUse;
	use Class::Abstract;
	# No new() -- same MRO chain.
}

# Concrete child of AbstractViaParent.  Has its own new() that uses SUPER.
{
	package BT::ConcreteChild;
	our @ISA = ('BT::AbstractViaParent');
	sub new {
		my ($class, %args) = @_;
		my $self = $class->SUPER::new;    # delegates through AbstractViaParent -> Class::Abstract
		$self->{name} = $args{name} if defined $args{name};
		return $self;
	}
}

# Grandchild of AbstractViaParent, no new() of its own.
{
	package BT::ConcreteGrandchild;
	our @ISA = ('BT::ConcreteChild');
}

# Concrete child of AbstractViaUse.
{
	package BT::ConcreteOfUse;
	our @ISA = ('BT::AbstractViaUse');
	sub new {
		my ($class, %args) = @_;
		my $self = $class->SUPER::new;
		$self->{name} = $args{name} if defined $args{name};
		return $self;
	}
}

# A second abstract class in a hierarchy.
{
	package BT::MultiAbstract;
	use parent -norequire, 'Class::Abstract', 'BT::AbstractViaParent';
}

# Concrete child of MultiAbstract.
{
	package BT::ConcreteOfMulti;
	our @ISA = ('BT::MultiAbstract');
	sub new {
		my ($class, %args) = @_;
		return $class->SUPER::new;
	}
}

# ---------------------------------------------------------------------------
# Helper: disable both bypass paths.
# ---------------------------------------------------------------------------

sub enforcement_on (&) {
	my ($code) = @_;
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;
	return $code->();
}

diag 'Basic enforcement tests' if $ENV{TEST_VERBOSE};

# ---------------------------------------------------------------------------
# 1. Direct instantiation of abstract classes must croak.
# ---------------------------------------------------------------------------

subtest 'direct instantiation of abstract class croaks (use parent form)' => sub {
	plan tests => 2;

	enforcement_on {
		# The error message must name the abstract class.
		throws_ok { BT::AbstractViaParent->new }
			qr/Cannot instantiate abstract class BT::AbstractViaParent directly/,
			'AbstractViaParent->new croaks';

		like $@,
			qr/Cannot instantiate abstract class/,
			'error message contains the expected phrase';
	};
};

subtest 'direct instantiation of abstract class croaks (use Class::Abstract form)' => sub {
	plan tests => 1;

	enforcement_on {
		throws_ok { BT::AbstractViaUse->new }
			qr/Cannot instantiate abstract class BT::AbstractViaUse directly/,
			'AbstractViaUse->new croaks';
	};
};

# ---------------------------------------------------------------------------
# 2. Concrete subclass can be instantiated.
# ---------------------------------------------------------------------------

subtest 'concrete subclass instantiation succeeds' => sub {
	plan tests => 3;

	enforcement_on {
		# ConcreteChild has its own new() that calls SUPER::new.
		my $obj;
		lives_ok { $obj = BT::ConcreteChild->new(name => $config{obj_val}) }
			'ConcreteChild->new lives';

		ok ref($obj) eq $config{concrete_child},
			"object is blessed into $config{concrete_child}";

		is $obj->{$config{obj_key}}, $config{obj_val},
			"object attribute '$config{obj_key}' was set correctly";
	};
};

# ---------------------------------------------------------------------------
# 3. SUPER::new chain works correctly.
# ---------------------------------------------------------------------------

subtest 'SUPER::new chain: class argument is the concrete subclass' => sub {
	plan tests => 2;

	enforcement_on {
		# When Dog->SUPER::new is called, $class inside Class::Abstract::new
		# is 'Dog' (not 'Animal').  The abstract check looks at Dog's @ISA,
		# finds no Class::Abstract, and allows the construction.
		my $obj;
		lives_ok { $obj = BT::ConcreteChild->new }
			'SUPER::new chain completes without error';

		ok ref($obj) eq $config{concrete_child},
			'returned object is blessed into the concrete class';
	};
};

# ---------------------------------------------------------------------------
# 4. Grandchild (no new() of its own) uses inherited SUPER chain.
# ---------------------------------------------------------------------------

subtest 'grandchild without own new() inherits via SUPER chain' => sub {
	plan tests => 2;

	enforcement_on {
		my $obj;
		lives_ok { $obj = BT::ConcreteGrandchild->new }
			'ConcreteGrandchild->new lives (no own new())';

		ok ref($obj) eq $config{concrete_grandchild},
			'object blessed into ConcreteGrandchild';
	};
};

# ---------------------------------------------------------------------------
# 5. AbstractViaUse concrete child works.
# ---------------------------------------------------------------------------

subtest 'concrete child of use-form abstract class works' => sub {
	plan tests => 2;

	enforcement_on {
		my $obj;
		lives_ok { $obj = BT::ConcreteOfUse->new(name => $config{obj_val}) }
			'ConcreteOfUse->new lives';

		is $obj->{$config{obj_key}}, $config{obj_val},
			'attribute set correctly via SUPER chain';
	};
};

# ---------------------------------------------------------------------------
# 6. Multi-level abstract hierarchy.
# ---------------------------------------------------------------------------

subtest 'multi-level abstract: intermediate abstract class croaks directly' => sub {
	plan tests => 2;

	enforcement_on {
		throws_ok { BT::MultiAbstract->new }
			qr/Cannot instantiate abstract class BT::MultiAbstract directly/,
			'MultiAbstract->new croaks';

		my $obj;
		lives_ok { $obj = BT::ConcreteOfMulti->new }
			'ConcreteOfMulti->new lives';
	};
};

# ---------------------------------------------------------------------------
# 7. blessed ref as invocant for new().
# ---------------------------------------------------------------------------

subtest 'blessed ref as invocant is treated as its class' => sub {
	plan tests => 2;

	enforcement_on {
		my $dog = BT::ConcreteChild->new;
		ok blessed($dog), 'ConcreteChild->new returned a blessed ref';

		# Calling new() on a blessed instance should work (class is taken from ref).
		my $dog2;
		lives_ok { $dog2 = $dog->new }
			'$dog->new (instance method call) lives';
	};
};

done_testing;
