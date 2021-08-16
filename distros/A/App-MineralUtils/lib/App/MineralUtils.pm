package App::MineralUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-15'; # DATE
our $DIST = 'App-MineralUtils'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

my @magnesium_forms = (
    #{
    #    name => 'mg',
    #    magnesium_ratio => 1,
    #    summary => 'Elemental magnesium, in milligrams',
    #},
    {
        name => 'mg-mg-elem',
        magnesium_ratio => 1,
        summary => 'Elemental magnesium, in milligrams',
    },
    {
        name => 'mg-mg-citrate',
        magnesium_ratio => 24.305/214.412, # 11.34%
        summary => 'Magnesium citrate (C6H6MgO7), in milligrams',
    },
    {
        name => 'mg-mg-citrate-ah',
        magnesium_ratio => 24.305/457.16*3, # 15.95%
        summary => 'Magnesium citrate anhydrous (C6H5Mg3O7), in milligrams',
    },
    {
        name => 'mg-mg-citrate-ah-nowfoods',
        magnesium_ratio => 24.305/457.16*3, # 15.95%
        purity => 0.9091, # 15.95% x 0.9091 = 14.5%
        summary=>'Magnesium citrate in NOW Foods supplement (anhydrous, C6H5Mg3O7, 90.9% pure, contains citric acid etc), in milligrams'},
    {
        name=>'mg-mg-glycinate',
        magnesium_ratio => 24.305/172.42, # 14.1%
        summary=>'Magnesium glycinate/bisglycinate (C4H8MgN2O4), in milligrams',
    },
    {
        name=>'mg-mg-bisglycinate',
        magnesium_ratio => 24.305/172.42, # 14.1%
        summary=>'Magnesium glycinate/bisglycinate (C4H8MgN2O4), in milligrams',
    },
    {
        name=>'mg-mg-bisglycinate-nowfoods',
        magnesium_ratio => 24.305/172.42, # 14.1%
        purity => 0.7094, # 14.1% x 0.7094 = 10%
        summary=>'Magnesium bisglycinate in NOW Foods supplement (C4H8MgN2O4, 70.5% pure, contains citric acid etc), in milligrams',
    },
    {
        name=>'mg-mg-ascorbate',
        magnesium_ratio => 24.305/327.53, # 7.42%
        summary => 'Magnesium ascorbate/pidolate (C11H13MgNO9), in milligrams',
    },
    {
        name=>'mg-mg-pidolate',
        magnesium_ratio => 24.305/327.53, # 7.42%
        summary => 'Magnesium ascorbate/pidolate (C11H13MgNO9), in milligrams',
    },
    {
        name=>'mg-mg-l-threonate',
        magnesium_ratio => 24.305/294.50, # 8.25%
        summary => 'Magnesium L-threonate (C8H14MgO10), in milligrams',
    },
    {
        name=>'mg-mg-oxide',
        magnesium_ratio => 24.305 / 40.3044, # 60.3%
        summary => 'Magnesium oxide (MgO), in milligrams',
    },
);

