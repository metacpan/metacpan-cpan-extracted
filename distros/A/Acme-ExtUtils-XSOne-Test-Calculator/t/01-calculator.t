#!/usr/bin/env perl
# t/01-calculator.t - Test Acme::ExtUtils::XSOne::Test::Calculator functionality

use strict;
use warnings;
use Test::More;

use_ok('Acme::ExtUtils::XSOne::Test::Calculator');

# =============================================================================
# Test constants
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
# Test Basic operations
# =============================================================================

subtest 'Basic arithmetic' => sub {
    plan tests => 9;

    # Clear any previous state
    Acme::ExtUtils::XSOne::Test::Calculator::Memory::clear();

    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::add(2, 3), 5, 'add(2, 3) = 5');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::add(-5, 3), -2, 'add(-5, 3) = -2');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::subtract(10, 4), 6, 'subtract(10, 4) = 6');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::subtract(3, 7), -4, 'subtract(3, 7) = -4');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::multiply(3, 4), 12, 'multiply(3, 4) = 12');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::multiply(-2, 5), -10, 'multiply(-2, 5) = -10');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::divide(15, 3), 5, 'divide(15, 3) = 5');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::divide(7, 2), 3.5, 'divide(7, 2) = 3.5');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::modulo(17, 5), 2, 'modulo(17, 5) = 2');
};

subtest 'Basic edge cases' => sub {
    plan tests => 12;

    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::negate(5), -5, 'negate(5) = -5');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::negate(-3), 3, 'negate(-3) = 3');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::absolute(-7), 7, 'absolute(-7) = 7');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::absolute(4), 4, 'absolute(4) = 4');

    # Test C helper functions (defined in basic.xs preamble)
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::safe_divide(10, 2), 5, 'safe_divide(10, 2) = 5');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::safe_divide(10, 0), 0, 'safe_divide(10, 0) = 0 (no croak)');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::clamp(5, 0, 10), 5, 'clamp(5, 0, 10) = 5');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::clamp(15, 0, 10), 10, 'clamp(15, 0, 10) = 10');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::clamp(-5, 0, 10), 0, 'clamp(-5, 0, 10) = 0');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::percent(200, 15), 30, 'percent(200, 15) = 30');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::percent(50, 50), 25, 'percent(50, 50) = 25');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Basic::percent(100, 100), 100, 'percent(100, 100) = 100');
};

subtest 'Division by zero' => sub {
    plan tests => 2;

    eval { Acme::ExtUtils::XSOne::Test::Calculator::Basic::divide(5, 0) };
    like($@, qr/Division by zero/, 'divide by zero croaks');

    eval { Acme::ExtUtils::XSOne::Test::Calculator::Basic::modulo(5, 0) };
    like($@, qr/Modulo by zero/, 'modulo by zero croaks');
};

# =============================================================================
# Test Scientific operations
# =============================================================================

subtest 'Scientific functions' => sub {
    plan tests => 14;

    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::power(2, 10), 1024, 'power(2, 10) = 1024');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::power(5, 0), 1, 'power(5, 0) = 1');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::sqrt_val(16), 4, 'sqrt(16) = 4');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::sqrt_val(2), sqrt(2), 'sqrt(2) matches perl sqrt');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::cbrt_val(27), 3, 'cbrt(27) = 3');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::cbrt_val(-8), -2, 'cbrt(-8) = -2');

    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::exp_val(1) - exp(1)) < 0.0001, 'exp(1) = e');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::factorial(5), 120, 'factorial(5) = 120');

    # Test C helper functions (defined in scientific.xs preamble)
    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::ipow(2, 10), 1024, 'ipow(2, 10) = 1024');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::ipow(3, -2), 1/9, 'ipow(3, -2) = 1/9');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::safe_sqrt(16), 4, 'safe_sqrt(16) = 4');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::safe_sqrt(-1), 0, 'safe_sqrt(-1) = 0 (no croak)');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::combination(5, 2), 10, 'combination(5, 2) = 10');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::permutation(5, 2), 20, 'permutation(5, 2) = 20');
};

