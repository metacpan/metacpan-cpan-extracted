package App::VitaminUtils;

use 5.010001;
use strict;
use warnings;

use Capture::Tiny 'capture_stderr';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-14'; # DATE
our $DIST = 'App-VitaminUtils'; # DIST
our $VERSION = '0.006'; # VERSION

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
        ['mcg-all-trans-beta-carotene-as-food-supplement'], '0.5 mcg',
        ['mcg-all-trans-retinol'], '1 mcg',
        ['mcg-all-trans-retinyl-acetate'], '0.872180241224122 mcg',            # https://www.rfaregulatoryaffairs.com/vitamin-converter: 1mg all-trans-retinyl-acetate = 2906.976744IU, 1mg all-trans-retinol = 3333IU
        ['mcg-all-trans-retinyl-palmitate'], '0.545454545454545 mcg',          # "1 IU corresponds to the activity of 0.300  g of all-trans retinol, 0.359  g of all-trans retinyl propionate or 0.550  g of all-trans retinyl palmitate"
        ['mcg-all-trans-retinyl-propionate'], '0.835654596100279 mcg',         # "1 IU corresponds to the activity of 0.300  g of all-trans retinol, 0.359  g of all-trans retinyl propionate or 0.550  g of all-trans retinyl palmitate"
        ['mcg-alpha-carotene'],                             '0.041666667 mcg', # 1/24
        ['mcg-beta-cryptoxanthin'],                         '0.041666667 mcg', # 1/24
        ['mcg-dietary-all-trans-beta-carotene'],            '0.083333333 mcg', # 1/12
        ['IU', 'iu'], '0.3 microgram', # definition from European pharmacopoeia
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
            'mcg-all-trans-retinyl-acetate',
            'mcg-all-trans-retinyl-palmitate',
            'mcg-all-trans-retinyl-propionate',
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

$SPEC{convert_vitamin_b5_unit} = {
    v => 1.1,
    summary => 'Convert a vitamin B5 (pantothenic acid) quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %args_common,
    },
    examples => [
        {args=>{quantity=>'mg'}, summary=>'Show all possible conversions'},
    ],
};
sub convert_vitamin_b5_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        ['mg-pantothenic-acid'], '1 mg',
        ['mg-d-calcium-pantothenate'], '0.916 mg', # https://www.rfaregulatoryaffairs.com/vitamin-converter
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
            'mg-pantothenic-acid',
            'mg-d-calcium-pantothenate',
        ) {
            push @rows, {
                unit => $u,
                amount => $quantity->convert($u),
            };
        }
        [200, "OK", \@rows];
    }
}

$SPEC{convert_vitamin_b6_unit} = {
    v => 1.1,
    summary => 'Convert a vitamin B6 (pyridoxine) quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %args_common,
    },
    examples => [
        {args=>{quantity=>'mg'}, summary=>'Show all possible conversions'},
    ],
};
sub convert_vitamin_b6_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        ['mg-pyridoxine'], '1 mg',
        ['mg-pyridoxine-hydrochloride'], '0.8227 mg',
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
            'mg-pyridoxine',
            'mg-pyridoxine-hydrochloride',
        ) {
            push @rows, {
                unit => $u,
                amount => $quantity->convert($u),
            };
        }
        [200, "OK", \@rows];
    }
}

$SPEC{convert_vitamin_b12_unit} = {
    v => 1.1,
    summary => 'Convert a vitamin B12 (cobalamin) quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %args_common,
    },
    examples => [
        {args=>{quantity=>'mcg'}, summary=>'Show all possible conversions'},
    ],
};
sub convert_vitamin_b12_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        ['mcg'], '0.001 mg',
        ['mcg-cobalamin'], '0.001 mg',
        ['mcg-cyanocobalamin'], '0.999988932992961 mg', # very close to cobalamin as it only adds CN-. molecular weight 1,355.38 g/mol vs 1,355.365
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
            'mcg-cobalamin',
            'mcg-cyanocobalamin',
        ) {
            push @rows, {
                unit => $u,
                amount => $quantity->convert($u),
            };
        }
        [200, "OK", \@rows];
    }
}

