#!perl

=head1 NAME

MY::Tests - run Class::Tiny::ConstrainedAccessor tests on a given class

=head1 SYNOPSIS

These are common test routines that can be used with various type systems.
The class under test must have the following attributes:

    regular             Unrestricted member, default undef
    medint              Constrained to numbers 10..19, no default
    med_with_default    Constrained as medint; default 12
    lazy_default        Constrained as medint; default 19

=cut

package MY::Tests;

use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Fatal;

=head1 FUNCTIONS

=head2 test_accessors

Test accessor calls on a newly-constructed object.
Call as C<Tests::test_accessors $instance_of_class_to_test>.

=cut

sub test_accessors {
    my $dut = shift;
    die "Need a class" unless ref $dut or @_;
    diag ref $dut;

    cmp_ok($dut->medint, '==', 15, 'medint stored OK by ctor');
    is($dut->regular, 'hello', 'regular stored OK by ctor');

    if(@_) {    # Check the non-lazy default first
        cmp_ok($dut->med_with_default, '==', 12, 'med_with_default has default value');
        cmp_ok($dut->lazy_default, '==', '19', 'lazy has default value');
        return;
    } else {    # Check the lazy default first
        cmp_ok($dut->lazy_default, '==', '19', 'lazy has default value');
        cmp_ok($dut->med_with_default, '==', 12, 'med_with_default has default value');
    }

    # The non-constrained accessor accepts everything
    is(
        exception { $dut->regular($_) },
        undef,
        'Regular accepts ' . ($_ // 'undef')
    ) foreach (0, 9, 10, 19, 20, 'some string', undef, \*STDOUT);

    # The constrained accessors accept 10..19
    is(
        exception { $dut->medint($_) },
        undef,
        'medint accepts ' . ($_ // 'undef')
    ) foreach (10..19, "10".."19");

    is(
        exception { $dut->med_with_default($_) },
        undef,
        'med_with_default accepts ' . ($_ // 'undef')
    ) foreach (10..19, "10".."19");

    # The constrained accessors reject numbers outside that range
    like(
        exception { $dut->medint($_) },
        qr/./,
        'medint rejects ' . ($_ // 'undef')
    ) foreach (0..9, "0".."9", 20..29, "20".."29");

    like(
        exception { $dut->med_with_default($_) },
        qr/./,
        'med_with_default rejects ' . ($_ // 'undef')
    ) foreach (0..9, "0".."9", 20..29, "20".."29");

    # The constrained accessors reject random stuff
    like(
        exception { $dut->medint($_) },
        qr/./,
        'medint rejects ' . ($_ // 'undef')
    ) foreach ('some string', undef, \*STDOUT);

    like(
        exception { $dut->med_with_default($_) },
        qr/./,
        'med_with_default rejects ' . ($_ // 'undef')
    ) foreach ('some string', undef, \*STDOUT);
} #test_accessors()

=head2 test_construction

Tests constructing an object using given parameters.  Usage:

    Tests::test_construction 'ClassUnderTest', sub { ClassUnderTest->new(@_) };

The parameters are (required) the name of a class, and (optional) a coderef
that returns a new instance created with the given parameters (default C<new()>
in the specified class).  The coderef is for flexibility.

=cut

sub test_construction {
    my $class = shift;
    die "Need a class name" unless $class;
    my $factory = shift // sub { $class->new(@_) };

    # Sanity check: parameters OK
    my $obj = $factory->(regular=>1, medint=>10);
    isa_ok($obj, $class);

    dies_ok { $factory->(regular=>1, medint=>$_) }
        "$class medint=>$_ fails constraint"
        foreach (9, 20, 'oops', '', \*STDOUT);

} #test_construction

1;
