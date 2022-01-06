package Acme::CPANModules::TextTable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-31'; # DATE
our $DIST = 'Acme-CPANModules-TextTable'; # DIST
our $VERSION = '0.013'; # VERSION

use 5.010001;
use strict;
use warnings;
use utf8;

sub _make_table {
    my ($cols, $rows, $celltext) = @_;
    my $res = [];
    push @$res, [];
    for (0..$cols-1) { $res->[0][$_] = "col" . ($_+1) }
    for my $row (1..$rows) {
        push @$res, [ map { $celltext // "row$row.$_" } 1..$cols ];
    }
    $res;
}

our $LIST = {
    summary => 'Modules that generate text tables',
    entry_features => {
        wide_char => {summary => 'Whether the use of wide characters (e.g. Kanji) in cells does not cause the table to be misaligned'},
        color_data =>  {summary => 'Whether module supports ANSI colors (i.e. text with ANSI color codes can still be aligned properly)'},
        multiline_data => {summary => 'Whether module supports aligning data cells that contain newlines'},

        box_char => {summary => 'Whether module can utilize box-drawing characters'},
        custom_border => {summary => 'Whether module allows customizing border in some way'},

        align_row => {summary => "Whether module supports aligning text horizontally in a row (left/right/middle)"},
        align_column => {summary => "Whether module supports aligning text horizontally in a column (left/right/middle)"},
        align_cell => {summary => "Whether module supports aligning text horizontally in individual cells (left/right/middle)"},

        valign_row => {summary => "Whether module supports aligning text vertically in a row (top/bottom/middle)"},
        valign_column => {summary => "Whether module supports aligning text vertically in a column (top/bottom/middle)"},
        valign_cell => {summary => "Whether module supports aligning text vertically in individual cells (top/bottom/middle)"},

        rowspan => {summary => "Whether module supports row spans"},
        colspan => {summary => "Whether module supports column spans"},

        custom_color => {summary => 'Whether the module produces colored table and supports customizing color in some way'},
        color_theme => {summary => 'Whether the module supports color theme/scheme'},

        speed => {summary => "Rendering speed", schema=>'str*'},

        column_width => {summary => 'Whether module allows setting the width of columns'},
        per_column_width => {summary => 'Whether module allows setting column width on a per-column basis'},
        row_height => {summary => 'Whether module allows setting the height of rows'},
        per_row_height => {summary => 'Whether module allows setting row height on a per-row basis'},

        pad => {summary => 'Whether module allows customizing cell horizontal padding'},
        vpad => {summary => 'Whether module allows customizing cell vertical padding'},
    },
    entries => [
        {
            module => 'Text::Table::Any',
            description => <<'_',

This is a frontend for many text table modules as backends. The interface is
dead simple, following <pm:Text::Table::Tiny>. The main drawback is that it
currently does not allow passing (some, any) options to each backend.

_
            bench_code => sub {
                my ($table) = @_;
                Text::Table::Any::table(rows=>$table, header_row=>1);
            },
            features => {
                align_cell     => {value=>undef, summary=>"Depends on backend"},
                align_column   => {value=>undef, summary=>"Depends on backend"},
                align_row      => {value=>undef, summary=>"Depends on backend"},
                box_char       => {value=>undef, summary=>"Depends on backend"},
                color_data     => {value=>undef, summary=>"Depends on backend"},
                color_theme    => {value=>undef, summary=>"Depends on backend"},
                colspan        => {value=>undef, summary=>"Depends on backend"},
                custom_border  => {value=>undef, summary=>"Depends on backend"},
                custom_color   => {value=>undef, summary=>"Depends on backend"},
                multiline_data => {value=>undef, summary=>"Depends on backend"},
                rowspan        => {value=>undef, summary=>"Depends on backend"},
                speed          => {value=>undef, summary=>"Depends on backend"},
                valign_cell    => {value=>undef, summary=>"Depends on backend"},
                valign_column  => {value=>undef, summary=>"Depends on backend"},
                valign_row     => {value=>undef, summary=>"Depends on backend"},
                wide_char_data => {value=>undef, summary=>"Depends on backend"},
            },
        },

        {
            module => 'Text::UnicodeBox::Table',
            description => <<'_',

The main feature of this module is the various border style it provides drawn
using Unicode box-drawing characters. It allows per-row style. The rendering
speed is particularly slow compared to other modules.

_
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::UnicodeBox::Table->new;
                $t->add_header(@{ $table->[0] });
                $t->add_row(@{ $table->[$_] }) for 1..$#{$table};
                $t->render;
            },
            features => {
                align_cell => 0,
                align_column => 1,
                box_char => 0,
                color_data => 1,
                color_theme => 0,
                colspan => 0,
                custom_border => 1,
                custom_color => 0,
                multiline_data => 0,
                rowspan => 0,
                wide_char_data => 1,
                speed => "slow",
            },
        },

        {
            module => 'Text::Table::Manifold',
            description => <<'_',

Two main features of this module is per-column aligning and wide character
support. This module, aside from doing its rendering, can also be told to pass
rendering to HTML, CSV, or other text table module like
<pm:Text::UnicodeBox::Table>); so in this way it is similar to
<pm:Text::Table::Any>.

_
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::Table::Manifold->new;
                $t->headers($table->[0]);
                $t->data([ @{$table}[1 .. $#{$table}] ]);
                join("\n", @{$t->render(padding => 1)}) . "\n";
            },
            features => {
                align_cell => 0,
                align_column => 1,
                box_char => undef, # ?
                color_data => 1,
                color_theme => 0,
                colspan => 0,
                custom_border => {value=>0, summary=>"But this module can pass rendering to other module like Text::UnicodeBox::Table"},
                custom_color => 0,
                multiline_data => 0,
                rowspan => 0,
                wide_char_data => 1,
            },
        },

        {
            module => 'Text::ANSITable',
            description => <<'_',

This 2013 project was my take in creating a text table module that can handle
color, multiline text, wide characters. I also threw in various formatting
options, e.g. per-column/row/cell align/valign/pad/vpad, conditional formatting,
and so on. I even added a couple of features I never used: hiding rows and
specifying columns to display which can be in different order from the original
specified columns or can contain the same original columns multiple times. I
think this module offers the most formatting options on CPAN.

In early 2021, I needed colspan/rowspan and I implemented this in a new module:
<pm:Text::Table::Span> (later renamed to <pm:Text::Table::More>). I plan to add
this feature too to Text::ANSITable, but in the meantime I'm also adding more
formatting options which I need to Text::Table::More.

_
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::ANSITable->new(
                    use_utf8 => 0,
                    use_box_chars => 0,
                    use_color =>  0,
                    columns => $table->[0],
                    border_style => 'ASCII::SingleLine',
                );
                $t->add_row($table->[$_]) for 1..@$table-1;
                $t->draw;
            },
            features => {
                align_cell => 1,
                align_column => 1,
                align_row => 1,
                box_char => 1,
                color_data =>  1,
                color_theme => 1,
                colspan => 0,
                column_width => 1,
                custom_border => 1,
                custom_color => 1,
                multiline_data => 1,
                pad => 1,
                per_column_width => 1,
                per_row_height => 1,
                row_height => 1,
                rowspan => 0,
                speed => "slow",
                valign_cell => 1,
                valign_column => 1,
                valign_row => 1,
                vpad => 1,
                wide_char_data => 1,
            },
        },

        {
            module => 'Text::ASCIITable',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::ASCIITable->new();
                $t->setCols(@{ $table->[0] });
                $t->addRow(@{ $table->[$_] }) for 1..@$table-1;
                "$t";
            },
            features => {
                wide_char_data => 0,
                color_data =>  0,
                box_char => 0,
                multiline_data => 1,
            },
        },
        {
            module => 'Text::FormatTable',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::FormatTable->new(join('|', ('l') x @{ $table->[0] }));
                $t->head(@{ $table->[0] });
                $t->row(@{ $table->[$_] }) for 1..@$table-1;
                $t->render;
            },
            features => {
                wide_char_data => 0,
                color_data =>  0,
                box_char => 0,
                multiline_data => 1,
            },
        },
        {
            module => 'Text::MarkdownTable',
            bench_code => sub {
                my ($table) = @_;
                my $out = "";
                my $t = Text::MarkdownTable->new(file => \$out);
                my $fields = $table->[0];
                foreach (1..@$table-1) {
                    my $row = $table->[$_];
                    $t->add( {
                        map { $fields->[$_] => $row->[$_] } 0..@$fields-1
                    });
                }
                $t->done;
                $out;
            },
            features => {
                wide_char_data => 0,
                color_data =>  0,
                box_char => 0,
                multiline_data => {value=>0, summary=>'Newlines stripped'},
            },
        },
        {
            module => 'Text::Table',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::Table->new(@{ $table->[0] });
                $t->load(@{ $table }[1..@$table-1]);
                $t;
            },
            features => {
                wide_char_data => 0,
                color_data =>  0,
                box_char => {value=>undef, summary=>'Does not draw borders'},
                multiline_data => 1,
            },
        },
        {
            module => 'Text::Table::Tiny',
            description => <<'_',

The simple and tiny table-generating module which I liked back in 2012 (v0.03).
It employs an sprintf() trick to generate a single row. This module started my
personal experiments creating other table-generating modules (at last count I've
created no fewer than 15 of them!).

_
            bench_code => sub {
                my ($table) = @_;
                Text::Table::Tiny::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char_data => 1,
                color_data =>  1,
                box_char => 1,
                multiline_data => 0,
            },
        },
        {
            module => 'Text::Table::TinyBorderStyle',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyBorderStyle::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char_data => 0,
                color_data =>  0,
                box_char => 1,
                multiline_data => 0,
            },
        },
        {
            module => 'Text::Table::More',
            description => <<'_',

A module I wrote in early 2021. Main distinguishing feature is support for
rowspan/clospan. I plan to add more features to this module on an as-needed
basic. This module is now preferred to <pm:Text::ANSITable>, although currently
it does not offer nearly as many formatting options as Text::ANSITable.

_
            bench_code => sub {
                my ($table) = @_;
                Text::Table::More::generate_table(rows=>$table, header_row=>1);
            },
            features => {
                align_cell => 1,
                align_column => 1,
                align_row => 1,
                box_char => 1,
                color_data =>  1,
                color_theme => 0,
                colspan => 1,
                custom_border => 1,
                custom_color => 0,
                multiline_data => 1,
                rowspan => 1,
                speed => "slow",
                valign_cell => 1,
                valign_column => 1,
                valign_row => 1,
                wide_char_data => 1,
                column_width => 0, # todo
                per_column_width => 0, # todo
                row_height => 0, # todo
                per_row_height => 0, # todo
                pad => 0, # todo
                vpad => 0, # todo
            },
        },
        {
            module => 'Text::Table::Sprintf',
            description => <<'_',

A performant (see benchmark result) and lightweight (a page of code, no use of
modules at all), but with minimal extra features.

_
            bench_code => sub {
                my ($table) = @_;
                Text::Table::Sprintf::table(rows=>$table, header_row=>1);
            },
            features => {
                box_char => 0,
                color_data =>  0,
                multiline_data => 0,
                speed => "fast",
                wide_char_data => 0,
            },
        },
        {
            module => 'Text::Table::TinyColor',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyColor::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char_data => 0,
                color_data =>  1,
                box_char => 0,
                multiline_data => 0,
            },
        },
        {
            module => 'Text::Table::TinyColorWide',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyColorWide::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char_data => 1,
                color_data =>  1,
                box_char => 0,
                multiline_data => 0,
            },
        },
        {
            module => 'Text::Table::TinyWide',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyWide::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char_data => 1,
                color_data =>  0,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::Org',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::Org::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char_data => 0,
                color_data =>  0,
                box_char => 0,
                multiline_data => 0,
            },
        },
        {
            module => 'Text::Table::CSV',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::CSV::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char_data => 1,
                color_data =>  0,
                box_char => {value=>undef, summary=>"Irrelevant"},
                multiline_data => {value=>1, summary=>"But make sure your CSV parser can handle multiline cell"},
            },
        },
        {
            module => 'Text::Table::HTML',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::HTML::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char_data => 1,
                color_data =>  {value=>0, summary=>'Not converted to HTML color elements'},
                box_char => 0,
                multiline_data => 1,
            },
        },
        {
            module => 'Text::Table::HTML::DataTables',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::HTML::DataTables::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char_data => 1,
                color_data =>  {value=>0, summary=>'Not converted to HTML color elements'},
                box_char => 0,
                multiline_data => 1,
            },
        },
        {
            module => 'Text::TabularDisplay',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::TabularDisplay->new(@{ $table->[0] });
                $t->add(@{ $table->[$_] }) for 1..@$table-1;
                $t->render; # doesn't add newline
            },
            features => {
                wide_char_data => 1,
                color_data =>  0,
                box_char => {value=>undef, summary=>"Irrelevant"},
                multiline_data => 1,
            },
        },
    ],

    bench_datasets => [
        {name=>'tiny (1x1)'          , argv => [_make_table( 1, 1)],},
        {name=>'small (3x5)'         , argv => [_make_table( 3, 5)],},
        {name=>'wide (30x5)'         , argv => [_make_table(30, 5)],},
        {name=>'long (3x300)'        , argv => [_make_table( 3, 300)],},
        {name=>'large (30x300)'      , argv => [_make_table(30, 300)],},
        {name=>'multiline data (2x1)', argv => [ [["col1", "col2"], ["foobar\nbaz\nqux\nquux","corge"]] ], include_by_default=>0 },
        {name=>'wide char data (1x2)', argv => [ [["col1"], ["no wide character"], ["宽字"]] ], include_by_default=>0 },
        {name=>'color data (1x2)'    , argv => [ [["col1"], ["no color"], ["\e[31m\e[1mwith\e[0m \e[32m\e[1mcolor\e[0m"]] ], include_by_default=>0 },
    ],

};

1;
# ABSTRACT: Modules that generate text tables

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::TextTable - Modules that generate text tables

=head1 VERSION

This document describes version 0.013 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2021-07-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module TextTable

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module TextTable

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Text::Table::Any>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

This is a frontend for many text table modules as backends. The interface is
dead simple, following L<Text::Table::Tiny>. The main drawback is that it
currently does not allow passing (some, any) options to each backend.


=item L<Text::UnicodeBox::Table>

Author: L<EWATERS|https://metacpan.org/author/EWATERS>

The main feature of this module is the various border style it provides drawn
using Unicode box-drawing characters. It allows per-row style. The rendering
speed is particularly slow compared to other modules.


=item L<Text::Table::Manifold>

Author: L<RSAVAGE|https://metacpan.org/author/RSAVAGE>

Two main features of this module is per-column aligning and wide character
support. This module, aside from doing its rendering, can also be told to pass
rendering to HTML, CSV, or other text table module like
L<Text::UnicodeBox::Table>); so in this way it is similar to
L<Text::Table::Any>.


=item L<Text::ANSITable>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

This 2013 project was my take in creating a text table module that can handle
color, multiline text, wide characters. I also threw in various formatting
options, e.g. per-column/row/cell align/valign/pad/vpad, conditional formatting,
and so on. I even added a couple of features I never used: hiding rows and
specifying columns to display which can be in different order from the original
specified columns or can contain the same original columns multiple times. I
think this module offers the most formatting options on CPAN.

In early 2021, I needed colspan/rowspan and I implemented this in a new module:
L<Text::Table::Span> (later renamed to L<Text::Table::More>). I plan to add
this feature too to Text::ANSITable, but in the meantime I'm also adding more
formatting options which I need to Text::Table::More.


=item L<Text::ASCIITable>

Author: L<LUNATIC|https://metacpan.org/author/LUNATIC>

=item L<Text::FormatTable>

Author: L<TREY|https://metacpan.org/author/TREY>

=item L<Text::MarkdownTable>

Author: L<VOJ|https://metacpan.org/author/VOJ>

=item L<Text::Table>

Author: L<SHLOMIF|https://metacpan.org/author/SHLOMIF>

=item L<Text::Table::Tiny>

Author: L<NEILB|https://metacpan.org/author/NEILB>

The simple and tiny table-generating module which I liked back in 2012 (v0.03).
It employs an sprintf() trick to generate a single row. This module started my
personal experiments creating other table-generating modules (at last count I've
created no fewer than 15 of them!).


=item L<Text::Table::TinyBorderStyle>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::More>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

A module I wrote in early 2021. Main distinguishing feature is support for
rowspan/clospan. I plan to add more features to this module on an as-needed
basic. This module is now preferred to L<Text::ANSITable>, although currently
it does not offer nearly as many formatting options as Text::ANSITable.


=item L<Text::Table::Sprintf>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

A performant (see benchmark result) and lightweight (a page of code, no use of
modules at all), but with minimal extra features.


=item L<Text::Table::TinyColor>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::TinyColorWide>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::TinyWide>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::Org>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::CSV>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::HTML>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::HTML::DataTables>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::TabularDisplay>

Author: L<DARREN|https://metacpan.org/author/DARREN>

=back

=head1 ACME::CPANMODULES FEATURE COMPARISON MATRIX

 +-------------------------------+----------------+------------------+---------------+--------------+----------------+-----------------+-------------+-------------------+------------------+---------------------+--------------+------------+------------------+--------------------+-----------------+----------------+-------------------+----------+-----------------------+---------------------+-----------------+-----------+
 | module                        | align_cell *1) | align_column *2) | align_row *3) | box_char *4) | color_data *5) | color_theme *6) | colspan *7) | custom_border *8) | custom_color *9) | multiline_data *10) | rowspan *11) | speed *12) | valign_cell *13) | valign_column *14) | valign_row *15) | wide_char_data | column_width *16) | pad *17) | per_column_width *18) | per_row_height *19) | row_height *20) | vpad *21) |
 +-------------------------------+----------------+------------------+---------------+--------------+----------------+-----------------+-------------+-------------------+------------------+---------------------+--------------+------------+------------------+--------------------+-----------------+----------------+-------------------+----------+-----------------------+---------------------+-----------------+-----------+
 | Text::Table::Any              | N/A *22)       | N/A *22)         | N/A *22)      | N/A *22)     | N/A *22)       | N/A *22)        | N/A *22)    | N/A *22)          | N/A *22)         | N/A *22)            | N/A *22)     | N/A *22)   | N/A *22)         | N/A *22)           | N/A *22)        | N/A *22)       | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::UnicodeBox::Table       | no             | yes              | N/A           | no           | yes            | no              | no          | yes               | no               | no                  | no           | slow       | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::Manifold         | no             | yes              | N/A           | N/A          | yes            | no              | no          | no *23)           | no               | no                  | no           | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::ANSITable               | yes            | yes              | yes           | yes          | yes            | yes             | no          | yes               | yes              | yes                 | no           | slow       | yes              | yes                | yes             | yes            | yes               | yes      | yes                   | yes                 | yes             | yes       |
 | Text::ASCIITable              | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::FormatTable             | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::MarkdownTable           | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | no *24)             | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table                   | N/A            | N/A              | N/A           | N/A *25)     | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::Tiny             | N/A            | N/A              | N/A           | yes          | yes            | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyBorderStyle  | N/A            | N/A              | N/A           | yes          | no             | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::More             | yes            | yes              | yes           | yes          | yes            | no              | yes         | yes               | no               | yes                 | yes          | slow       | yes              | yes                | yes             | yes            | no                | no       | no                    | no                  | no              | no        |
 | Text::Table::Sprintf          | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | fast       | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyColor        | N/A            | N/A              | N/A           | no           | yes            | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyColorWide    | N/A            | N/A              | N/A           | no           | yes            | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyWide         | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | N/A                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::Org              | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::CSV              | N/A            | N/A              | N/A           | N/A *26)     | no             | N/A             | N/A         | N/A               | N/A              | yes *27)            | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::HTML             | N/A            | N/A              | N/A           | no           | no *28)        | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::HTML::DataTables | N/A            | N/A              | N/A           | no           | no *28)        | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::TabularDisplay          | N/A            | N/A              | N/A           | N/A *26)     | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 +-------------------------------+----------------+------------------+---------------+--------------+----------------+-----------------+-------------+-------------------+------------------+---------------------+--------------+------------+------------------+--------------------+-----------------+----------------+-------------------+----------+-----------------------+---------------------+-----------------+-----------+
 


