package App::VitaminUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-03'; # DATE
our $DIST = 'App-VitaminUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %args_common = (
    quantity => {
        # schema => 'physical::mass*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
        schema => 'str*',
        req => 1,
        pos => 0,
    },
    to_unit => {
        # schema => 'physical::unit', # IU hasn't been added
        schema => 'str*',
        pos => 1,
    },
);

$SPEC{convert_vitamin_a_unit} = {
    v => 1.1,
    summary => 'Convert a vitamin A quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %args_common,
    },
    examples => [
        {args=>{quantity=>'mcg'}, summary=>'Show all possible conversions'},
        {args=>{quantity=>'1500 mcg', to_unit=>'IU'}, summary=>'Convert from mcg to IU (retinol)'},
        {args=>{quantity=>'1500 mcg', to_unit=>'IU-retinol'}, summary=>'Convert from mcg to IU (retinol)'},
        {args=>{quantity=>'1500 mcg', to_unit=>'IU-beta-carotene'}, summary=>'Convert from mcg to IU (beta-carotene)'},
        {args=>{quantity=>'5000 IU', to_unit=>'mg'}, summary=>'Convert from IU to mg'},
    ],
};
sub convert_vitamin_a_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        ['mcg'], '0.001 mg',
        ['mcg-all-trans-retinol'], '1 mcg',
        ['mcg-dietary-all-trans-beta-carotene'],            '0.083333333 mcg', # 1/12
        ['mcg-alpha-carotene'],                             '0.041666667 mcg', # 1/24
        ['mcg-beta-cryptoxanthin'],                         '0.041666667 mcg', # 1/24
        ['mcg-all-trans-beta-carotene-as-food-supplement'], '0.5 mcg',
        ['IU', 'iu'], '0.3 microgram',
        ['IU-retinol', 'iu-retinol'], '0.3 microgram',
        ['IU-beta-carotene', 'iu-beta-carotene'], '0.6 microgram',
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Mass quantity"] unless $quantity->type eq 'Mass';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u (
            'mg', 'mcg',
            'mcg-all-trans-retinol',
            'mcg-dietary-all-trans-beta-carotene',
            'mcg-alpha-carotene',
            'mcg-beta-cryptoxanthin',
            'mcg-all-trans-beta-carotene-as-food-supplement',
            'IU',
            'IU-retinol',
            'IU-beta-carotene') {
            push @rows, {
                unit => $u,
                amount => $quantity->convert($u),
            };
        }
        [200, "OK", \@rows];
    }
}

$SPEC{convert_vitamin_d_unit} = {
    v => 1.1,
    summary => 'Convert a vitamin D quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %args_common,
    },
    examples => [
        {args=>{quantity=>'mcg'}, summary=>'Show all possible conversions'},
        {args=>{quantity=>'2 mcg', to_unit=>'IU'}, summary=>'Convert from mcg to IU'},
        {args=>{quantity=>'5000 IU', to_unit=>'mg'}, summary=>'Convert from IU to mg'},
    ],
};
sub convert_vitamin_d_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        ['mcg'], '0.001 mg',
        ['IU', 'iu'], '0.025 microgram',
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Mass quantity"] unless $quantity->type eq 'Mass';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u ('mcg', 'mg', 'IU') {
            push @rows, {
                unit => $u,
                amount => $quantity->convert($u),
            };
        }
        [200, "OK", \@rows];
    }
}

$SPEC{convert_vitamin_e_unit} = {
    v => 1.1,
    summary => 'Convert a vitamin E quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %args_common,
    },
    examples => [
        {args=>{quantity=>'mg'}, summary=>'Show all possible conversions'},
        {args=>{quantity=>'67 mg', to_unit=>'IU'}, summary=>'Convert from mg to IU (d-alpha-tocopherol/natural vitamin E)'},
        {args=>{quantity=>'67 mg', to_unit=>'IU-natural'}, summary=>'Convert from mg to IU (d-alpha-tocopherol/natural vitamin E)'},
        {args=>{quantity=>'90 mg', to_unit=>'IU-synthetic'}, summary=>'Convert from mg to IU (dl-alpha-tocopherol/synthetic vitamin E)'},
        {args=>{quantity=>'400 IU', to_unit=>'mg'}, summary=>'Convert from IU to mg'},
    ],
};
sub convert_vitamin_e_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        ['mcg'], '0.001 mg',
        ['mg-alpha-tocopherol-equivalent', 'mcg-alpha-TE'], '1 mg',
        ['mg-rrr-alpha-tocopherol'], '1 mg',
        ['mg-rrr-alpha-tocopherol'], '1 mg',
        ['mg-beta-tocopherol'], '0.5 mg',
        ['mg-gamma-tocopherol'], '0.1 mg',
        ['mg-alpha-tocotrienol'], '0.30 mg',
        ['IU', 'iu'], '0.67 mg',
        ['IU-natural', 'iu-natural'], '0.67 mg',
        ['IU-synthetic', 'iu-synthetic'], '0.9 mg',
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Mass quantity"] unless $quantity->type eq 'Mass';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u (
            'mg',
            'mcg',
            'mg-alpha-tocopherol-equivalent',
            'mg-rrr-alpha-tocopherol',
            'mg-rrr-alpha-tocopherol',
            'mg-beta-tocopherol',
            'mg-gamma-tocopherol',
            'mg-alpha-tocotrienol',
            'IU',
            'IU-natural',
            'IU-synthetic') {
            push @rows, {
                unit => $u,
                amount => $quantity->convert($u),
            };
        }
        [200, "OK", \@rows];
    }
}

