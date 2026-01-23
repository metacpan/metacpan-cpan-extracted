#!/usr/bin/env perl
# t/02-import.t - Test import functionality for Calculator submodules

use strict;
use warnings;
use Test::More;

# =============================================================================
# Test importing functions from each submodule
# =============================================================================

use_ok('Acme::ExtUtils::XSOne::Test::Calculator::Basic', qw(add subtract multiply divide modulo negate absolute safe_divide clamp percent));
use_ok('Acme::ExtUtils::XSOne::Test::Calculator::Scientific', qw(power sqrt_val cbrt_val nth_root log_natural log10_val log_base exp_val factorial ipow safe_sqrt safe_log combination permutation));
use_ok('Acme::ExtUtils::XSOne::Test::Calculator::Trig', qw(sin_val cos_val tan_val asin_val acos_val atan_val atan2_val deg_to_rad rad_to_deg hypot_val normalize_angle sec_val csc_val cot_val is_valid_asin_arg));
use_ok('Acme::ExtUtils::XSOne::Test::Calculator::Memory', qw(store recall clear ans history_count get_history_entry max_memory_slots max_history_entries is_valid_slot used_slots sum_all_slots add_to));

# Also load the main module for constants
use Acme::ExtUtils::XSOne::Test::Calculator;

# =============================================================================
# Test constants (using fully qualified - not exported)
# =============================================================================

subtest 'Constants' => sub {
    plan tests => 3;

    my $pi = Acme::ExtUtils::XSOne::Test::Calculator::pi();
    ok(abs($pi - 3.14159265358979) < 0.0001, 'pi is approximately correct');

    my $e = Acme::ExtUtils::XSOne::Test::Calculator::e();
    ok(abs($e - 2.71828182845905) < 0.0001, 'e is approximately correct');

    is(Acme::ExtUtils::XSOne::Test::Calculator::version(), '0.01', 'version returns correct value');
};

# =============================================================================
# Test Basic operations (using imported functions)
# =============================================================================

subtest 'Basic arithmetic' => sub {
    plan tests => 9;

    # Clear any previous state
    clear();

    is(add(2, 3), 5, 'add(2, 3) = 5');
    is(add(-5, 3), -2, 'add(-5, 3) = -2');

    is(subtract(10, 4), 6, 'subtract(10, 4) = 6');
    is(subtract(3, 7), -4, 'subtract(3, 7) = -4');

    is(multiply(3, 4), 12, 'multiply(3, 4) = 12');
    is(multiply(-2, 5), -10, 'multiply(-2, 5) = -10');

    is(divide(15, 3), 5, 'divide(15, 3) = 5');
    is(divide(7, 2), 3.5, 'divide(7, 2) = 3.5');

    is(modulo(17, 5), 2, 'modulo(17, 5) = 2');
};

subtest 'Basic edge cases' => sub {
    plan tests => 12;

    is(negate(5), -5, 'negate(5) = -5');
    is(negate(-3), 3, 'negate(-3) = 3');

    is(absolute(-7), 7, 'absolute(-7) = 7');
    is(absolute(4), 4, 'absolute(4) = 4');

    is(safe_divide(10, 2), 5, 'safe_divide(10, 2) = 5');
    is(safe_divide(10, 0), 0, 'safe_divide(10, 0) = 0 (no croak)');

    is(clamp(5, 0, 10), 5, 'clamp(5, 0, 10) = 5');
    is(clamp(15, 0, 10), 10, 'clamp(15, 0, 10) = 10');
    is(clamp(-5, 0, 10), 0, 'clamp(-5, 0, 10) = 0');

    is(percent(200, 15), 30, 'percent(200, 15) = 30');
    is(percent(50, 50), 25, 'percent(50, 50) = 25');
    is(percent(100, 100), 100, 'percent(100, 100) = 100');
};

subtest 'Division by zero' => sub {
    plan tests => 2;

    eval { divide(5, 0) };
    like($@, qr/Division by zero/, 'divide by zero croaks');

    eval { modulo(5, 0) };
    like($@, qr/Modulo by zero/, 'modulo by zero croaks');
};