Notes:

=over

=item 1. align_cell: Whether module supports aligning text horizontally in individual cells (left/right/middle)

=item 2. align_column: Whether module supports aligning text horizontally in a column (left/right/middle)

=item 3. align_row: Whether module supports aligning text horizontally in a row (left/right/middle)

=item 4. box_char: Whether module can utilize box-drawing characters

=item 5. color_data: Whether module supports ANSI colors (i.e. text with ANSI color codes can still be aligned properly)

=item 6. color_theme: Whether the module supports color theme/scheme

=item 7. colspan: Whether module supports column spans

=item 8. custom_border: Whether module allows customizing border in some way

=item 9. custom_color: Whether the module produces colored table and supports customizing color in some way

=item 10. multiline_data: Whether module supports aligning data cells that contain newlines

=item 11. rowspan: Whether module supports row spans

=item 12. speed: Rendering speed

=item 13. valign_cell: Whether module supports aligning text vertically in individual cells (top/bottom/middle)

=item 14. valign_column: Whether module supports aligning text vertically in a column (top/bottom/middle)

=item 15. valign_row: Whether module supports aligning text vertically in a row (top/bottom/middle)

=item 16. column_width: Whether module allows setting the width of columns

=item 17. pad: Whether module allows customizing cell horizontal padding

=item 18. per_column_width: Whether module allows setting column width on a per-column basis

=item 19. per_row_height: Whether module allows setting row height on a per-row basis

=item 20. row_height: Whether module allows setting the height of rows

=item 21. vpad: Whether module allows customizing cell vertical padding

=item 22. Depends on backend

=item 23. But this module can pass rendering to other module like Text::UnicodeBox::Table

=item 24. Newlines stripped

=item 25. Does not draw borders

=item 26. Irrelevant

=item 27. But make sure your CSV parser can handle multiline cell

=item 28. Not converted to HTML color elements

=back

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Table::Any> 0.104

L<Text::UnicodeBox::Table>

L<Text::Table::Manifold> 1.03

L<Text::ANSITable> 0.602

L<Text::ASCIITable> 0.22

L<Text::FormatTable> 1.03

L<Text::MarkdownTable> 0.3.1

L<Text::Table> 1.134

L<Text::Table::Tiny> 1.02

L<Text::Table::TinyBorderStyle> 0.004

L<Text::Table::More> 0.014

L<Text::Table::Sprintf> 0.003

L<Text::Table::TinyColor> 0.002

L<Text::Table::TinyColorWide> 0.001

L<Text::Table::TinyWide> 0.001

L<Text::Table::Org> 0.02

L<Text::Table::CSV> 0.023

L<Text::Table::HTML> 0.004

L<Text::Table::HTML::DataTables> 0.007

L<Text::TabularDisplay> 1.38

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::Table::Any (perl_code)

L<Text::Table::Any>



=item * Text::UnicodeBox::Table (perl_code)

L<Text::UnicodeBox::Table>



=item * Text::Table::Manifold (perl_code)

L<Text::Table::Manifold>



=item * Text::ANSITable (perl_code)

L<Text::ANSITable>



=item * Text::ASCIITable (perl_code)

L<Text::ASCIITable>



=item * Text::FormatTable (perl_code)

L<Text::FormatTable>



=item * Text::MarkdownTable (perl_code)

L<Text::MarkdownTable>



=item * Text::Table (perl_code)

L<Text::Table>



=item * Text::Table::Tiny (perl_code)

L<Text::Table::Tiny>



=item * Text::Table::TinyBorderStyle (perl_code)

L<Text::Table::TinyBorderStyle>



=item * Text::Table::More (perl_code)

L<Text::Table::More>



=item * Text::Table::Sprintf (perl_code)

L<Text::Table::Sprintf>



=item * Text::Table::TinyColor (perl_code)

L<Text::Table::TinyColor>



=item * Text::Table::TinyColorWide (perl_code)

L<Text::Table::TinyColorWide>



=item * Text::Table::TinyWide (perl_code)

L<Text::Table::TinyWide>



=item * Text::Table::Org (perl_code)

L<Text::Table::Org>



=item * Text::Table::CSV (perl_code)

L<Text::Table::CSV>



=item * Text::Table::HTML (perl_code)

L<Text::Table::HTML>



=item * Text::Table::HTML::DataTables (perl_code)

L<Text::Table::HTML::DataTables>



=item * Text::TabularDisplay (perl_code)

L<Text::TabularDisplay>



=back

=head1 BENCHMARK DATASETS

=over

=item * tiny (1x1)

=item * small (3x5)

=item * wide (30x5)

=item * long (3x300)

=item * large (30x300)

=item * multiline data (2x1) (not included by default)

=item * wide char data (1x2) (not included by default)

=item * color data (1x2) (not included by default)

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher --cpanmodules-module TextTable

