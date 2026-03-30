#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Error');

# --- clear state ---
Chandra::Error->clear_handlers;

# --- capture basic error ---
{
    eval { die "test error" };
    my $err = Chandra::Error->capture($@, context => 'test');
    ok($err, 'capture returns hashref');
    like($err->{message}, qr/test error/, 'message captured');
    is($err->{context}, 'test', 'context captured');
    ok($err->{time}, 'time recorded');
    ok(ref $err->{trace} eq 'ARRAY', 'trace is arrayref');
}

# --- capture with default context ---
{
    my $err = Chandra::Error->capture("oops");
    is($err->{context}, 'unknown', 'default context is unknown');
}

# --- format_text ---
{
    my $err = {
        message => 'something broke',
        context => 'mymod',
        trace   => [
            { sub => 'Foo::bar', file => 'Foo.pm', line => 42, package => 'Foo' },
            { sub => 'main::run', file => 'app.pl', line => 10, package => 'main' },
        ],
        time => time(),
    };
    my $text = Chandra::Error->format_text($err);
    like($text, qr/\[Chandra::mymod\]/, 'format_text includes context');
    like($text, qr/something broke/, 'format_text includes message');
    like($text, qr/Foo::bar at Foo\.pm line 42/, 'format_text includes trace frame 1');
    like($text, qr/main::run at app\.pl line 10/, 'format_text includes trace frame 2');
}

# --- format_text with no trace ---
{
    my $err = {
        message => 'simple error',
        context => 'ctx',
        trace   => [],
        time    => time(),
    };
    my $text = Chandra::Error->format_text($err);
    is($text, '[Chandra::ctx] simple error', 'format_text with empty trace');
}

# --- format_text with undef sub ---
{
    my $err = {
        message => 'err',
        context => 'x',
        trace   => [{ sub => undef, file => 'f.pl', line => 1, package => 'main' }],
        time    => time(),
    };
    my $text = Chandra::Error->format_text($err);
    like($text, qr/\(main\) at f\.pl line 1/, 'undef sub shows (main)');
}

# --- format_js_console ---
{
    my $err = {
        message => "bad stuff",
        context => 'js',
        trace   => [],
        time    => time(),
    };
    my $js = Chandra::Error->format_js_console($err);
    like($js, qr/^console\.error\('/, 'format_js_console starts with console.error');
    like($js, qr/bad stuff/, 'format_js_console includes message');
    like($js, qr/'\)$/, 'format_js_console ends correctly');
}

# --- format_js_console escapes special chars ---
{
    my $err = {
        message => "it's a test\nwith newlines\\slashes",
        context => 'esc',
        trace   => [],
        time    => time(),
    };
    my $js = Chandra::Error->format_js_console($err);
    like($js, qr/it\\'s a test/, 'single quotes escaped in message');
    unlike($js, qr/(?<!\\)\n/, 'newlines escaped');
    like($js, qr/\\\\slashes/, 'backslashes escaped');
}

# --- on_error handler ---
{
    Chandra::Error->clear_handlers;
    my @captured;
    Chandra::Error->on_error(sub {
        push @captured, shift;
    });

    eval { die "handler test" };
    Chandra::Error->capture($@, context => 'htest');

    is(scalar @captured, 1, 'handler called once');
    like($captured[0]->{message}, qr/handler test/, 'handler received error');
    is($captured[0]->{context}, 'htest', 'handler received context');
}

# --- multiple handlers ---
{
    Chandra::Error->clear_handlers;
    my ($a, $b) = (0, 0);
    Chandra::Error->on_error(sub { $a++ });
    Chandra::Error->on_error(sub { $b++ });

    Chandra::Error->capture("multi");

    is($a, 1, 'first handler called');
    is($b, 1, 'second handler called');
}

# --- handler error doesn't break capture ---
{
    Chandra::Error->clear_handlers;
    my $ok = 0;
    Chandra::Error->on_error(sub { die "handler crash" });
    Chandra::Error->on_error(sub { $ok = 1 });

    my $err = Chandra::Error->capture("safe");
    ok($err, 'capture succeeds even if handler dies');
    is($ok, 1, 'second handler still called after first dies');
}

# --- clear_handlers ---
{
    Chandra::Error->clear_handlers;
    my $called = 0;
    Chandra::Error->on_error(sub { $called++ });
    Chandra::Error->clear_handlers;
    Chandra::Error->capture("cleared");
    is($called, 0, 'cleared handler not called');
}

# --- handlers() returns arrayref ---
{
    Chandra::Error->clear_handlers;
    my $ref = Chandra::Error->handlers;
    is(ref $ref, 'ARRAY', 'handlers returns arrayref');
    is(scalar @$ref, 0, 'no handlers initially');

    Chandra::Error->on_error(sub {});
    $ref = Chandra::Error->handlers;
    is(scalar @$ref, 1, 'one handler after on_error');
}

# --- stack_trace ---
{
    sub _inner_trace {
        return Chandra::Error->stack_trace(0);
    }
    sub _outer_trace {
        return _inner_trace();
    }

    my $trace = _outer_trace();
    ok(ref $trace eq 'ARRAY', 'stack_trace returns arrayref');
    ok(scalar @$trace >= 2, 'trace has multiple frames');

    my $first = $trace->[0];
    ok(exists $first->{package}, 'frame has package');
    ok(exists $first->{file}, 'frame has file');
    ok(exists $first->{line}, 'frame has line');
    ok(exists $first->{sub}, 'frame has sub');
}

# --- stack_trace depth limit ---
{
    # Create deeply nested calls
    my $trace;
    my $deep;
    $deep = sub {
        my ($n) = @_;
        if ($n <= 0) {
            $trace = Chandra::Error->stack_trace(0);
            return;
        }
        $deep->($n - 1);
    };
    $deep->(20);
    ok(scalar @$trace <= 10, 'stack trace limited to 10 frames');
}

# --- capture with skip ---
{
    Chandra::Error->clear_handlers;
    sub _wrapper {
        return Chandra::Error->capture("skipped", context => 'skip', skip => 0);
    }
    my $err = _wrapper();
    ok($err->{trace} && @{$err->{trace}} > 0, 'trace present with skip=0');
}

# --- on_error rejects non-coderefs ---
{
    Chandra::Error->clear_handlers;
    Chandra::Error->on_error("not a coderef");
    Chandra::Error->on_error(undef);
    my $ref = Chandra::Error->handlers;
    is(scalar @$ref, 0, 'non-coderefs rejected');
}

# --- message whitespace trimming ---
{
    my $err = Chandra::Error->capture("trimmed\n\n", context => 'trim');
    is($err->{message}, 'trimmed', 'trailing whitespace trimmed from message');
}

# cleanup
Chandra::Error->clear_handlers;

done_testing;