subtest 'Logarithms' => sub {
    plan tests => 6;

    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::log_natural(exp(1)) - 1) < 0.0001, 'ln(e) = 1');
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::log10_val(100) - 2) < 0.0001, 'log10(100) = 2');
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::log_base(8, 2) - 3) < 0.0001, 'log2(8) = 3');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::nth_root(27, 3), 3, 'nth_root(27, 3) = 3');

    # Test C helper function (defined in scientific.xs preamble)
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::safe_log(exp(1)) - 1) < 0.0001, 'safe_log(e) = 1');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Scientific::safe_log(-1), 0, 'safe_log(-1) = 0 (no croak)');
};

subtest 'Scientific error handling' => sub {
    plan tests => 3;

    eval { Acme::ExtUtils::XSOne::Test::Calculator::Scientific::sqrt_val(-1) };
    like($@, qr/negative/, 'sqrt of negative croaks');

    eval { Acme::ExtUtils::XSOne::Test::Calculator::Scientific::log_natural(-1) };
    like($@, qr/non-positive/, 'log of negative croaks');

    eval { Acme::ExtUtils::XSOne::Test::Calculator::Scientific::factorial(-1) };
    like($@, qr/negative/, 'factorial of negative croaks');
};

# =============================================================================
# Test Trig operations
# =============================================================================

subtest 'Trigonometric functions' => sub {
    plan tests => 14;

    my $pi = Acme::ExtUtils::XSOne::Test::Calculator::pi();

    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::sin_val(0)) < 0.0001, 'sin(0) = 0');
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::sin_val($pi/2) - 1) < 0.0001, 'sin(pi/2) = 1');

    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::cos_val(0) - 1) < 0.0001, 'cos(0) = 1');
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::cos_val($pi) - (-1)) < 0.0001, 'cos(pi) = -1');

    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::tan_val(0)) < 0.0001, 'tan(0) = 0');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Trig::hypot_val(3, 4), 5, 'hypot(3, 4) = 5');

    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::deg_to_rad(180) - $pi) < 0.0001, 'deg_to_rad(180) = pi');

    # Test C helper functions (defined in trig.xs preamble)
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::normalize_angle(3 * $pi) - $pi) < 0.0001, 'normalize_angle(3*pi) = pi');
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::normalize_angle(-3 * $pi) - (-$pi)) < 0.0001, 'normalize_angle(-3*pi) = -pi');

    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::sec_val(0) - 1) < 0.0001, 'sec(0) = 1');
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::csc_val($pi/2) - 1) < 0.0001, 'csc(pi/2) = 1');
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::cot_val($pi/4) - 1) < 0.0001, 'cot(pi/4) = 1');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Trig::is_valid_asin_arg(0.5), 1, 'is_valid_asin_arg(0.5) = 1');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Trig::is_valid_asin_arg(2.0), 0, 'is_valid_asin_arg(2.0) = 0');
};

subtest 'Inverse trig' => sub {
    plan tests => 3;

    my $pi = Acme::ExtUtils::XSOne::Test::Calculator::pi();

    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::asin_val(1) - $pi/2) < 0.0001, 'asin(1) = pi/2');
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::acos_val(0) - $pi/2) < 0.0001, 'acos(0) = pi/2');
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Trig::atan_val(1) - $pi/4) < 0.0001, 'atan(1) = pi/4');
};

# =============================================================================
# Test Memory - THIS IS THE KEY TEST FOR SHARED STATE!
# =============================================================================