Result formatted as table (split, part 1 of 5):

 #table1#
 {dataset=>"large (30x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |      1.44 |    696    |                 0.00% |             38063.55% |   0.00046 |      20 |
 | Text::ANSITable               |      3.28 |    305    |               128.30% |             16616.21% |   0.0002  |      20 |
 | Text::Table::More             |      6.66 |    150    |               363.51% |              8133.67% |   0.00014 |      20 |
 | Text::ASCIITable              |     15    |     66    |               947.67% |              3542.72% | 7.8e-05   |      20 |
 | Text::Table::TinyColorWide    |     22.1  |     45.2  |              1439.32% |              2379.25% |   2e-05   |      20 |
 | Text::FormatTable             |     22.8  |     43.9  |              1483.83% |              2309.58% | 3.2e-05   |      20 |
 | Text::Table::TinyWide         |     31.2  |     32    |              2072.28% |              1656.84% | 1.1e-05   |      20 |
 | Text::Table::Manifold         |     49    |     20    |              3318.43% |              1016.41% | 2.4e-05   |      20 |
 | Text::Table::Tiny             |     53    |     19    |              3583.64% |               936.03% | 3.4e-05   |      20 |
 | Text::TabularDisplay          |     58.7  |     17    |              3985.42% |               834.14% | 5.6e-06   |      20 |
 | Text::Table::TinyColor        |     78.8  |     12.7  |              5379.60% |               596.47% | 1.2e-05   |      20 |
 | Text::Table::HTML             |     79    |     13    |              5390.03% |               595.14% | 2.7e-05   |      20 |
 | Text::MarkdownTable           |    114    |      8.76 |              7844.02% |               380.41% | 4.7e-06   |      20 |
 | Text::Table                   |    140    |      7    |              9907.76% |               281.34% | 9.6e-06   |      20 |
 | Text::Table::HTML::DataTables |    165    |      6.05 |             11398.27% |               231.91% | 3.4e-06   |      20 |
 | Text::Table::CSV              |    283    |      3.54 |             19572.73% |                93.99% |   2e-06   |      20 |
 | Text::Table::Org              |    299    |      3.34 |             20702.20% |                83.46% | 9.1e-07   |      20 |
 | Text::Table::TinyBorderStyle  |    331    |      3.02 |             22934.08% |                65.68% | 1.5e-06   |      20 |
 | Text::Table::Any              |    520    |      1.9  |             35751.62% |                 6.45% | 5.2e-06   |      20 |
 | Text::Table::Sprintf          |    548    |      1.82 |             38063.55% |                 0.00% | 1.6e-06   |      23 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                   Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::Table::TinyColorWide  Text::FormatTable  Text::Table::TinyWide  Text::Table::Manifold  Text::Table::Tiny  Text::TabularDisplay  Text::Table::HTML  Text::Table::TinyColor  Text::MarkdownTable  Text::Table  Text::Table::HTML::DataTables  Text::Table::CSV  Text::Table::Org  Text::Table::TinyBorderStyle  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table        1.44/s                       --             -56%               -78%              -90%                        -93%               -93%                   -95%                   -97%               -97%                  -97%               -98%                    -98%                 -98%         -98%                           -99%              -99%              -99%                          -99%              -99%                  -99% 
  Text::ANSITable                3.28/s                     128%               --               -50%              -78%                        -85%               -85%                   -89%                   -93%               -93%                  -94%               -95%                    -95%                 -97%         -97%                           -98%              -98%              -98%                          -99%              -99%                  -99% 
  Text::Table::More              6.66/s                     363%             103%                 --              -56%                        -69%               -70%                   -78%                   -86%               -87%                  -88%               -91%                    -91%                 -94%         -95%                           -95%              -97%              -97%                          -97%              -98%                  -98% 
  Text::ASCIITable                 15/s                     954%             362%               127%                --                        -31%               -33%                   -51%                   -69%               -71%                  -74%               -80%                    -80%                 -86%         -89%                           -90%              -94%              -94%                          -95%              -97%                  -97% 
  Text::Table::TinyColorWide     22.1/s                    1439%             574%               231%               46%                          --                -2%                   -29%                   -55%               -57%                  -62%               -71%                    -71%                 -80%         -84%                           -86%              -92%              -92%                          -93%              -95%                  -95% 
  Text::FormatTable              22.8/s                    1485%             594%               241%               50%                          2%                 --                   -27%                   -54%               -56%                  -61%               -70%                    -71%                 -80%         -84%                           -86%              -91%              -92%                          -93%              -95%                  -95% 
  Text::Table::TinyWide          31.2/s                    2075%             853%               368%              106%                         41%                37%                     --                   -37%               -40%                  -46%               -59%                    -60%                 -72%         -78%                           -81%              -88%              -89%                          -90%              -94%                  -94% 
  Text::Table::Manifold            49/s                    3379%            1425%               650%              229%                        126%               119%                    60%                     --                -5%                  -15%               -35%                    -36%                 -56%         -65%                           -69%              -82%              -83%                          -84%              -90%                  -90% 
  Text::Table::Tiny                53/s                    3563%            1505%               689%              247%                        137%               131%                    68%                     5%                 --                  -10%               -31%                    -33%                 -53%         -63%                           -68%              -81%              -82%                          -84%              -90%                  -90% 
  Text::TabularDisplay           58.7/s                    3994%            1694%               782%              288%                        165%               158%                    88%                    17%                11%                    --               -23%                    -25%                 -48%         -58%                           -64%              -79%              -80%                          -82%              -88%                  -89% 
  Text::Table::HTML                79/s                    5253%            2246%              1053%              407%                        247%               237%                   146%                    53%                46%                   30%                 --                     -2%                 -32%         -46%                           -53%              -72%              -74%                          -76%              -85%                  -86% 
  Text::Table::TinyColor         78.8/s                    5380%            2301%              1081%              419%                        255%               245%                   151%                    57%                49%                   33%                 2%                      --                 -31%         -44%                           -52%              -72%              -73%                          -76%              -85%                  -85% 
  Text::MarkdownTable             114/s                    7845%            3381%              1612%              653%                        415%               401%                   265%                   128%               116%                   94%                48%                     44%                   --         -20%                           -30%              -59%              -61%                          -65%              -78%                  -79% 
  Text::Table                     140/s                    9842%            4257%              2042%              842%                        545%               527%                   357%                   185%               171%                  142%                85%                     81%                  25%           --                           -13%              -49%              -52%                          -56%              -72%                  -74% 
  Text::Table::HTML::DataTables   165/s                   11404%            4941%              2379%              990%                        647%               625%                   428%                   230%               214%                  180%               114%                    109%                  44%          15%                             --              -41%              -44%                          -50%              -68%                  -69% 
  Text::Table::CSV                283/s                   19561%            8515%              4137%             1764%                       1176%              1140%                   803%                   464%               436%                  380%               267%                    258%                 147%          97%                            70%                --               -5%                          -14%              -46%                  -48% 
  Text::Table::Org                299/s                   20738%            9031%              4391%             1876%                       1253%              1214%                   858%                   498%               468%                  408%               289%                    280%                 162%         109%                            81%                5%                --                           -9%              -43%                  -45% 
  Text::Table::TinyBorderStyle    331/s                   22946%            9999%              4866%             2085%                       1396%              1353%                   959%                   562%               529%                  462%               330%                    320%                 190%         131%                           100%               17%               10%                            --              -37%                  -39% 
  Text::Table::Any                520/s                   36531%           15952%              7794%             3373%                       2278%              2210%                  1584%                   952%               900%                  794%               584%                    568%                 361%         268%                           218%               86%               75%                           58%                --                   -4% 
  Text::Table::Sprintf            548/s                   38141%           16658%              8141%             3526%                       2383%              2312%                  1658%                   998%               943%                  834%               614%                    597%                 381%         284%                           232%               94%               83%                           65%                4%                    -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::Table: participant=Text::Table
   Text::Table::Any: participant=Text::Table::Any
   Text::Table::CSV: participant=Text::Table::CSV
   Text::Table::HTML: participant=Text::Table::HTML
   Text::Table::HTML::DataTables: participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: participant=Text::Table::Manifold
   Text::Table::More: participant=Text::Table::More
   Text::Table::Org: participant=Text::Table::Org
   Text::Table::Sprintf: participant=Text::Table::Sprintf
   Text::Table::Tiny: participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: participant=Text::Table::TinyWide
   Text::TabularDisplay: participant=Text::TabularDisplay
   Text::UnicodeBox::Table: participant=Text::UnicodeBox::Table

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


Result formatted as table (split, part 2 of 5):

 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |      11.3 |    88.4   |                 0.00% |             34905.68% | 8.5e-05 |      21 |
 | Text::ANSITable               |      30   |    33     |               164.51% |             13134.31% |   4e-05 |      20 |
 | Text::Table::More             |      61.7 |    16.2   |               445.13% |              6321.58% | 1.6e-05 |      20 |
 | Text::ASCIITable              |     162   |     6.17  |              1331.88% |              2344.74% | 3.4e-06 |      20 |
 | Text::FormatTable             |     200   |     5     |              1671.23% |              1876.35% | 7.1e-06 |      20 |
 | Text::Table::TinyColorWide    |     217   |     4.61  |              1817.34% |              1725.74% | 2.4e-06 |      21 |
 | Text::Table::TinyWide         |     304   |     3.29  |              2587.30% |              1202.63% | 1.3e-06 |      20 |
 | Text::TabularDisplay          |     431   |     2.32  |              3708.00% |               819.27% | 2.2e-06 |      20 |
 | Text::Table::Manifold         |     439   |     2.28  |              3780.76% |               802.03% | 1.1e-06 |      20 |
 | Text::Table::Tiny             |     477   |     2.1   |              4112.27% |               731.04% | 1.3e-06 |      22 |
 | Text::MarkdownTable           |     540   |     1.85  |              4671.83% |               633.59% | 1.1e-06 |      20 |
 | Text::Table                   |     646   |     1.55  |              5605.53% |               513.54% | 7.5e-07 |      20 |
 | Text::Table::TinyColor        |     735   |     1.36  |              6390.04% |               439.38% | 4.8e-07 |      20 |
 | Text::Table::HTML             |     743   |     1.35  |              6463.79% |               433.32% | 1.1e-06 |      21 |
 | Text::Table::HTML::DataTables |    1300   |     0.79  |             11078.51% |               213.15% | 8.3e-07 |      21 |
 | Text::Table::Org              |    2170   |     0.461 |             19065.87% |                82.65% | 2.1e-07 |      20 |
 | Text::Table::CSV              |    2170   |     0.46  |             19094.61% |                82.37% | 2.1e-07 |      21 |
 | Text::Table::TinyBorderStyle  |    2210   |     0.452 |             19451.10% |                79.05% | 2.1e-07 |      20 |
 | Text::Table::Any              |    3810   |     0.262 |             33567.68% |                 3.97% | 1.9e-07 |      26 |
 | Text::Table::Sprintf          |    3960   |     0.252 |             34905.68% |                 0.00% | 2.1e-07 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                   Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::TabularDisplay  Text::Table::Manifold  Text::Table::Tiny  Text::MarkdownTable  Text::Table  Text::Table::TinyColor  Text::Table::HTML  Text::Table::HTML::DataTables  Text::Table::Org  Text::Table::CSV  Text::Table::TinyBorderStyle  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table        11.3/s                       --             -62%               -81%              -93%               -94%                        -94%                   -96%                  -97%                   -97%               -97%                 -97%         -98%                    -98%               -98%                           -99%              -99%              -99%                          -99%              -99%                  -99% 
  Text::ANSITable                  30/s                     167%               --               -50%              -81%               -84%                        -86%                   -90%                  -92%                   -93%               -93%                 -94%         -95%                    -95%               -95%                           -97%              -98%              -98%                          -98%              -99%                  -99% 
  Text::Table::More              61.7/s                     445%             103%                 --              -61%               -69%                        -71%                   -79%                  -85%                   -85%               -87%                 -88%         -90%                    -91%               -91%                           -95%              -97%              -97%                          -97%              -98%                  -98% 
  Text::ASCIITable                162/s                    1332%             434%               162%                --               -18%                        -25%                   -46%                  -62%                   -63%               -65%                 -70%         -74%                    -77%               -78%                           -87%              -92%              -92%                          -92%              -95%                  -95% 
  Text::FormatTable               200/s                    1668%             560%               223%               23%                 --                         -7%                   -34%                  -53%                   -54%               -57%                 -63%         -69%                    -72%               -73%                           -84%              -90%              -90%                          -90%              -94%                  -94% 
  Text::Table::TinyColorWide      217/s                    1817%             615%               251%               33%                 8%                          --                   -28%                  -49%                   -50%               -54%                 -59%         -66%                    -70%               -70%                           -82%              -90%              -90%                          -90%              -94%                  -94% 
  Text::Table::TinyWide           304/s                    2586%             903%               392%               87%                51%                         40%                     --                  -29%                   -30%               -36%                 -43%         -52%                    -58%               -58%                           -75%              -85%              -86%                          -86%              -92%                  -92% 
  Text::TabularDisplay            431/s                    3710%            1322%               598%              165%               115%                         98%                    41%                    --                    -1%                -9%                 -20%         -33%                    -41%               -41%                           -65%              -80%              -80%                          -80%              -88%                  -89% 
  Text::Table::Manifold           439/s                    3777%            1347%               610%              170%               119%                        102%                    44%                    1%                     --                -7%                 -18%         -32%                    -40%               -40%                           -65%              -79%              -79%                          -80%              -88%                  -88% 
  Text::Table::Tiny               477/s                    4109%            1471%               671%              193%               138%                        119%                    56%                   10%                     8%                 --                 -11%         -26%                    -35%               -35%                           -62%              -78%              -78%                          -78%              -87%                  -88% 
  Text::MarkdownTable             540/s                    4678%            1683%               775%              233%               170%                        149%                    77%                   25%                    23%                13%                   --         -16%                    -26%               -27%                           -57%              -75%              -75%                          -75%              -85%                  -86% 
  Text::Table                     646/s                    5603%            2029%               945%              298%               222%                        197%                   112%                   49%                    47%                35%                  19%           --                    -12%               -12%                           -49%              -70%              -70%                          -70%              -83%                  -83% 
  Text::Table::TinyColor          735/s                    6400%            2326%              1091%              353%               267%                        238%                   141%                   70%                    67%                54%                  36%          13%                      --                 0%                           -41%              -66%              -66%                          -66%              -80%                  -81% 
  Text::Table::HTML               743/s                    6448%            2344%              1099%              357%               270%                        241%                   143%                   71%                    68%                55%                  37%          14%                      0%                 --                           -41%              -65%              -65%                          -66%              -80%                  -81% 
  Text::Table::HTML::DataTables  1300/s                   11089%            4077%              1950%              681%               532%                        483%                   316%                  193%                   188%               165%                 134%          96%                     72%                70%                             --              -41%              -41%                          -42%              -66%                  -68% 
  Text::Table::Org               2170/s                   19075%            7058%              3414%             1238%               984%                        900%                   613%                  403%                   394%               355%                 301%         236%                    195%               192%                            71%                --                0%                           -1%              -43%                  -45% 
  Text::Table::CSV               2170/s                   19117%            7073%              3421%             1241%               986%                        902%                   615%                  404%                   395%               356%                 302%         236%                    195%               193%                            71%                0%                --                           -1%              -43%                  -45% 
  Text::Table::TinyBorderStyle   2210/s                   19457%            7200%              3484%             1265%              1006%                        919%                   627%                  413%                   404%               364%                 309%         242%                    200%               198%                            74%                1%                1%                            --              -42%                  -44% 
  Text::Table::Any               3810/s                   33640%           12495%              6083%             2254%              1808%                       1659%                  1155%                  785%                   770%               701%                 606%         491%                    419%               415%                           201%               75%               75%                           72%                --                   -3% 
  Text::Table::Sprintf           3960/s                   34979%           12995%              6328%             2348%              1884%                       1729%                  1205%                  820%                   804%               733%                 634%         515%                    439%               435%                           213%               82%               82%                           79%                3%                    -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::Table: participant=Text::Table
   Text::Table::Any: participant=Text::Table::Any
   Text::Table::CSV: participant=Text::Table::CSV
   Text::Table::HTML: participant=Text::Table::HTML
   Text::Table::HTML::DataTables: participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: participant=Text::Table::Manifold
   Text::Table::More: participant=Text::Table::More
   Text::Table::Org: participant=Text::Table::Org
   Text::Table::Sprintf: participant=Text::Table::Sprintf
   Text::Table::Tiny: participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: participant=Text::Table::TinyWide
   Text::TabularDisplay: participant=Text::TabularDisplay
   Text::UnicodeBox::Table: participant=Text::UnicodeBox::Table

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


Result formatted as table (split, part 3 of 5):

 #table3#
 {dataset=>"small (3x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |     300   | 4         |                 0.00% |             46360.22% | 4.6e-05 |      20 |
 | Text::ANSITable               |    1120   | 0.89      |               332.32% |             10646.84% | 2.7e-07 |      20 |
 | Text::Table::More             |    2500   | 0.4       |               854.89% |              4765.52% | 4.3e-07 |      20 |
 | Text::ASCIITable              |    6100   | 0.16      |              2256.09% |              1871.92% | 2.1e-07 |      20 |
 | Text::FormatTable             |    8680   | 0.115     |              3238.29% |              1291.74% | 5.3e-08 |      20 |
 | Text::Table::Manifold         |    9500   | 0.11      |              3561.69% |              1168.82% | 1.6e-07 |      20 |
 | Text::Table                   |    9600   | 0.1       |              3588.47% |              1159.61% | 2.1e-07 |      20 |
 | Text::Table::TinyColorWide    |    9930   | 0.101     |              3721.66% |              1115.71% | 9.9e-08 |      23 |
 | Text::Table::TinyWide         |   14000   | 0.0715    |              5280.40% |               763.51% | 2.7e-08 |      20 |
 | Text::Table::TinyBorderStyle  |   14600   | 0.0683    |              5531.98% |               724.94% | 2.7e-08 |      20 |
 | Text::MarkdownTable           |   16000   | 0.064     |              5901.06% |               674.20% | 1.1e-07 |      20 |
 | Text::Table::HTML::DataTables |   18000   | 0.055     |              6884.01% |               565.24% | 8.3e-08 |      33 |
 | Text::Table::Tiny             |   18408.4 | 0.0543232 |              6983.55% |               555.89% |   0     |      20 |
 | Text::TabularDisplay          |   18900   | 0.0529    |              7177.45% |               538.41% | 2.5e-08 |      22 |
 | Text::Table::TinyColor        |   29300   | 0.0341    |             11168.24% |               312.31% | 1.3e-08 |      22 |
 | Text::Table::HTML             |   38400   | 0.026     |             14681.96% |               214.30% | 1.3e-08 |      20 |
 | Text::Table::Org              |   68200   | 0.0147    |             26145.72% |                77.02% | 6.1e-09 |      24 |
 | Text::Table::CSV              |   95800   | 0.0104    |             36764.56% |                26.03% | 8.6e-09 |      27 |
 | Text::Table::Any              |  108000   | 0.00928   |             41362.43% |                12.05% | 2.9e-09 |      26 |
 | Text::Table::Sprintf          |  121000   | 0.00828   |             46360.22% |                 0.00% | 2.6e-09 |      32 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                      Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::Manifold  Text::Table::TinyColorWide  Text::Table  Text::Table::TinyWide  Text::Table::TinyBorderStyle  Text::MarkdownTable  Text::Table::HTML::DataTables  Text::Table::Tiny  Text::TabularDisplay  Text::Table::TinyColor  Text::Table::HTML  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table            300/s                       --             -77%               -90%              -96%               -97%                   -97%                        -97%         -97%                   -98%                          -98%                 -98%                           -98%               -98%                  -98%                    -99%               -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                   1120/s                     349%               --               -55%              -82%               -87%                   -87%                        -88%         -88%                   -91%                          -92%                 -92%                           -93%               -93%                  -94%                    -96%               -97%              -98%              -98%              -98%                  -99% 
  Text::Table::More                 2500/s                     900%             122%                 --              -60%               -71%                   -72%                        -74%         -75%                   -82%                          -82%                 -84%                           -86%               -86%                  -86%                    -91%               -93%              -96%              -97%              -97%                  -97% 
  Text::ASCIITable                  6100/s                    2400%             456%               150%                --               -28%                   -31%                        -36%         -37%                   -55%                          -57%                 -60%                           -65%               -66%                  -66%                    -78%               -83%              -90%              -93%              -94%                  -94% 
  Text::FormatTable                 8680/s                    3378%             673%               247%               39%                 --                    -4%                        -12%         -13%                   -37%                          -40%                 -44%                           -52%               -52%                  -54%                    -70%               -77%              -87%              -90%              -91%                  -92% 
  Text::Table::Manifold             9500/s                    3536%             709%               263%               45%                 4%                     --                         -8%          -9%                   -35%                          -37%                 -41%                           -50%               -50%                  -51%                    -69%               -76%              -86%              -90%              -91%                  -92% 
  Text::Table::TinyColorWide        9930/s                    3860%             781%               296%               58%                13%                     8%                          --           0%                   -29%                          -32%                 -36%                           -45%               -46%                  -47%                    -66%               -74%              -85%              -89%              -90%                  -91% 
  Text::Table                       9600/s                    3900%             790%               300%               59%                14%                     9%                          1%           --                   -28%                          -31%                 -36%                           -45%               -45%                  -47%                    -65%               -74%              -85%              -89%              -90%                  -91% 
  Text::Table::TinyWide            14000/s                    5494%            1144%               459%              123%                60%                    53%                         41%          39%                     --                           -4%                 -10%                           -23%               -24%                  -26%                    -52%               -63%              -79%              -85%              -87%                  -88% 
  Text::Table::TinyBorderStyle     14600/s                    5756%            1203%               485%              134%                68%                    61%                         47%          46%                     4%                            --                  -6%                           -19%               -20%                  -22%                    -50%               -61%              -78%              -84%              -86%                  -87% 
  Text::MarkdownTable              16000/s                    6150%            1290%               525%              150%                79%                    71%                         57%          56%                    11%                            6%                   --                           -14%               -15%                  -17%                    -46%               -59%              -77%              -83%              -85%                  -87% 
  Text::Table::HTML::DataTables    18000/s                    7172%            1518%               627%              190%               109%                   100%                         83%          81%                    29%                           24%                  16%                             --                -1%                   -3%                    -38%               -52%              -73%              -81%              -83%                  -84% 
  Text::Table::Tiny              18408.4/s                    7263%            1538%               636%              194%               111%                   102%                         85%          84%                    31%                           25%                  17%                             1%                 --                   -2%                    -37%               -52%              -72%              -80%              -82%                  -84% 
  Text::TabularDisplay             18900/s                    7461%            1582%               656%              202%               117%                   107%                         90%          89%                    35%                           29%                  20%                             3%                 2%                    --                    -35%               -50%              -72%              -80%              -82%                  -84% 
  Text::Table::TinyColor           29300/s                   11630%            2509%              1073%              369%               237%                   222%                        196%         193%                   109%                          100%                  87%                            61%                59%                   55%                      --               -23%              -56%              -69%              -72%                  -75% 
  Text::Table::HTML                38400/s                   15284%            3323%              1438%              515%               342%                   323%                        288%         284%                   175%                          162%                 146%                           111%               108%                  103%                     31%                 --              -43%              -60%              -64%                  -68% 
  Text::Table::Org                 68200/s                   27110%            5954%              2621%              988%               682%                   648%                        587%         580%                   386%                          364%                 335%                           274%               269%                  259%                    131%                76%                --              -29%              -36%                  -43% 
  Text::Table::CSV                 95800/s                   38361%            8457%              3746%             1438%              1005%                   957%                        871%         861%                   587%                          556%                 515%                           428%               422%                  408%                    227%               150%               41%                --              -10%                  -20% 
  Text::Table::Any                108000/s                   43003%            9490%              4210%             1624%              1139%                  1085%                        988%         977%                   670%                          635%                 589%                           492%               485%                  470%                    267%               180%               58%               12%                --                  -10% 
  Text::Table::Sprintf            121000/s                   48209%           10648%              4730%             1832%              1288%                  1228%                       1119%        1107%                   763%                          724%                 672%                           564%               556%                  538%                    311%               214%               77%               25%               12%                    -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::Table: participant=Text::Table
   Text::Table::Any: participant=Text::Table::Any
   Text::Table::CSV: participant=Text::Table::CSV
   Text::Table::HTML: participant=Text::Table::HTML
   Text::Table::HTML::DataTables: participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: participant=Text::Table::Manifold
   Text::Table::More: participant=Text::Table::More
   Text::Table::Org: participant=Text::Table::Org
   Text::Table::Sprintf: participant=Text::Table::Sprintf
   Text::Table::Tiny: participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: participant=Text::Table::TinyWide
   Text::TabularDisplay: participant=Text::TabularDisplay
   Text::UnicodeBox::Table: participant=Text::UnicodeBox::Table

The above result presented as chart:

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAQ5QTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADUlQDVlQDVlADUAAAAlADUlADUlADVlQDWlADUlADUlQDVAAAAAAAAlQDVlADUlQDVlADUlADUlQDVlADUlADUlgDXlADUlADVlADUdACmlADUjQDKdACnhgDAVgB7ZQCRUgB2jwDNAAAAXQCGZgCTNgBNQgBeaQCXYQCMYQCLZgCSMABFTwBxRwBmKQA7WAB+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADUbQCb////xu1r+wAAAFZ0Uk5TABFEImbuu8yZM3eI3apVqdXKx9I/7/z27Pnx9HVE9ez38M3fTnUiM6fk7Y7HaYj6n/HWMBF67+uj+dX2dce359b57Z7g9Png/JnotLTPnyBgMI2mQI/TFv0KAAAAAWJLR0QAiAUdSAAAAAlwSFlzAAAASAAAAEgARslrPgAAAAd0SU1FB+UHHwg4LWxUCn4AACqQSURBVHja7Z0Jm+w4dYYl7y67KgQyYUKYmdwMy0AIJASyQBISsq+QzfD/f0m0WdZut7u6y1Z97zM97tsquWzrk3R0dCQTAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAeEdooX4p6PLHonz0ZQHwAqpFsMWkfpkKnVpPU0Nfek4AHkajxRsQNK0rQtvu0dcIwFb69sKa6GoYCi7oUhyFoIth6KXEh+bRFwnAVqqxK0gzDgNri4up7rppEIK+1EM3VeIj1+ujLxKAzXCTo2GN9HBlgr4QcplKJuhy6rkBzdPHETY0OA/Shu5vbaNsaNY8T0U1Fgyuavbr8OhrBGAzXNDD1HTNLOiaC3qoG07P/3CbXvcNALwjTNC3uhRDv2JixgUVLfRtJNwvLcaDBQQNzkNzYwNDJl5hcnRM2CO3Ori/jv0qjI5ufPQ1ArCZ61jRdmzGrq6Kth3HuhdmdFW3Lfu1mxrxFwBOAuVz20VB5Rx3oWe9qfy1LIpXnBwAAAAAAAAAAAAAAAAAAACAezLPXckp2V7NbcWOABybUkV/iVCwsp14SE30CMCxKW+tFHQxcUE3V1ryCPTYEYBjUzVS0LS+Nry1ZnbHpY0eATg8MuD8OnCTQ/zO/hc7AnB4hE6rVtjQlRQujR1Vlt/4kuA3vwzAffiKUNRXfutOgi7HUgj6IoVbxo4qy0e//VXORx+H+J2P43z1a4nEVMa3OevXvnqey9l91oNdTuSsvysUNX39ToIeWmZxjEO50eT4+MuJ86X2URmKnRnf5qzFsDPjAy5n91kPdjnJs95N0MUgBV3yRrgaSeyogKBPpKCDXc77CFpconDbDekfCQR9IgUd7HLeWdB93Y4tjR8lEPSJFHSwy3l7QdtQtYozdhRA0CdS0MEu570FvYmkoKvU3ZQ7M77NWctiZ8YHXM7usx7scpJnPaSgAdgLBA2yAoIGWQFBg6yAoEFWQNAgKyBokBUQNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmQFBA2yAoIGWQFBg6yAoEFWQNAgKyBokBUQNMgKCBpkxX0ELbdU79WW7D1NHzkQNHgT7iLokr80qB+naezZP9pp6kj8KIGgwZtwB0GXN/Hy+rojtBsJaa60HIf4UQJBgzfhDoKuGi5o8RrvcurZf4RcWhI7KiBo8Cbc7T2FtBC/3OXVyAAk+OTTzxS/5yfe9cWbZduRSgqXxo4qCwQN9vLJr2Y+8xPvKGg6TMxEvkjhlrGjyvLhQ8PpH/1wwPmICHoQirqfoPtWyBMmB3hj3qmFHqVPruSNcDVGjwoIGuzlfQR9mwoOIc2Q/pFA0GAv7yPoYRIw06Nux5bGjxIIGuzl7QVtQ4sieRRA0GAv7y3oTUDQYC8QNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmQFBA2yAoIGWQFBg6yAoMHp+P3PZ77hpUHQ4HR8rkX7TS8NgganA4IGWQFBg6yAoEFWQNAgKyBokBUQNMgKCBpkBQQNsgKCBlkBQYOseLCg5ctTevVKoLUjB4IGKR4r6JK/p7Bsp6nbcJRA0CDFIwVd3lou6OZKy3FYP0ogaJDikYKuGi7ocuoJubSrRwUEDVI81uTgL95ce8c33vUNXsDjBV1JwdK1o8oCQYMUjxf0RQq2XDuqLB8+NJz+0Q8OHJMdgh6EomBygCPy+Ba65I1vNa4eFRA0SPF4QZNm2PYjgaBBigMIuq/bsaXrRwkEDVIcIZaDFsWmowCCBimOIOgXAUGDFBA0yAoIGmQFBA3Oxrc+mfm2nwhBg7Pxhdbl534iBA3OBgQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmQFBA2yAoIGWQFBg6yAoEFWQNAgKyBokBUQNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICuOL+hevVWzp+kjB4J+eo4u6H6cpoZJtmynqSPxowSCfnqOLuhxILRlim2utByH+FECQT89Rxf0VPDXLZNy6gm5tNGjAoJ+eo4u6PpCyLXDu77BRo4u6KIe65GSSgqXxo7q0x99Z+CUj36q4GHcW9CVUNTdBE3ba3FjNvRFCreMHdXHv/ulgkN3fx84O/cWdC8UdTdBVyM/51TC5ADbOLjJMfDxHp2KkjfCTN2xowKCfnoOLuieezGGmpBmSP9IIOin5+CCZqPBdqyZqPu6HVsaP0og6Kfn6IImZVGII105CiDop+fwgn4REPTTA0GDrICgQVZA0CArIGiQFQ8VdN/f+W4g6KfngYKu6qkpxrtqGoJ+eh4n6H6qioYO9T0jiSDop+dxgh46UjSEtMX6RzcDQT89DxT0AEGDu/M4QRd1zwRdweQA9+SBg8LLNNZjXd3zbiDop+eRbruyGm73XVwCQT89jxN0KY3n6p4LACHop+dRgi6LS8cXa91GDArBHXmUoKumHRvOFYNCcEceOLFy1+GgBIJ+eh4enAQbGtyTR8ZyXLnJUcOGBnfkkRMrQ9sMbbf+ye1A0E/PQ6e+bx2hIwaF4I48VNB9Q0gDkwO8jE8+/Uzx6Sde4uMEXY0lmUoCPzR4IYv0fnUkQZOmIUM9ths+uRkI+hk4qKAL7oe+VXcN5oCgn4GDCvpy17ZZAkE/AwcVNOkGsfXuPW8Vgn4GDiroYpLc81Yh6GfgoIJ+CyDoZwCCBlkBQYOsgKBBVkDQICsgaJAVJxc0Vbvf9TR95EDQz8CpBU2v09SWhJTtNPHQ6dhRAkE/A6cWdNdSer0S0lxpOQ7xowSCfgbOLGjK31NYDqTkx0sbPSog6GfgzIIuJtLzV3fj1chAc2ZB36Zm5C/erKRwaeyoPg5BPwNnFvQwDeLVyBcp3DJ2VB//8EFsXnPvN12AQ/Gugh6Eou5pcoiX18PkAJozt9C9FHRf8ka4GknsqICgn4EzC5qMF0I6JthmSP9IIOhn4NSC7uuWDwrFsaXxowSCfgZOLWhC1SKttaMAgn4Gzi3oFwFBPwMQNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmQFBA2yAoIGWQFBg6yAoEFWQNAgKyBokBUQNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZMXpBS3fo9mrVwPFjhwI+hk4u6CHhv2vbKepSxwlEPQzcHJBFxMXdHOl5TjEjxII+hk4t6BpfWWCLidmd1za6FEBQT8D5xb0deAmB971DTSnFnTVChu6ksKlsaP69He/VHDo7q8DJ+BdBd0LRd1N0OVYCkFfpHDL2FF9/KPvDJxy9/eBE/Cugq6Eou4m6KFlFsc4lDA5gObMJkcxSEGXvBGuRhI7KiDoZ+DMguYIP3QzpH8kEHQu/MH3ZlLSO7Gg+7odWxo/SiDoXFik9z0v7eyCltCiSB4FEHQu5C/oTUDQuQBBCyDoXICgBRB0LkDQAgg6FyBoAQSdCxC0AILOBQhaAEHnAgQtgKBzAYIWQNC5AEELIOhcgKAFEHQuQNACCDoXIGgBBJ0LELQAgs4FCFoAQecCBC2AoHMBghZA0LkAQQsg6FyAoAUQ9In41jdn/tBPhKAFEPSJ+L5W0Kd+IgQtgKBPxPdTCoKgBRD0iYCg14GgTwQEvQ4EfSIg6HUg6BMBQa8DQZ8ICHodCPpEQNDrQNAnAoJeB4I+ERD0OhD0iYCg14GgTwQEvQ4EfSIg6HUg6BMBQa8DQZ+IZxV0r9462NP0kQNBn4jnFHQ/TtPYE1K209SR+FECQZ+I5xR03RHajYQ0V1qOQ/wogaBPxFMKWrzGu5x69h8hl5bEjgoI+kQ8paApf2dbMeHVyBnylILmlG1HKilcGjuqj0LQJ+JJBU2HiZnIFyncMnZUH/7woeH0b1IA4L6cQ9CDUNQdvRytkCdMjvw4h6Al9xP0KH1yJW+EqzF6VEDQJ+IpBX2bCg4hzZD+kUDQB+MHCek9paCHScBMj7odWxo/SiDo9+eP/vgzxQ/9xM8g6BiUt9OJowCCfhM++XTW7A/8xKSCIOjXAUG/CYaC/EQI+g2BoN8ECBqCzgoIGoI+Hd/Qm9v+iZcGQUPQp2Mp6y+8NAgagj4dEDQEnRUQNAR9Nr7YpiAI2s8IQT+KH34+820vDYKGoE/HZ5vKGoKGoE8CBA1BZwUEDUFnBQQNQWcFBA1BZwUEDUFnBQQNQWcFBA1BH5AffaJ5YU4IGoJ+EItmf+Sn6YcbeK/7j7+Y+bGfCEFD0A/iT/c+3M9TRQZBQ9Bvx7d0I+wHVux/uBA0BP0g3ubhQtAQ9IOAoCHo1wFBQ9AQ9NsBQUPQrwOChqAh6NeRcidD0BD063iAoD9994cLQUPQb8g2BUHQEPQeIGgIGoJ+HRA0BP12QNAQNAT9OiBoCPrtgKAhaAj6dUDQEPR96enye1LQTSJtKBKJfza/YeSzP/cT/yLxcH+Serg/TTzcv0w93J+mzrrtcpJn9QW9XE5A0D/Zezl/te1yfEEbl/Nez/z9BF2209Tpf72NoFMPF4KGoO9Kc6XluO09hRA0BH14QZdTT8ilnf+5W9B//bN5087Ay/YgaAj6vQT9knd9pwS9++FC0BD0PamkoOdx4cd/8/U4f/vzmb/z0v7+1zP/4Gf8R534T37iP+vEf/HS/lWn/Tx11n/z0v592+UEzrrtcpJn/Y/E5fz664mzvvBydj9z43Le65m/m6AvUtCl+ueHCYC34EEmBwDnpuSNczU++jIAuBPNIH8AYO3boy/g9fR1O7b09ed5XzJ48Edk8d++lOo4JUKL4vUneW/GE17zCdg9mKrq/tHXfm6GbKz+ZNOWSqzeoE7TKXnS+OVcsimPRzGexuyvmi5l0SX7mngiLadb8O/Nqs5voU/08nmOl1TO2OWUhI5NR05BKUujaqdAsSQTJTsyysR0xmtTB76xXP3KyKXuz5hKFHTt0NxInOSAPJ7ITuv/sW8vpFtpK6uhCRnKbCjF76BLyjJyOZeGFPV0HCM6jXhww3gr2vaFiWRvRp6YzNiN1VAHHr1oQfacdXfGdCLjNsab53KsWOZuRyJ3twbEdZtqWtbJRnZoL91UhU7Ytr3Q5ssvh9bNf5an8ZQVNat69Y1Pkt9elsitvF0ZeWIqTfjO+4C5JyzrPWfdnTGdyLjVxa0TWnHpeaaK3GKOhXhi1Y4DDY0iyqntyFBHqxArEP7oLvYnyq6uB26s1EVsVJi+1qJmD6E/TRN9vRIy9X3T9P2LEoWVtyejSEylyafeBRoTblnvOuvujKlEYYk009jd+N3a3OqJ9fFF3ZUBCV1G3v76idLAGdrbrW2pbe5KidaXqaej246WlRjNyQKhxBmA9HVX3HidJLzpngL3mLxWJnZa8n6qS8WuHQE1TGDVviBtO96IcbNzWjBRIay8F2U0EyMnFWlUtIbF0nOWsgilZf2SsyYzKqoydDnJa1XCWyyRyihs/p20HAuhAqYm8wtlxo4plrWWbiJRBhfvmmg9VEY7y1pX8cGmYrK6iUx0UMn0OrWsglBZINxyIIPRmlJhosjPVtPQeOZI5FrVo1NiZyekdWqocABK9kyrcWr6oWV3Kjp5P40EEufP8FbmRRnNRCdNOoxkX9uyoqFcJHOzR6no0pVl/YKzpjMqmH3tZUyelSjhKUukGEily7q83gj7zm4clNlFW8tW4RmFRTVyi8JJVFmEGquRmH6FZhLVexjKuiJNw9MbKVra8l+KupEFIgySYVx6DMvIYGO7pfGmFyHz2LXyR6fFzrugw7vuhrGob8W1/sXIx87VpR78NEoDiVJ40jB9UUYz0UqTfnvd19K2vVW1tqGZXChdLOvNZ01nnBsxNtrxMibPSmbhSUukr6dR6YAO9ZULg43c+KeFIUJbNyMdWUXrhEVBXV8GzyIaWabDfr5CVkvKSVxA0bDroj1raOtKX6c49CxZ/Mof3SgN3rIoefWpSDG0k8zQGx4Z1rKLT8WulT06LXZWv/vDT9/SUTy6puOd29BYziedRqxE7jeahUeklbctYyDRTJOVf+lraVe3S0Y2Erp2hmW99azJjHy8r4f2bsbkWTm8/LUlMhf0bZSOXPadQlulqJND42YkvJmt6pJaiaKV4JaaaGRvtb4QUUuGsWd3QydhIA/ToM2RVpnaQy0LhPVw7FrZaWg3Tbw95od2uA2erTW0rWxHgtdaFew2FrEP03j8+ImbslVD/kedZiVyv5EWHqlC4+1wxlQis9ak3173tUaaeuIhyzp51kRGOeqnNdfqPLTfeK3WEMGxRMqG2aCFSlSVXTgvLUHzjOQqfIH8/CxRtKO6lWAGF2nGqtItsKolzBRmxgUdeyZ11gMsJ5ytBL7WThYIa1l5m9CyalBwc6QvRDF5jm32oY5/Teha+QBTVC4t9qPGInAjj8zjbGmlTcXcuclEO23p+YjyG2nhLVaeeVYv4+pZ21767b2+lv2JtyE9Kyv2qG3LeuWs8Yxq1C98UXpov/FarSGCY8J0rNVspCDYd964tqj4Ot2285wlz8g9OSNXZV//UrWjcysh1LV0CEstufB+q+Xtsd2KaJ3yj4lLvo7t2Dv1iKina9JPzKaYLiR0rWKAyU5hiP2QKCNvHmcLX69en6USg2mm30gLby5p+6xOxvRZ1Wd+Ifz2Tl/Luba8YWVPldaVaVmvnjWWUY/6pS/KHtqvX6s1RCCeJVLKboDykZvrXKPLiIWb3fJLl3Z0biXMbq80a4lwnTnTLbQrZ3+1WA0tC0REozWL12/gw7urH3LJ7q8Y+R4X/rS2GGDy29BiPySzkafH2UM9DHMboxKDabbfyBGee1YrY/Ksgl4YnWIYY/W1onuvWm4V8NbGsqyTZ01lNEf9cmGaMbRfv1ZniOAzSEuTJfbuEKptlxELnevQ0o7qVmIxcNTKOVVLCqFY+5x0vFE1pepOic+CvrCxed11dWNdLqsJ/Juu9aWqW/taRT8ibQ1+qQeO4Vi6Lz3OpvV1uNmJgTTxfCy/kSE8/6xGxrWzKj8nt9aE395s8qpJuLgoE6ZoJg37OH3WeEaReRn1y+mQeWi/fq3cEokOEYRExNBCPC4rUcQvzTmpmba0o7qVMNQ1WzCyllwdI4J/I88zsUaejQscrV+VEPlzra7utiqUj2c7Mbbsrbl0avZA/Db64/o2jO5Lj7NvpZ/opYk/mn4jU3iBs/6yJBvPOvs5ubXm+e0rYTTc+JGn9ZvPGs0oc+tRv/BF6VYycVZpWUtLJDgKIEoiyjFv2OQd0fFL7oiFY7SjVvckKWTnoWpJ6UhLfSM3GyZu1ptJXakuxLelZdXjVUQ5lqm6UjFBPvcjsgc6sJoVqvsyxtkCGYSlEp00heU30lgZvZzl2llnPye31ly/fVVwYXZi9qYOGHnRs1ZlImNVGKN+6Ysyijx4VmVZK0skOApQjaU4rT0L3vY6fknltDRitqNm96R+U3ZEFY6j0Neg7shIYVpv5W35JsNcEay7mCfIdT9yZFvDZO6+5nG2RM6mqkQnTTyDrrT8RiSY0c15MXvMwFkNpz5vD+xv5IEJTJg3YctNftRM/KxjEc1oRhlzo5V3xL3ZNQTOOg8RZkskYFkvGuHV09E61fFLw+TkrKLtqFRy2ahBoFNLzHhWOri2vKpdfd0IU8SvCzrDEv+1TJDHeqDjYRl5yzhbIvtameimEVlgvt+IN89mRjencPXGzipdY9rP6TqCZTwwE6YocXMDVXkf8WsVpwpl1GcNjvqV18E96zJEmC2R//rItqxlPv95syaej0RZGzzHL7HnYduyrKZE2lF+HVRUAHFmXUu8KBLp2PYKS9xRw02R0sxoBnazmtBpzS5D5VA/ckxsI28eZyvTqZd9rUyktkTm/tTzG/Hm2cro5JSuXvescrZRuca0n9NtD1Q8cFXXrvt0Lq/QtS5RvWbG0jlrYNQvY3ACZzWHCMoS+e9SPTl3EYPZWN7Gtip4eNssOB6/dHFm2/iYK9KODvWl5naxG1pnRpHIb/TrkmGKlFZGK7DbqgnGUNnrRw5JzMjTsYXKaGivgbzz4MPwG8npLV7SqYxlG+gxxWyjdo2Zfk4tER0pwqdcl7yldR/+V1pRvUZGaTII5cmzuqN+HYMTvhE9RLDtG28RgyGRq3QdVHyyrSE6fmmZrdNVz2pHjdIapSVUOA2wGUVifGO6ds0ZrYpg14RlqOz1I4ckYuQtppMyGhwLUD6g+U/abzSHCfDmOZxxDvmVDbeVKGYblwAds7OVEjEjRdgl6KzcJDfuw/1KN6p3yShULJVHA4vqSiPgzL8ReQLxN8e+sRcx2I3lHIV/5e6bSscv6ZP3RtUz29GltGYlN84FW1EkyzemapfO6FeEuTxLY6h8OX7URhU08kortvBimU2+rcYKbPYbLdNbvKQvIXtrDvm1I9+N2UbtGjNtDdn8xCJFhEkeetapCGQB16tSnj8f0k9mcFyQ2bvs2GLWIgZbI1S5gnoVYTFbsv8jDqLuRQLqtVPNXhqYiiLRjy5Uu8KB3c7AdbSGyu3RDY5idohZ3RB/1mZs4WiVp22rEavAliG5KOkx1Ekri0K5euWHzdnGsBtPSMSLFJlvo54tTfM+1iKQ5/D+WXnOWam4SyPgzER2M8Txm0UWMZga4S5Hed+iE1oEYgYZh6qeIa7SCsNKRZEsjy5Qu9KB3WSx4pahclEfuYmmYjZkKQHjETRWbKE9srVtNbs/NXpB3jy7Q+KSGhaFGXZozTaG3XjsAt1IkZlKm+TGfaxHIM/h/bPy7LM2rACvQyAGx4h44ZiW9erqB+EcnCMwLvpGxPSMGWTsVb25wCSDFdUSiSJZr13JwG6y1CBjqHxkFwdtx0oK2hsRC5+sEVto34Yd8WvVBGN6SzTPtgO5mWrDoiDWUNqMUncdbvNylUCIEod3M6LqmPexIQJ5Du8Pr1e51i2tWuLF4Ihoab2yxGm00qsflHOwVzMU88NRVc8KMtZVL+hUc6YCwlEk62uL0oHdZLltf4L8mFRjLawxQ5SN3K1kWBrP0QoJmj++PCBretSc3vI8lt1QRi0Ka7aRWg4TY2loYA547ma4Cpb72BCBXBU6vN9fdsIq1KXr2l4EfDiWCLPXjZUlNslFDEQ7B0cel+wEaRE7yFhfadqpJs8QjiJZq13BjOtOkUMi/V/crhAFYNgMU80lLUYuzixDylabfXzW9Jal56quaxl26FsU4dlG6sQDByWiuxlhkuv7WI1A5n3/Et7vnbar+7Jm7enoB3xIe31ZWWITXFHQyfAIPV1E667xI7jsIGMt6JhTLRloLu8xXLtWArvXnSIHgg5yLKP8X/zRVaPVvbNyHiYmaVZY3ixDPOJ38fHFprf69iZ8Hjx60pvCC842+vHA7pShbEXmbsZbCZSKQJZ9v7PilizLcbmi28ILMuYqkPa61c2saUt+lzFddFkWShlVzwwyNmbdg061ZKD5TKh2rQZ2p1yOR4PPUYkue/Z/ibZgfkRypS9fm9QxSfNidkyneMSvMT0amt6qim6cY8rawXZxaV+UO9voxwObS0OJ0YqobsZrRxIRyCpM3V5xK6ZZ5rre1UKz1kmVCrgtZXQz69piGtFWt3x0zlhZeS2sIOOkUy0ZaC6I1K4Ngd0Jl+OxoE0tl66a/q/lXtRKX6FzJukxcCfRiF/Dx+dPb4lFaLwaiYfjRegsAV52lHogHljlUALSrYjXzSQjkM3pRnvFrfibrutd7YY9aRWwIl+6mXVt8Qzh6aLli+l8pUutjTvV0oHmRkCrW7uSgd3h3ViO2zzztUf8/7yP0/4vw96fV/qqJkQsKVseUKzGzzs4GOuH3ektuQhNTMl5ljUxnpgTpR6LB54FtLQiRjcznzMQgeyYW6GJQT4g1XXddNXJaCKtAm6vq24mqS11wYXQSGi6yK16VlrcqZYINLcDWt3alQwXT+3Gckz4Zn50mGoVqeX4v+aVvnyFv3g05gOK9qeqXY+uHyZz7z6KlWjOvIY1lHai1MPxwMYYSrcidgusbRhi+Yg9c8ufGBTTLLquEyuriCbSKljs9eQiBgkfQrOfcCy5XfWcpJRTLRxo7ga0erUrFS6e2o3lmKg4rdvUB/xfeqWvGfSy2p/O7bpC+/hK0fIYvbsY7fQ6dS3UMRYPbAhItyK2WykY0xE0t5y+X06z+HXdiCbSKrAuNraIgYjJEtEXsJ9wLHkk+F8+/NS2D6FAcz+g1atdOmPochK7sRwTquK0xMom73r1Sl+9996G/lS365aPT7XrVu9u6ceaPvcDvFLxwIuAIq1I0OoLmFuqf5em401Ps3h13YgmCs5hxhYxiD/xi+d1uar/NxxLrljCmtd2dkiErwcCWm+xjKFw8dRuLMfB3NH7JkN63UBieaN6pa/u+zf0p7pdN318rI8uVFEsvbtVKNb0eWgknYgHXsZQhiWyNh0QN7eEHXQxNjb1N0rS0USeCiLa0h6KXoRkyNeNWc4dO1hxOd+GnR0i4evzjYYDWv2M8yAgtRvLIbF29Bab+Rmr6WQcsbzR0ErfVH8qC1O364uP7zqfwu/ddUlb0+eO/zgVDyy/2W+XV6cD4uYWX7F4ZXIPbr/Eb9KIJqLhNtbVluGhaERyb6yNDQQrzqdbcaqVJGmmyAIJBbSWsaFFcjeWg2Lt6G1t5rfEEYs7sFb6mvkj/aksTN2uGzmkn+QSCCbSJR0JdXRC8f14YIk/hrKmA3wbpioT5hZrgbkz2p1mWW7SiCaaiUpkfmizh4I/7cocK8eDFdd2SxALMVNrFEVSIKA1Gi6e3I3lsFg7eneT2RVbccT+rkUxW81cHxJo13kfzVe9hYKJdEk70+f2nsORDbYX/DGUOR3g2zCs3CLmFo/pqG/cg+5Osyw36UYTra4oMDwUl/p2G7cFK67u7CAWYobD142W26/tkXDx5G4sh8XZ0du2qpY4Yo4rg5itZpVmqF2/TXLVWyCYSJe0O31u7Tkcjge2LjwQpB6zYYiyYh1zS14PDyy88nZprJxpFuMm7WgiklhRsDyC2UPRTc4bpBLBiuk9GIzSskYIbsvt1fZIxuRuLEcluaO3EUfMb1Sv9F2z1VLtutxJai4K35miS9raqe16s8KBI/HAAdZjJBeT3Da31POR+4xX3Jqctb68H01HbBrRRPKugxIJeig05kycG6y4EHWq8X+3ZvW1y8M4kdtdVLGMJOlyPCTRrcDlI1riiM0bXbPV7PUhU2CSrg8+GaektW9IjkyscGB/v+8YKzGSpklum1vzA5Kzh8RUhL0ZHL/Ji501KJE1D4U5Excqj5RTTQXJqj33nIChWMsdKOYXDJGOSXQrcC+O2LWs4x2qsz5kbtetZn2wI99E0+WW9DxS1EP7IhqKnyAcIxk0yZ3yMuM5lw1l+VYK9vvRhGKdxjIgkfWwH3MmLtB3hZxqc9IcJCs3RbfbkFQDHAkXl0mp3ViOCJ+m+0VsK/BIHLHIl67xwfUhbrNuOdZk0xUp6WVkYu85vFXQkfm0lEke2P5j8aaIrRSW96P54ZMrKwoS4ytrJs5gxWMiC0UGycqFmHYo3xhrudPFnHZnHxA5TRf0RZmPyIsjjttqJFXhnWbdeCHevNF8uKSXkYm153CffrFSej5txSS3t/9w1SW3UtD7tXtN3uqKgvj4KjwTF/WYyJucJ4tkkKxTWmZ5eC13LFx8ZYh0VOQ03f+Zvig1K2Q/IisuIWmrJSu826xrcS3xBdGSViOTzXsOr+y/vmaSx7b/MLZSWN6P5lteaysK7PHV+kxcxGMyhw/MUzAqSNa2Gqzy0CcR3xkNF18bIh2Qittnappu8UXNs0LuIwo9oFCNl6eOlGbUkDOarvhIWpncG/ccTlurSZM8sf2HvZWC9X60cGMZW1Fgjq+2zMSFLbx5zsOI+g69zSRQHuo7o+HiK0OkQyHHQkNbsUfrxkHqOOLkIwrYauvt+oohp5uuUHiBNTLZMspOW6tJkzyx/Qe7SWsrBcvHF2ksI7dhjK+2zMQFm4LlNvQUjLFGMVm75u+MhouvOEWOhXibpLTy7Wk6o+cPPCJCorbalnY9YchJZNMVGkkn4oEjpK3VtEke2/5D3KSzcfviqNvQWAY9FJtm4sJOteU29BSMfj1ssnYt3xkJF087RY6HeJuk+MWOgzRfMeM+Itvksm21De16xJBTiWYLHNi7dN/IJLn/esIkj2z/oW7S3krBHwSEWoKUh2J9Ji7hVJtvw50sWqldy3dGwsXTfenx4AG4QsWVHwdZGvvbGi8J9kyu5QGtt+uCkGE9x3skWuBUMMQKsfk0K+DMMcl5Wmj7j8WGCW7cnmgs12M60jNxKaeavg1rCiZdu+zvDM3drPalx6Kfx0LUfmm6/YTsO/VMLvMBJdp127L2DGtd0pEWWOTb0z6kg9StgLPAq058zZrvR4u98C/SWJINMR3RmbiVPRjIchtmu5SsXe53rmxicuDmWT4nOS3Gx0LCVRfaG03JOLREL/qAgu26a1l7hrVb0omN5l82MonPpxldv9MhGNGBrmbt96OFXvgnn5jfWKrbig+wYjNxaaeaSXhkEa1dXjkHzpiqQIdBjinUtBgfC9FuDC8I855QwOTyCLTrnmXtGdZ2HJ9JavPSFKvzaWbXb6VadoGrWev9aKEX/slz+42leGjJWefgTNyaU81+VsGRRax2GddllvM2l+Oh4IWip8WqlDUaekJxk0vitesBy9rb1MgoaafpsuKBg/EyQVatVRLsEOQNWNGBtmbt96NdYxPuwcYyEvaTmolbdarZXxAsy0jtMvHWpCScVAeEB7ct02KpFY7BJxQzuWbcwgxY1u5LDsySdpsuMx54+8Akba0m9xa0owO1ZkPvRyuj3kOvKYh6KBIzcetOtU2sOzm9NSkr8zOHoZnXPxtvjXrxCke6tugm/nKR4B7IbknLZxvevHSzJRexVje8+8mJDlyWAKffj+Z9/9YogMRM3KpTbSNbnZybnCKHQjWu4lVf3s7cm1mr8YmXi/iGSqykVzeaT19izFpd3RAhEh1Iou9H23xJ4QHWSrDiqoW3ha3Xus0pciTmxpUHt7k7c7+AHQFXvsdEEynp+Oal68SD1NMbIiRnLmLvR0uwPsBKBiuq55C28O7MulPkUMzv5RkH8oo31u4JuLKb9Q1D6fjmpSskVZnaECFlF3CHSeT9aPELWRtgrQQrqg+987LqdafIYeClohpXHnzzztuDGM36tqF0emur+F0GVbn27idFzPEqBm2x96NFWB1grQcrymt635exbnCKHAXjpXUPsPWXZj1V0hu2tlolOLUeNck3RH3PPrWm3XgFZOMAK76wxOSdQ+rfuQLtwfR08v3kaPfAIO1USW/a2ip81jUbJmKSb4gOjL0fLc3aAMsKAkjPxL13SP3h16RYnk7a1s3UPHDsmijpDfvFh9lgw4RN8m1R3/rzQ01eQnCAZb9PILSw5NEcfk2K4+msLg+f+QmX9IaFo2E2TQeEXuG0OeqbqEHbCztjf4Dlvk/g4BMXh2TN0/kIQkPpTQtHA6RsmLRJnoz65kJ+7dudvAGW9z6Bg09cHJF1T+cDiA2l06H4YeI2zBaTPDqHyZ/Zq9/u5Dgr/fcJHKSBOQ2bPJ2PIDaUjm5tlSZow2wzyWNzmHwK5vVvd4qtSTnNzMWx2OjpfAR+9M7KfvFpfBtmq0kencNkz+z1b3eKrkk5xczFAdnm6XwAXkkntrbagG/DbDbJnc7CnIJ5i3bUf58A2EhiC50jsWVrq3WCNsw2k9z+RmsK5g3a0feeys6I+BY6R2JDKP4mghVhk0nufKM1BfMG7egJZuKOyhlCtDcsHN2GI8v9JvnuqKitHH4m7qicIkT7rbzkrzDJd0ZFbebwM3FH5Qwh2vf3ku80ye8RFQXemoM7Ok0v+fb1r2n2meT7o6LA+3F0R6flJb+Xk3yXSb47Kgq8J8d3dJpe8vu0h3tM8v1RUQAokhvN72eXSb43KgoAkt689HW8xiTfExUFQHLz0tee+lUm+c6oKPDcJDcvfTW7THI5A7M7Kgo8MRs2L335Odff/ZRm9vHtjIoCT8yWzUtfxpZ3P0Uxts3lYEYa7OAeW1tpXrW34L2iosBzc7+trV65t+C9oqLAc3O/eODX7S1Y2dvmArCTu8YD795b0JyCOdTaNHA67jr62rW3oDsFgwYavIK7jr727C34JlFRANyFXRbM/aOiALgTGy2Y4C6jB147DJ6VTRZMbJdRmBvgjGzbZRSAU7DxHeQAnIPULqMAnJLEmxIBOCHRNyUCcEYSb0oE4IRgTzmQF4jgB1mBCH4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADgufl/b7ajXyKK+6YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjEtMDctMzFUMDg6NTY6NDUrMDc6MDDBl1XgAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIxLTA3LTMxVDA4OjU2OjQ1KzA3OjAwsMrtXAAAACF0RVh0cHM6SGlSZXNCb3VuZGluZ0JveAA1MDR4NzIwKzUwKzUw1uIiwwAAABN0RVh0cHM6TGV2ZWwAQWRvYmUtMi4wCjmTdA0AAAAASUVORK5CYII=" />

=end html


Result formatted as table (split, part 4 of 5):

 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) |  time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |       600 | 2          |                 0.00% |             61075.10% | 6.5e-05 |      20 |
 | Text::ANSITable               |      4020 | 0.249      |               586.14% |              8815.88% | 2.1e-07 |      21 |
 | Text::Table::More             |      9500 | 0.11       |              1524.04% |              3666.85% | 2.7e-07 |      20 |
 | Text::Table::Manifold         |     16000 | 0.062      |              2650.29% |              2124.32% | 1.2e-07 |      25 |
 | Text::Table::TinyBorderStyle  |     19000 | 0.052      |              3155.00% |              1779.42% | 1.2e-07 |      25 |
 | Text::ASCIITable              |     21000 | 0.047      |              3555.71% |              1573.41% | 5.3e-08 |      20 |
 | Text::Table::HTML::DataTables |     25000 | 0.04       |              4152.36% |              1338.61% | 9.5e-08 |      25 |
 | Text::Table                   |     26000 | 0.039      |              4295.16% |              1291.87% | 5.3e-08 |      20 |
 | Text::MarkdownTable           |     31000 | 0.033      |              5151.57% |              1064.89% | 5.3e-08 |      20 |
 | Text::FormatTable             |     43000 | 0.023      |              7228.34% |               734.77% | 2.7e-08 |      30 |
 | Text::Table::TinyColorWide    |     59000 | 0.017      |              9966.01% |               507.74% | 2.7e-08 |      20 |
 | Text::Table::Tiny             |     65800 | 0.0152     |             11142.60% |               444.14% | 5.8e-09 |      26 |
 | Text::Table::TinyWide         |     75800 | 0.0132     |             12842.13% |               372.68% | 6.7e-09 |      20 |
 | Text::TabularDisplay          |     76700 | 0.013      |             12990.18% |               367.34% | 6.5e-09 |      21 |
 | Text::Table::TinyColor        |    115103 | 0.00868789 |             19555.45% |               211.24% |   0     |      23 |
 | Text::Table::HTML             |    180000 | 0.0056     |             30532.11% |                99.71% | 6.7e-09 |      20 |
 | Text::Table::Org              |    180000 | 0.0054     |             31396.78% |                94.23% | 6.7e-09 |      20 |
 | Text::Table::Any              |    258245 | 0.00387228 |             43999.10% |                38.72% |   0     |      20 |
 | Text::Table::Sprintf          |    352000 | 0.00284    |             60033.82% |                 1.73% | 7.8e-10 |      23 |
 | Text::Table::CSV              |    358000 | 0.00279    |             61075.10% |                 0.00% | 8.3e-10 |      20 |
 +-------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                     Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::Table::Manifold  Text::Table::TinyBorderStyle  Text::ASCIITable  Text::Table::HTML::DataTables  Text::Table  Text::MarkdownTable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::Tiny  Text::Table::TinyWide  Text::TabularDisplay  Text::Table::TinyColor  Text::Table::HTML  Text::Table::Org  Text::Table::Any  Text::Table::Sprintf  Text::Table::CSV 
  Text::UnicodeBox::Table           600/s                       --             -87%               -94%                   -96%                          -97%              -97%                           -98%         -98%                 -98%               -98%                        -99%               -99%                   -99%                  -99%                    -99%               -99%              -99%              -99%                  -99%              -99% 
  Text::ANSITable                  4020/s                     703%               --               -55%                   -75%                          -79%              -81%                           -83%         -84%                 -86%               -90%                        -93%               -93%                   -94%                  -94%                    -96%               -97%              -97%              -98%                  -98%              -98% 
  Text::Table::More                9500/s                    1718%             126%                 --                   -43%                          -52%              -57%                           -63%         -64%                 -70%               -79%                        -84%               -86%                   -88%                  -88%                    -92%               -94%              -95%              -96%                  -97%              -97% 
  Text::Table::Manifold           16000/s                    3125%             301%                77%                     --                          -16%              -24%                           -35%         -37%                 -46%               -62%                        -72%               -75%                   -78%                  -79%                    -85%               -90%              -91%              -93%                  -95%              -95% 
  Text::Table::TinyBorderStyle    19000/s                    3746%             378%               111%                    19%                            --               -9%                           -23%         -25%                 -36%               -55%                        -67%               -70%                   -74%                  -75%                    -83%               -89%              -89%              -92%                  -94%              -94% 
  Text::ASCIITable                21000/s                    4155%             429%               134%                    31%                           10%                --                           -14%         -17%                 -29%               -51%                        -63%               -67%                   -71%                  -72%                    -81%               -88%              -88%              -91%                  -93%              -94% 
  Text::Table::HTML::DataTables   25000/s                    4900%             522%               175%                    55%                           29%               17%                             --          -2%                 -17%               -42%                        -57%               -62%                   -67%                  -67%                    -78%               -86%              -86%              -90%                  -92%              -93% 
  Text::Table                     26000/s                    5028%             538%               182%                    58%                           33%               20%                             2%           --                 -15%               -41%                        -56%               -61%                   -66%                  -66%                    -77%               -85%              -86%              -90%                  -92%              -92% 
  Text::MarkdownTable             31000/s                    5960%             654%               233%                    87%                           57%               42%                            21%          18%                   --               -30%                        -48%               -53%                   -60%                  -60%                    -73%               -83%              -83%              -88%                  -91%              -91% 
  Text::FormatTable               43000/s                    8595%             982%               378%                   169%                          126%              104%                            73%          69%                  43%                 --                        -26%               -33%                   -42%                  -43%                    -62%               -75%              -76%              -83%                  -87%              -87% 
  Text::Table::TinyColorWide      59000/s                   11664%            1364%               547%                   264%                          205%              176%                           135%         129%                  94%                35%                          --               -10%                   -22%                  -23%                    -48%               -67%              -68%              -77%                  -83%              -83% 
  Text::Table::Tiny               65800/s                   13057%            1538%               623%                   307%                          242%              209%                           163%         156%                 117%                51%                         11%                 --                   -13%                  -14%                    -42%               -63%              -64%              -74%                  -81%              -81% 
  Text::Table::TinyWide           75800/s                   15051%            1786%               733%                   369%                          293%              256%                           203%         195%                 150%                74%                         28%                15%                     --                   -1%                    -34%               -57%              -59%              -70%                  -78%              -78% 
  Text::TabularDisplay            76700/s                   15284%            1815%               746%                   376%                          300%              261%                           207%         200%                 153%                76%                         30%                16%                     1%                    --                    -33%               -56%              -58%              -70%                  -78%              -78% 
  Text::Table::TinyColor         115103/s                   22920%            2766%              1166%                   613%                          498%              440%                           360%         348%                 279%               164%                         95%                74%                    51%                   49%                      --               -35%              -37%              -55%                  -67%              -67% 
  Text::Table::HTML              180000/s                   35614%            4346%              1864%                  1007%                          828%              739%                           614%         596%                 489%               310%                        203%               171%                   135%                  132%                     55%                 --               -3%              -30%                  -49%              -50% 
  Text::Table::Org               180000/s                   36937%            4511%              1937%                  1048%                          862%              770%                           640%         622%                 511%               325%                        214%               181%                   144%                  140%                     60%                 3%                --              -28%                  -47%              -48% 
  Text::Table::Any               258245/s                   51549%            6330%              2740%                  1501%                         1242%             1113%                           932%         907%                 752%               493%                        339%               292%                   240%                  235%                    124%                44%               39%                --                  -26%              -27% 
  Text::Table::Sprintf           352000/s                   70322%            8667%              3773%                  2083%                         1730%             1554%                          1308%        1273%                1061%               709%                        498%               435%                   364%                  357%                    205%                97%               90%               36%                    --               -1% 
  Text::Table::CSV               358000/s                   71584%            8824%              3842%                  2122%                         1763%             1584%                          1333%        1297%                1082%               724%                        509%               444%                   373%                  365%                    211%               100%               93%               38%                    1%                -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::Table: participant=Text::Table
   Text::Table::Any: participant=Text::Table::Any
   Text::Table::CSV: participant=Text::Table::CSV
   Text::Table::HTML: participant=Text::Table::HTML
   Text::Table::HTML::DataTables: participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: participant=Text::Table::Manifold
   Text::Table::More: participant=Text::Table::More
   Text::Table::Org: participant=Text::Table::Org
   Text::Table::Sprintf: participant=Text::Table::Sprintf
   Text::Table::Tiny: participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: participant=Text::Table::TinyWide
   Text::TabularDisplay: participant=Text::TabularDisplay
   Text::UnicodeBox::Table: participant=Text::UnicodeBox::Table

The above result presented as chart:

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAARFQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADUlQDVlQDVlADUlADUlADUlQDWAAAAlADUAAAAAAAAlADVlQDVlADVlADUlADUlADUlADUlADUlADUlQDVlQDVlQDVlQDWlQDVlADUhgDAjQDKdACnVgB7ZQCRIQAwcgCjAAAAUgB1YQCLLgBCQgBeaQCXYQCMZgCSMABFTwBxZgCTRwBmKQA7WAB+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADUbQCb////dJ2YKwAAAFd0Uk5TABFEM2YiiLvMd+6q3ZlVTp+p1crH0j/v/Pbs+fH0dVxE9ez3Ee915N/t8Hqnt6Mzx4jxIoRpn1yO+vb51XXHl5nW9OCW4PT5/Jno7bS0zyBQYHAwpkCPQGmk2AAAAAFiS0dEAIgFHUgAAAAJcEhZcwAAAEgAAABIAEbJaz4AAAAHdElNRQflBx8IOC1sVAp+AAArD0lEQVR42u2dCbvkOHWGvdvlsgtCgAmEQNNsw2QmM0DIQkhIQvZtQggx/P8/Eq22drl8a7FV3/s8M7e7dWXL9ifpSDrSyTIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMADyQvxhyJX/7l8drkAWE9Vz38sJvGHqVB+oWmfXUQA1tMu4nUKupggaHAcyu5EmuiqaQqq3Zr9ZIIumobaGnl/hqDBcaiGscjaoWn6igi6H8epYYI+9c04VVl2bmBygCNBTY6WNNLNmQj6lGWnqSaCrifSPFd9VnWwocGh4DZ0eelaYUOT5nkqqqEgTF8YaggaHAoq6GZqx1YKuqeCbvqW8sWOWBxDU7/1JgA8CiLoS1+z2bliyskokLXQlyGj89JkZAhBg0PRXsjAkIiXmRwjEfZArY6cjBHZHzEPDY7FeajybmiHsa+KrhuGvmRmdNV3Xc/WCCFocCTyghgURZFn9Cf7g/x3fQEcAAAAAAAAAAAAAAAAAAAAgOfDlmRLsZAV+wnAzqHeBXU3UVea6E8A9g7bttme83po4j8B2Dls2ybbInTqoj8B2Dts2ybbXEH+F/sJwM7h2zYrLtg89lNk+r0vMX7/ywDchq8wRX3lq2/Vc823bZ64YOvYT5Hrgz/4GuWDr7v4w6/7+do3AomhjPe56je+dpzibL7qzorjueofMUVN33yroBu+bfNb15kcX/9y4JKhHRlNsTHjfa5aNBszPqE4m6+6s+IEr/p2QYttm1+ljW81kMFf+KcAgj6QgnZWnDsLmpWNTts16/7jQNAHUtDOivMgQZd9N3R5/CcHgj6QgnZWnAcImpEXxaqfDAj6QAraWXEeJeirCAq6Cj1NvTHjfa5aFxszPqE4m6+6s+IEr7pLQQOwFQgaJAUEDZICggZJAUGDpICgQVJA0CApIGiQFBA0SAoIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKSBokBQQNEgKCBokBQQNkgKCBkkBQYOkgKBBUkDQICkgaJAUEDRICggaJAUEDZICggZH49233wu+YyfeRNDGsXtrAm9C0GAr734reW8n3kDQVT9NbZ41E2FFAE4OBA22cmdB532V5d2YnceiKMq1gTchaLCVOwuaBQJq2qzlR/quDLwJQYMQ72a+a6fd2eSgnM/ZVDX0TPZbRMECL8/3ZtF+30q7v6DbYcizaWjGqYoG4BRZPvhBQ6k33xMkzYfXC7piirrNLEc1NHVDtHrqowE4RZYffqmg5JvvCZJmg6BLpqgbmRwXbkvkUwGTA9yADYLm3CCSLA1YVEwFHROSkd8tAm+Cl+eJgi7o9MU48B/dTQJvgpfniYLOxqkd+jJryI+hvEngTfDyPFPQWc0jatY3C7wJXp6nCnoLEDQIAUGDpICgQVJA0CApIGiQFBA0SAoIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKSBokBQQNEgKCBokBQQNkgKCBkkBQYOkgKBBUkDQICkgaJAUEDRICggaJAUEDZICggZJAUGDpICgQVJA0CApnitoEacwFp8QcQrBWp4paBGnMBafEHEKwXqeKGgZpzAWnxBxCsF6nihoEacwFp8QcQrBFTx7UHg+x4IFIWgQuILnCprGKYzFJzTiFELQIMSTZzmqoYnFJzTiFH70UUspn/3iwD7ZIOiGKepmcQphcoAb8sQWWsQpjMUnRJxCcAVPneVgcQqj8QkRpxCs55k2tIhTGItPiDiFYD1PHRSKAIWx+ISIUwhW8+x56KuBoEEICBokBQQNkgKCBkkBQYOkgKBBUkDQICkgaJAUEDRICggaJAUEDZICggZJAUGDpICgQVJA0CApIGiQFBA0SAoIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKSBokBQQNEgKCBokBQQNkgKCBkkBQYOj8ccfSj62E58r6LLW/4rAmyDOx7MuP7QTnynocpimocyaidAi8CZYyW4F3Y9ZPg7ZeSyKokTgTbCSvQqahWqrp7Kt2F8ReBOsY6+Czum5/DRoUNU0RYYoWGAlexU0pe7GbBqacaoyBN4E69ivoPNmarK6IVo99RkCb4J13FrQNwu8WXazLvOpgMkB1rHbFnpgk3EFHROSkR8Cb4J17FXQF9IqU1j8zQ6BN8FK9ipotqAyTeRnOwwlAm+ClexV0DM1Am+CK9i9oK8Cgn55IGiQFBA0SAoIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKSBokBQQNEgKCBokBQQNkgKCBkkBQYOkgKBBUkDQICkgaJAUEDRICggaJAUEDZICggZJAUGDpHiqoMtbn6oIQb88TxR01U9tMdxU0xD0y/M8QZdTVbR50+fxX10NBP3yPE/QzZgVbZZ1RfxXVwNBvzxPFHQDQYOb8zxBF31JBF3B5AC35ImDwtM09ENfedNF4M1YwE0E3gQKz5y2q6vm4m2fReDNWMBNBN4EGs8TdM2N56p2J4vAm7GAmwi8CTSeJei6ONEYscVlcA8KReDNL0QCbiLwJtB5lqCrthtYwKyz2+gQgTe/FYl+hShYQOeJCytV7DfqbowF3DQCb/7wSyzS0C0nTsCxuLWgSx67ar1zks+G5oE3YwE3jcCbH/ygodQr7gvS5NaCrpii1vlynKnJ0XsWVnjgzZipAZMD6DxzYaXp2qYbPck88GYs4CYCbwKdpy59X8YsH9wGrwi8GQ24icCbQOOpgi5boka3ySEDb8YCbiLwJtB4nqCroc6IwTBEnJNiATcReBOoPHHpu22zph+6Fb+5Ggj65XnioJDOQ1+qm84ZQ9Avz/MEfbpp28yBoF+eJ5ocY8MnMm4IBP3yPNHkmMRExg2BoF8enMsBkgKCBkkBQYOkgKBBUkDQICkgaLBHPnkv+RMr7dM57f2nViIEDfbIIr3PrLRFer99ZyVC0GCPQNAMCDoVIGgGBJ0KEDQDgk4FCJoBQacCBM2AoFMBgmZA0KkAQTMg6FSAoBkQdCpA0AwIOhUgaAYEnQoQNAOCTgUImgFBpwIEzYCgUwGCZkDQqQBBMyDoVICgGRB0KiQpaP1QJQTefCVSFHRND1Vi50S3CLz5aqQn6PrSUUGfaTTDEoE3X430BF21TNAtD/6GwJsvRnqCFsGtpqpping0LAEEnQrpCnpoxqnKEHjzxdiNoK8OvOmHCrpuiDhPfTQAp8iCwJupsBtBXxF4M8ZsSeRTAZPjxdiNoDk3EzQLxEJGfgi8+WIkK2g6izF2CLz5aqQq6KyZ2mEoEXjz1UhR0JwagTdfkXQFfRUQdCpA0AwIOhUgaAYEnQoQNAOCTgUImgFBpwIEzYCgUwGCZkDQqQBBMyDoVICgGRB0KkDQDAg6FSBoBgSdChA0A4JOBQiaAUGnAgTNgKBTAYJmQNCpAEEzIOhUgKAZEHQqQNAMCDoVIGgGBJ0KEDQDgk4FCJoBQacCBM2AoFMBgmZA0AfiRz9+L/iOnQhBMyDoA/GjkIIgaAYEfSAg6DgQ9IGAoONA0AcCgo4DQR+I1xM0P4UxFp8QcQoPyssJmsUpjMUnRJzCw/JighZxCmPxCRGn8LC8mKB5nMJYfELEKTwuLyZoGZIiCwYLQtCg4/KSgo7FJzTiFELQB+IlBR2LT2jEKfzoo5ZS3usbgBtyDEE3TFEwOUCUYwiac7tIspH4hIhTeFxeUtDR+ISIU3hYXlPQsfiEiFN4WF5O0JxYfELEKTwqLyroq4CgDwQEHQeCPhAQdBwI+kBA0HEg6AMBQceBoA8EBB0Hgj4QEHQcCPpAQNBxIOgDAUHHgaAPBAQdB4I+EBB0HAj6QEDQcSDoAwFBx4GgDwQEHQeC3hmffCb5iZUGQceBoB/Pn8pTnt9/Yif+OCA9CDoOBP14ggp6D0G/CQj68UDQdwSCfjwQ9B2BoB8PBH1HIOjHA0HfEQj68UDQdwSCfjwQ9B2BoO/Cpx/O2IkQ9B2BoO+CoiA7EYK+IxD0XYCgIeikgKAh6KSAoCHow/HpO4ntFwdBQ9CHY/nWH1tpEPQ9BI3Am3cFgn6MoJuJ0CLw5t2BoB8j6PNYFEWJwJt3B4J+jKDbiv1A4M17A0E/RtBT1TRFPBqWAILeDAT9IEEPzThV0QCc4rch6M1A0A8RdN0QrZ76aABO8esIvLkZCNpdnBsG3pzJpwImx72BoB/SQhd0TEhGfgi8eW8g6McIms5ijB0Cb94dCPohgs6aqR2GEoE37w4E/RhBZzUCb96Kn8z+R5/aiRD0gwR9FRB0iI/XKQiCtjNC0HsEgoagkwKChqCTAoKGoJMCgoagkwKChqCTAoKGoJMCgoagkwKChqAPx0+/L/mulQZBQ9CH49urvjUEDUEfhPervjUEDUEfBAgagj4an4ac5iBoCHqH/ORjyZ/ZiR9uVRAEDUE/ieXl/thOhKAh6KPxbt23hqBDDwlBP5bZEn5nzxhD0BA040iC/t7WlwtBQ9BP4s8/k/yFnbj55ULQEPSTuM/LhaAh6CcBQUPQb+MJgv7Lh79cCBqCviPrFARB28WBoONA0BA0BP02IGgI+n5A0BA0BB3l4w8ljulkCBqCvh/3EXTo5ULQEPSNWR14sw2kNUUg8WchQf9V4OX+PPRyfxZ4uX8derk/C111XXGCV7UFvRTHIeifby3O36wrjv3OleI86p0/TtBXBN6EoCHo/Qv6isCbIUH/4m/lZumfXvdyIWgI+pZcE3gzJOjl5X77upcLQUPQt+SaKFjrBH3ly4WgIehbYgbe/Ltv+vn7X0r+wUr7x99J/snO+M9z4i/txH+ZE//VSvu3Oe3fQ1f9DyvtP9cVx3HVdcUJXvW/AsX53TcDV72yOJvfuVKcR73zhwnaDLw5AXAPnmRyAHBsjMCbABwcPfAmAJuo336JG6EH3nzZ1wCiVIGvtUz8Ph8t8OaDGZ53a3AlVV/6EzEK4zQvYbxXmzuiUM7qLo2B/46n0LfKJzRNjOEO1nvVjs8yoTwPuflj+3Pm9XRx/nsbvdkl9Bu+O9ZZPrSjI6HkX3A43eRV3Z+ai6PqJodKgomccMZz2/sSN99x7JrW8a03XzWUUQwCQsXJPGPuekXGwGidPKX9j2V3ysZIp1c1bcje9dzx1GZFP7labzIGo08wjtlBYC+uGS5F112ZmMUyjkPV9KM7cfMdL4NHIZuvGsrIGrRAceqhIumuj01zhp7Dn5MnTw7lXaY+r/tgW9l0p3Gqrr5j3rdfrN1ir7uuZIo/CEVP6mV/oYvkl+sSqZUXysimwEuH8UUTt92RcOmLy8je8a2uGsrIBgH+4pTk36vs4tIszRl6Dn9O0q4PTe4aftRTN2ZN723zyQeh7/zk+o0ydEfyDshLKI0muh77vqFWTl8caVR4PmfZVJZtW5ZXJTIrL5SRv4OxdSZuuSPvwdtpGC/0t2511WBGOgjwJV76qcuLfqydH5vk9GU8DbT9tXNy66fpLpeuy3WrlUu0P01lPpiNbF2xoR7/IHnmGrmwoma+spYkL+2n9G9V9mNxoXUyo23+FJgD2QfC2ifVvsi6brhkSpllmjNRwKw8TxrLmLO2qbA6wKomiVbGUHHkl1568Kq1MmaOqwafI5SR3JHdhg0C3Il5PRRUBuS7q8/PM/KcnucYiWJJo2fmzIRpRPu0vG8qpZ0ljST7xbYimruwTHkjkvPz1JEKkvMPQs2KrDGaWllUd1mF2EmevFd6k5zZNvwm1dS0bjtmR9TknVbD1JZNRwrMrAM7LXMkyt+hrYyRxloK1mPSjCMdTlSt2ZgS67LprIuGiiO+tOjBiyarlDevlvWq5whkzImKy3kQYCTW5wtPbLi5kneKVZHnzBriOd3PwUyxgVoUWk4KM42YGqshUycd2om1C01T91XWtjS95aLNO/qHom/5B2EGSTOId56fmCDnopp37MpF7LQTU6fuNCODjBj3v9rcDEV/Kc795wMdO1envrHT8tyRKCU78C+3pLG5ed5jZiQjaaEuVT/b0LLVIGMPkmhdNFQc8aV5D17203DJ3GW96jn8GWl9yfN5EKAm5k1/rqnia/YvVAa5MiNBctI0kdP5HPlAVD8yiyI35zLo5VgjS+RUyhdGalA9sesULSl0XpL2sq/mh2A/SpLM/kjf+SCtYdJ40z8sRTXvmOez2En9LuU3qgs6BKqyoukmfqey9QwFdkQ+sFfXjrRza1qtxHNapiXSeSNVsvQvSkZWwUWPSTPmY98tia0y0CaJxh2DxeFfY+7Ba/dzOK7qeY5YRjL2ys7jMghYEi8Dm/g4j0JKtJknyWpOkjbndD5HRpvZqq9zLSdrJahpxBrZSz+XktWgZijJpfOJGcjN1MzmSCdM7abnHyRvOnJLMRRvuo7ZKktR1TuSQeR5XMTeTGICKR+niTTI9P9dc2n2bz1LLsLIdU1OzmlaIp030iS7JFF7jM3Nyx5zychHy3lPlSMH2qFbKmmaEeyxfTxljac5E2spgHr6b2sQULfECC1EcUSFbqRIZM7A8IFnzM5sopD+DslJW8NsbiWIaZS1Q1XNLbCoQcSiJcZFPpRE6qTvWC4oTQi6145/ENJDyC9Dfo70SktRFUHTQSQpziJ20ZfmHalABTFkyoJdpdu1sUG6L/qDj7O5lTYVsnPjiXra0vNlYt5Ikaw63ib2GJublz3mnFGMltnM0DzQDt1SuaNmBGtdf6is6kNazxF5yIE2aSVtlZrWGgSMpGVsmSKoLi5UNjl9wIuWk6Q5hw/0QWr6HHQKaKCqLPtf8dZwbiWY9JZ2fa5BdC4uHzvaHutzcrPc6K+x5zkP3SAa1XIiY8XptBRVlpU9DJuAbxWxcxpjXmrY8XCQd1/zOJtNEs/7s0SiM02dN7IlK36DtBykpTN6zHm0zGeG9IF2+Jbs7apG8PKlQxn1hzQuGr3juaPtKuu8+//RBwGcmrW7OW349LXiOSdJy+2c+TJEoKMA/g7m1nBuJdRur1ZqEFPuaAzN8rGW89VsNzT/IIo3Gnm+YqDHWDiWtdkgkpR1FrugnecLm5JOojzNVzOO6L6WcXbTN41s8kSiM02fNzIlyyiZXUlHI1qPqY6W+U4wZaAdvKW4sWYEZysymg+pXTR4R2bfVB01i1grVfWfq4OA+TMzU5MWZ67QRk5z+MDoumWIkMsqvbSGcyuxWD9i5xyvQeRvJVse0d/OJRdrsdaSOBE7vdi5P1V9l+ttD+sruGVNimOIXQr6dBr7cezb3ep56b7mcXben5uLnuhIY0+pzRvpks34XOavaX59CCW/hxgt8+UQOdCO3ZKbBQ47N5TRfkjlopE7VhObVMuJLnmr3VrtIfvBa4CaaOY0MjJ3KvkguZqotIaylVCkJ9pmXoOys2EK0OLQPBNp5MkwxRy65XQEPbLhY6kvl+dqp0fKqoudNUwU8imrc7NjLzul+5rH2ZfaTrTS2D+q80bWdAGfy6TNjTY3Ly49j5bZzNDcLAVuyexcYRbYdm6orI6H/NX8HLGHrJjNcKE/2WOU5nTKRfxabSYaOZcZN1p44U7lGCIoraGjlSDqZzcUNag2fIdkcYhNMdFRhpbGxS4nlnNZGraWLfsK3ulpz0HzVWLOrzmC+4bovpRxNoP7UolEI02gzRsZiLnMX9PvYbrVVoUyWuYzQ/RNCe8t5y25nSvNApdlHS6r5yGzOpKxKqguR7ZeZDlVSYmwJzHWiqo68+UkQ2XpTiUeRJOl0hpqrYT4k7AjKqcf3GL3ihesJkmxq+9NrmXPfYVtWbN8HVdyewgHO9l9yXE2h6+mikQjjT3nWGvzRsZF5Vwmq/F6RsWtl1qJRSYG2uKOrlvKiSppFjgs61BZvQ95aoMZWVGJLi/MspxMJ55cWcwpjDdAy+vLmeezO1UzGQ9S1b7WkCu5bsUg0KpBi1tq3jhtXPmPim/YspbtnMFa6mzZt8yI2fkGOm4Biu5rGWdzeEfME820jH9N97wRn/6Sc5nWXC936zVHy7R5Fl2/dcvFCJZmwee6Za1ZslZZyyXNTGQT4f6H5EUluuQGhSWTmEO0mZO0/3RYSNpg6U5FCqCbpKQieFpDWsicVQB2tbkGWU4tfGJbSTPEPi6qXEbnrr4iU+ps2VIjZud6lsUVbYIcZwuzquQdMU/M3faYPm/EFw2FnSvnMuU88JyXu/Wao2XaPIs7WrdU7FxpFlz0dkSzZPWycj8b6yE5fCLc85CzB3LVL4asUyJGrsXJWM1JupmuKqiXmhQcdac6Gb7cbeNtDZv+1FO72HStU51aeHFyPc0tdv63eXRu9RXi6eY/lcXO5axYgFr3NbsIil66c7hlLvaYOm/EFg3n6S99LpPPmzEd8GnSZbTM18WoYsUdXbeUdq5hFtRhS3bxs/E8h0hTE2fJLh7IzbQkRyRiOEQrOc98XqGiK9ltNrtTLYtuc0VwtYb0KQc+ui6MG6pOLWZxdK9vXeyUZXS+9BUr6uwuUSxA1QBczCrRSxvWIX9O+U/avBFbNFz8bLQ+k0mD60B36xVeAqx5Fne0DFJ+AW7LaWYBtYEDlmytOJVZFxUeyLzhVhO5ZDUP5CpXbhGUiOkQveSUXvjkleV9NbtTzXdWK4LdGtKnlEpujQ0qmlOLoVjN61sXO7M9ltH50ldE6+weqZwWYK25CJ40k8q21cjXlPNGyqLhPP2lDy+osoQONLfeeV2MKvY0ebs1IXbdLGA2sLf1KKdccSozkB7Idhpv8WwPZIFHIiGHaF5WMRVUCg8LOR35v+xHaGcAUx4buWmDy5BTi8frO9cLtLQEtHOY+4pYs75HCjmTpvUm9F2rLoKD9rF1Wy1Tvqa2aOie/mJu8VIHStutOMZQ7Q2WvHhDmrknqqQN7OoVc1ZYxalMY7aMxES4CpOs5YHs3m4gR2Yhh2he/KISGme912Kt0nyhiqAor9Zcm/xOLSu812dDbRmdL71UoFnfJTlbDVk+zwK1IBQXQX3Uq9tqWsXVFg0d82bCLV7qQF35WrpP2jxrd1RcTCi2EVzNNrD92lvyjc5NZvnZsF/OFctodpFcksm1LA/k0HaDiEN0JiYApQfGKdNcpki+QEUQH4zTaM4FHqcWO83ywVYqiTI6r4N1dr/k3VBxQVu9CZsiVlwEjQVQzQFZVZDubG5Nf0nndkdToayLseZZuSPzlp63cjgsa9rNsBrg6hXPfZdXnTk2ZU/dTr1iGWVqTZi31jicU7zbDWIO0ZmYACzF6oV8RuEVRfI5KoJ9lAJ5SmMpwOnU4kqzfLCVV6KsZYe3CO2YauiZNaaIsuWnlTRLazW7CHpsNcMDTlk0NKa/qmJ2bld0ICYH1XUxYxqUGsjKVg4D2c1QFZjNc0Eq1Gkcu5I5UZirW2NTW5aR7oFMWzV72dmz3SDoEC0Rc5UD9Us26gHL56gI1lEKdt9/rde3VUlMQy24RWiX8BaI2hXs4yyPQ1otKmk2cjEWPUK2Gnsr1BzzLhrSznZxbl82uojJQW1dTO8QuIG8bOXQLyu7GWYDm6ljX9Y9aRaHi+l9UfV9zz09FcsoNzyQPa2ae/eD3yGa60dZZ8r7cd4opawWkXyOiqAdpcCUx58y5Nkd9PrO7Epi1pHwFqEdkTd8aCVaIPrqqkGzC4jsmolImmjHWvQI2WqZMMd8zua8s7Wc25fJQfe6GP0k3EB2DDF5EyO7mdkGlkca0SpLFN0Vlq8w6Tu6C5tJIR8s5IGstmrh7Qby7TkdovmjK+tMp2WjlLJaRPMZOwMo6lEKy/g74Nkd9PpmWJXEbAlCO5Z2BF2jYv2nbIFYWyBfEd8GTDcKjUTSVHWGi2DQVpOjZZezOYX7jJvO7cqaq2tdTKiA2iDqEJOLa25iRDcjL8uPNBJVduxZTdAaoKoYB+ni1jVBD+RynjyJbTcQl7AdojOmn3kQwF+dcWyLXBrtFacg91EKufySfs/uoNe3wFlJOJE6uyPytj+Jz+ZogeQ2YKZzIunBMUsTsNXm0bLD2VzZCW46tyuTg451sVkF5P0rDalogOYmxuhmGnU/LlG04UvE9svRWs0+pDrCdHggywePbjfwO0Szd3v2rDPNRealoAves3up/yiFkGd30Os7WEl4MxGtszvizD4t7ePmFkgZDMhtwKIJYfvNluf022Pyi853ke2cYd+Y5/2IcyGU/cPLupjw3plVQA1k2ZDKBmhpYpRuhsGONJJV1pyqE/vlWIphr/s8kKPbDbKgQ/SlYHXHvc6k+YXp+fxHKYQ8u4Ne36HzRngzEdoitDvoYX55M/XCU8vYKSW3AbON+plUaNweM0fLctHQsm90O0V0CK79w7P3zjIUXAzkZQw1NzF6e8jXbuYqa78FZvsMjb3jwOeBHHP+D7uRsCE0+c/tS677hRlJ/jMY/J7d4TRvJZHNRKDO7hDhp3WZSsceiHkbsOr0ErbH2PDdPVp22jeaU4foEATK/mHFe2f5JPK6irjmJkabcxJrN0aVrUfl4CbaOrPBl2YZ+T2Q+ZMFdjj43UjynB8UQP5z+5I7/cLkyw+ds+Dx7I6keSqJ0kx46uw+yYWfFt0gYs/FzNuA54P5gvaYuJBvtOywb/SdSbJDsPYPK9477s8lGyC1ieHW4WU511StsqKb0Wwfy5T1eyDzUgV2DfgX0VijTytP1f/G7UsuWNyaY+dFhN3Xg67tma+SqHaKu87uCPVg7gv39zXaZvEW5m3A9Sp7jH+G2jdaDts3Sodg7R9WvXccnyRbxlBKrWTmw0k911Q90qhjJdNsH2sU4PNA9uwaCDpXzoMvdoqHCDemrTPpzorLzdbMprjd1wNpKyqJYqe46+x+0A7mZof5KVvbuB8xfwvObcBue2z+YOTpfYv9fvuGS2TuEPTJQZKoeu/ktpyXMZQK3bB4JnXIPpjoLJ/IbftkMQ9kz66BkHOlMvhihx7Qqim96lzOijJfZDalzvxmij8tXkn4BxHNhLsN2RHawdzaYX6LHzF7En0bsJLftsfmD1Y7HTMyapH67RsukblD0DPSRMV7x41rDEXadTrDbR9MxE2Y+uQ7BcfngWxIxDRzg86Vy+CLvu1KHfL6nRVjsyls56PHfd2ftuqEE5pPNhP5ruWcGQdzj5M6hNL8iK2+LWCPzR+MHo3rWuwnL9Fh36gbS1wdgkg0vXdsrDFUVZAC0els+2AiasLQTXj2QJH98HkgmxKxnKJCzpXL4OvUXy7DOmfF2GwK3/nottd9aeFKotfZatqxoTFjHMydGzawai+aSykBW23+YHSE5VrsZ2ajYd/oG0tcHYJM1L13HBjiYl6ZZ9r0DJV9MNFl4pvwTEejsAeyVz6rnCuXwdc4GeGl/M6KWeQoheVrWW7fvrRgJTHrrGuqZW+4D+aWr2jxI6ZvYd4GHLLVBPMHs1fBF4tUt2/8HcISkEyOrxTvnVVPyU8Lr6i9qNvH/NQrqQxloirqgeyVj9+50jn4mlErgsdZMQvMptC/d8pKn+9L2t543kpi1lnXlred4TyYe3lFix+x+hZCtlpmfTBjjlSNQKPbN+bGEuWO+ulrJPE0XbUfsxZLkpklEPYYpTVxHPJA5gQk4nGujA2+1Irg9LVXLDxzZCacZMURgJY30fwl3RulfJUk1OTvFNcslvaKZj9i07J2bjVUjuGaPxgfYakG6XwwrjH5Y2wsER0CPfRAD0jGFopXPyKrX9xRZNDNdWV/kb4ZJeKBzF5cQCJu58r44EutCA47TbPwjMk46STLD0U37HXlS7r2v/oqSbhZ3yF0Xexz3/HaAT9in62mH8NlfjDVIHXvifNsLGGHHiwByVbvxeSnf4j6xRdLlD3Sei+jzfNFPZBDEhFFtpwr1/l7KBVBoVb2v2YeS1Y4yfKdj/r4QfuS7jGJ87yRSLO+O/i6mCc6z/KKrL10PlvNPIZLGy2fL5pBaluk/o0l4tCD0b5jGB4yQNYv05Q3ehk1Pl/UA9ktkbBDdNTfgxfZ5WXsPYOB31Eu3XAnWf1reTzCsxUHlUTq7A7h62L/p85iCcc5/RVpjmpeW80+hmv5YLzp1gxSa3Oos0NQDj1YApKtbSp4yIC5fhmLJWYv41kW0zyQF2yJrFnCcw6+gnER+KXdZzDI9Xq5BCOcZNVP6fMIjx5UEmzWd0hF7TOxLrbMYknHOfMVuZ7TqriOY7hk0mw8qgap5eHj0Ih26IEWkCyCevqHrF+/0XdYxcxD2wNZr+2GRFasTmSuwVcwLoLAbeFJO1/x+l6KIy7r8wjPIgeVuL/HHuFDs6aryKs1HShnP2LnKzKe01lxncdwLU23ZpAyQbv6THFHmqQdemDN8XnRK4JzyjY4pHN6IJu1XZNI3ED2zFAE4yLIN+6qe8tbnZdgFDNFXtbrEe45qCRYZ/cJC+3IF0L0dTHFZHC9oixsqwlcx3AtTbdqkFKL1NNn8rfMx5faSemrZ+q0imDPRkXMQ6cHslXbNYnEDWTnDEUwLoJEGyo7Fg3nJZjGtv48HuGeg0qCdXa3sNCO7A+Fti6mhpgxX5Fuj+m2mriqtsHIcTonP6BUM0gDfaZM0g89WD1Tp1cEa8o2ZB66l4sctd3yQPasToRmKIJxEXhxAmcwiDvaS2LLZd0e4Z75pHCd3S3UAZepuLJDO9bKwbjW3huPIaK647lW+zVHLWVLXKDPVBquwEnpXlh4JzVkgFW/Auahe7nIUdvt3sK5OhEbfAU3lkTOYBB3dLrKiMu60tyVZE2d3R+lHJrlWgx34w05j/vxGCKaO17mmv5RHbWUwbu/z6wV+XgPPQjAwjtZFSFuHno8kCXu2s5uGFidiA++fJtH/DNuysXZW3WeiyEu61iecVeSVXV2N/D3xFfp6NCMTdW5zkYTMnbtvbFtNZ5D/2BaC6T0tU5HLWefycdqsuHyHXrge0phMpgVITykC3kgL7hqO//twOpEaPHY56wYmXFTCLi/5X7XLW8l8dfZncHNJbFKR4dm+Ti4D7ux3pDDHtMv3QfCaah9rXN5y9lnitOF+Mt2RdjzoK396RUhYh76PZC1p7Frexbb/xqcHXQ7K0Zn3FQC7m/ap4wvMCjf4wCHe1GNzKt0Vcgcdb2hgD1muOOZ+JruOd3VZ/KAZFI+Z4dl5EZb+1MrQtQ8DByXqj2sUdujDtGeGYqgs2J8xk0vuf9bLpddscCgfY9dH+7FoN5kyypdyNh3viGvPeZzx8vWBirQNaIFJBNJ9eq5Db13VypC3DwMeiAvGLU95E+fBWYoAs6KK2bcVjNfdt0Cg+N77JFW7n9WTnC9+vQmtz3mcccLBVuy0aextIBkV3qTG727URHc5uE6D+QZo7aHnSv9MxSBihCfcbua+AKD93vsEdG4slBfriO91+E85sT3wTSLVO9rbfRBpBaQ7Dpv8phrmNM8jHkgh19KbPXcM/iqIl7GAQtvC6EFBsdr3LsLv2xcqTeZfaT3akIei+YH0yzS6/y0fAHJok8Zdw1zm4cRD+QQ7hoUWMyf8610I7mhIXuY6YsVyPA6Q5O9IWCtrLirRsuaRXrNekjmC0gWy7rGNcxpHvo8kKN3dNegwGK+li/sZZzffobhMNMXEahIRONKfYHeevRpeLQcCra05uK0BvgCksVY4xrm7GW2nXPsqUFBBzgtX9jL+PZDs8NMX8SeYwlad4N1zMhoOXaAf7CgchKr7dZmudo1zPCLf9s5x44aFHaA0/NFvIxvPzTb//RFGHWmkx4Ll49vNvbjo+XIAf4hPAHJQjm2uoat8UD2vIFwDQo5wFn5wl7Gdxia7X76Iog205l3fTu1b35D8dFy6AD/GPPvN/2q39/sGrbGA9ldwjU1yLmYr8cTcDkrPoDdT18EMWY6q9ONvFojo+Xw8a4ejBWYVU6im13DVnkgO1lZg+zFfDOewDGcMvdFbKZzO47R8qqTK50ETo+OsNk1LO6B7Cnq2hpkLeZb8QQO4JS5N+IznZuxRstrg+U4CZweHWfz3GrQA9nD+hqkj74c8QR27JS5S1bNdG7HGC2v2xvqI3B69Ao2z62GjrYPsLIG+fakJLGq8XhWznRuR/1eaw5PCRI4PXrFo14/txo7vj7Muhrk3ZNy+FWNJ7FupnMzhftElqsCb6hLMG9ouK6fWw0dbb8i98bVCUc8AbCO6Lbs2xMMluPLoy7BvKHhWj+3uuK41BVsXJ24w1L2q+Dfln0/gsFyvHmUJZjtDdfqudXIcamreWxFADH37RsTOt41kvMNSzCbShp2xV/NgysCiLlv35bA8a4xNi3BbOZ+8/IrOfYy3ROJuW/fiDXHu7qybV6CeRt3nJcH9+YRE53Rw1OcvGkJZjt3npcHd+UxE53xw1McvG0JZntZ7z0vD+7JQyY6t1ikb16CeUNx7zsvD47OJot06xLM27jCAxm8JqpFGtvQbbJlCWYju/BABvtHs0g3ehPdP/Y5PJDBalSL9LoN3duWYDYAD2QQJh5sKUIweNitCwsPZBAkHGwpQix42O2BBzIIEj1rIsS2JZg3Aw9k4GHVWRN+Ni3B3AB4IAM3sbMmwlTu4GH3Bx7IwI8v2FIUdQnmwYvO8EAGfgLBlvyYSzAPNjzggQy8hIItefO8aQnm7cADGfjZ1IFvWoIB4BGs7MCdp0fDKQjsjlUduO/0aLhRgCNyRawlAPbOdbGWANg518VaAuAApBRrCYB0Yi0BwEgl1hIAHLhQgLSACwVICrhQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGBH/D/PGDqmjym78QAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMS0wNy0zMVQwODo1Njo0NSswNzowMMGXVeAAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjEtMDctMzFUMDg6NTY6NDUrMDc6MDCwyu1cAAAAIXRFWHRwczpIaVJlc0JvdW5kaW5nQm94ADUwNHg3MjArNTArNTDW4iLDAAAAE3RFWHRwczpMZXZlbABBZG9iZS0yLjAKOZN0DQAAAABJRU5ErkJggg==" />

=end html


Result formatted as table (split, part 5 of 5):

 #table5#
 {dataset=>"wide (30x5)"}
 +-------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms)  | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |      53   | 19         |                 0.00% |             35533.33% | 3.7e-05 |      20 |
 | Text::ANSITable               |     143   |  7.01      |               168.54% |             13169.40% | 2.5e-06 |      20 |
 | Text::Table::More             |     320   |  3.2       |               494.57% |              5893.12% | 3.5e-06 |      24 |
 | Text::ASCIITable              |     641   |  1.56      |              1105.52% |              2855.85% | 6.4e-07 |      20 |
 | Text::FormatTable             |     883   |  1.13      |              1561.88% |              2044.16% | 6.9e-07 |      20 |
 | Text::Table::TinyColorWide    |    1100   |  0.909     |              1969.45% |              1621.87% | 2.1e-07 |      20 |
 | Text::Table                   |    1480   |  0.675     |              2688.68% |              1177.78% | 4.3e-07 |      20 |
 | Text::Table::TinyWide         |    1550   |  0.645     |              2816.27% |              1121.88% | 2.7e-07 |      20 |
 | Text::Table::Manifold         |    2040   |  0.49      |              3741.03% |               827.70% | 4.3e-07 |      20 |
 | Text::Table::Tiny             |    2470   |  0.405     |              4541.36% |               667.73% | 2.6e-07 |      21 |
 | Text::TabularDisplay          |    2790   |  0.358     |              5152.33% |               578.43% | 2.1e-07 |      20 |
 | Text::Table::TinyColor        |    3700   |  0.27      |              6856.23% |               412.25% | 4.9e-08 |      24 |
 | Text::Table::TinyBorderStyle  |    4080   |  0.245     |              7571.15% |               364.51% | 2.1e-07 |      20 |
 | Text::MarkdownTable           |    4340   |  0.23      |              8063.82% |               336.48% |   2e-07 |      22 |
 | Text::Table::HTML             |    4780   |  0.209     |              8900.61% |               295.90% | 5.3e-08 |      20 |
 | Text::Table::HTML::DataTables |    6200   |  0.16      |             11553.86% |               205.76% | 2.6e-07 |      21 |
 | Text::Table::Org              |   11000   |  0.09      |             20879.74% |                69.85% | 1.1e-07 |      20 |
 | Text::Table::CSV              |   14356.1 |  0.0696569 |             26910.63% |                31.92% |   0     |      28 |
 | Text::Table::Any              |   16000   |  0.062     |             30132.43% |                17.86% |   1e-07 |      22 |
 | Text::Table::Sprintf          |   18900   |  0.0528    |             35533.33% |                 0.00% | 2.1e-08 |      32 |
 +-------------------------------+-----------+------------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                      Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table  Text::Table::TinyWide  Text::Table::Manifold  Text::Table::Tiny  Text::TabularDisplay  Text::Table::TinyColor  Text::Table::TinyBorderStyle  Text::MarkdownTable  Text::Table::HTML  Text::Table::HTML::DataTables  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table             53/s                       --             -63%               -83%              -91%               -94%                        -95%         -96%                   -96%                   -97%               -97%                  -98%                    -98%                          -98%                 -98%               -98%                           -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                    143/s                     171%               --               -54%              -77%               -83%                        -87%         -90%                   -90%                   -93%               -94%                  -94%                    -96%                          -96%                 -96%               -97%                           -97%              -98%              -99%              -99%                  -99% 
  Text::Table::More                  320/s                     493%             119%                 --              -51%               -64%                        -71%         -78%                   -79%                   -84%               -87%                  -88%                    -91%                          -92%                 -92%               -93%                           -95%              -97%              -97%              -98%                  -98% 
  Text::ASCIITable                   641/s                    1117%             349%               105%                --               -27%                        -41%         -56%                   -58%                   -68%               -74%                  -77%                    -82%                          -84%                 -85%               -86%                           -89%              -94%              -95%              -96%                  -96% 
  Text::FormatTable                  883/s                    1581%             520%               183%               38%                 --                        -19%         -40%                   -42%                   -56%               -64%                  -68%                    -76%                          -78%                 -79%               -81%                           -85%              -92%              -93%              -94%                  -95% 
  Text::Table::TinyColorWide        1100/s                    1990%             671%               252%               71%                24%                          --         -25%                   -29%                   -46%               -55%                  -60%                    -70%                          -73%                 -74%               -77%                           -82%              -90%              -92%              -93%                  -94% 
  Text::Table                       1480/s                    2714%             938%               374%              131%                67%                         34%           --                    -4%                   -27%               -40%                  -46%                    -60%                          -63%                 -65%               -69%                           -76%              -86%              -89%              -90%                  -92% 
  Text::Table::TinyWide             1550/s                    2845%             986%               396%              141%                75%                         40%           4%                     --                   -24%               -37%                  -44%                    -58%                          -62%                 -64%               -67%                           -75%              -86%              -89%              -90%                  -91% 
  Text::Table::Manifold             2040/s                    3777%            1330%               553%              218%               130%                         85%          37%                    31%                     --               -17%                  -26%                    -44%                          -50%                 -53%               -57%                           -67%              -81%              -85%              -87%                  -89% 
  Text::Table::Tiny                 2470/s                    4591%            1630%               690%              285%               179%                        124%          66%                    59%                    20%                 --                  -11%                    -33%                          -39%                 -43%               -48%                           -60%              -77%              -82%              -84%                  -86% 
  Text::TabularDisplay              2790/s                    5207%            1858%               793%              335%               215%                        153%          88%                    80%                    36%                13%                    --                    -24%                          -31%                 -35%               -41%                           -55%              -74%              -80%              -82%                  -85% 
  Text::Table::TinyColor            3700/s                    6937%            2496%              1085%              477%               318%                        236%         150%                   138%                    81%                50%                   32%                      --                           -9%                 -14%               -22%                           -40%              -66%              -74%              -77%                  -80% 
  Text::Table::TinyBorderStyle      4080/s                    7655%            2761%              1206%              536%               361%                        271%         175%                   163%                   100%                65%                   46%                     10%                            --                  -6%               -14%                           -34%              -63%              -71%              -74%                  -78% 
  Text::MarkdownTable               4340/s                    8160%            2947%              1291%              578%               391%                        295%         193%                   180%                   113%                76%                   55%                     17%                            6%                   --                -9%                           -30%              -60%              -69%              -73%                  -77% 
  Text::Table::HTML                 4780/s                    8990%            3254%              1431%              646%               440%                        334%         222%                   208%                   134%                93%                   71%                     29%                           17%                  10%                 --                           -23%              -56%              -66%              -70%                  -74% 
  Text::Table::HTML::DataTables     6200/s                   11775%            4281%              1900%              875%               606%                        468%         321%                   303%                   206%               153%                  123%                     68%                           53%                  43%                30%                             --              -43%              -56%              -61%                  -67% 
  Text::Table::Org                 11000/s                   21011%            7688%              3455%             1633%              1155%                        910%         650%                   616%                   444%               350%                  297%                    200%                          172%                 155%               132%                            77%                --              -22%              -31%                  -41% 
  Text::Table::CSV               14356.1/s                   27176%            9963%              4493%             2139%              1522%                       1204%         869%                   825%                   603%               481%                  413%                    287%                          251%                 230%               200%                           129%               29%                --              -10%                  -24% 
  Text::Table::Any                 16000/s                   30545%           11206%              5061%             2416%              1722%                       1366%         988%                   940%                   690%               553%                  477%                    335%                          295%                 270%               237%                           158%               45%               12%                --                  -14% 
  Text::Table::Sprintf             18900/s                   35884%           13176%              5960%             2854%              2040%                       1621%        1178%                  1121%                   828%               667%                  578%                    411%                          364%                 335%               295%                           203%               70%               31%               17%                    -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::Table: participant=Text::Table
   Text::Table::Any: participant=Text::Table::Any
   Text::Table::CSV: participant=Text::Table::CSV
   Text::Table::HTML: participant=Text::Table::HTML
   Text::Table::HTML::DataTables: participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: participant=Text::Table::Manifold
   Text::Table::More: participant=Text::Table::More
   Text::Table::Org: participant=Text::Table::Org
   Text::Table::Sprintf: participant=Text::Table::Sprintf
   Text::Table::Tiny: participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: participant=Text::Table::TinyWide
   Text::TabularDisplay: participant=Text::TabularDisplay
   Text::UnicodeBox::Table: participant=Text::UnicodeBox::Table

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher --cpanmodules-module TextTable --module-startup