# XXX share with App::VitaminUtils
our %argspecs_magnesium = (
    quantity => {
        # schema => 'physical::mass*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
        schema => 'str*',
        default => '1 mg',
        req => 0,
        pos => 0,
        completion => sub {
            require Complete::Sequence;

            my %args = @_;
            Complete::Sequence::complete_sequence(
                word => $args{word},
                sequence => [
                    # TEMP
                    #sub {
                    #    require Complete::Number;
                    #    my $stash = shift;
                    #    Complete::Number::complete_int(word => $stash->{cur_word});
                    #},
                    #' ',
                    {alternative=>[map {$_->{name}} @magnesium_forms]},
                ],
            );
        },
    },
    to_unit => {
        # schema => 'physical::unit', # IU hasn't been added
        schema => ['str*', in=>['mg', map {$_->{name}} @magnesium_forms]],
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
        %argspecs_magnesium,
    },
    examples => [
        {
            args=>{},
            summary=>'Show all possible conversions',
        },
        {
            args=>{quantity=>'1000 mg-mg-l-threonate', to_unit=>'mg-mg-elem'},
            summary=>'Find out how many milligrams of elemental magnesium is in 1000mg of pure magnesium l-threonate (but note that a supplement product might not contain 100%-pure compound)',
        },
        {
            args=>{quantity=>'3000 mg-mg-citrate-ah-nowfoods', to_unit=>'mg-mg-elem'},
            summary=>'Find out how many milligrams of elemental magnesium is in 3g (1 recommended serving) of NOW Foods magnesium citrate powder (magnesium content is as advertised on the label)',
        },
        {
            args=>{quantity=>'2500 mg-mg-bisglycinate-nowfoods', to_unit=>'mg-mg-elem'},
            summary=>'Find out how many milligrams of elemental magnesium is in 2.5g (1 recommended serving) of NOW Foods magnesium bisglycinate powder (magnesium content is as advertised on the label)',
        },
    ],
};
sub convert_magnesium_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        map {([$_->{name}], sprintf("%.3f mg", $_->{magnesium_ratio}*($_->{purity}//1)))}
        @magnesium_forms,
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
            @magnesium_forms,
        ) {
            push @rows, {
                amount => $quantity->convert($u->{name}),
                unit => $u->{name},
                summary => $u->{summary},
            };
        }
        [200, "OK", \@rows, {
            'table.fields' => [qw/amount unit summary/],
            'table.field_formats'=>[[number=>{thousands_sep=>'', precision=>3}], undef, undef],
            'table.field_aligns' => [qw/number left left/],
        }];
    }
}

1;
# ABSTRACT: Utilities related to mineral supplements

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MineralUtils - Utilities related to mineral supplements

=head1 VERSION

This document describes version 0.005 of App::MineralUtils (from Perl distribution App-MineralUtils), released on 2021-08-15.

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

 convert_magnesium_unit();

Result:

 [
   200,
   "OK",
   [
     {
       amount  => 1,
       unit    => "mg-mg-elem",
       summary => "Elemental magnesium, in milligrams",
     },
     {
       amount  => 8.84955752212389,
       unit    => "mg-mg-citrate",
       summary => "Magnesium citrate (C6H6MgO7), in milligrams",
     },
     {
       amount  => 6.28930817610063,
       unit    => "mg-mg-citrate-ah",
       summary => "Magnesium citrate anhydrous (C6H5Mg3O7), in milligrams",
     },
     {
       amount  => 6.89655172413793,
       unit    => "mg-mg-citrate-ah-nowfoods",
       summary => "Magnesium citrate in NOW Foods supplement (anhydrous, C6H5Mg3O7, 90.9% pure, contains citric acid etc), in milligrams",
     },
     {
       amount  => 7.09219858156028,
       unit    => "mg-mg-glycinate",
       summary => "Magnesium glycinate/bisglycinate (C4H8MgN2O4), in milligrams",
     },
     {
       amount  => 7.09219858156028,
       unit    => "mg-mg-bisglycinate",
       summary => "Magnesium glycinate/bisglycinate (C4H8MgN2O4), in milligrams",
     },
     {
       amount  => 10,
       unit    => "mg-mg-bisglycinate-nowfoods",
       summary => "Magnesium bisglycinate in NOW Foods supplement (C4H8MgN2O4, 70.5% pure, contains citric acid etc), in milligrams",
     },
     {
       amount  => 13.5135135135135,
       unit    => "mg-mg-ascorbate",
       summary => "Magnesium ascorbate/pidolate (C11H13MgNO9), in milligrams",
     },
     {
       amount  => 13.5135135135135,
       unit    => "mg-mg-pidolate",
       summary => "Magnesium ascorbate/pidolate (C11H13MgNO9), in milligrams",
     },
     {
       amount  => 12.0481927710843,
       unit    => "mg-mg-l-threonate",
       summary => "Magnesium L-threonate (C8H14MgO10), in milligrams",
     },
     {
       amount  => 1.65837479270315,
       unit    => "mg-mg-oxide",
       summary => "Magnesium oxide (MgO), in milligrams",
     },
   ],
   {
     "table.field_aligns"  => ["number", "left", "left"],
     "table.field_formats" => [
                                ["number", { precision => 3, thousands_sep => "" }],
                                undef,
                                undef,
                              ],
     "table.fields"        => ["amount", "unit", "summary"],
   },
 ]

=item * Find out how many milligrams of elemental magnesium is in 1000mg of pure magnesium l-threonate (but note that a supplement product might not contain 100%-pure compound):

 convert_magnesium_unit(quantity => "1000 mg-mg-l-threonate", to_unit => "mg-mg-elem");

Result:

 [200, "OK", 83, {}]

=item * Find out how many milligrams of elemental magnesium is in 3g (1 recommended serving) of NOW Foods magnesium citrate powder (magnesium content is as advertised on the label):

 convert_magnesium_unit(
   quantity => "3000 mg-mg-citrate-ah-nowfoods",
   to_unit  => "mg-mg-elem"
 );

Result:

 [200, "OK", 435, {}]

=item * Find out how many milligrams of elemental magnesium is in 2.5g (1 recommended serving) of NOW Foods magnesium bisglycinate powder (magnesium content is as advertised on the label):

 convert_magnesium_unit(
   quantity => "2500 mg-mg-bisglycinate-nowfoods",
   to_unit  => "mg-mg-elem"
 );

Result:

 [200, "OK", 250, {}]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity> => I<str> (default: "1 mg")

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