1;
# ABSTRACT: Utilities related to vitamins

__END__

=pod

=encoding UTF-8

=head1 NAME

App::VitaminUtils - Utilities related to vitamins

=head1 VERSION

This document describes version 0.002 of App::VitaminUtils (from Perl distribution App-VitaminUtils), released on 2020-11-03.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<convert-vitamin-a-unit>

=item * L<convert-vitamin-d-unit>

=item * L<convert-vitamin-e-unit>

=back

=head1 FUNCTIONS


=head2 convert_vitamin_a_unit

Usage:

 convert_vitamin_a_unit(%args) -> [status, msg, payload, meta]

Convert a vitamin A quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_vitamin_a_unit(quantity => "mcg");

Result:

 [
   200,
   "OK",
   [
     { amount => 0.001, unit => "mg" },
     { amount => 1, unit => "mcg" },
     { amount => 1, unit => "mcg-all-trans-retinol" },
     {
       amount => 12.000000048,
       unit   => "mcg-dietary-all-trans-beta-carotene",
     },
     { amount => 23.999999808, unit => "mcg-alpha-carotene" },
     { amount => 23.999999808, unit => "mcg-beta-cryptoxanthin" },
     {
       amount => 2,
       unit   => "mcg-all-trans-beta-carotene-as-food-supplement",
     },
     { amount => 3.33333333333333, unit => "IU" },
     { amount => 3.33333333333333, unit => "IU-retinol" },
     { amount => 1.66666666666667, unit => "IU-beta-carotene" },
   ],
   {},
 ]

=item * Convert from mcg to IU (retinol):

 convert_vitamin_a_unit(quantity => "1500 mcg", to_unit => "IU"); # -> [200, "OK", 5000, {}]

=item * Convert from mcg to IU (retinol):

 convert_vitamin_a_unit(quantity => "1500 mcg", to_unit => "IU-retinol"); # -> [200, "OK", 5000, {}]

=item * Convert from mcg to IU (beta-carotene):

 convert_vitamin_a_unit(quantity => "1500 mcg", to_unit => "IU-beta-carotene"); # -> [200, "OK", 2500, {}]

=item * Convert from IU to mg:

 convert_vitamin_a_unit(quantity => "5000 IU", to_unit => "mg"); # -> [200, "OK", 1.5, {}]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity>* => I<str>

=item * B<to_unit> => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 convert_vitamin_d_unit

Usage:

 convert_vitamin_d_unit(%args) -> [status, msg, payload, meta]

Convert a vitamin D quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_vitamin_d_unit(quantity => "mcg");

Result:

 [
   200,
   "OK",
   [
     { amount => 1, unit => "mcg" },
     { amount => 0.001, unit => "mg" },
     { amount => 40, unit => "IU" },
   ],
   {},
 ]

=item * Convert from mcg to IU:

 convert_vitamin_d_unit(quantity => "2 mcg", to_unit => "IU"); # -> [200, "OK", 80, {}]

=item * Convert from IU to mg:

 convert_vitamin_d_unit(quantity => "5000 IU", to_unit => "mg"); # -> [200, "OK", 0.125, {}]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity>* => I<str>

=item * B<to_unit> => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 convert_vitamin_e_unit

Usage:

 convert_vitamin_e_unit(%args) -> [status, msg, payload, meta]

Convert a vitamin E quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_vitamin_e_unit(quantity => "mg");

Result:

 [
   200,
   "OK",
   [
     { amount => 1, unit => "mg" },
     { amount => 1000, unit => "mcg" },
     { amount => 1, unit => "mg-alpha-tocopherol-equivalent" },
     { amount => 1, unit => "mg-rrr-alpha-tocopherol" },
     { amount => 1, unit => "mg-rrr-alpha-tocopherol" },
     { amount => 2, unit => "mg-beta-tocopherol" },
     { amount => 10, unit => "mg-gamma-tocopherol" },
     { amount => 3.33333333333333, unit => "mg-alpha-tocotrienol" },
     { amount => 1.49253731343284, unit => "IU" },
     { amount => 1.49253731343284, unit => "IU-natural" },
     { amount => 1.11111111111111, unit => "IU-synthetic" },
   ],
   {},
 ]

=item * Convert from mg to IU (d-alpha-tocopherolE<sol>natural vitamin E):

 convert_vitamin_e_unit(quantity => "67 mg", to_unit => "IU"); # -> [200, "OK", 100, {}]

=item * Convert from mg to IU (d-alpha-tocopherolE<sol>natural vitamin E):

 convert_vitamin_e_unit(quantity => "67 mg", to_unit => "IU-natural"); # -> [200, "OK", 100, {}]

=item * Convert from mg to IU (dl-alpha-tocopherolE<sol>synthetic vitamin E):

 convert_vitamin_e_unit(quantity => "90 mg", to_unit => "IU-synthetic"); # -> [200, "OK", 100, {}]

=item * Convert from IU to mg:

 convert_vitamin_e_unit(quantity => "400 IU", to_unit => "mg"); # -> [200, "OK", 268, {}]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity>* => I<str>

=item * B<to_unit> => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-VitaminUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-VitaminUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-VitaminUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Physics::Unit>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