Result formatted as table:

 #table6#
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                   | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |     130   |             124   |                 0.00% |              2253.61% |   0.00019 |      20 |
 | Text::Table::Manifold         |      71   |              65   |                77.51% |              1225.91% |   0.00012 |      20 |
 | Text::ANSITable               |      37   |              31   |               237.43% |               597.51% |   0.00014 |      20 |
 | Text::MarkdownTable           |      36   |              30   |               254.32% |               564.26% |   9e-05   |      20 |
 | Text::Table::TinyColorWide    |      28   |              22   |               346.25% |               427.42% |   0.0002  |      20 |
 | Text::Table::TinyWide         |      26   |              20   |               389.24% |               381.07% |   0.00014 |      21 |
 | Text::Table::More             |      21   |              15   |               513.44% |               283.67% |   0.0001  |      21 |
 | Text::Table                   |      20   |              14   |               533.68% |               271.42% |   0.00016 |      20 |
 | Text::ASCIITable              |      20   |              14   |               727.66% |               184.37% |   0.0002  |      21 |
 | Text::Table::Tiny             |      20   |              14   |               742.57% |               179.34% |   0.00016 |      20 |
 | Text::Table::TinyColor        |      10   |               4   |               959.53% |               122.14% |   0.00021 |      20 |
 | Text::FormatTable             |      10   |               4   |               974.94% |               118.95% |   0.00015 |      20 |
 | Text::Table::TinyBorderStyle  |      10   |               4   |              1217.24% |                78.68% |   0.00012 |      20 |
 | Text::Table::HTML             |       8   |               2   |              1429.79% |                53.85% |   0.00013 |      20 |
 | Text::TabularDisplay          |       8   |               2   |              1434.59% |                53.37% |   0.00015 |      20 |
 | Text::Table::Any              |       7.6 |               1.6 |              1575.00% |                40.51% | 6.1e-05   |      20 |
 | Text::Table::HTML::DataTables |       8   |               2   |              1575.72% |                40.45% |   0.00013 |      22 |
 | Text::Table::CSV              |       6   |               0   |              1848.42% |                20.80% |   0.00012 |      20 |
 | perl -e1 (baseline)           |       6   |               0   |              1891.09% |                18.21% | 9.4e-05   |      20 |
 | Text::Table::Org              |       6   |               0   |              2009.07% |                11.59% |   0.00022 |      20 |
 | Text::Table::Sprintf          |       5   |              -1   |              2253.61% |                 0.00% |   0.00019 |      21 |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                    Rate  Text::UnicodeBox::Table  Text::Table::Manifold  Text::ANSITable  Text::MarkdownTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::Table::More  Text::Table  Text::ASCIITable  Text::Table::Tiny  Text::Table::TinyColor  Text::FormatTable  Text::Table::TinyBorderStyle  Text::Table::HTML  Text::TabularDisplay  Text::Table::HTML::DataTables  Text::Table::Any  Text::Table::CSV  perl -e1 (baseline)  Text::Table::Org  Text::Table::Sprintf 
  Text::UnicodeBox::Table          7.7/s                       --                   -45%             -71%                 -72%                        -78%                   -80%               -83%         -84%              -84%               -84%                    -92%               -92%                          -92%               -93%                  -93%                           -93%              -94%              -95%                 -95%              -95%                  -96% 
  Text::Table::Manifold           14.1/s                      83%                     --             -47%                 -49%                        -60%                   -63%               -70%         -71%              -71%               -71%                    -85%               -85%                          -85%               -88%                  -88%                           -88%              -89%              -91%                 -91%              -91%                  -92% 
  Text::ANSITable                 27.0/s                     251%                    91%               --                  -2%                        -24%                   -29%               -43%         -45%              -45%               -45%                    -72%               -72%                          -72%               -78%                  -78%                           -78%              -79%              -83%                 -83%              -83%                  -86% 
  Text::MarkdownTable             27.8/s                     261%                    97%               2%                   --                        -22%                   -27%               -41%         -44%              -44%               -44%                    -72%               -72%                          -72%               -77%                  -77%                           -77%              -78%              -83%                 -83%              -83%                  -86% 
  Text::Table::TinyColorWide      35.7/s                     364%                   153%              32%                  28%                          --                    -7%               -25%         -28%              -28%               -28%                    -64%               -64%                          -64%               -71%                  -71%                           -71%              -72%              -78%                 -78%              -78%                  -82% 
  Text::Table::TinyWide           38.5/s                     400%                   173%              42%                  38%                          7%                     --               -19%         -23%              -23%               -23%                    -61%               -61%                          -61%               -69%                  -69%                           -69%              -70%              -76%                 -76%              -76%                  -80% 
  Text::Table::More               47.6/s                     519%                   238%              76%                  71%                         33%                    23%                 --          -4%               -4%                -4%                    -52%               -52%                          -52%               -61%                  -61%                           -61%              -63%              -71%                 -71%              -71%                  -76% 
  Text::Table                     50.0/s                     550%                   254%              85%                  80%                         39%                    30%                 5%           --                0%                 0%                    -50%               -50%                          -50%               -60%                  -60%                           -60%              -62%              -70%                 -70%              -70%                  -75% 
  Text::ASCIITable                50.0/s                     550%                   254%              85%                  80%                         39%                    30%                 5%           0%                --                 0%                    -50%               -50%                          -50%               -60%                  -60%                           -60%              -62%              -70%                 -70%              -70%                  -75% 
  Text::Table::Tiny               50.0/s                     550%                   254%              85%                  80%                         39%                    30%                 5%           0%                0%                 --                    -50%               -50%                          -50%               -60%                  -60%                           -60%              -62%              -70%                 -70%              -70%                  -75% 
  Text::Table::TinyColor         100.0/s                    1200%                   610%             270%                 260%                        179%                   160%               110%         100%              100%               100%                      --                 0%                            0%               -19%                  -19%                           -19%              -24%              -40%                 -40%              -40%                  -50% 
  Text::FormatTable              100.0/s                    1200%                   610%             270%                 260%                        179%                   160%               110%         100%              100%               100%                      0%                 --                            0%               -19%                  -19%                           -19%              -24%              -40%                 -40%              -40%                  -50% 
  Text::Table::TinyBorderStyle   100.0/s                    1200%                   610%             270%                 260%                        179%                   160%               110%         100%              100%               100%                      0%                 0%                            --               -19%                  -19%                           -19%              -24%              -40%                 -40%              -40%                  -50% 
  Text::Table::HTML              125.0/s                    1525%                   787%             362%                 350%                        250%                   225%               162%         150%              150%               150%                     25%                25%                           25%                 --                    0%                             0%               -5%              -25%                 -25%              -25%                  -37% 
  Text::TabularDisplay           125.0/s                    1525%                   787%             362%                 350%                        250%                   225%               162%         150%              150%               150%                     25%                25%                           25%                 0%                    --                             0%               -5%              -25%                 -25%              -25%                  -37% 
  Text::Table::HTML::DataTables  125.0/s                    1525%                   787%             362%                 350%                        250%                   225%               162%         150%              150%               150%                     25%                25%                           25%                 0%                    0%                             --               -5%              -25%                 -25%              -25%                  -37% 
  Text::Table::Any               131.6/s                    1610%                   834%             386%                 373%                        268%                   242%               176%         163%              163%               163%                     31%                31%                           31%                 5%                    5%                             5%                --              -21%                 -21%              -21%                  -34% 
  Text::Table::CSV               166.7/s                    2066%                  1083%             516%                 500%                        366%                   333%               250%         233%              233%               233%                     66%                66%                           66%                33%                   33%                            33%               26%                --                   0%                0%                  -16% 
  perl -e1 (baseline)            166.7/s                    2066%                  1083%             516%                 500%                        366%                   333%               250%         233%              233%               233%                     66%                66%                           66%                33%                   33%                            33%               26%                0%                   --                0%                  -16% 
  Text::Table::Org               166.7/s                    2066%                  1083%             516%                 500%                        366%                   333%               250%         233%              233%               233%                     66%                66%                           66%                33%                   33%                            33%               26%                0%                   0%                --                  -16% 
  Text::Table::Sprintf           200.0/s                    2500%                  1320%             640%                 620%                        459%                   420%               320%         300%              300%               300%                    100%               100%                          100%                60%                   60%                            60%               52%               19%                  19%               19%                    -- 
 
 Legends:
   Text::ANSITable: mod_overhead_time=31 participant=Text::ANSITable
   Text::ASCIITable: mod_overhead_time=14 participant=Text::ASCIITable
   Text::FormatTable: mod_overhead_time=4 participant=Text::FormatTable
   Text::MarkdownTable: mod_overhead_time=30 participant=Text::MarkdownTable
   Text::Table: mod_overhead_time=14 participant=Text::Table
   Text::Table::Any: mod_overhead_time=1.6 participant=Text::Table::Any
   Text::Table::CSV: mod_overhead_time=0 participant=Text::Table::CSV
   Text::Table::HTML: mod_overhead_time=2 participant=Text::Table::HTML
   Text::Table::HTML::DataTables: mod_overhead_time=2 participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: mod_overhead_time=65 participant=Text::Table::Manifold
   Text::Table::More: mod_overhead_time=15 participant=Text::Table::More
   Text::Table::Org: mod_overhead_time=0 participant=Text::Table::Org
   Text::Table::Sprintf: mod_overhead_time=-1 participant=Text::Table::Sprintf
   Text::Table::Tiny: mod_overhead_time=14 participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: mod_overhead_time=4 participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: mod_overhead_time=4 participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: mod_overhead_time=22 participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: mod_overhead_time=20 participant=Text::Table::TinyWide
   Text::TabularDisplay: mod_overhead_time=2 participant=Text::TabularDisplay
   Text::UnicodeBox::Table: mod_overhead_time=124 participant=Text::UnicodeBox::Table
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 SAMPLE OUTPUTS