subtest 'Memory operations' => sub {
    plan tests => 13;

    Acme::ExtUtils::XSOne::Test::Calculator::Memory::clear();

    ok(Acme::ExtUtils::XSOne::Test::Calculator::Memory::store(0, 42), 'store(0, 42) succeeds');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::recall(0), 42, 'recall(0) = 42');

    ok(Acme::ExtUtils::XSOne::Test::Calculator::Memory::store(5, 3.14), 'store(5, 3.14) succeeds');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::recall(5), 3.14, 'recall(5) = 3.14');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::max_memory_slots(), 10, 'max_memory_slots = 10');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::max_history_entries(), 100, 'max_history_entries = 100');

    # Test C helper functions (defined in _header.xs, exposed via memory.xs)
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::is_valid_slot(5), 1, 'is_valid_slot(5) = 1');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::is_valid_slot(-1), 0, 'is_valid_slot(-1) = 0');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::is_valid_slot(10), 0, 'is_valid_slot(10) = 0');

    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::used_slots(), 2, 'used_slots() = 2 (slots 0 and 5)');

    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Memory::sum_all_slots() - (42 + 3.14)) < 0.0001, 'sum_all_slots() = 45.14');

    Acme::ExtUtils::XSOne::Test::Calculator::Memory::add_to(0, 8);
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::recall(0), 50, 'add_to(0, 8) makes slot 0 = 50');

    Acme::ExtUtils::XSOne::Test::Calculator::Memory::add_to(1, 100);
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::recall(1), 100, 'add_to empty slot sets value');
};

subtest 'Shared state - ans() tracks last result' => sub {
    plan tests => 5;

    # This test proves that all modules share the same C static variables
    Acme::ExtUtils::XSOne::Test::Calculator::Memory::clear();

    # Do a calculation in Basic
    my $result1 = Acme::ExtUtils::XSOne::Test::Calculator::Basic::add(10, 20);
    is($result1, 30, 'add(10, 20) = 30');

    # Check that Memory::ans() sees the result
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::ans(), 30, 'ans() returns 30 after Basic::add');

    # Do a calculation in Scientific
    my $result2 = Acme::ExtUtils::XSOne::Test::Calculator::Scientific::power(2, 8);
    is($result2, 256, 'power(2, 8) = 256');

    # ans() should now return 256
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::ans(), 256, 'ans() returns 256 after Scientific::power');

    # Do a trig calculation
    Acme::ExtUtils::XSOne::Test::Calculator::Trig::sin_val(0);
    ok(abs(Acme::ExtUtils::XSOne::Test::Calculator::Memory::ans()) < 0.0001, 'ans() returns ~0 after Trig::sin_val(0)');
};

subtest 'History tracking across modules' => sub {
    plan tests => 4;

    Acme::ExtUtils::XSOne::Test::Calculator::Memory::clear();

    # Perform calculations across different modules
    Acme::ExtUtils::XSOne::Test::Calculator::Basic::add(1, 2);
    Acme::ExtUtils::XSOne::Test::Calculator::Scientific::sqrt_val(4);
    Acme::ExtUtils::XSOne::Test::Calculator::Trig::sin_val(0);
    Acme::ExtUtils::XSOne::Test::Calculator::Basic::multiply(3, 4);

    # History should have 4 entries
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::history_count(), 4, 'history has 4 entries');

    # Check first entry (add)
    my @entry = Acme::ExtUtils::XSOne::Test::Calculator::Memory::get_history_entry(0);
    is($entry[0], '+', 'first operation was +');
    is($entry[3], 3, 'first result was 3');

    # Check last entry (multiply)
    @entry = Acme::ExtUtils::XSOne::Test::Calculator::Memory::get_history_entry(3);
    is($entry[3], 12, 'last result was 12');
};

# =============================================================================
# Test that clear() resets everything
# =============================================================================

subtest 'Clear resets all state' => sub {
    plan tests => 4;

    # Set up some state
    Acme::ExtUtils::XSOne::Test::Calculator::Memory::store(0, 999);
    Acme::ExtUtils::XSOne::Test::Calculator::Basic::add(1, 1);

    # Clear
    Acme::ExtUtils::XSOne::Test::Calculator::Memory::clear();

    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::recall(0), 0, 'memory slot cleared');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::ans(), 0, 'ans() cleared');
    is(Acme::ExtUtils::XSOne::Test::Calculator::Memory::history_count(), 0, 'history cleared');

    # Memory should still work
    ok(Acme::ExtUtils::XSOne::Test::Calculator::Memory::store(0, 123), 'can store after clear');
};

done_testing();
