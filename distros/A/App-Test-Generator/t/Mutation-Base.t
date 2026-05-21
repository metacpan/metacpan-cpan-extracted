#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use PPI;

BEGIN {
	use_ok('App::Test::Generator::Mutation::Base');
}

# ==================================================================
# new
# ==================================================================
subtest 'new' => sub {
	# Constructor returns a defined blessed object
	my $b = new_ok('App::Test::Generator::Mutation::Base');
	ok(defined $b, 'new() returns defined value');
	isa_ok($b, 'App::Test::Generator::Mutation::Base');
	is(ref($b), 'App::Test::Generator::Mutation::Base',
		'object is blessed into correct class');

	# Each call produces a distinct object
	my $b2 = App::Test::Generator::Mutation::Base->new();
	isnt($b, $b2, 'each call produces a distinct object');

	# Object is an empty hashref
	is(scalar keys %{$b}, 0, 'object is an empty hashref');
};

# ==================================================================
# applies_to -- must croak on base class
# ==================================================================
subtest 'applies_to: croaks on base class' => sub {
	my $b   = App::Test::Generator::Mutation::Base->new();
	my $doc = PPI::Document->new(\'sub foo { 1; }');

	# Calling applies_to on the base class must croak
	throws_ok {
		$b->applies_to($doc)
	} qr/App::Test::Generator::Mutation::Base::applies_to\(\) must be implemented by subclass/,
		'applies_to croaks with correct message on base class';
};

# ==================================================================
# mutate -- must croak on base class
# ==================================================================
subtest 'mutate: croaks on base class' => sub {
	my $b   = App::Test::Generator::Mutation::Base->new();
	my $doc = PPI::Document->new(\'sub foo { 1; }');

	# Calling mutate on the base class must croak
	throws_ok {
		$b->mutate($doc)
	} qr/App::Test::Generator::Mutation::Base::mutate\(\) must be implemented by subclass/,
		'mutate croaks with correct message on base class';
};

# ==================================================================
# croak messages include the actual class name
# --------------------------------------------------
# When called via a subclass that forgot to implement
# the method, the message names the subclass, not Base
# ==================================================================
subtest 'croak messages name the calling class' => sub {
	# Create a minimal subclass that does not override anything
	{
		package My::Incomplete::Mutation;
		use parent -norequire, 'App::Test::Generator::Mutation::Base';
	}

	my $m   = My::Incomplete::Mutation->new();
	my $doc = PPI::Document->new(\'sub foo { 1; }');

	# applies_to croak must name the subclass
	throws_ok {
		$m->applies_to($doc)
	} qr/My::Incomplete::Mutation::applies_to\(\) must be implemented by subclass/,
		'applies_to croak names the subclass';

	# mutate croak must name the subclass
	throws_ok {
		$m->mutate($doc)
	} qr/My::Incomplete::Mutation::mutate\(\) must be implemented by subclass/,
		'mutate croak names the subclass';
};

# ==================================================================
# subclass that implements both methods works correctly
# ==================================================================
subtest 'complete subclass overrides both methods' => sub {
	# Create a minimal but complete subclass
	{
		package My::Complete::Mutation;
		use parent -norequire, 'App::Test::Generator::Mutation::Base';

		# applies_to always returns 1 for testing
		sub applies_to { return 1 }

		# mutate always returns an empty list for testing
		sub mutate { return () }
	}

	my $m   = My::Complete::Mutation->new();
	my $doc = PPI::Document->new(\'sub foo { 1; }');

	# Subclass must inherit new() correctly
	isa_ok($m, 'My::Complete::Mutation');
	isa_ok($m, 'App::Test::Generator::Mutation::Base',
		'complete subclass isa Base');

	# applies_to must not croak
	lives_ok { $m->applies_to($doc) }
		'applies_to lives on complete subclass';
	ok($m->applies_to($doc), 'applies_to returns true');

	# mutate must not croak
	lives_ok { $m->mutate($doc) }
		'mutate lives on complete subclass';
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'mutate returns empty list');
};

# ==================================================================
# all four concrete subclasses inherit from Base
# ==================================================================
subtest 'concrete subclasses inherit from Base' => sub {
	for my $subclass (qw(
		App::Test::Generator::Mutation::BooleanNegation
		App::Test::Generator::Mutation::ConditionalInversion
		App::Test::Generator::Mutation::NumericBoundary
		App::Test::Generator::Mutation::ReturnUndef
	)) {
		# Load the subclass
		eval "require $subclass";
		ok(!$@, "$subclass loaded without error");

		my $obj = $subclass->new();
		isa_ok($obj, 'App::Test::Generator::Mutation::Base',
			"$subclass isa Base");
	}
};

done_testing();