$SPEC{convert_choline_unit} = {
    v => 1.1,
    summary => 'Convert a choline quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %args_common,
    },
    examples => [
        {args=>{quantity=>'mcg'}, summary=>'Show all possible conversions'},
    ],
};
sub convert_choline_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        ['mcg'], '0.001 mg',
        ['mcg-choline'], '0.001 mg',
        ['mcg-choline-bitartrate'], '0.000411332675222113 mg', # molecular weight: 253.25 vs 104.17
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
            'mcg-choline',
            'mcg-choline-bitartrate',
        ) {
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

    capture_stderr {
        Physics::Unit::InitUnit(
            ['g'], 'gram', # emits warning 'already defined' warning, but '3g' won't work if we don't add this
            ['mcg'], '0.001 mg',
            ['IU', 'iu'], '0.025 microgram',
        );
    }; # silence warning

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
        ['mg-alpha-tocopherol-equivalent'], '1 mg',
        ['mg-alpha-TE'], '1 mg',
        ['mg-rrr-alpha-tocopherol'], '1 mg',
        ['mg-d-alpha-tocopherol'], '1 mg', # RRR- = d-
        ['mg-dl-alpha-tocopherol'], '0.738255033557047 mg', # https://www.rfaregulatoryaffairs.com/vitamin-converter

        ['mg-d-alpha-tocopheryl-acetate'], '0.912751677852349 mg', # https://www.rfaregulatoryaffairs.com/vitamin-converter
        ['mg-dl-alpha-tocopheryl-acetate'], '0.671140939597315 mg', # https://www.rfaregulatoryaffairs.com/vitamin-converter

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
            'mg-alpha-TE',
            'mg-alpha-tocopherol-equivalent',
            'mg-rrr-alpha-tocopherol',
            'mg-d-alpha-tocopherol',
            'mg-d-alpha-tocopheryl-acetate',
            'mg-dl-alpha-tocopheryl-acetate',
            'mg-dl-alpha-tocopherol',
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

This document describes version 0.006 of App::VitaminUtils (from Perl distribution App-VitaminUtils), released on 2022-09-14.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<convert-choline-unit>

=item * L<convert-cobalamin-unit>

=item * L<convert-pantothenic-acid-unit>

=item * L<convert-pyridoxine-unit>

=item * L<convert-vitamin-a-unit>

=item * L<convert-vitamin-b12-unit>

=item * L<convert-vitamin-b5-unit>

=item * L<convert-vitamin-b6-unit>

=item * L<convert-vitamin-d-unit>

=item * L<convert-vitamin-e-unit>

=back

=head1 FUNCTIONS


=head2 convert_choline_unit

Usage:

 convert_choline_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a choline quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_choline_unit(quantity => "mcg");

Result:

 [
   200,
   "OK",
   [
     { amount => 0.001, unit => "mg" },
     { amount => 1, unit => "mcg" },
     { amount => 1, unit => "mcg-choline" },
     { amount => 2.43112220408947, unit => "mcg-choline-bitartrate" },
   ],
   {},
 ]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity>* => I<str>

=item * B<to_unit> => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_vitamin_a_unit

Usage:

 convert_vitamin_a_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

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
     { amount => 1.14655200007338, unit => "mcg-all-trans-retinyl-acetate" },
     {
       amount => 1.83333333333333,
       unit   => "mcg-all-trans-retinyl-palmitate",
     },
     {
       amount => 1.19666666666667,
       unit   => "mcg-all-trans-retinyl-propionate",
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

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_vitamin_b12_unit

Usage:

 convert_vitamin_b12_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a vitamin B12 (cobalamin) quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_vitamin_b12_unit(quantity => "mcg");

Result:

 [
   200,
   "OK",
   [
     { amount => 0.001, unit => "mg" },
     { amount => 1, unit => "mcg" },
     { amount => 1, unit => "mcg-cobalamin" },
     { amount => 0.00100001106712952, unit => "mcg-cyanocobalamin" },
   ],
   {},
 ]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity>* => I<str>

=item * B<to_unit> => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_vitamin_b5_unit

Usage:

 convert_vitamin_b5_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a vitamin B5 (pantothenic acid) quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_vitamin_b5_unit(quantity => "mg");

Result:

 [
   200,
   "OK",
   [
     { amount => 1, unit => "mg" },
     { amount => 1, unit => "mg-pantothenic-acid" },
     { amount => 1.09170305676856, unit => "mg-d-calcium-pantothenate" },
   ],
   {},
 ]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity>* => I<str>

=item * B<to_unit> => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_vitamin_b6_unit

Usage:

 convert_vitamin_b6_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a vitamin B6 (pyridoxine) quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_vitamin_b6_unit(quantity => "mg");

Result:

 [
   200,
   "OK",
   [
     { amount => 1, unit => "mg" },
     { amount => 1, unit => "mg-pyridoxine" },
     { amount => 1.21550990640574, unit => "mg-pyridoxine-hydrochloride" },
   ],
   {},
 ]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity>* => I<str>

=item * B<to_unit> => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_vitamin_d_unit

Usage:

 convert_vitamin_d_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

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

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_vitamin_e_unit

Usage:

 convert_vitamin_e_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

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
     { amount => 1, unit => "mg-alpha-TE" },
     { amount => 1, unit => "mg-alpha-tocopherol-equivalent" },
     { amount => 1, unit => "mg-rrr-alpha-tocopherol" },
     { amount => 1, unit => "mg-d-alpha-tocopherol" },
     { amount => 1.09558823529412, unit => "mg-d-alpha-tocopheryl-acetate" },
     { amount => 1.49, unit => "mg-dl-alpha-tocopheryl-acetate" },
     { amount => 1.35454545454545, unit => "mg-dl-alpha-tocopherol" },
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

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-VitaminUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-VitaminUtils>.

=head1 SEE ALSO

L<App::MineralUtils>

L<Physics::Unit>

Online vitamin converters:
L<https://www.rfaregulatoryaffairs.com/vitamin-converter>,
L<https://avsnutrition.com.au/wp-content/themes/avs-nutrition/vitamin-converter.html>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-VitaminUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
