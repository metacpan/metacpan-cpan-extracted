
use strict;
use warnings;
use feature 'state';

package Test::Spec::Util;

our $VERSION = v1.0.0;

use parent 'Exporter';

use Hash::Util qw[ ];
use Ref::Util qw[ is_coderef ];
use Scalar::Util qw[ ];
use Sub::Install qw[ ];
use Sub::Name qw[ ];
use Sub::Override qw[ ];
use Sub::Uplevel qw[ ];

use Test::More 0.94;
use Test::Deep;
use Test::Exception;

our %context;
our $context_accessor = 'Test::Spec::Util::Shared';

our @EXPORT = (
    'export',
    'example',
    'as',
    'shared',
    @Test::More::EXPORT,
    @Test::Exception::EXPORT,
    @Test::Deep::EXPORT,
);

sub export {
    my ($name, $coderef) = @_;
    my $caller = caller;

    Sub::Install::install_sub({
        code => $coderef,
        as   => $name,
        into => $caller,
    });

    Sub::Name::subname "${caller}::${name}", $coderef;

    {
        no strict 'refs';
        (state $caller_cache)->{$caller} //= push @{ "${caller}::ISA" }, 'Exporter';
        push @{ "${caller}::EXPORT" }, $name;
    }

    1;
}


sub as (&) {
    shift
}

sub example {
    my ($name, $coderef) = @_;

    my $default_title = $name;
    $default_title =~ s/_/ /g;

    @_ = ($name, sub { unshift @_, $default_title unless @_ % 2; goto $coderef });
    goto &export;
}

sub shared (;$) : lvalue {
    return $context_accessor unless @_;

    $context{$_[0]};
}

export describe => sub {
    my ($name, $code) = @_;
    local %context = %context;
    Test::More::note("describe $name");
    Test::More::subtest ($name, sub { $code->(); done_testing });
};

export context => sub {
    my ($name, $code) = @_;
    local %context = %context;
    Test::More::note("context $name");
    Test::More::subtest ($name, sub { $code->(); done_testing });
};

export it => sub {
    my ($description, $code) = @_;
    local %context = %context;

    my $test_builder_ok = \&Test::Builder::ok;
    my $only_one_assert = 0;
    my $guard = Sub::Override->new ('Test::Builder::ok' => as {
        my @args = @_;

        if ($only_one_assert++) {
            $args[1] = 0;
            $args[2] = 'Only one assert allowed in one it';
        }

        $args[2] = $description;

        local $Test::Builder::Level = $Test::Builder::Level+1;
        $test_builder_ok->(@args);
    });

    is_coderef $code ? $code->() : ok $code;
};

export is_instance_of => as {
    my ($object, $class) = @_;

    cmp_deeply $object, obj_isa ($class);
};

export is_test_deep_comparision => as {
    my ($object) = @_;

    eq_deeply ($object, obj_isa ('Test::Deep::Cmp'));
};

export is_empty => as {
    my (@list) = @_;

    is_deeply \@list, [];
};

export expect_false => as {
    bool (0);
};

export expect_true => as {
    bool (1);
};

export describe_method => as {
    my ($method, $args, $code) = @_;

    describe ("$method()" => as {
        shared->method = $method;
        shared->method_args = [ map "with_$_", @{$args} ];

        $code->();
    });
};

export test_method => as {
    my ($title, %params) = @_;
    my $method = $params{method} // shared->method;
    my @args = @{ $params{method_args} // shared->method_args // [] };
    my $wanthash = $params{method_wanthash} // shared->method_wanthash;
    my $wantarray = $params{method_wantarray} // shared->method_wantarray;

    Hash::Util::lock_keys %params,
        qw[ method method_args method_wantarray method_wanthash ],
        qw[ object throws expect ], @args;

    $params{object} //= shared->object;

    my ($value, $lives_ok, $error);
    $lives_ok = eval {
        $value = $wantarray || $wanthash
            ? [ $params{object}->$method (@params{@args}) ]
            : $params{object}->$method (@params{@args})
            ;
        $value = { @$value } if $wanthash;
        1
    };
    $error = $@;

    return it ($title => as { throws_ok { die $error unless $lives_ok } $params{throws}})
        if $params{throws};

    return it ("should not throw - $title" => as { lives_ok { die $error } })
        unless $lives_ok;

    return it ($title => as { pass })
        unless exists $params{expect};

    return it ($title => as { cmp_deeply $value, $params{expect} });
};

export test_list_method => as {
    test_method (@_, method_wantarray => 1);
};

export test_hash_method => as {
    test_method (@_, method_wanthash => 1);
};

export build_instance => as {
    my $args = pop // [];
    my $class = shift // shared->class;

    shared->object = $class->new (@$args);
};

example expect_instance_of => as {
    my ($title, %params) = @_;
    Hash::Util::lock_keys %params, qw[ object class ];

    $params{object} //= shared->object;
    $params{class} //= shared->class;

    it ("is instance of $params{class}" => as {
        return fail ("instance is not an object")
            unless Scalar::Util::blessed ($params{object});

        return fail ("instance is not of $params{class}")
            unless $params{object}->isa ($params{class});

        return pass;
    });
};

example it_should_build_instance => as {
    my ($title, %params) = @_;
    Hash::Util::lock_keys %params, qw[ class args throws expect ];

    $params{class} //= shared->class;
    $params{args} //= [];

    my ($value, $lives_ok, $error);
    $lives_ok = eval { $value = $params{class}->new (@{ $params{args} }); 1 };
    $error = $@;

    return it ($title => as { throws_ok { die $error unless $lives_ok } $params{throws}})
        if $params{throws};

    return it ("should not throw - $title" => as { lives_ok { die $error } })
        unless $lives_ok;

    shared->object = $value;

    return it ($title => as { expect_instance_of (class => $params{class}) })
        unless exists $params{expect};

    return it ($title => as { cmp_deeply $value, $params{expect} });
};

export use_sample_class => as {
    my $name = pop;
    my $base = shift // shared->class_under_test // shared->class;

    shared->class = "Sample::${base}::__::$name";
};

export class_under_test => as {
    shared->class = shared->class_under_test = shift;
};

package Test::Spec::Util::Shared;

our $AUTOLOAD;

sub AUTOLOAD : lvalue {
    my $key = substr $AUTOLOAD, 2 + length __PACKAGE__;
    $context{$key};
}

1;