This section shows what the output is like for (some of the) modules:

=over

=item * L</Text::Table::Any>

 +--------+--------+--------+
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 +--------+--------+--------+

=item * L</Text::Table::Manifold>

 +--------+--------+--------+
 |  col1  |  col2  |  col3  |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 +--------+--------+--------+

=item * L</Text::ANSITable>

 .--------+--------+--------.
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 `--------+--------+--------'

=item * L</Text::ASCIITable>

 .--------------------------.
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 '--------+--------+--------'

=item * L</Text::FormatTable>

 col1  |col2  |col3  
 row1.1|row1.2|row1.3
 row2.1|row2.2|row2.3
 row3.1|row3.2|row3.3
 row4.1|row4.2|row4.3
 row5.1|row5.2|row5.3

=item * L</Text::MarkdownTable>

 | col1   | col2   | col3   |
 |--------|--------|--------|
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |

=item * L</Text::Table>

 col1   col2   col3  
 row1.1 row1.2 row1.3
 row2.1 row2.2 row2.3
 row3.1 row3.2 row3.3
 row4.1 row4.2 row4.3
 row5.1 row5.2 row5.3

=item * L</Text::Table::Tiny>

 +--------+--------+--------+
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 +--------+--------+--------+

=item * L</Text::Table::TinyBorderStyle>

 .--------+--------+--------.
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 `--------+--------+--------'

