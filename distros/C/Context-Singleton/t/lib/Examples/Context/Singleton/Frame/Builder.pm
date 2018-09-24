
use v5.10;
use strict;
use warnings;

package Examples::Context::Singleton::Frame::Builder;

our $VERSION = v1.0.0;

use Test::Spec::Util;
use Hash::Util;
use Ref::Util qw[ is_plain_arrayref ];

example expect_required => as {
    my ($title, %params) = @_;
    Hash::Util::lock_keys %params, qw[ object expect ];

    my $object = $params{object} // shared->object;
    my $expect = $params{expect} // [];

    $expect = bag (@$expect)
        if not is_test_deep_comparision ($expect) and is_plain_arrayref ($expect);

    test_list_method $title => (
        method => 'required',
        method_args => [],

        object => $object,
        expect => $expect,
    );
};

example expect_unresolved => as {
    my ($title, %params) = @_;
    Hash::Util::lock_keys %params, qw[ object expect with_deduced ];

    my $object = $params{object} // shared->object;
    my $expect = $params{expect} // [];

    $expect = bag (@$expect)
        if not is_test_deep_comparision ($expect) and is_plain_arrayref ($expect);

    test_list_method $title => (
        method => 'unresolved',
        method_args => [ 'with_deduced' ],
        method_wantarray => 1,

        object => $object,
        expect => $expect,
        with_deduced => $params{with_deduced},
    );
};

example expect_dep => as {
    my ($title, %params) = @_;
    Hash::Util::lock_keys %params, qw[ object expect ];

    test_method $title => (
        method => 'dep',
        method_args => [],

        object => $params{object} // shared->object,
        expect => $params{expect},
    );
};

example expect_default => as {
    my ($title, %params) = @_;
    Hash::Util::lock_keys %params, qw[ object expect ];

    test_hash_method $title => (
        method => 'default',
        method_args => [],

        object => $params{object} // shared->object,
        expect => $params{expect} // {},
    );
};

example expect_build_args => as {
    my ($title, %params) = @_;
    Hash::Util::lock_keys %params, qw[ object expect with_deduced];

    test_list_method $title => (
        method => 'build_callback_args',
        method_args => [ 'with_deduced' ],

        object => $params{object} // shared->object,
        with_deduced => $params{with_deduced},
        expect => $params{expect},
    );
};

example expect_build => as {
    my ($title, %params) = @_;
    Hash::Util::lock_keys %params, qw[ object throws expect with_deduced];

    my $object = $params{object} // shared->object;

    test_method $title => (
        method => 'build',
        method_args => [ 'with_deduced' ],

        object => $params{object} // shared->object,
        with_deduced => $params{with_deduced},
        (expect => $params{expect}) x!  exists $params{throws},
        (throws => $params{throws}) x!! exists $params{throws},
    );
};

1;