# =============================================================================
# Test Scientific operations (using imported functions)
# =============================================================================

subtest 'Scientific functions' => sub {
    plan tests => 14;

    is(power(2, 10), 1024, 'power(2, 10) = 1024');
    is(power(5, 0), 1, 'power(5, 0) = 1');

    is(sqrt_val(16), 4, 'sqrt(16) = 4');
    is(sqrt_val(2), sqrt(2), 'sqrt(2) matches perl sqrt');

    is(cbrt_val(27), 3, 'cbrt(27) = 3');
    is(cbrt_val(-8), -2, 'cbrt(-8) = -2');

    ok(abs(exp_val(1) - exp(1)) < 0.0001, 'exp(1) = e');

    is(factorial(5), 120, 'factorial(5) = 120');

    is(ipow(2, 10), 1024, 'ipow(2, 10) = 1024');
    is(ipow(3, -2), 1/9, 'ipow(3, -2) = 1/9');

    is(safe_sqrt(16), 4, 'safe_sqrt(16) = 4');
    is(safe_sqrt(-1), 0, 'safe_sqrt(-1) = 0 (no croak)');

    is(combination(5, 2), 10, 'combination(5, 2) = 10');
    is(permutation(5, 2), 20, 'permutation(5, 2) = 20');
};

subtest 'Logarithms' => sub {
    plan tests => 6;

    ok(abs(log_natural(exp(1)) - 1) < 0.0001, 'ln(e) = 1');
    ok(abs(log10_val(100) - 2) < 0.0001, 'log10(100) = 2');
    ok(abs(log_base(8, 2) - 3) < 0.0001, 'log2(8) = 3');

    is(nth_root(27, 3), 3, 'nth_root(27, 3) = 3');

    ok(abs(safe_log(exp(1)) - 1) < 0.0001, 'safe_log(e) = 1');
    is(safe_log(-1), 0, 'safe_log(-1) = 0 (no croak)');
};

subtest 'Scientific error handling' => sub {
    plan tests => 3;

    eval { sqrt_val(-1) };
    like($@, qr/negative/, 'sqrt of negative croaks');

    eval { log_natural(-1) };
    like($@, qr/non-positive/, 'log of negative croaks');

    eval { factorial(-1) };
    like($@, qr/negative/, 'factorial of negative croaks');
};

# =============================================================================
# Test Trig operations (using imported functions)
# =============================================================================

subtest 'Trigonometric functions' => sub {
    plan tests => 14;

    my $pi = Acme::ExtUtils::XSOne::Test::Calculator::pi();

    ok(abs(sin_val(0)) < 0.0001, 'sin(0) = 0');
    ok(abs(sin_val($pi/2) - 1) < 0.0001, 'sin(pi/2) = 1');

    ok(abs(cos_val(0) - 1) < 0.0001, 'cos(0) = 1');
    ok(abs(cos_val($pi) - (-1)) < 0.0001, 'cos(pi) = -1');

    ok(abs(tan_val(0)) < 0.0001, 'tan(0) = 0');

    is(hypot_val(3, 4), 5, 'hypot(3, 4) = 5');

    ok(abs(deg_to_rad(180) - $pi) < 0.0001, 'deg_to_rad(180) = pi');

    ok(abs(normalize_angle(3 * $pi) - $pi) < 0.0001, 'normalize_angle(3*pi) = pi');
    ok(abs(normalize_angle(-3 * $pi) - (-$pi)) < 0.0001, 'normalize_angle(-3*pi) = -pi');

    ok(abs(sec_val(0) - 1) < 0.0001, 'sec(0) = 1');
    ok(abs(csc_val($pi/2) - 1) < 0.0001, 'csc(pi/2) = 1');
    ok(abs(cot_val($pi/4) - 1) < 0.0001, 'cot(pi/4) = 1');

    is(is_valid_asin_arg(0.5), 1, 'is_valid_asin_arg(0.5) = 1');
    is(is_valid_asin_arg(2.0), 0, 'is_valid_asin_arg(2.0) = 0');
};

