#!/usr/bin/perl

# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Example demonstrating interaction with the store from a CGI script

use strict;
use warnings;

use Data::Identifier::Wellknown 'colour';
use Data::Displaycolour;
use Template;
use CGI::Simple;

my $cgi = CGI::Simple->new;
my $tt = Template->new;
my @for_keys = qw(name username displayname text email);

print "Content-type: text/html\x0D\x0A";
print "\x0D\x0A";

my %query = map {$_ => scalar($cgi->param($_))} (map {'for_'.$_} @for_keys), qw(palette);

$query{palette} ||= 'v0';

my $dc = Data::Displaycolour->new(%query);

$tt->process(\*DATA, {
        cgi => $cgi,
        for_keys => \@for_keys,
        palettes => [sort Data::Displaycolour->known('palettes')],
        palette => $query{palette},
        colour => {
            rgb         => $dc->rgb(default => undef, no_defaults => 1),
            abstract    => $dc->abstract('Data::Identifier', default => undef, no_defaults => 1),
            specific    => $dc->specific('Data::Identifier', default => undef, no_defaults => 1),
        },
    });

#ll
__DATA__
<!DOCTYPE html>
<html>
    <head>
        <title>Colour lookup</title>
        <meta charset="utf-8">
        <style>
body {
    background-color: black;
    color: wheat;
}
form {
    display: grid;
    grid-template-columns: 1fr 5fr;
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
.inline {
    display: inline;
}
        </style>
    </head>
    <body>
        <h1>Colour lookup</h1>

        <form id="input">
            <label>Palette</label>
            <select name="palette">
                <option selected>[% palette | html %]</option>
                <option disabled>&#8213;&#8213;&#8213;&#8213;&#8213;</option>
                [% FOREACH palette IN palettes %]
                <option>[% palette | html %]</option>
                [% END %]
            </select>
            [% FOREACH key IN for_keys %]
            <label for="for_[% key | html %]">[% key | html %]</label>
            <input type="text" id="for_[% key | html %]" name="for_[% key | html %]" value="[% cgi.param("for_$key") | html %]">
            [% END %]

            <div>
            <input type="reset">
            <input type="submit">
            </div>
        </form>

        <h2>Result</h2>
        <table>
        [% IF colour.rgb %]
        <tr>
            <th>RGB</th>
            <td style="background-color: [% colour.rgb | html %];">[% colour.rgb | html %]</td>
        </tr>
        [% END %]
        [% IF colour.abstract %]
        <tr>
            <th>Abstract</th>
            <td><pre class="inline ise">[% colour.abstract.ise | html %]</pre>[% IF colour.abstract.displayname('default', undef, 'no_defaults', 1) %] ([% colour.abstract.displayname('default', undef, 'no_defaults', 1) | html %])[% END %]</td>
        </tr>
        [% END %]
        [% IF colour.specific %]
        <tr>
            <th>Specific</th>
            <td><pre class="inline ise">[% colour.specific.ise | html %]</pre>[% IF colour.specific.displayname('default', undef, 'no_defaults', 1) %] ([% colour.specific.displayname('default', undef, 'no_defaults', 1) | html %])[% END %]</td>
        </tr>
        [% END %]
        </table>
    </body>
</html>
