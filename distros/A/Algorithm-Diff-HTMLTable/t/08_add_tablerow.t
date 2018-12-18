#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use Algorithm::Diff::HTMLTable;

my $table = Algorithm::Diff::HTMLTable->new;

{
    my $row = $table->_add_tablerow(
        line_nr_a => 20,
        line_nr_b => 19,
    );

    my $check = q~
        <tr style="border: 1px solid">
            <td style="background-color: gray">20</td>
            <td ></td>
            <td style="background-color: gray">19</td>
            <td ></td>
        </tr>
    ~;

    is_string $row, $check;
}

{
    my $row = $table->_add_tablerow(
        line_nr_a => 20,
        line_a    => 'This is a T"est',
        line_nr_b => 19,
    );

    my $check = q~
        <tr style="border: 1px solid">
            <td style="background-color: gray">20</td>
            <td >This&nbsp;is&nbsp;a&nbsp;T&quot;est</td>
            <td style="background-color: gray">19</td>
            <td ></td>
        </tr>
    ~;

    is_string $row, $check;
}

{
    my $row = $table->_add_tablerow(
        line_nr_a => 20,
        line_a    => 'This is a T"est',
        line_b    => 'This is a T"est',
        line_nr_b => 19,
    );

    my $check = q~
        <tr style="border: 1px solid">
            <td style="background-color: gray">20</td>
            <td >This&nbsp;is&nbsp;a&nbsp;T&quot;est</td>
            <td style="background-color: gray">19</td>
            <td >This&nbsp;is&nbsp;a&nbsp;T&quot;est</td>
        </tr>
    ~;

    is_string $row, $check;
}

{
    my $row = $table->_add_tablerow(
        line_nr_a => 20,
        line_b    => 'This is a T"est',
        line_nr_b => 19,
    );

    my $check = q~
        <tr style="border: 1px solid">
            <td style="background-color: gray">20</td>
            <td ></td>
            <td style="background-color: gray">19</td>
            <td >This&nbsp;is&nbsp;a&nbsp;T&quot;est</td>
        </tr>
    ~;

    is_string $row, $check;
}

{
    my $row = $table->_add_tablerow(
        line_nr_a => 20,
        line_b    => 'This is a T"est',
        color_b   => 'green',
        line_nr_b => 19,
    );

    my $check = q~
        <tr style="border: 1px solid">
            <td style="background-color: gray">20</td>
            <td ></td>
            <td style="background-color: gray">19</td>
            <td style="color: green;">This&nbsp;is&nbsp;a&nbsp;T&quot;est</td>
        </tr>
    ~;

    is_string $row, $check;
}

done_testing();