subtest 'Inverse trig' => sub {
    plan tests => 3;

    my $pi = Acme::ExtUtils::XSOne::Test::Calculator::pi();

    ok(abs(asin_val(1) - $pi/2) < 0.0001, 'asin(1) = pi/2');
    ok(abs(acos_val(0) - $pi/2) < 0.0001, 'acos(0) = pi/2');
    ok(abs(atan_val(1) - $pi/4) < 0.0001, 'atan(1) = pi/4');
};

# =============================================================================
# Test Memory (using imported functions)
# =============================================================================

subtest 'Memory operations' => sub {
    plan tests => 13;

    clear();

    ok(store(0, 42), 'store(0, 42) succeeds');
    is(recall(0), 42, 'recall(0) = 42');

    ok(store(5, 3.14), 'store(5, 3.14) succeeds');
    is(recall(5), 3.14, 'recall(5) = 3.14');

    is(max_memory_slots(), 10, 'max_memory_slots = 10');
    is(max_history_entries(), 100, 'max_history_entries = 100');

    is(is_valid_slot(5), 1, 'is_valid_slot(5) = 1');
    is(is_valid_slot(-1), 0, 'is_valid_slot(-1) = 0');
    is(is_valid_slot(10), 0, 'is_valid_slot(10) = 0');

    is(used_slots(), 2, 'used_slots() = 2 (slots 0 and 5)');

    ok(abs(sum_all_slots() - (42 + 3.14)) < 0.0001, 'sum_all_slots() = 45.14');

    add_to(0, 8);
    is(recall(0), 50, 'add_to(0, 8) makes slot 0 = 50');

    add_to(1, 100);
    is(recall(1), 100, 'add_to empty slot sets value');
};

subtest 'Shared state - ans() tracks last result' => sub {
    plan tests => 5;

    # This test proves that all modules share the same C static variables
    clear();

    # Do a calculation in Basic
    my $result1 = add(10, 20);
    is($result1, 30, 'add(10, 20) = 30');

    # Check that ans() sees the result
    is(ans(), 30, 'ans() returns 30 after add');

    # Do a calculation in Scientific
    my $result2 = power(2, 8);
    is($result2, 256, 'power(2, 8) = 256');

    # ans() should now return 256
    is(ans(), 256, 'ans() returns 256 after power');

    # Do a trig calculation
    sin_val(0);
    ok(abs(ans()) < 0.0001, 'ans() returns ~0 after sin_val(0)');
};

subtest 'History tracking across modules' => sub {
    plan tests => 4;

    clear();

    # Perform calculations across different modules
    add(1, 2);
    sqrt_val(4);
    sin_val(0);
    multiply(3, 4);

    # History should have 4 entries
    is(history_count(), 4, 'history has 4 entries');

    # Check first entry (add)
    my @entry = get_history_entry(0);
    is($entry[0], '+', 'first operation was +');
    is($entry[3], 3, 'first result was 3');

    # Check last entry (multiply)
    @entry = get_history_entry(3);
    is($entry[3], 12, 'last result was 12');
};

# =============================================================================
# Test that clear() resets everything
# =============================================================================

subtest 'Clear resets all state' => sub {
    plan tests => 4;

    # Set up some state
    store(0, 999);
    add(1, 1);

    # Clear
    clear();

    is(recall(0), 0, 'memory slot cleared');
    is(ans(), 0, 'ans() cleared');
    is(history_count(), 0, 'history cleared');

    # Memory should still work
    ok(store(0, 123), 'can store after clear');
};

# =============================================================================
# Test invalid import
# =============================================================================

subtest 'Invalid import croaks' => sub {
    plan tests => 1;

    eval {
        Acme::ExtUtils::XSOne::Test::Calculator::Basic->import('nonexistent_function');
    };
    like($@, qr/not exported/, 'importing nonexistent function croaks');
};

done_testing();
