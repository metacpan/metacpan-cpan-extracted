#!/usr/bin/perl

# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Example demonstrating interaction with the store from a CGI script

use strict;
use warnings;

use Data::Displaycolour;
use Template;

my $tt = Template->new;

print "Content-type: text/html\x0D\x0A";
print "\x0D\x0A";

my @palettes;

my $columns = 0;
my $columns_extra = 1; # force a minimum of 1 so we don't render invalid HTML
my %columns;
my @column_names;

# build our index, go for fallbacks first as that will improve ordering considerably
foreach my $palette ('fallbacks', sort Data::Displaycolour->known('palettes')) {
    my $c = Data::Displaycolour->list_colours($palette);
    my $extra = 0;

    foreach my $rgb (sort keys %{$c}) {
        if (defined(my $abstract = $c->{$rgb})) {
            my $abstract = $c->{$rgb};
            my $ise = $abstract->ise;
            $columns{$ise} //= $columns++;
            $column_names[$columns{$ise}] //= $abstract->displayname(default => undef, no_defaults => 1);
        } else {
            $extra++;
        }
    }

    $columns_extra = $extra if $extra > $columns_extra;
}

foreach my $palette (sort Data::Displaycolour->known('palettes')) {
    my @colours;
    my $r = {name => $palette, colours => \@colours};
    my $c = Data::Displaycolour->list_colours($palette);

    $#colours = $columns - 1;

    foreach my $rgb (sort keys %{$c}) {
        if (defined(my $abstract = $c->{$rgb})) {
            $colours[$columns{$abstract->ise}] = $rgb;
        } else {
            push(@colours, $rgb);
        }
    }

    push(@palettes, $r);
}

$tt->process(\*DATA, {
        column_names => \@column_names,
        palettes => \@palettes,
        columns_extra => $columns_extra,
    });

#ll
__DATA__
<!DOCTYPE html>
<html>
    <head>
        <title>Palettes</title>
        <meta charset="utf-8">
        <style>
body {
    background-color: black;
    color: wheat;
}
table, tr, td, th {
    border: 1px solid wheat;
    border-collapse: collapse;
}
td, th {
    padding: 5px;
}
td {
    text-shadow: -1px -1px black, 1px -1px black, -1px 1px black, 1px 1px black;
    color: white;
}
        </style>
    </head>
    <body>
        <h1>Palettes</h1>

        <table>
        <tr>
            <th>Palette</th>
            [% FOREACH name IN column_names %]
            <th>[% name | html %]</th>
            [% END %]
            <th colspan="[% columns_extra | html %]">Extra colours</th>
        </tr>
        [% FOREACH palette IN palettes %]
        <tr>
            <th>[% palette.name | html %]</th>
            [% FOREACH c IN palette.colours %]
            [% IF c %]
            <td style="background-color: [% c | html %];">[% c | html %]</td>
            [% ELSE %]
            <td>-</td>
            [% END %]
            [% END %]
        </tr>
        [% END %]
        </table>
    </body>
</html>
