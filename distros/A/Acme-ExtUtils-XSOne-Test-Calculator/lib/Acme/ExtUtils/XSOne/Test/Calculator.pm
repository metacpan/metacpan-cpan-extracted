package Acme::ExtUtils::XSOne::Test::Calculator;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Acme::ExtUtils::XSOne::Test::Calculator', $VERSION);

=head1 NAME

Acme::ExtUtils::XSOne::Test::Calculator - A scientific calculator demonstrating ExtUtils::XSOne

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    # Import functions directly from submodules
    use Acme::ExtUtils::XSOne::Test::Calculator::Basic qw(add subtract multiply divide);
    use Acme::ExtUtils::XSOne::Test::Calculator::Scientific qw(power sqrt_val);
    use Acme::ExtUtils::XSOne::Test::Calculator::Trig qw(sin_val cos_val deg_to_rad);
    use Acme::ExtUtils::XSOne::Test::Calculator::Memory qw(store recall ans clear);

    # Basic arithmetic
    my $sum  = add(2, 3);        # 5
    my $diff = subtract(10, 4);  # 6
    my $prod = multiply(3, 4);   # 12
    my $quot = divide(15, 3);    # 5

    # Scientific functions
    my $pow  = power(2, 10);     # 1024
    my $sqrt = sqrt_val(16);     # 4

    # Trigonometry
    my $sin = sin_val(deg_to_rad(90));  # 1.0

    # Memory functions (shared state across all submodules!)
    store(0, 42);
    my $val  = recall(0);        # 42
    my $last = ans();            # last result from any calculation
    clear();                     # reset all memory and history

    # Or use fully qualified names without importing
    use Acme::ExtUtils::XSOne::Test::Calculator;

    my $pi = Acme::ExtUtils::XSOne::Test::Calculator::pi();
    my $e  = Acme::ExtUtils::XSOne::Test::Calculator::e();

=head1 DESCRIPTION

Acme::ExtUtils::XSOne::Test::Calculator is a demonstration module showing how to use
L<ExtUtils::XSOne> to create a multi-file XS module where all
submodules share C-level state.

=head1 PACKAGES

All submodules support importing functions by name via C<use Module qw(func1 func2)>.

=over 4

=item * L<Acme::ExtUtils::XSOne::Test::Calculator::Basic>

Basic arithmetic: C<add>, C<subtract>, C<multiply>, C<divide>, C<modulo>,
C<negate>, C<absolute>, C<safe_divide>, C<clamp>, C<percent>

=item * L<Acme::ExtUtils::XSOne::Test::Calculator::Scientific>

Scientific operations: C<power>, C<sqrt_val>, C<cbrt_val>, C<nth_root>,
C<log_natural>, C<log10_val>, C<log_base>, C<exp_val>, C<factorial>,
C<ipow>, C<safe_sqrt>, C<safe_log>, C<combination>, C<permutation>

=item * L<Acme::ExtUtils::XSOne::Test::Calculator::Trig>

Trigonometry: C<sin_val>, C<cos_val>, C<tan_val>, C<asin_val>, C<acos_val>,
C<atan_val>, C<atan2_val>, C<deg_to_rad>, C<rad_to_deg>, C<hypot_val>,
C<normalize_angle>, C<sec_val>, C<csc_val>, C<cot_val>, C<is_valid_asin_arg>

=item * L<Acme::ExtUtils::XSOne::Test::Calculator::Memory>

Memory and history: C<store>, C<recall>, C<clear>, C<ans>, C<history_count>,
C<get_history_entry>, C<max_memory_slots>, C<max_history_entries>,
C<is_valid_slot>, C<used_slots>, C<sum_all_slots>, C<add_to>

=back

=head1 SHARED STATE

A key feature of this module is that all submodules share C-level state.
This means:

=over 4

=item * The C<ans()> function returns the last result from I<any> calculation

=item * Memory slots are accessible from all submodules

=item * Calculation history records operations from all submodules

=back

This is made possible by L<ExtUtils::XSOne>, which combines multiple XS
files into a single shared library.

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by lnation.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
