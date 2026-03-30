#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Error');

# === capture with empty string ===
{
    Chandra::Error->clear_handlers;
    my $err = Chandra::Error->capture("");
    ok($err, 'capture empty string');
    is($err->{message}, '', 'empty message stored');
}

# === capture with undef ===
{
    Chandra::Error->clear_handlers;
    my $err = Chandra::Error->capture(undef);
    ok($err, 'capture undef');
    is($err->{message}, '', 'undef becomes empty string');
}

# === capture preserves meaningful whitespace ===
{
    Chandra::Error->clear_handlers;
    my $err = Chandra::Error->capture("error with  spaces");
    is($err->{message}, 'error with  spaces', 'internal spaces preserved');
}

# === format_text with deep trace ===
{
    my $err = {
        message => 'deep error',
        context => 'deep',
        trace   => [
            { sub => 'A::a', file => 'A.pm', line => 1, package => 'A' },
            { sub => 'B::b', file => 'B.pm', line => 2, package => 'B' },
            { sub => 'C::c', file => 'C.pm', line => 3, package => 'C' },
            { sub => 'D::d', file => 'D.pm', line => 4, package => 'D' },
        ],
        time => time(),
    };
    my $text = Chandra::Error->format_text($err);
    like($text, qr/A::a at A\.pm line 1/, 'first frame');
    like($text, qr/D::d at D\.pm line 4/, 'last frame');
}

# === format_js_console with deep trace ===
{
    my $err = {
        message => 'js error',
        context => 'js',
        trace   => [
            { sub => 'Foo::bar', file => 'Foo.pm', line => 10, package => 'Foo' },
        ],
        time => time(),
    };
    my $js = Chandra::Error->format_js_console($err);
    like($js, qr/^console\.error\('/, 'starts with console.error');
    like($js, qr/Foo::bar at Foo\.pm line 10/, 'trace in JS console output');
}

# === multiple handlers with mixed success/failure ===
{
    Chandra::Error->clear_handlers;
    my @order;
    Chandra::Error->on_error(sub { push @order, 'first' });
    Chandra::Error->on_error(sub { die "crash"; });
    Chandra::Error->on_error(sub { push @order, 'third' });

    my $err = Chandra::Error->capture("test");
    ok($err, 'capture succeeds despite handler crash');
    is_deeply(\@order, ['first', 'third'], 'handlers before and after crash both called');

    Chandra::Error->clear_handlers;
}

# === capture returns consistent structure ===
{
    Chandra::Error->clear_handlers;
    my $err = Chandra::Error->capture("structure test", context => 'ctx');
    ok(exists $err->{message}, 'has message');
    ok(exists $err->{context}, 'has context');
    ok(exists $err->{trace}, 'has trace');
    ok(exists $err->{time}, 'has time');
    is(ref $err->{trace}, 'ARRAY', 'trace is array');
    ok($err->{time} > 0, 'time is positive');
}

# === stack_trace frame structure ===
{
    sub _frame_check {
        return Chandra::Error->stack_trace(0);
    }
    my $trace = _frame_check();
    ok(scalar @$trace >= 1, 'at least one frame');
    my $frame = $trace->[0];
    ok(exists $frame->{package}, 'frame has package');
    ok(exists $frame->{file}, 'frame has file');
    ok(exists $frame->{line}, 'frame has line');
    ok(exists $frame->{sub}, 'frame has sub');
    ok($frame->{line} > 0, 'line number is positive');
}

# === clear_handlers is idempotent ===
{
    Chandra::Error->clear_handlers;
    Chandra::Error->clear_handlers;
    is(scalar @{Chandra::Error->handlers}, 0, 'double clear is safe');
}

# === capture with die object (ref) ===
{
    Chandra::Error->clear_handlers;
    eval { die { code => 42, msg => 'object error' } };
    my $err = Chandra::Error->capture($@, context => 'obj');
    ok($err, 'capture with die object');
    # The message should be a stringification of the reference
    ok(defined $err->{message}, 'message defined for object error');
}

# === handler receives correct error structure ===
{
    Chandra::Error->clear_handlers;
    my $received;
    Chandra::Error->on_error(sub { $received = shift });

    Chandra::Error->capture("handler struct", context => 'hctx');
    ok($received, 'handler received error');
    is($received->{context}, 'hctx', 'handler got correct context');
    like($received->{message}, qr/handler struct/, 'handler got correct message');
    is(ref $received->{trace}, 'ARRAY', 'handler got trace array');

    Chandra::Error->clear_handlers;
}

done_testing;
