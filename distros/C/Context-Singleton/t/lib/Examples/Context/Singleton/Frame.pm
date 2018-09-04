
use strict;
use warnings;

package Examples::Context::Singleton::Frame;

our $VERSION = v1.0.0;

use Test::Spec::Util;
use Hash::Util qw[ ];

use Context::Singleton::Frame;
use Sample::Context::Singleton::Frame;

sub evaluate (&) {
	my ($code) = @_;
	my $value;
	my $lives_ok = eval { $value = $code->(); 1 };
	my $error = $@;

	($lives_ok, $error, $value);
}

sub behaves_like_proclaim {
	my ($title, %params) = @_;
	Hash::Util::lock_keys %params,
		qw[ object ],
		qw[ with_key with_value ],
		qw[ throws expect_value ],
		;

	$params{throws} = qr/Key already resolved/
		if exists $params{throws};

	my ($lives, $error, $returns) = evaluate {
		$params{object}->proclaim ($params{with_key}, $params{with_value});
	};

	context $title => as {
		if ($params{throws}) {
			it "should throw exception" => as { throws_ok { die $error unless $lives } $params{throws} };
			it "should deduce value" => as { is $params{object}->deduce ($params{with_key}), $params{expect_value} }
				if exists $params{expect_value};
		} else {
			it "should not throw exception" => as { lives_ok { die $error unless $lives } };
			it "should return 'self'" => as { is $returns, $params{object} };
			it "should deduce value" => as { is $params{object}->deduce ($params{with_key}), $params{with_value} };
		}
	};
}

sub behaves_like_is_deduced {
	my ($title, %params) = @_;
	Hash::Util::lock_keys %params, qw[ object expect with_key ];

	my ($lives_ok, $error, $status) = evaluate {
		$params{object}->is_deduced ($params{with_key})
	};

	it $title => $lives_ok
		? as { cmp_deeply $status, bool $params{expect} }
		: as { lives_ok { die $error } }
		;
}

sub behaves_like_deduce {
	my ($title, %params) = @_;
	Hash::Util::lock_keys %params, qw[ object throws with_key expect_value ];

	my ($lives_ok, $error, $got) = evaluate {
		$params{object}->deduce ($params{with_key});
	};

	my $code;
	$code = as { throws_ok { die $error unless $lives_ok } $params{throws} }
		if $params{throws};
	$code //= as { lives_ok { die $error } }
		unless $lives_ok;
	$code //= as { cmp_deeply $got, $params{expect_value} };

	it $title => $code;
}

export build_frame => as {
	my $parent = shared->frame_class // 'Context::Singleton::Frame';
	$parent = shift if @_ % 2;
	return $parent->new (@_);
};

export build_sample_dependencies => as {
	build_frame ('Sample::Context::Singleton::Frame::002::Resolve::Dependencies', @_);
};

export build_sample_unique => as {
	build_frame ('Sample::Context::Singleton::Frame::001::Unique::DB', @_);
};

example expect_depth => as {
	my $title = shift if @_ % 2;
	my (%params) = @_;
	Hash::Util::lock_keys %params, qw[ object expect ];

	it $title // "expect depth $params{expect}" => as { cmp_deeply $params{object}{depth}, $params{expect} };
};

example it_should_have_parent => as {
	my (%params) = @_;

	it "should have parent" => as { ok $params{object}->{parent} };
};

example it_should_not_have_parent => as {
	my (%params) = @_;

	it "should not have parent" => as { ok ! $params{object}->{parent} };
};

example should_proclaim => as {
	my ($title, %params) = @_;

	behaves_like_proclaim $title, %params;
};

example should_not_proclaim => as {
	my ($title, %params) = @_;

	behaves_like_proclaim $title, throws => 1, %params;
};

example should_be_deduced => as {
	my ($title, %params) = @_;

	test_method $title, %params, expect => expect_true;
};

example should_not_be_deduced => as {
	my ($title, %params) = @_;

	test_method $title, %params, expect => expect_false;
};

example should_be_deducible => as {
	my ($title, %params) = @_;

	test_method $title, %params, expect => expect_true;
};

example should_not_be_deducible => as {
	my ($title, %params) = @_;

	test_method $title, %params, expect => expect_false;
};

example should_deduce => as {
	my ($title, %params) = @_;

	test_method $title, %params;
};

example should_not_deduce => as {
	my ($title, %params) = @_;

	test_method $title, %params, throws => 'Context::Singleton::Exception::Nondeducible';
};

example it_should_have_db => as {
	my (%params) = @_;

	it "should have db" => as { ok $params{object}->db };
	it "should share db with its ancestor" => as { is $params{object}->db, $params{ancestor}->db }
		if $params{ancestor};
};

example frame_constructor => as {
	my ($title, %params) = @_;
	Hash::Util::lock_keys %params,
		qw[ object plan ],
		qw[ expect_class expect_depth expect_parent expect_resolved ],
		qw[ expect_root ],
		;

	$params{expect_resolved} //= [];

	context $title => as {
		Test::More::plan tests => $params{plan} if $params{plan};
		is_instance_of (
			object => $params{object},
			class  => $params{expect_class},
		) if exists $params{expect_class};

		expect_depth ("expect depth $params{expect_depth}" => do {
			object => $params{object},
				expect => $params{expect_depth},
			}) if exists $params{expect_depth};

		it_should_have_parent (object => $params{object})
			if exists $params{expect_parent} and $params{expect_parent};

		it_should_not_have_parent (object => $params{object})
			if exists $params{expect_parent} and not $params{expect_parent};

		is ($params{object}->root_resolver, $params{expect_root})
			if exists $params{expect_root};

		#it_should_have_db (
		#    object => $params{object},
		#    ancestor => $params{expect_parent},
		#);

		for my $key (@{ $params{expect_resolved} }) {
			should_be_deduced (
				"'$key' should be deduced",
				object => $params{object},
				with_key => $key,
			)
		}
	};
};

example test_method_proclaim => as {
	my ($title, %params) = @_;
	Hash::Util::lock_keys %params, qw[ object with_rule with_value throws expect ];

	$params{expect} = $params{with_value}
		unless exists $params{expect} or $params{throws};

	test_method $title => %params;
};

1;
