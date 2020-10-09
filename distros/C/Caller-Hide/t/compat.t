use Test::More;
use Caller::Hide;

{
    package Foo;

    sub foo { Bar::bar() }

    package Bar;

    sub bar {
        main::compat_test('nested call');
    }
}

compat_test('call in main');
Foo::foo();

is scalar caller, scalar CORE::caller, 'empty caller (scalar)';
is_deeply [caller], [ CORE::caller ], 'empty caler (list)';

done_testing();

sub compat_test {
    my ($test) = @_;

    my (@trace, @trace_scalar, @core_trace, @core_trace_scalar);

    my $frame = 0;
    while (my @frame = caller($frame)) {
        push @trace,        \@frame;
        push @trace_scalar, scalar caller;
        ++$frame;
    }

    $frame = 0;
    while (my @frame = CORE::caller($frame)) {
        push @core_trace,        \@frame;
        push @core_trace_scalar, scalar CORE::caller;
        ++$frame;
    }

    is_deeply \@trace,        \@core_trace,        "$test (list)";
    is_deeply \@trace_scalar, \@core_trace_scalar, "$test (scalar)";
}
