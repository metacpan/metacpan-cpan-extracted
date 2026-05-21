#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Scalar::Util qw(reftype);

# Black-box unit tests for App::Test::Generator::Mutation::Base.
# Tests each public function according to its POD API specification.
# No mocking required — Base has no external dependencies.

BEGIN { use_ok('App::Test::Generator::Mutation::Base') }

# ==================================================================
# new()
#
# POD spec:
#   Arguments: none
#   Returns:   a blessed hashref
# ==================================================================

subtest 'new() returns a blessed object' => sub {
	my $b = App::Test::Generator::Mutation::Base->new();
	isa_ok($b, 'App::Test::Generator::Mutation::Base');
};

subtest 'new() underlying type is a hashref' => sub {
	my $b = App::Test::Generator::Mutation::Base->new();
	is(reftype($b), 'HASH', 'underlying type is HASH');
};

subtest 'new() each call returns a distinct object' => sub {
	my $b1 = App::Test::Generator::Mutation::Base->new();
	my $b2 = App::Test::Generator::Mutation::Base->new();
	isnt($b1, $b2, 'distinct objects returned');
};

subtest 'new() accepts no arguments' => sub {
	lives_ok(
		sub { App::Test::Generator::Mutation::Base->new() },
		'new() with no arguments lives',
	);
};

# ==================================================================
# applies_to()
#
# POD spec:
#   Must be implemented by subclass.
#   Calling on base class croaks with message naming the calling class.
# ==================================================================

subtest 'applies_to() croaks on base class' => sub {
	my $b   = App::Test::Generator::Mutation::Base->new();
	throws_ok(
		sub { $b->applies_to() },
		qr/App::Test::Generator::Mutation::Base::applies_to\(\) must be implemented by subclass/,
		'applies_to croaks on base class with correct message',
	);
};

subtest 'applies_to() croak message names the actual calling class for subclass' => sub {
	{
		package My::Unit::Incomplete;
		use parent -norequire, 'App::Test::Generator::Mutation::Base';
	}
	my $m = My::Unit::Incomplete->new();
	throws_ok(
		sub { $m->applies_to() },
		qr/My::Unit::Incomplete::applies_to\(\) must be implemented by subclass/,
		'croak message names the subclass not Base',
	);
};

subtest 'applies_to() does not croak when overridden in subclass' => sub {
	{
		package My::Unit::Complete;
		use parent -norequire, 'App::Test::Generator::Mutation::Base';
		sub applies_to { return 1 }
		sub mutate     { return () }
	}
	my $m = My::Unit::Complete->new();
	lives_ok(
		sub { $m->applies_to() },
		'applies_to lives when overridden',
	);
};

# ==================================================================
# mutate()
#
# POD spec:
#   Must be implemented by subclass.
#   Calling on base class croaks with message naming the calling class.
# ==================================================================

subtest 'mutate() croaks on base class' => sub {
	my $b = App::Test::Generator::Mutation::Base->new();
	throws_ok(
		sub { $b->mutate() },
		qr/App::Test::Generator::Mutation::Base::mutate\(\) must be implemented by subclass/,
		'mutate croaks on base class with correct message',
	);
};

subtest 'mutate() croak message names the actual calling class for subclass' => sub {
	{
		package My::Unit::Incomplete2;
		use parent -norequire, 'App::Test::Generator::Mutation::Base';
	}
	my $m = My::Unit::Incomplete2->new();
	throws_ok(
		sub { $m->mutate() },
		qr/My::Unit::Incomplete2::mutate\(\) must be implemented by subclass/,
		'croak message names the subclass not Base',
	);
};

subtest 'mutate() does not croak when overridden in subclass' => sub {
	my $m = My::Unit::Complete->new();
	lives_ok(
		sub { $m->mutate() },
		'mutate lives when overridden',
	);
};

# ==================================================================
# Concrete subclasses inherit from Base
#
# POD spec:
#   All four concrete mutation types inherit from Base.
# ==================================================================

subtest 'BooleanNegation inherits from Base' => sub {
	use_ok('App::Test::Generator::Mutation::BooleanNegation');
	my $m = App::Test::Generator::Mutation::BooleanNegation->new();
	isa_ok($m, 'App::Test::Generator::Mutation::Base');
};

subtest 'ConditionalInversion inherits from Base' => sub {
	use_ok('App::Test::Generator::Mutation::ConditionalInversion');
	my $m = App::Test::Generator::Mutation::ConditionalInversion->new();
	isa_ok($m, 'App::Test::Generator::Mutation::Base');
};

subtest 'NumericBoundary inherits from Base' => sub {
	use_ok('App::Test::Generator::Mutation::NumericBoundary');
	my $m = App::Test::Generator::Mutation::NumericBoundary->new();
	isa_ok($m, 'App::Test::Generator::Mutation::Base');
};

subtest 'ReturnUndef inherits from Base' => sub {
	use_ok('App::Test::Generator::Mutation::ReturnUndef');
	my $m = App::Test::Generator::Mutation::ReturnUndef->new();
	isa_ok($m, 'App::Test::Generator::Mutation::Base');
};

# ==================================================================
# Concrete subclasses implement both required methods
# ==================================================================

subtest 'concrete subclasses implement applies_to and mutate' => sub {
	require PPI;
	my $doc = PPI::Document->new(\'sub foo { return 1; }');
	for my $class (qw(
		App::Test::Generator::Mutation::BooleanNegation
		App::Test::Generator::Mutation::ConditionalInversion
		App::Test::Generator::Mutation::NumericBoundary
		App::Test::Generator::Mutation::ReturnUndef
	)) {
		my $m = $class->new();
		lives_ok(sub { $m->applies_to($doc) }, "$class: applies_to lives");
		lives_ok(sub { $m->mutate($doc) }, "$class: mutate lives");
	}
};

done_testing();