=item * L</Text::Table::More>

 .--------+--------+--------.
 | col1   | col2   | col3   |
 +========+========+========+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 `--------+--------+--------'

=item * L</Text::Table::Sprintf>

 +--------+--------+--------+
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 +--------+--------+--------+

=item * L</Text::Table::TinyColor>

 +--------+--------+--------+
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 +--------+--------+--------+

=item * L</Text::Table::TinyColorWide>

 +--------+--------+--------+
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 +--------+--------+--------+

=item * L</Text::Table::TinyWide>

 +--------+--------+--------+
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 +--------+--------+--------+

=item * L</Text::Table::Org>

 | col1   | col2   | col3   |
 |--------+--------+--------|
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |

=item * L</Text::Table::CSV>

 "col1","col2","col3"
 "row1.1","row1.2","row1.3"
 "row2.1","row2.2","row2.3"
 "row3.1","row3.2","row3.3"
 "row4.1","row4.2","row4.3"
 "row5.1","row5.2","row5.3"

=item * L</Text::Table::HTML>

 <table>
 <thead>
 <tr><th>col1</th><th>col2</th><th>col3</th></tr>
 </thead>
 <tbody>
 <tr><td>row1.1</td><td>row1.2</td><td>row1.3</td></tr>
 <tr><td>row2.1</td><td>row2.2</td><td>row2.3</td></tr>
 <tr><td>row3.1</td><td>row3.2</td><td>row3.3</td></tr>
 <tr><td>row4.1</td><td>row4.2</td><td>row4.3</td></tr>
 <tr><td>row5.1</td><td>row5.2</td><td>row5.3</td></tr>
 </tbody>
 </table>

=item * L</Text::Table::HTML::DataTables>

 <html>
 <head>
 <link rel="stylesheet" type="text/css" href="file:///home/s1/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/auto/share/dist/Text-Table-HTML-DataTables/datatables-1.10.22/datatables.css">
 <script src="file:///home/s1/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/auto/share/dist/Text-Table-HTML-DataTables/jquery-2.2.4/jquery-2.2.4.min.js"></script>
 <script src="file:///home/s1/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/auto/share/dist/Text-Table-HTML-DataTables/datatables-1.10.22/datatables.js"></script>
 <script>var dt_opts = {"dom":"lQfrtip","buttons":["colvis","print"]}; $(document).ready(function() { $("table").DataTable(dt_opts); });</script>
 
 </head>
 
 <body>
 <table>
 <thead>
 <tr><th>col1</th><th>col2</th><th>col3</th></tr>
 </thead>
 <tbody>
 <tr><td>row1.1</td><td>row1.2</td><td>row1.3</td></tr>
 <tr><td>row2.1</td><td>row2.2</td><td>row2.3</td></tr>
 <tr><td>row3.1</td><td>row3.2</td><td>row3.3</td></tr>
 <tr><td>row4.1</td><td>row4.2</td><td>row4.3</td></tr>
 <tr><td>row5.1</td><td>row5.2</td><td>row5.3</td></tr>
 </tbody>
 </table>
 </body>
 
 </html>

=item * L</Text::TabularDisplay>

 +--------+--------+--------+
 | col1   | col2   | col3   |
 +--------+--------+--------+
 | row1.1 | row1.2 | row1.3 |
 | row2.1 | row2.2 | row2.3 |
 | row3.1 | row3.2 | row3.3 |
 | row4.1 | row4.2 | row4.3 |
 | row5.1 | row5.2 | row5.3 |
 +--------+--------+--------+

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n TextTable

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries TextTable | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=TextTable -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::TextTable -E'say $_->{module} for @{ $Acme::CPANModules::TextTable::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module contains benchmark instructions. You can run a
benchmark for some/all the modules listed in this Acme::CPANModules module using
the L<bencher> CLI (from L<Bencher> distribution):

    % bencher --cpanmodules-module TextTable

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-TextTable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-TextTable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-TextTable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::HTMLTable>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
