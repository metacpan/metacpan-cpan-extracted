#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Error');

# === format_js_console escaping ===
{
    my $err = {
        message => "it's an error with 'quotes' and \\backslash",
        context => 'js_test',
        trace   => [],
        time    => time(),
    };
    my $js = Chandra::Error->format_js_console($err);
    like($js, qr/^console\.error\(/, 'starts with console.error(');
    like($js, qr/\)$/, 'ends with )');
    # Should not contain unescaped single quotes (all internal ' should be \')
    my $inner = $js;
    $inner =~ s/^console\.error\('//;
    $inner =~ s/'\)$//;
    unlike($inner, qr/(?<!\\)'/, 'quotes properly escaped');
}

# === format_js_console with newlines ===
{
    my $err = {
        message => "line1\nline2",
        context => 'newline',
        trace   => [{ sub => 'Foo::bar', file => 'Foo.pm', line => 1, package => 'Foo' }],
        time    => time(),
    };
    my $js = Chandra::Error->format_js_console($err);
    unlike($js, qr/(?<!\\)\n/, 'no raw newlines in JS output');
    like($js, qr/\\n/, 'newlines escaped');
}

# === format_text with empty trace ===
{
    my $err = {
        message => 'no trace',
        context => 'empty',
        trace   => [],
        time    => time(),
    };
    my $text = Chandra::Error->format_text($err);
    like($text, qr/\[Chandra::empty\] no trace/, 'format with empty trace');
    unlike($text, qr/\n/, 'no newlines when trace is empty');
}

# === format_text with undef sub in frame ===
{
    my $err = {
        message => 'no sub',
        context => 'test',
        trace   => [{ sub => undef, file => 'test.pl', line => 5, package => 'main' }],
        time    => time(),
    };
    my $text = Chandra::Error->format_text($err);
    like($text, qr/\(main\) at test\.pl line 5/, 'undef sub shows as (main)');
}

# === stack_trace with skip=0 gets caller info ===
{
    sub _skip0_trace {
        return Chandra::Error->stack_trace(0);
    }
    my $trace = _skip0_trace();
    ok(scalar @$trace >= 1, 'skip=0 returns frames');
}

# === stack_trace with high skip returns empty ===
{
    my $trace = Chandra::Error->stack_trace(1000);
    is_deeply($trace, [], 'very high skip returns empty trace');
}

# === stack_trace caps at 10 frames ===
{
    # Create a deep call stack
    sub _deep {
        my ($n) = @_;
        return $n <= 0 ? Chandra::Error->stack_trace(0) : _deep($n - 1);
    }
    my $trace = _deep(20);
    ok(scalar @$trace <= 10, 'stack_trace capped at 10 frames');
    is(scalar @$trace, 10, 'exactly 10 frames from deep stack');
}

# === capture strips trailing whitespace from error ===
{
    Chandra::Error->clear_handlers;
    my $err = Chandra::Error->capture("error with trailing spaces   \n\n");
    is($err->{message}, 'error with trailing spaces', 'trailing whitespace stripped');
}

# === capture with multiline error ===
{
    Chandra::Error->clear_handlers;
    my $err = Chandra::Error->capture("first line\nsecond line");
    is($err->{message}, "first line\nsecond line", 'multiline error preserved (minus trailing)');
}

# === capture default context is 'unknown' ===
{
    Chandra::Error->clear_handlers;
    my $err = Chandra::Error->capture("test error");
    is($err->{context}, 'unknown', 'default context is unknown');
}

# === capture with custom skip ===
{
    Chandra::Error->clear_handlers;
    sub _outer {
        sub _inner {
            return Chandra::Error->capture("inner error", skip => 0);
        }
        return _inner();
    }
    my $err = _outer();
    ok(scalar @{$err->{trace}} >= 1, 'custom skip produces trace');
}

# === capture with die object (blessed reference) ===
{
    Chandra::Error->clear_handlers;
    {
        package MyException;
        use overload '""' => sub { "MyException: " . $_[0]->{msg} };
        sub new { bless { msg => $_[1] }, $_[0] }
    }
    eval { die MyException->new("test exception") };
    my $err = Chandra::Error->capture($@, context => 'blessed');
    like($err->{message}, qr/MyException: test exception/, 'blessed object stringified');
}

# === on_error ignores non-coderef ===
{
    Chandra::Error->clear_handlers;
    Chandra::Error->on_error('not a coderef');
    Chandra::Error->on_error(undef);
    Chandra::Error->on_error([]);
    is(scalar @{Chandra::Error->handlers}, 0, 'non-coderef handlers ignored');
}

# === handlers returns reference to internal array ===
{
    Chandra::Error->clear_handlers;
    Chandra::Error->on_error(sub { 1 });
    my $handlers = Chandra::Error->handlers;
    is(ref $handlers, 'ARRAY', 'handlers returns arrayref');
    is(scalar @$handlers, 1, 'one handler registered');
    Chandra::Error->clear_handlers;
}

# === multiple handlers called in order ===
{
    Chandra::Error->clear_handlers;
    my @order;
    Chandra::Error->on_error(sub { push @order, 1 });
    Chandra::Error->on_error(sub { push @order, 2 });
    Chandra::Error->on_error(sub { push @order, 3 });

    Chandra::Error->capture("ordering test");
    is_deeply(\@order, [1, 2, 3], 'handlers called in registration order');
    Chandra::Error->clear_handlers;
}

# === capture returns err even with no handlers ===
{
    Chandra::Error->clear_handlers;
    my $err = Chandra::Error->capture("no handlers");
    ok($err, 'capture returns result with no handlers');
    is($err->{message}, 'no handlers', 'message correct');
}

# === time field is reasonable ===
{
    Chandra::Error->clear_handlers;
    my $before = time();
    my $err = Chandra::Error->capture("time test");
    my $after = time();
    ok($err->{time} >= $before, 'time >= before capture');
    ok($err->{time} <= $after, 'time <= after capture');
}

# === format_text with undef trace ===
{
    my $err = {
        message => 'no trace key',
        context => 'test',
        trace   => undef,
        time    => time(),
    };
    my $text = Chandra::Error->format_text($err);
    like($text, qr/no trace key/, 'format_text handles undef trace');
}

done_testing;
