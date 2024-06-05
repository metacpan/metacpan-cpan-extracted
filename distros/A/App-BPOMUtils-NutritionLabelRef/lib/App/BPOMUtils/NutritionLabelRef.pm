package App::BPOMUtils::NutritionLabelRef;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-30'; # DATE
our $DIST = 'App-BPOMUtils-NutritionLabelRef'; # DIST
our $VERSION = '0.001'; # VERSION

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
                list_groups    => {is_flag=>1, code=>sub {$_[0]{action}='list_groups'   }, summary=>'Shortcut for --action=list_groups'   },
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
            summary => 'List all ALG values',
            argv => [qw//],
            test => 0,
        },
        {
            summary => 'List ALG for vitamin D, for all groups',
            argv => [qw/VD/],
            test => 0,
            'x.doc.max_result_lines' => 10,
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

This document describes version 0.001 of App::BPOMUtils::NutritionLabelRef (from Perl distribution App-BPOMUtils-NutritionLabelRef), released on 2024-05-30.

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
     "Carbohydrate",
     "Cholesterol",
     "Choline",
     "Cr",
     "Cu",
     "Dietary_Fiber",
     "Energy",
     "F",
     "Fe",
     "I",
     "K",
     "L_Carnitine",
     "Linoleic_Acid",
     "Mg",
     "Mn",
     "Myo_Inositol",
     "Na",
     "P",
     "Protein",
     "Saturated_Fat",
     "Se",
     "Total_Fat",
     "VA",
     "VB1",
     "VB12",
     "VB2",
     "VB3",
     "VB5",
     "VB6",
     "VB9",
     "VC",
     "VD",
     "VE",
     "VK",
     "Zn",
   ],
   {},
 ]

=item * List all groups (symbols):

 bpom_get_nutrition_label_ref(action => "list_nutrients");

