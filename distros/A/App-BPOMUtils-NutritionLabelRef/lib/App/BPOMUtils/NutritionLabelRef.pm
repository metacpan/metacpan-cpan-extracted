package App::BPOMUtils::NutritionLabelRef;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-13'; # DATE
our $DIST = 'App-BPOMUtils-NutritionLabelRef'; # DIST
our $VERSION = '0.004'; # VERSION

our @EXPORT_OK = qw(
                       bpom_get_nutrition_label_ref
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
    require TableData::Business::ID::BPOM::NutritionLabelRef;
    my $td = TableData::Business::ID::BPOM::NutritionLabelRef->new;
    @rows = $td->get_all_rows_hashref;
    for (@rows) {
        $nutrient_symbols{ $_->{symbol} }++;
        $groups{ $_->{group} }++;
    }
    @nutrient_symbols = sort keys %nutrient_symbols;
    @groups = sort keys %groups;
}

$SPEC{bpom_get_nutrition_label_ref} = {
    v => 1.1,
    summary => 'Get one or more values from BPOM nutrition label reference (ALG, acuan label gizi)',
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
            'x.doc.max_result_lines' => 8,
        },
        {
            summary => 'List all groups (symbols)',
            argv => [qw/--list-groups/],
            test => 0,
        },
        {
            summary => 'List all ALG values',
            argv => [qw//],
            test => 0,
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List ALG for vitamin D, for all groups',
            argv => [qw/VD/],
            test => 0,
        },
        {
            summary => 'List ALG for vitamin D, for 1-3 years olds',
            argv => [qw/VD 1to3y/],
            test => 0,
        },
        {
            summary => 'List ALG for vitamin D, for 1-3 years olds, and compare a value to reference',
            argv => [qw/VD 1to3y 10/],
            test => 0,
        },
    ],
};
sub bpom_get_nutrition_label_ref {
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
                $resrow->{'%alg'} = $args{value} / $resrow->{ref} * 100;
            }
            push @res, $resrow;
        }
        return [200, "OK", \@res, {'table.fields'=>[qw/symbol group ref unit %alg/]}];
    } else {
        return [400, "Unknown action: $action"];
    }
}

1;
# ABSTRACT: Get one or more values from BPOM nutrition label reference (ALG, acuan label gizi)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BPOMUtils::NutritionLabelRef - Get one or more values from BPOM nutrition label reference (ALG, acuan label gizi)

=head1 VERSION

This document describes version 0.004 of App::BPOMUtils::NutritionLabelRef (from Perl distribution App-BPOMUtils-NutritionLabelRef), released on 2024-06-13.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes CLI utilities related to BPOM nutrition label
reference (ALG, acuan label gizi):

=over

=item * L<alg>

=item * L<bpom-get-nutrition-label-ref>

=back

=head1 FUNCTIONS


=head2 bpom_get_nutrition_label_ref

Usage:

 bpom_get_nutrition_label_ref(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get one or more values from BPOM nutrition label reference (ALG, acuan label gizi).

Examples:

=over

=item * List all nutrient (symbols):

 bpom_get_nutrition_label_ref(action => "list_nutrients");

Result:

 [
   200,
   "OK",
   [
     "Alpha_Linoleic_Acid",
     "Biotin",
     "Ca",
 # ...snipped 31 lines for brevity...
     "VD",
     "VE",
     "VK",
     "Zn",
   ],
   {},
 ]

=item * List all groups (symbols):

 bpom_get_nutrition_label_ref(action => "list_groups");

Result:

 [
   200,
   "OK",
   [
     "0to6mo",
     "1to3y",
     "7to11mo",
     "breastfeeding",
     "general",
     "pregnant",
   ],
   {},
 ]

=item * List all ALG values:

 bpom_get_nutrition_label_ref();

Result:

 [
   200,
   "OK",
   [
     { symbol => "Energy", group => "0to6mo", ref => 550, unit => "kkal" },
     { symbol => "Energy", group => "7to11mo", ref => 725, unit => "kkal" },
     { symbol => "Energy", group => "1to3y", ref => 1125, unit => "kkal" },
     { symbol => "Energy", group => "general", ref => 2150, unit => "kkal" },
 # ...snipped 254 lines for brevity...
       symbol => "Myo_Inositol",
       group  => "breastfeeding",
       ref    => undef,
       unit   => "mg",
     },
   ],
   { "table.fields" => ["symbol", "group", "ref", "unit", "%alg"] },
 ]

=item * List ALG for vitamin D, for all groups:

 bpom_get_nutrition_label_ref(nutrient => "VD");

Result:

 [
   200,
   "OK",
   [
     { group => "0to6mo", ref => 5, unit => "mcg" },
     { group => "7to11mo", ref => 5, unit => "mcg" },
     { group => "1to3y", ref => 15, unit => "mcg" },
     { group => "general", ref => 15, unit => "mcg" },
     { group => "pregnant", ref => 15, unit => "mcg" },
     { group => "breastfeeding", ref => 15, unit => "mcg" },
   ],
   { "table.fields" => ["symbol", "group", "ref", "unit", "%alg"] },
 ]

=item * List ALG for vitamin D, for 1-3 years olds:

 bpom_get_nutrition_label_ref(nutrient => "VD", group => "1to3y");

Result:

 [
   200,
   "OK",
   [{ ref => 15, unit => "mcg" }],
   { "table.fields" => ["symbol", "group", "ref", "unit", "%alg"] },
 ]

=item * List ALG for vitamin D, for 1-3 years olds, and compare a value to reference:

 bpom_get_nutrition_label_ref(nutrient => "VD", group => "1to3y", value => 10);

Result:

 [
   200,
   "OK",
   [{ "ref" => 15, "unit" => "mcg", "%alg" => 66.6666666666667 }],
   { "table.fields" => ["symbol", "group", "ref", "unit", "%alg"] },
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

Please visit the project's homepage at L<https://metacpan.org/release/App-BPOMUtils-NutritionLabelRef>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BPOMUtils-NutritionLabelRef>.

=head1 SEE ALSO

L<TableData::Business::ID::BPOM::NutritionLabelRef>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BPOMUtils-NutritionLabelRef>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
