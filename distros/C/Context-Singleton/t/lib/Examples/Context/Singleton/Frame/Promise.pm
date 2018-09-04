
use strict;
use warnings;

package Examples::Context::Singleton::Frame::Promise;

use Test::Spec::Util;
use Hash::Util;

sub build_object {
	my (%params) = @_;

	$params{class}->new (@{ $params{arguments} // [] })
}

sub augment_arguments (\%;@) {
	my ($params, @augment) = @_;

	$params->{arguments} = [ @augment, @{ $params->{arguments} // [] } ];
}

BEGIN {
	export promise_is_resolved => as {
		my (%params) = @_;
		Hash::Util::lock_keys %params, qw[ promise expected ];

		$params{expected} //= expect_true;
		$params{expected} = bool ($params{expected})
			unless is_test_deep_comparision $params{expected};

		eq_deeply $params{promise}->is_resolved, $params{expected};
	};

	export expect_not_resolved => as {
		expect_resolved (@_, expected => expect_false);
	};

	export expect_resolvable => as {
		my $title = shift if @_ % 2;

		my %params = @_;
		Hash::Util::lock_keys %params, qw[ object throws expected ];

		$params{expected} //= expect_true;

		$title //= "shoud throw" if $params{throws};
		$title //= "should ${\ (eq_deeply (0, $params{expected}) ? 'not ' : '') }be resolvable";

		my $got;
		my $lives_ok = eval { $got = $params{object}->is_resolvable; 1 };
		my $error = $@;

		return it $title => as { throws_ok { die $error unless $lives_ok } $params{throws}, '' }
			if exists $params{throws};

		return it "should not throw ($title)" => as { lives_ok { die $error } }
			unless $lives_ok;

		it $title => as { cmp_deeply $got, $params{expected} };
	};

	export expect_not_resolvable => as {
		expect_resolvable (@_, expected => expect_false);
	};

	export expect_in_depth => as {
		my $title = shift if @_ % 2;
		$title //= 'should be resolvable in depth';

		my (%params) = @_;

		Hash::Util::lock_keys %params, qw[ object throws expected ];

		my $got;
		my $lives_ok = eval { $got = $params{object}->in_depth; 1 };
		my $error = $@;

		return it $title => as { throws_ok { die $error unless $lives_ok } $params{throws}, '' }
			if exists $params{throws};

		return it "should not throw ($title)" => as { lives_ok { die $error } }
			unless $lives_ok;

		it $title => as { cmp_deeply $got, $params{expected} };
	};
}

example argument_depth_should_be_mandatory => as {
	my ($title, %params) = @_;
	Hash::Util::lock_keys %params, qw[ class arguments ];

	it $title => as {
		throws_ok { build_object %params } qr/Missing required arguments: depth/, '';
	};
};

example new_promise_should_not_be_resolved_nor_resolvable => as {
	my ($title, %params) = @_;
	Hash::Util::lock_keys %params, qw[ object class arguments ];

	augment_arguments %params, depth => 4;
    $params{object} //= build_object %params;

	it $title => as {
		my $is_resolvable = $params{object}->is_deducible;
		my $is_resolved   = $params{object}->is_deduced;

		ok (not $is_resolved and not $is_resolved);
	}
};