Result:

 [
   200,
   "OK",
   [
     "Alpha_Linoleic_Acid",
     "Biotin",
     "Ca",
     "Carbohydrate",
     "Cholesterol",
     "Choline",
     "Cr",
     "Cu",
     "Dietary_Fiber",
     "Energy",
     "F",
     "Fe",
     "I",
     "K",
     "L_Carnitine",
     "Linoleic_Acid",
     "Mg",
     "Mn",
     "Myo_Inositol",
     "Na",
     "P",
     "Protein",
     "Saturated_Fat",
     "Se",
     "Total_Fat",
     "VA",
     "VB1",
     "VB12",
     "VB2",
     "VB3",
     "VB5",
     "VB6",
     "VB9",
     "VC",
     "VD",
     "VE",
     "VK",
     "Zn",
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
     { symbol => "Energy", group => "pregnant", ref => 2510, unit => "kkal" },
     { symbol => "Energy", group => "breastfeeding", ref => 2615, unit => "kkal" },
     { symbol => "Protein", group => "0to6mo", ref => 12, unit => "g" },
     { symbol => "Protein", group => "7to11mo", ref => 18, unit => "g" },
     { symbol => "Protein", group => "1to3y", ref => 26, unit => "g" },
     { symbol => "Protein", group => "general", ref => 60, unit => "g" },
     { symbol => "Protein", group => "pregnant", ref => 76, unit => "g" },
     { symbol => "Protein", group => "breastfeeding", ref => 76, unit => "g" },
     { symbol => "Total_Fat", group => "0to6mo", ref => 34, unit => "g" },
     { symbol => "Total_Fat", group => "7to11mo", ref => 36, unit => "g" },
     { symbol => "Total_Fat", group => "1to3y", ref => 44, unit => "g" },
     { symbol => "Total_Fat", group => "general", ref => 67, unit => "g" },
     { symbol => "Total_Fat", group => "pregnant", ref => 84, unit => "g" },
     { symbol => "Total_Fat", group => "breastfeeding", ref => 87, unit => "g" },
     { symbol => "Saturated_Fat", group => "0to6mo", ref => undef, unit => "g" },
     { symbol => "Saturated_Fat", group => "7to11mo", ref => undef, unit => "g" },
     { symbol => "Saturated_Fat", group => "1to3y", ref => undef, unit => "g" },
     { symbol => "Saturated_Fat", group => "general", ref => 20, unit => "g" },
     { symbol => "Saturated_Fat", group => "pregnant", ref => 20, unit => "g" },
     { symbol => "Saturated_Fat", group => "breastfeeding", ref => 20, unit => "g" },
     { symbol => "Cholesterol", group => "0to6mo", ref => undef, unit => "mg" },
     { symbol => "Cholesterol", group => "7to11mo", ref => undef, unit => "mg" },
     { symbol => "Cholesterol", group => "1to3y", ref => undef, unit => "mg" },
     { symbol => "Cholesterol", group => "general", ref => "<300", unit => "mg" },
     { symbol => "Cholesterol", group => "pregnant", ref => "<300", unit => "mg" },
     {
       symbol => "Cholesterol",
       group  => "breastfeeding",
       ref    => "<300",
       unit   => "mg",
     },
     { symbol => "Linoleic_Acid", group => "0to6mo", ref => 4.4, unit => "g" },
     { symbol => "Linoleic_Acid", group => "7to11mo", ref => 4.4, unit => "g" },
     { symbol => "Linoleic_Acid", group => "1to3y", ref => 7, unit => "g" },
     { symbol => "Linoleic_Acid", group => "general", ref => 13, unit => "g" },
     { symbol => "Linoleic_Acid", group => "pregnant", ref => 14, unit => "g" },
     { symbol => "Linoleic_Acid", group => "breastfeeding", ref => 14, unit => "g" },
     { symbol => "Alpha_Linoleic_Acid", group => "0to6mo", ref => 0.5, unit => "g" },
     {
       symbol => "Alpha_Linoleic_Acid",
       group  => "7to11mo",
       ref    => 0.5,
       unit   => "g",
     },
     { symbol => "Alpha_Linoleic_Acid", group => "1to3y", ref => 0.7, unit => "g" },
     {
       symbol => "Alpha_Linoleic_Acid",
       group  => "general",
       ref    => 1.4,
       unit   => "g",
     },
     {
       symbol => "Alpha_Linoleic_Acid",
       group  => "pregnant",
       ref    => 1.4,
       unit   => "g",
     },
     {
       symbol => "Alpha_Linoleic_Acid",
       group  => "breastfeeding",
       ref    => 1.3,
       unit   => "g",
     },
     { symbol => "Carbohydrate", group => "0to6mo", ref => 58, unit => "g" },
     { symbol => "Carbohydrate", group => "7to11mo", ref => 82, unit => "g" },
     { symbol => "Carbohydrate", group => "1to3y", ref => 155, unit => "g" },
     { symbol => "Carbohydrate", group => "general", ref => 325, unit => "g" },
     { symbol => "Carbohydrate", group => "pregnant", ref => 345, unit => "g" },
     { symbol => "Carbohydrate", group => "breastfeeding", ref => 360, unit => "g" },
     { symbol => "Dietary_Fiber", group => "0to6mo", ref => 0, unit => "g" },
     { symbol => "Dietary_Fiber", group => "7to11mo", ref => 5, unit => "g" },
     { symbol => "Dietary_Fiber", group => "1to3y", ref => 16, unit => "g" },
     { symbol => "Dietary_Fiber", group => "general", ref => 30, unit => "g" },
     { symbol => "Dietary_Fiber", group => "pregnant", ref => 35, unit => "g" },
     { symbol => "Dietary_Fiber", group => "breastfeeding", ref => 38, unit => "g" },
     { symbol => "VA", group => "0to6mo", ref => 375, unit => "mcg" },
     { symbol => "VA", group => "7to11mo", ref => 400, unit => "mcg" },
     { symbol => "VA", group => "1to3y", ref => 400, unit => "mcg" },
     { symbol => "VA", group => "general", ref => 600, unit => "mcg" },
     { symbol => "VA", group => "pregnant", ref => 816, unit => "mcg" },
     { symbol => "VA", group => "breastfeeding", ref => 850, unit => "mcg" },
     { symbol => "VD", group => "0to6mo", ref => 5, unit => "mcg" },
     { symbol => "VD", group => "7to11mo", ref => 5, unit => "mcg" },
     { symbol => "VD", group => "1to3y", ref => 15, unit => "mcg" },
     { symbol => "VD", group => "general", ref => 15, unit => "mcg" },
     { symbol => "VD", group => "pregnant", ref => 15, unit => "mcg" },
     { symbol => "VD", group => "breastfeeding", ref => 15, unit => "mcg" },
     { symbol => "VE", group => "0to6mo", ref => 4, unit => "mg" },
     { symbol => "VE", group => "7to11mo", ref => 5, unit => "mg" },
     { symbol => "VE", group => "1to3y", ref => 6, unit => "mg" },
     { symbol => "VE", group => "general", ref => 15, unit => "mg" },
     { symbol => "VE", group => "pregnant", ref => 15, unit => "mg" },
     { symbol => "VE", group => "breastfeeding", ref => 19, unit => "mg" },
     { symbol => "VK", group => "0to6mo", ref => 5, unit => "mcg" },
     { symbol => "VK", group => "7to11mo", ref => 10, unit => "mcg" },
     { symbol => "VK", group => "1to3y", ref => 15, unit => "mcg" },
     { symbol => "VK", group => "general", ref => 60, unit => "mcg" },
     { symbol => "VK", group => "pregnant", ref => 55, unit => "mcg" },
     { symbol => "VK", group => "breastfeeding", ref => 55, unit => "mcg" },
     { symbol => "VB1", group => "0to6mo", ref => 0.3, unit => "mg" },
     { symbol => "VB1", group => "7to11mo", ref => 0.4, unit => "mg" },
     { symbol => "VB1", group => "1to3y", ref => 0.6, unit => "mg" },
     { symbol => "VB1", group => "general", ref => 1.4, unit => "mg" },
     { symbol => "VB1", group => "pregnant", ref => 1.4, unit => "mg" },
     { symbol => "VB1", group => "breastfeeding", ref => 1.4, unit => "mg" },
     { symbol => "VB2", group => "0to6mo", ref => 0.3, unit => "mg" },
     { symbol => "VB2", group => "7to11mo", ref => 0.4, unit => "mg" },
     { symbol => "VB2", group => "1to3y", ref => 0.7, unit => "mg" },
     { symbol => "VB2", group => "general", ref => 1.6, unit => "mg" },
     { symbol => "VB2", group => "pregnant", ref => 1.7, unit => "mg" },
     { symbol => "VB2", group => "breastfeeding", ref => 1.8, unit => "mg" },
     { symbol => "VB3", group => "0to6mo", ref => 2, unit => "mg" },
     { symbol => "VB3", group => "7to11mo", ref => 4, unit => "mg" },
     { symbol => "VB3", group => "1to3y", ref => 6, unit => "mg" },
     { symbol => "VB3", group => "general", ref => 15, unit => "mg" },
     { symbol => "VB3", group => "pregnant", ref => 16, unit => "mg" },
     { symbol => "VB3", group => "breastfeeding", ref => 15, unit => "mg" },
     { symbol => "VB5", group => "0to6mo", ref => 1.7, unit => "mg" },
     { symbol => "VB5", group => "7to11mo", ref => 1.8, unit => "mg" },
     { symbol => "VB5", group => "1to3y", ref => 2, unit => "mg" },
     { symbol => "VB5", group => "general", ref => 5, unit => "mg" },
     { symbol => "VB5", group => "pregnant", ref => 6, unit => "mg" },
     { symbol => "VB5", group => "breastfeeding", ref => 7, unit => "mg" },
     { symbol => "VB6", group => "0to6mo", ref => 0.1, unit => "mg" },
     { symbol => "VB6", group => "7to11mo", ref => 0.3, unit => "mg" },
     { symbol => "VB6", group => "1to3y", ref => 0.5, unit => "mg" },
     { symbol => "VB6", group => "general", ref => 1.3, unit => "mg" },
     { symbol => "VB6", group => "pregnant", ref => 1.7, unit => "mg" },
     { symbol => "VB6", group => "breastfeeding", ref => 1.8, unit => "mg" },
     { symbol => "VB9", group => "0to6mo", ref => 65, unit => "mcg" },
     { symbol => "VB9", group => "7to11mo", ref => 80, unit => "mcg" },
     { symbol => "VB9", group => "1to3y", ref => 160, unit => "mcg" },
     { symbol => "VB9", group => "general", ref => 400, unit => "mcg" },
     { symbol => "VB9", group => "pregnant", ref => 600, unit => "mcg" },
     { symbol => "VB9", group => "breastfeeding", ref => 500, unit => "mcg" },
     { symbol => "VB12", group => "0to6mo", ref => 0.4, unit => "mcg" },
     { symbol => "VB12", group => "7to11mo", ref => 0.5, unit => "mcg" },
     { symbol => "VB12", group => "1to3y", ref => 0.9, unit => "mcg" },
     { symbol => "VB12", group => "general", ref => 2.4, unit => "mcg" },
     { symbol => "VB12", group => "pregnant", ref => 2.6, unit => "mcg" },
     { symbol => "VB12", group => "breastfeeding", ref => 2.8, unit => "mcg" },
     { symbol => "Biotin", group => "0to6mo", ref => 5, unit => "mcg" },
     { symbol => "Biotin", group => "7to11mo", ref => 6, unit => "mcg" },
     { symbol => "Biotin", group => "1to3y", ref => 8, unit => "mcg" },
     { symbol => "Biotin", group => "general", ref => 30, unit => "mcg" },
     { symbol => "Biotin", group => "pregnant", ref => 30, unit => "mcg" },
     { symbol => "Biotin", group => "breastfeeding", ref => 35, unit => "mcg" },
     { symbol => "Choline", group => "0to6mo", ref => 125, unit => "mg" },
     { symbol => "Choline", group => "7to11mo", ref => 150, unit => "mg" },
     { symbol => "Choline", group => "1to3y", ref => 200, unit => "mg" },
     { symbol => "Choline", group => "general", ref => 450, unit => "mg" },
     { symbol => "Choline", group => "pregnant", ref => 450, unit => "mg" },
     { symbol => "Choline", group => "breastfeeding", ref => 500, unit => "mg" },
     { symbol => "VC", group => "0to6mo", ref => 40, unit => "mg" },
     { symbol => "VC", group => "7to11mo", ref => 50, unit => "mg" },
     { symbol => "VC", group => "1to3y", ref => 40, unit => "mg" },
     { symbol => "VC", group => "general", ref => 90, unit => "mg" },
     { symbol => "VC", group => "pregnant", ref => 90, unit => "mg" },
     { symbol => "VC", group => "breastfeeding", ref => 100, unit => "mg" },
     { symbol => "Ca", group => "0to6mo", ref => 200, unit => "mg" },
     { symbol => "Ca", group => "7to11mo", ref => 250, unit => "mg" },
     { symbol => "Ca", group => "1to3y", ref => 650, unit => "mg" },
     { symbol => "Ca", group => "general", ref => 1100, unit => "mg" },
     { symbol => "Ca", group => "pregnant", ref => 1300, unit => "mg" },
     { symbol => "Ca", group => "breastfeeding", ref => 1300, unit => "mg" },
     { symbol => "P", group => "0to6mo", ref => 100, unit => "mg" },
     { symbol => "P", group => "7to11mo", ref => 250, unit => "mg" },
     { symbol => "P", group => "1to3y", ref => 500, unit => "mg" },
     { symbol => "P", group => "general", ref => 700, unit => "mg" },
     { symbol => "P", group => "pregnant", ref => 700, unit => "mg" },
     { symbol => "P", group => "breastfeeding", ref => 700, unit => "mg" },
     { symbol => "Mg", group => "0to6mo", ref => 30, unit => "mg" },
     { symbol => "Mg", group => "7to11mo", ref => 55, unit => "mg" },
     { symbol => "Mg", group => "1to3y", ref => 60, unit => "mg" },
     { symbol => "Mg", group => "general", ref => 350, unit => "mg" },
     { symbol => "Mg", group => "pregnant", ref => 350, unit => "mg" },
     { symbol => "Mg", group => "breastfeeding", ref => 310, unit => "mg" },
     { symbol => "Na", group => "0to6mo", ref => 120, unit => "mg" },
     { symbol => "Na", group => "7to11mo", ref => 200, unit => "mg" },
     { symbol => "Na", group => "1to3y", ref => 1000, unit => "mg" },
     { symbol => "Na", group => "general", ref => 1500, unit => "mg" },
     { symbol => "Na", group => "pregnant", ref => 1500, unit => "mg" },
     { symbol => "Na", group => "breastfeeding", ref => 1500, unit => "mg" },
     { symbol => "K", group => "0to6mo", ref => 500, unit => "mg" },
     { symbol => "K", group => "7to11mo", ref => 700, unit => "mg" },
     { symbol => "K", group => "1to3y", ref => 3000, unit => "mg" },
     { symbol => "K", group => "general", ref => 4700, unit => "mg" },
     { symbol => "K", group => "pregnant", ref => 4700, unit => "mg" },
     { symbol => "K", group => "breastfeeding", ref => 5100, unit => "mg" },
     { symbol => "Mn", group => "0to6mo", ref => 5.5, unit => "mcg" },
     { symbol => "Mn", group => "7to11mo", ref => 600, unit => "mcg" },
     { symbol => "Mn", group => "1to3y", ref => 1200, unit => "mcg" },
     { symbol => "Mn", group => "general", ref => 2000, unit => "mcg" },
     { symbol => "Mn", group => "pregnant", ref => 2000, unit => "mcg" },
     { symbol => "Mn", group => "breastfeeding", ref => 2600, unit => "mcg" },
     { symbol => "Cu", group => "0to6mo", ref => 200, unit => "mcg" },
     { symbol => "Cu", group => "7to11mo", ref => 220, unit => "mcg" },
     { symbol => "Cu", group => "1to3y", ref => 340, unit => "mcg" },
     { symbol => "Cu", group => "general", ref => 800, unit => "mcg" },
     { symbol => "Cu", group => "pregnant", ref => 1000, unit => "mcg" },
     { symbol => "Cu", group => "breastfeeding", ref => 1300, unit => "mcg" },
     { symbol => "Cr", group => "0to6mo", ref => undef, unit => "mcg" },
     { symbol => "Cr", group => "7to11mo", ref => 6, unit => "mcg" },
     { symbol => "Cr", group => "1to3y", ref => 11, unit => "mcg" },
     { symbol => "Cr", group => "general", ref => 26, unit => "mcg" },
     { symbol => "Cr", group => "pregnant", ref => 30, unit => "mcg" },
     { symbol => "Cr", group => "breastfeeding", ref => 45, unit => "mcg" },
     { symbol => "Fe", group => "0to6mo", ref => 2.5, unit => "mg" },
     { symbol => "Fe", group => "7to11mo", ref => 7, unit => "mg" },
     { symbol => "Fe", group => "1to3y", ref => 8, unit => "mg" },
     { symbol => "Fe", group => "general", ref => 22, unit => "mg" },
     { symbol => "Fe", group => "pregnant", ref => 34, unit => "mg" },
     { symbol => "Fe", group => "breastfeeding", ref => 33, unit => "mg" },
     { symbol => "I", group => "0to6mo", ref => 90, unit => "mcg" },
     { symbol => "I", group => "7to11mo", ref => 120, unit => "mcg" },
     { symbol => "I", group => "1to3y", ref => 120, unit => "mcg" },
     { symbol => "I", group => "general", ref => 150, unit => "mcg" },
     { symbol => "I", group => "pregnant", ref => 220, unit => "mcg" },
     { symbol => "I", group => "breastfeeding", ref => 250, unit => "mcg" },
     { symbol => "Zn", group => "0to6mo", ref => 2.75, unit => "mg" },
     { symbol => "Zn", group => "7to11mo", ref => 3, unit => "mg" },
     { symbol => "Zn", group => "1to3y", ref => 4, unit => "mg" },
     { symbol => "Zn", group => "general", ref => 13, unit => "mg" },
     { symbol => "Zn", group => "pregnant", ref => 16, unit => "mg" },
     { symbol => "Zn", group => "breastfeeding", ref => 15, unit => "mg" },
     { symbol => "Se", group => "0to6mo", ref => 5, unit => "mcg" },
     { symbol => "Se", group => "7to11mo", ref => 10, unit => "mcg" },
     { symbol => "Se", group => "1to3y", ref => 17, unit => "mcg" },
     { symbol => "Se", group => "general", ref => 30, unit => "mcg" },
     { symbol => "Se", group => "pregnant", ref => 35, unit => "mcg" },
     { symbol => "Se", group => "breastfeeding", ref => 40, unit => "mcg" },
     { symbol => "F", group => "0to6mo", ref => undef, unit => "mg" },
     { symbol => "F", group => "7to11mo", ref => 0.4, unit => "mg" },
     { symbol => "F", group => "1to3y", ref => 0.6, unit => "mg" },
     { symbol => "F", group => "general", ref => 2.5, unit => "mg" },
     { symbol => "F", group => "pregnant", ref => 2.5, unit => "mg" },
     { symbol => "F", group => "breastfeeding", ref => 2.5, unit => "mg" },
     { symbol => "L_Carnitine", group => "0to6mo", ref => 6.6, unit => "mg" },
     { symbol => "L_Carnitine", group => "7to11mo", ref => 8.7, unit => "mg" },
     { symbol => "L_Carnitine", group => "1to3y", ref => 13.5, unit => "mg" },
     { symbol => "L_Carnitine", group => "general", ref => undef, unit => "mg" },
     { symbol => "L_Carnitine", group => "pregnant", ref => undef, unit => "mg" },
     {
       symbol => "L_Carnitine",
       group  => "breastfeeding",
       ref    => undef,
       unit   => "mg",
     },
     { symbol => "Myo_Inositol", group => "0to6mo", ref => 22, unit => "mg" },
     { symbol => "Myo_Inositol", group => "7to11mo", ref => 29, unit => "mg" },
     { symbol => "Myo_Inositol", group => "1to3y", ref => 45, unit => "mg" },
     { symbol => "Myo_Inositol", group => "general", ref => undef, unit => "mg" },
     { symbol => "Myo_Inositol", group => "pregnant", ref => undef, unit => "mg" },
     {
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
