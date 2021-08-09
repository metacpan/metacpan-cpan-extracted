package App::MineralUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-08'; # DATE
our $DIST = 'App-MineralUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

# XXX share with App::VitaminUtils
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

$SPEC{convert_magnesium_unit} = {
    v => 1.1,
    summary => 'Convert a magnesium quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %args_common,
    },
    examples => [
        {args=>{quantity=>'mg'}, summary=>'Show all possible conversions'},
        {args=>{quantity=>'1000 mg-magnesium-l-threonate', to_unit=>'mg-magnesium-elemental'}, summary=>'Find out how many mg of elemental magnesium is in 1000mg of magnesium l-threonate'},
    ],
};
sub convert_magnesium_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        ['mg-magnesium-elemental'], '1 mg',
        ['mg-magnesium-citrate'], '0.1123 mg-magnesium-elemental',
        ['mg-magnesium-glycinate'], '0.141 mg-magnesium-elemental',
        ['mg-magnesium-l-threonate'], '0.072 mg-magnesium-elemental',
        ['mg-magnesium-oxide'], '0.603 mg-magnesium-elemental',
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
            'mg-magnesium-elemental',
            'mg-magnesium-citrate',
            'mg-magnesium-glycinate',
            'mg-magnesium-l-threonate',
            'mg-magnesium-oxide',
        ) {
            push @rows, {
                unit => $u,
                amount => $quantity->convert($u),
            };
        }
        [200, "OK", \@rows];
    }
}

1;
# ABSTRACT: Utilities related to minerals (and mineral supplements)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MineralUtils - Utilities related to minerals (and mineral supplements)

=head1 VERSION

This document describes version 0.001 of App::MineralUtils (from Perl distribution App-MineralUtils), released on 2021-08-08.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<convert-magnesium-unit>

=back

=head1 FUNCTIONS


=head2 convert_magnesium_unit

Usage:

 convert_magnesium_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a magnesium quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_magnesium_unit(quantity => "mg");

Result:

 [
   200,
   "OK",
   [
     { amount => 1, unit => "mg" },
     { amount => 1, unit => "mg-magnesium-elemental" },
     { amount => 8.90471950133571, unit => "mg-magnesium-citrate" },
     { amount => 7.09219858156028, unit => "mg-magnesium-glycinate" },
     { amount => 13.8888888888889, unit => "mg-magnesium-l-threonate" },
     { amount => 1.65837479270315, unit => "mg-magnesium-oxide" },
   ],
   {},
 ]

=item * Find out how many mg of elemental magnesium is in 1000mg of magnesium l-threonate:

 convert_magnesium_unit(
   quantity => "1000 mg-magnesium-l-threonate",
   to_unit  => "mg-magnesium-elemental"
 );

Result:

 [200, "OK", 72, {}]

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

Please visit the project's homepage at L<https://metacpan.org/release/App-MineralUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-MineralUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-MineralUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::VitaminUtils>

L<Physics::Unit>

Online vitamin converters:
L<https://www.rfaregulatoryaffairs.com/vitamin-converter>,
L<https://avsnutrition.com.au/wp-content/themes/avs-nutrition/vitamin-converter.html>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
