package App::KemenkesUtils::RDA;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-08'; # DATE
our $DIST = 'App-KemenkesUtils-RDA'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       kemenkes_get_rda
               );

our %SPEC;

our @actions = qw(
                     list_refs
                     list_nutrients
                     list_groups
             );

our (@rows, @nutrient_symbols, @groups);
# load and cache table
{
    my (%nutrient_symbols, %groups);
    require TableData::Business::ID::Kemenkes::RDA;
    my $td = TableData::Business::ID::Kemenkes::RDA->new;
    @rows = $td->get_all_rows_hashref;
    for (@rows) {
        $nutrient_symbols{ $_->{symbol} }++;
        $groups{ $_->{group} }++;
    }
    @nutrient_symbols = sort keys %nutrient_symbols;
    @groups = sort keys %groups;
}

$SPEC{kemenkes_get_rda} = {
    v => 1.1,
    summary => 'Get one or more values from Indonesian Ministry of Health\'s RDA (AKG, angka kecukupan gizi, from Kemenkes)',
    args => {
        action => {
            schema => ['str*', in=>\@actions],
            default => 'list_refs',
            cmdline_aliases => {
                list_nutrients => {is_flag=>1, code=>sub {$_[0]{action}='list_nutrients'}, summary=>'Shortcut for --action=list_nutrients'},
                n              => {is_flag=>1, code=>sub {$_[0]{action}='list_nutrients'}, summary=>'Shortcut for --action=list_nutrients'},
                list_groups    => {is_flag=>1, code=>sub {$_[0]{action}='list_groups'   }, summary=>'Shortcut for --action=list_groups'   },
                g              => {is_flag=>1, code=>sub {$_[0]{action}='list_groups'   }, summary=>'Shortcut for --action=list_groups'   },
            },
        },
        nutrient => {
            schema => 'nutrient::symbol*',
            pos => 0,
        },
        group => {
            schema => ['str*', in=>\@groups],
            pos => 1,
        },
        value => {
            schema => ['float*'],
            pos => 2,
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases =>{l=>{}},
        },
    },
    examples => [
        {
            summary => 'List all nutrient (symbols)',
            argv => [qw/--list-nutrients/],
            test => 0,
        },
        {
            summary => 'List all groups (symbols)',
            argv => [qw/--list-nutrients/],
            test => 0,
        },
        {
            summary => 'List all AKG values',
            argv => [qw//],
            test => 0,
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List AKG for vitamin D, for all groups',
            argv => [qw/VD/],
            test => 0,
        },
        {
            summary => 'List AKG for vitamin D, for 1-3 years olds',
            argv => [qw/VD 1to3y/],
            test => 0,
        },
        {
            summary => 'List AKG for vitamin D, for 1-3 years olds, and compare a value to reference',
            argv => [qw/VD 1to3y 10/],
            test => 0,
        },
    ],
};
sub kemenkes_get_rda {
    my %args = @_;
    my $action = $args{action} // 'list_refs';

    if ($action eq 'list_nutrients') {
        return [200, "OK", \@nutrient_symbols];
    } elsif ($action eq 'list_groups') {
        return [200, "OK", \@groups];
    } elsif ($action eq 'list_refs') {
        my @res;
        for my $row0 (@rows) {
            my $resrow = { %{$row0} };
            if (defined $args{nutrient}) {
                next unless $resrow->{symbol} eq $args{nutrient};
                delete $resrow->{symbol};
            }
            if (defined $args{group}) {
                next unless $resrow->{group} eq $args{group};
                delete $resrow->{group};
            }
            if (defined $args{value}) {
                $resrow->{'%akg'} = $args{value} / $resrow->{ref} * 100;
            }
            push @res, $resrow;
        }
        return [200, "OK", \@res, {'table.fields'=>[qw/symbol group height weight ref %akg/]}];
    } else {
        return [400, "Unknown action: $action"];
    }
}

1;
# ABSTRACT: Get one or more values from Indonesian Ministry of Health's RDA (AKG, angka kecukupan gizi, from Kemenkes)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::KemenkesUtils::RDA - Get one or more values from Indonesian Ministry of Health's RDA (AKG, angka kecukupan gizi, from Kemenkes)

=head1 VERSION

This document describes version 0.001 of App::KemenkesUtils::RDA (from Perl distribution App-KemenkesUtils-RDA), released on 2024-06-08.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes CLI utilities related to "AKG" (angka kecukupan gizi,
nutritional adeqecy rate, RDA, recommended daily intake) from Kemenkes
(Kementerian Kesehatan, Indonesia) Indonesia's Ministry of Health.

=over

=item * L<akg>

=item * L<kemenkes-get-rda>

=back

=head1 FUNCTIONS


=head2 kemenkes_get_rda

Usage:

 kemenkes_get_rda(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get one or more values from Indonesian Ministry of Health's RDA (AKG, angka kecukupan gizi, from Kemenkes).

Examples:

=over

=item * List all nutrient (symbols):

 kemenkes_get_rda(action => "list_nutrients");

Result:

 [
   200,
   "OK",
   [
     "Ca",
     "Cl",
     "Cr",
     "Cu",
     "Dietary_Fiber",
     "Energy",
     "F",
     "Fe",
     "I",
     "K",
     "Mg",
     "Mn",
     "Na",
     "Omega3",
     "Omega6",
     "P",
     "Protein",
     "Se",
     "Total_Carbohydrate",
     "Total_Fat",
     "VA",
     "VB1",
     "VB12",
     "VB2" .. "VB7",
     "VB9",
     "VC",
     "VD",
     "VE",
     "VK",
     "Water",
     "Zn",
     "group",
     "height",
     "weight",
   ],
   {},
 ]

=item * List all groups (symbols):

 kemenkes_get_rda(action => "list_nutrients");

Result:

 [
   200,
   "OK",
   [
     "Ca",
     "Cl",
     "Cr",
     "Cu",
     "Dietary_Fiber",
     "Energy",
     "F",
     "Fe",
     "I",
     "K",
     "Mg",
     "Mn",
     "Na",
     "Omega3",
     "Omega6",
     "P",
     "Protein",
     "Se",
     "Total_Carbohydrate",
     "Total_Fat",
     "VA",
     "VB1",
     "VB12",
     "VB2" .. "VB7",
     "VB9",
     "VC",
     "VD",
     "VE",
     "VK",
     "Water",
     "Zn",
     "group",
     "height",
     "weight",
   ],
   {},
 ]

=item * List all AKG values:

 kemenkes_get_rda();

Result:

 [
   200,
   "OK",
   [
     { symbol => "Ca", group => "0to5mo", height => 60, weight => 6, ref => 200 },
     { symbol => "Cl", group => "0to5mo", height => 60, weight => 6, ref => 180 },
     { symbol => "Cr", group => "0to5mo", height => 60, weight => 6, ref => 0.2 },
     { symbol => "Cu", group => "0to5mo", height => 60, weight => 6, ref => 200 },
 # ...snipped 5477 lines for brevity...
       weight => "",
       ref    => "",
     },
   ],
   {
     "table.fields" => ["symbol", "group", "height", "weight", "ref", "%akg"],
   },
 ]

=item * List AKG for vitamin D, for all groups:

 kemenkes_get_rda(nutrient => "VD");

Result:

 [
   200,
   "OK",
   [
     { group => "0to5mo", height => 60, weight => 6, ref => 10 },
     { group => "6to11mo", height => 72, weight => 9, ref => 10 },
     { group => "1to3y", height => 92, weight => 13, ref => 15 },
     { group => "4to6y", height => 113, weight => 19, ref => 15 },
     { group => "7to9y", height => 130, weight => 27, ref => 15 },
     { group => "male_10to12y", height => 145, weight => 36, ref => 15 },
     { group => "male_13to15y", height => 163, weight => 50, ref => 15 },
     { group => "male_16to18y", height => 168, weight => 60, ref => 15 },
     { group => "male_19to29y", height => 168, weight => 60, ref => 15 },
     { group => "male_30to49y", height => 166, weight => 60, ref => 15 },
     { group => "male_50to64y", height => 166, weight => 60, ref => 15 },
     { group => "male_65to80y", height => 164, weight => 58, ref => 20 },
     { group => "male_80y_plus", height => 164, weight => 54, ref => 20 },
     { group => "female_10to12y", height => 147, weight => 38, ref => 15 },
     { group => "female_13to15y", height => 156, weight => 48, ref => 15 },
     { group => "female_16to18y", height => 159, weight => 52, ref => 15 },
     { group => "female_19to29y", height => 159, weight => 55, ref => 15 },
     { group => "female_30to49y", height => 158, weight => 56, ref => 15 },
     { group => "female_50to64y", height => 158, weight => 56, ref => 15 },
     { group => "female_65to80y", height => 157, weight => 53, ref => 20 },
     { group => "female_80y_plus", height => 157, weight => 53, ref => 20 },
     { group => "add_pregnant_trimst1", height => "", weight => "", ref => 0 },
     { group => "add_pregnant_trimst2", height => "", weight => "", ref => 0 },
     { group => "add_pregnant_trimst3", height => "", weight => "", ref => 0 },
     { group => "add_breastfeeding_0to6m", height => "", weight => "", ref => 0 },
     { group => "add_breastfeeding_6to12m", height => "", weight => "", ref => 0 },
   ],
   {
     "table.fields" => ["symbol", "group", "height", "weight", "ref", "%akg"],
   },
 ]

=item * List AKG for vitamin D, for 1-3 years olds:

 kemenkes_get_rda(nutrient => "VD", group => "1to3y");

Result:

 [
   200,
   "OK",
   [{ height => 92, weight => 13, ref => 15 }],
   {
     "table.fields" => ["symbol", "group", "height", "weight", "ref", "%akg"],
   },
 ]

=item * List AKG for vitamin D, for 1-3 years olds, and compare a value to reference:

 kemenkes_get_rda(nutrient => "VD", group => "1to3y", value => 10);

Result:

 [
   200,
   "OK",
   [
     { "height" => 92, "weight" => 13, "ref" => 15, "%akg" => 66.6666666666667 },
   ],
   {
     "table.fields" => ["symbol", "group", "height", "weight", "ref", "%akg"],
   },
 ]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "list_refs")

(No description)

=item * B<detail> => I<bool>

(No description)

=item * B<group> => I<str>

(No description)

=item * B<nutrient> => I<nutrient::symbol>

(No description)

=item * B<value> => I<float>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-KemenkesUtils-RDA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-KemenkesUtils-RDA>.

=head1 SEE ALSO

L<TableData::Business::ID::Kemenkes::RDA>

Other C<App::BPOMUtils::*> distributions.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-KemenkesUtils-RDA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
