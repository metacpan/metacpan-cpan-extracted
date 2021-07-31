package Acme::CPANModules::TextTable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-31'; # DATE
our $DIST = 'Acme-CPANModules-TextTable'; # DIST
our $VERSION = '0.012'; # VERSION

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
it does not nearly as many formatting options as Text::ANSITable.

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

This document describes version 0.012 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2021-07-31.

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

=item L<Text::Table::TinyBorderStyle>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::More>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

A module I wrote in early 2021. Main distinguishing feature is support for
rowspan/clospan. I plan to add more features to this module on an as-needed
basic. This module is now preferred to L<Text::ANSITable>, although currently
it does not nearly as many formatting options as Text::ANSITable.


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
 | Text::UnicodeBox::Table       |      1.41 |    711    |                 0.00% |             39301.74% |   0.0006  |      20 |
 | Text::ANSITable               |      3.3  |    310    |               132.56% |             16842.32% |   0.00045 |      20 |
 | Text::Table::More             |      6.7  |    150    |               373.37% |              8223.68% |   0.00022 |      20 |
 | Text::ASCIITable              |     15.1  |     66.4  |               971.50% |              3577.26% | 4.6e-05   |      20 |
 | Text::Table::TinyColorWide    |     21.8  |     45.8  |              1452.89% |              2437.32% | 1.7e-05   |      21 |
 | Text::FormatTable             |     22    |     45    |              1497.13% |              2367.03% | 7.8e-05   |      20 |
 | Text::Table::TinyWide         |     30.7  |     32.6  |              2079.44% |              1707.88% | 1.1e-05   |      21 |
 | Text::Table::Manifold         |     49    |     20    |              3400.88% |              1025.48% | 2.2e-05   |      21 |
 | Text::Table::Tiny             |     52.4  |     19.1  |              3625.18% |               957.71% | 1.4e-05   |      20 |
 | Text::TabularDisplay          |     57    |     18    |              3926.84% |               878.48% | 6.9e-05   |      22 |
 | Text::Table::HTML             |     79    |     13    |              5499.57% |               603.66% | 1.5e-05   |      23 |
 | Text::Table::TinyColor        |     78.8  |     12.7  |              5501.62% |               603.40% | 5.2e-06   |      20 |
 | Text::MarkdownTable           |    110    |      8.9  |              7926.73% |               390.88% |   1e-05   |      20 |
 | Text::Table                   |    140    |      7.4  |              9571.82% |               307.39% | 1.9e-05   |      20 |
 | Text::Table::HTML::DataTables |    165    |      6.06 |             11626.63% |               236.00% | 2.7e-06   |      20 |
 | Text::Table::CSV              |    280    |      3.6  |             19775.29% |                98.24% | 4.3e-06   |      24 |
 | Text::Table::Org              |    296    |      3.37 |             20973.88% |                86.97% | 1.1e-06   |      20 |
 | Text::Table::TinyBorderStyle  |    329    |      3.04 |             23308.91% |                68.32% | 1.1e-06   |      20 |
 | Text::Table::Any              |    519    |      1.93 |             36817.27% |                 6.73% | 1.1e-06   |      20 |
 | Text::Table::Sprintf          |    554    |      1.8  |             39301.74% |                 0.00% | 4.3e-07   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                   Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::Table::TinyColorWide  Text::FormatTable  Text::Table::TinyWide  Text::Table::Manifold  Text::Table::Tiny  Text::TabularDisplay  Text::Table::HTML  Text::Table::TinyColor  Text::MarkdownTable  Text::Table  Text::Table::HTML::DataTables  Text::Table::CSV  Text::Table::Org  Text::Table::TinyBorderStyle  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table        1.41/s                       --             -56%               -78%              -90%                        -93%               -93%                   -95%                   -97%               -97%                  -97%               -98%                    -98%                 -98%         -98%                           -99%              -99%              -99%                          -99%              -99%                  -99% 
  Text::ANSITable                 3.3/s                     129%               --               -51%              -78%                        -85%               -85%                   -89%                   -93%               -93%                  -94%               -95%                    -95%                 -97%         -97%                           -98%              -98%              -98%                          -99%              -99%                  -99% 
  Text::Table::More               6.7/s                     374%             106%                 --              -55%                        -69%               -70%                   -78%                   -86%               -87%                  -88%               -91%                    -91%                 -94%         -95%                           -95%              -97%              -97%                          -97%              -98%                  -98% 
  Text::ASCIITable               15.1/s                     970%             366%               125%                --                        -31%               -32%                   -50%                   -69%               -71%                  -72%               -80%                    -80%                 -86%         -88%                           -90%              -94%              -94%                          -95%              -97%                  -97% 
  Text::Table::TinyColorWide     21.8/s                    1452%             576%               227%               44%                          --                -1%                   -28%                   -56%               -58%                  -60%               -71%                    -72%                 -80%         -83%                           -86%              -92%              -92%                          -93%              -95%                  -96% 
  Text::FormatTable                22/s                    1480%             588%               233%               47%                          1%                 --                   -27%                   -55%               -57%                  -60%               -71%                    -71%                 -80%         -83%                           -86%              -92%              -92%                          -93%              -95%                  -96% 
  Text::Table::TinyWide          30.7/s                    2080%             850%               360%              103%                         40%                38%                     --                   -38%               -41%                  -44%               -60%                    -61%                 -72%         -77%                           -81%              -88%              -89%                          -90%              -94%                  -94% 
  Text::Table::Manifold            49/s                    3454%            1450%               650%              232%                        129%               125%                    63%                     --                -4%                   -9%               -35%                    -36%                 -55%         -63%                           -69%              -82%              -83%                          -84%              -90%                  -91% 
  Text::Table::Tiny              52.4/s                    3622%            1523%               685%              247%                        139%               135%                    70%                     4%                 --                   -5%               -31%                    -33%                 -53%         -61%                           -68%              -81%              -82%                          -84%              -89%                  -90% 
  Text::TabularDisplay             57/s                    3850%            1622%               733%              268%                        154%               150%                    81%                    11%                 6%                    --               -27%                    -29%                 -50%         -58%                           -66%              -80%              -81%                          -83%              -89%                  -90% 
  Text::Table::HTML                79/s                    5369%            2284%              1053%              410%                        252%               246%                   150%                    53%                46%                   38%                 --                     -2%                 -31%         -43%                           -53%              -72%              -74%                          -76%              -85%                  -86% 
  Text::Table::TinyColor         78.8/s                    5498%            2340%              1081%              422%                        260%               254%                   156%                    57%                50%                   41%                 2%                      --                 -29%         -41%                           -52%              -71%              -73%                          -76%              -84%                  -85% 
  Text::MarkdownTable             110/s                    7888%            3383%              1585%              646%                        414%               405%                   266%                   124%               114%                  102%                46%                     42%                   --         -16%                           -31%              -59%              -62%                          -65%              -78%                  -79% 
  Text::Table                     140/s                    9508%            4089%              1927%              797%                        518%               508%                   340%                   170%               158%                  143%                75%                     71%                  20%           --                           -18%              -51%              -54%                          -58%              -73%                  -75% 
  Text::Table::HTML::DataTables   165/s                   11632%            5015%              2375%              995%                        655%               642%                   437%                   230%               215%                  197%               114%                    109%                  46%          22%                             --              -40%              -44%                          -49%              -68%                  -70% 
  Text::Table::CSV                280/s                   19650%            8511%              4066%             1744%                       1172%              1150%                   805%                   455%               430%                  400%               261%                    252%                 147%         105%                            68%                --               -6%                          -15%              -46%                  -50% 
  Text::Table::Org                296/s                   20997%            9098%              4351%             1870%                       1259%              1235%                   867%                   493%               466%                  434%               285%                    276%                 164%         119%                            79%                6%                --                           -9%              -42%                  -46% 
  Text::Table::TinyBorderStyle    329/s                   23288%           10097%              4834%             2084%                       1406%              1380%                   972%                   557%               528%                  492%               327%                    317%                 192%         143%                            99%               18%               10%                            --              -36%                  -40% 
  Text::Table::Any                519/s                   36739%           15962%              7672%             3340%                       2273%              2231%                  1589%                   936%               889%                  832%               573%                    558%                 361%         283%                           213%               86%               74%                           57%                --                   -6% 
  Text::Table::Sprintf            554/s                   39400%           17122%              8233%             3588%                       2444%              2400%                  1711%                  1011%               961%                  900%               622%                    605%                 394%         311%                           236%              100%               87%                           68%                7%                    -- 
 
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
 | Text::UnicodeBox::Table       |      11.1 |    90     |                 0.00% |             35656.59% | 8.7e-05 |      21 |
 | Text::ANSITable               |      30.3 |    33     |               172.87% |             13003.66% | 3.2e-05 |      20 |
 | Text::Table::More             |      61.9 |    16.2   |               456.88% |              6320.90% | 7.4e-06 |      20 |
 | Text::ASCIITable              |     161   |     6.23  |              1345.86% |              2373.03% | 6.1e-06 |      20 |
 | Text::FormatTable             |     199   |     5.02  |              1692.31% |              1895.00% | 3.5e-06 |      22 |
 | Text::Table::TinyColorWide    |     214   |     4.68  |              1824.18% |              1758.27% | 3.1e-06 |      20 |
 | Text::Table::TinyWide         |     300   |     3.33  |              2599.02% |              1224.80% | 6.9e-07 |      20 |
 | Text::TabularDisplay          |     426   |     2.35  |              3733.77% |               832.68% | 6.9e-07 |      20 |
 | Text::Table::Manifold         |     436   |     2.29  |              3826.91% |               810.55% | 2.2e-06 |      20 |
 | Text::Table::Tiny             |     470   |     2.1   |              4135.97% |               744.12% | 2.4e-06 |      20 |
 | Text::MarkdownTable           |     530   |     1.9   |              4692.22% |               646.14% | 3.4e-06 |      20 |
 | Text::Table                   |     620   |     1.6   |              5474.12% |               541.48% | 2.5e-06 |      20 |
 | Text::Table::HTML             |     732   |     1.37  |              6485.78% |               442.94% | 2.7e-07 |      20 |
 | Text::Table::TinyColor        |     736   |     1.36  |              6525.02% |               439.72% | 4.3e-07 |      20 |
 | Text::Table::HTML::DataTables |    1200   |     0.81  |             11046.38% |               220.79% | 4.4e-06 |      20 |
 | Text::Table::Org              |    2160   |     0.463 |             19338.45% |                83.95% | 2.1e-07 |      20 |
 | Text::Table::CSV              |    2170   |     0.46  |             19449.29% |                82.90% | 5.2e-08 |      21 |
 | Text::Table::TinyBorderStyle  |    2200   |     0.455 |             19699.86% |                80.59% | 2.1e-07 |      20 |
 | Text::Table::Any              |    3820   |     0.262 |             34290.44% |                 3.97% | 2.3e-07 |      28 |
 | Text::Table::Sprintf          |    3970   |     0.252 |             35656.59% |                 0.00% | 5.2e-08 |      21 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                   Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::TabularDisplay  Text::Table::Manifold  Text::Table::Tiny  Text::MarkdownTable  Text::Table  Text::Table::HTML  Text::Table::TinyColor  Text::Table::HTML::DataTables  Text::Table::Org  Text::Table::CSV  Text::Table::TinyBorderStyle  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table        11.1/s                       --             -63%               -82%              -93%               -94%                        -94%                   -96%                  -97%                   -97%               -97%                 -97%         -98%               -98%                    -98%                           -99%              -99%              -99%                          -99%              -99%                  -99% 
  Text::ANSITable                30.3/s                     172%               --               -50%              -81%               -84%                        -85%                   -89%                  -92%                   -93%               -93%                 -94%         -95%               -95%                    -95%                           -97%              -98%              -98%                          -98%              -99%                  -99% 
  Text::Table::More              61.9/s                     455%             103%                 --              -61%               -69%                        -71%                   -79%                  -85%                   -85%               -87%                 -88%         -90%               -91%                    -91%                           -95%              -97%              -97%                          -97%              -98%                  -98% 
  Text::ASCIITable                161/s                    1344%             429%               160%                --               -19%                        -24%                   -46%                  -62%                   -63%               -66%                 -69%         -74%               -78%                    -78%                           -86%              -92%              -92%                          -92%              -95%                  -95% 
  Text::FormatTable               199/s                    1692%             557%               222%               24%                 --                         -6%                   -33%                  -53%                   -54%               -58%                 -62%         -68%               -72%                    -72%                           -83%              -90%              -90%                          -90%              -94%                  -94% 
  Text::Table::TinyColorWide      214/s                    1823%             605%               246%               33%                 7%                          --                   -28%                  -49%                   -51%               -55%                 -59%         -65%               -70%                    -70%                           -82%              -90%              -90%                          -90%              -94%                  -94% 
  Text::Table::TinyWide           300/s                    2602%             890%               386%               87%                50%                         40%                     --                  -29%                   -31%               -36%                 -42%         -51%               -58%                    -59%                           -75%              -86%              -86%                          -86%              -92%                  -92% 
  Text::TabularDisplay            426/s                    3729%            1304%               589%              165%               113%                         99%                    41%                    --                    -2%               -10%                 -19%         -31%               -41%                    -42%                           -65%              -80%              -80%                          -80%              -88%                  -89% 
  Text::Table::Manifold           436/s                    3830%            1341%               607%              172%               119%                        104%                    45%                    2%                     --                -8%                 -17%         -30%               -40%                    -40%                           -64%              -79%              -79%                          -80%              -88%                  -88% 
  Text::Table::Tiny               470/s                    4185%            1471%               671%              196%               139%                        122%                    58%                   11%                     9%                 --                  -9%         -23%               -34%                    -35%                           -61%              -77%              -78%                          -78%              -87%                  -88% 
  Text::MarkdownTable             530/s                    4636%            1636%               752%              227%               164%                        146%                    75%                   23%                    20%                10%                   --         -15%               -27%                    -28%                           -57%              -75%              -75%                          -76%              -86%                  -86% 
  Text::Table                     620/s                    5525%            1962%               912%              289%               213%                        192%                   108%                   46%                    43%                31%                  18%           --               -14%                    -15%                           -49%              -71%              -71%                          -71%              -83%                  -84% 
  Text::Table::HTML               732/s                    6469%            2308%              1082%              354%               266%                        241%                   143%                   71%                    67%                53%                  38%          16%                 --                      0%                           -40%              -66%              -66%                          -66%              -80%                  -81% 
  Text::Table::TinyColor          736/s                    6517%            2326%              1091%              358%               269%                        244%                   144%                   72%                    68%                54%                  39%          17%                 0%                      --                           -40%              -65%              -66%                          -66%              -80%                  -81% 
  Text::Table::HTML::DataTables  1200/s                   11011%            3974%              1899%              669%               519%                        477%                   311%                  190%                   182%               159%                 134%          97%                69%                     67%                             --              -42%              -43%                          -43%              -67%                  -68% 
  Text::Table::Org               2160/s                   19338%            7027%              3398%             1245%               984%                        910%                   619%                  407%                   394%               353%                 310%         245%               195%                    193%                            74%                --                0%                           -1%              -43%                  -45% 
  Text::Table::CSV               2170/s                   19465%            7073%              3421%             1254%               991%                        917%                   623%                  410%                   397%               356%                 313%         247%               197%                    195%                            76%                0%                --                           -1%              -43%                  -45% 
  Text::Table::TinyBorderStyle   2200/s                   19680%            7152%              3460%             1269%              1003%                        928%                   631%                  416%                   403%               361%                 317%         251%               201%                    198%                            78%                1%                1%                            --              -42%                  -44% 
  Text::Table::Any               3820/s                   34251%           12495%              6083%             2277%              1816%                       1686%                  1170%                  796%                   774%               701%                 625%         510%               422%                    419%                           209%               76%               75%                           73%                --                   -3% 
  Text::Table::Sprintf           3970/s                   35614%           12995%              6328%             2372%              1892%                       1757%                  1221%                  832%                   808%               733%                 653%         534%               443%                    439%                           221%               83%               82%                           80%                3%                    -- 
 
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
 | Text::UnicodeBox::Table       |     200   | 4         |                 0.00% |             48379.56% | 6.7e-05 |      22 |
 | Text::ANSITable               |    1130   | 0.886     |               355.73% |             10537.69% | 4.3e-07 |      20 |
 | Text::Table::More             |    2500   | 0.41      |               896.85% |              4763.29% | 4.3e-07 |      20 |
 | Text::ASCIITable              |    6100   | 0.16      |              2360.74% |              1870.12% |   2e-07 |      22 |
 | Text::FormatTable             |    8500   | 0.12      |              3338.59% |              1309.87% | 1.8e-07 |      28 |
 | Text::Table                   |    9400   | 0.11      |              3676.61% |              1183.68% | 2.4e-07 |      25 |
 | Text::Table::Manifold         |    9400   | 0.11      |              3708.10% |              1173.06% | 1.6e-07 |      20 |
 | Text::Table::TinyColorWide    |    9700   | 0.1       |              3829.10% |              1133.86% | 2.1e-07 |      20 |
 | Text::Table::TinyWide         |   13700   | 0.0731    |              5427.41% |               777.08% | 2.3e-08 |      26 |
 | Text::Table::TinyBorderStyle  |   14532.3 | 0.0688123 |              5769.69% |               725.93% | 2.4e-11 |      20 |
 | Text::MarkdownTable           |   15000   | 0.066     |              6062.05% |               686.74% | 1.1e-07 |      28 |
 | Text::Table::HTML::DataTables |   18000   | 0.055     |              7188.91% |               565.11% | 8.9e-08 |      29 |
 | Text::Table::Tiny             |   18000   | 0.055     |              7270.97% |               557.71% | 8.6e-08 |      31 |
 | Text::TabularDisplay          |   18000   | 0.054     |              7331.71% |               552.33% | 1.9e-07 |      33 |
 | Text::Table::TinyColor        |   28800   | 0.0347    |             11543.81% |               316.35% | 1.1e-08 |      30 |
 | Text::Table::HTML             |   39000   | 0.026     |             15479.67% |               211.17% | 4.8e-08 |      25 |
 | Text::Table::Org              |   67000   | 0.015     |             26827.87% |                80.03% |   2e-08 |      20 |
 | Text::Table::CSV              |   95040   | 0.010522  |             38287.51% |                26.29% | 2.2e-11 |      20 |
 | Text::Table::Any              |  110000   | 0.0093    |             43460.29% |                11.29% | 1.1e-08 |      27 |
 | Text::Table::Sprintf          |  120030   | 0.0083315 |             48379.56% |                 0.00% | 2.4e-11 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                      Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table  Text::Table::Manifold  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::Table::TinyBorderStyle  Text::MarkdownTable  Text::Table::HTML::DataTables  Text::Table::Tiny  Text::TabularDisplay  Text::Table::TinyColor  Text::Table::HTML  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table            200/s                       --             -77%               -89%              -96%               -97%         -97%                   -97%                        -97%                   -98%                          -98%                 -98%                           -98%               -98%                  -98%                    -99%               -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                   1130/s                     351%               --               -53%              -81%               -86%         -87%                   -87%                        -88%                   -91%                          -92%                 -92%                           -93%               -93%                  -93%                    -96%               -97%              -98%              -98%              -98%                  -99% 
  Text::Table::More                 2500/s                     875%             116%                 --              -60%               -70%         -73%                   -73%                        -75%                   -82%                          -83%                 -83%                           -86%               -86%                  -86%                    -91%               -93%              -96%              -97%              -97%                  -97% 
  Text::ASCIITable                  6100/s                    2400%             453%               156%                --               -25%         -31%                   -31%                        -37%                   -54%                          -56%                 -58%                           -65%               -65%                  -66%                    -78%               -83%              -90%              -93%              -94%                  -94% 
  Text::FormatTable                 8500/s                    3233%             638%               241%               33%                 --          -8%                    -8%                        -16%                   -39%                          -42%                 -44%                           -54%               -54%                  -55%                    -71%               -78%              -87%              -91%              -92%                  -93% 
  Text::Table                       9400/s                    3536%             705%               272%               45%                 9%           --                     0%                         -9%                   -33%                          -37%                 -40%                           -50%               -50%                  -50%                    -68%               -76%              -86%              -90%              -91%                  -92% 
  Text::Table::Manifold             9400/s                    3536%             705%               272%               45%                 9%           0%                     --                         -9%                   -33%                          -37%                 -40%                           -50%               -50%                  -50%                    -68%               -76%              -86%              -90%              -91%                  -92% 
  Text::Table::TinyColorWide        9700/s                    3900%             786%               309%               59%                19%           9%                     9%                          --                   -26%                          -31%                 -34%                           -45%               -45%                  -46%                    -65%               -74%              -85%              -89%              -90%                  -91% 
  Text::Table::TinyWide            13700/s                    5371%            1112%               460%              118%                64%          50%                    50%                         36%                     --                           -5%                  -9%                           -24%               -24%                  -26%                    -52%               -64%              -79%              -85%              -87%                  -88% 
  Text::Table::TinyBorderStyle   14532.3/s                    5712%            1187%               495%              132%                74%          59%                    59%                         45%                     6%                            --                  -4%                           -20%               -20%                  -21%                    -49%               -62%              -78%              -84%              -86%                  -87% 
  Text::MarkdownTable              15000/s                    5960%            1242%               521%              142%                81%          66%                    66%                         51%                    10%                            4%                   --                           -16%               -16%                  -18%                    -47%               -60%              -77%              -84%              -85%                  -87% 
  Text::Table::HTML::DataTables    18000/s                    7172%            1510%               645%              190%               118%         100%                   100%                         81%                    32%                           25%                  19%                             --                 0%                   -1%                    -36%               -52%              -72%              -80%              -83%                  -84% 
  Text::Table::Tiny                18000/s                    7172%            1510%               645%              190%               118%         100%                   100%                         81%                    32%                           25%                  19%                             0%                 --                   -1%                    -36%               -52%              -72%              -80%              -83%                  -84% 
  Text::TabularDisplay             18000/s                    7307%            1540%               659%              196%               122%         103%                   103%                         85%                    35%                           27%                  22%                             1%                 1%                    --                    -35%               -51%              -72%              -80%              -82%                  -84% 
  Text::Table::TinyColor           28800/s                   11427%            2453%              1081%              361%               245%         217%                   217%                        188%                   110%                           98%                  90%                            58%                58%                   55%                      --               -25%              -56%              -69%              -73%                  -75% 
  Text::Table::HTML                39000/s                   15284%            3307%              1476%              515%               361%         323%                   323%                        284%                   181%                          164%                 153%                           111%               111%                  107%                     33%                 --              -42%              -59%              -64%                  -67% 
  Text::Table::Org                 67000/s                   26566%            5806%              2633%              966%               700%         633%                   633%                        566%                   387%                          358%                 340%                           266%               266%                  260%                    131%                73%                --              -29%              -38%                  -44% 
  Text::Table::CSV                 95040/s                   37915%            8320%              3796%             1420%              1040%         945%                   945%                        850%                   594%                          553%                 527%                           422%               422%                  413%                    229%               147%               42%                --              -11%                  -20% 
  Text::Table::Any                110000/s                   42910%            9426%              4308%             1620%              1190%        1082%                  1082%                        975%                   686%                          639%                 609%                           491%               491%                  480%                    273%               179%               61%               13%                --                  -10% 
  Text::Table::Sprintf            120030/s                   47910%           10534%              4821%             1820%              1340%        1220%                  1220%                       1100%                   777%                          725%                 692%                           560%               560%                  548%                    316%               212%               80%               26%               11%                    -- 
 
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

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAARdQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADUlADUlADUlADUlQDVlQDWlQDWmADalADUlQDVlQDVlADVAAAAAAAAlADUlADUlADVlADUlADUlADUlQDVlADUlQDVlADUlADVlQDVlQDVdACmlADUjQDKdACnhgDAVgB7ZQCRUgB2jwDNAAAAUgB1YQCLLgBCQgBeaQCXYQCMZgCSMABFTwBxZgCTRwBmKQA7WAB+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADUbQCb////u3l/5wAAAFl0Uk5TABFEImbuu8yZM3eI3apVqdXKx9I/7/z27Pnx9HXwM9/WROxcdSDvUKd65O0R8bfHIoj1+p/39GmE66P51fZ1x7fn1vTgluD0+fyZ6O20tM+fIGAwjUCmTo8JYN+UAAAAAWJLR0QAiAUdSAAAAAlwSFlzAAAASAAAAEgARslrPgAAAAd0SU1FB+UHHwgbOcgnqWIAACrYSURBVHja7Z0Jv/Q4dtYly2vZVQwJzQxhmp5uAjTJJJCBsCasYd+SQCBOvv/3QKut3a66dW/Zquf/69u+71XJJduPpaOjI4kQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAF0Ir/UtF1z9W7NXFAuAO6lWw1ax/masltZnnlt57TgBeRruINyJo2tSEdv2rywjAXobuwqvoehwrIWgmj1LQ1TgOSuJj++pCArCXeuor0k7jyOviam76fh6loC/N2M+1/Mj1+upCArAbYXK0vJIer1zQF0IuM+OCZvMgDGiRPk2wocF5UDb0cOtabUPz6nmu6qniCFXzX8dXlxGA3QhBj3Pbt0bQjRD02LSCQfzhNn/sGwD4Qrigbw2TXb9q5sYFlTX0bSLCLy37gxUEDc5De+MdQy5eaXL0XNiTsDqEv47/Ko2Ofnp1GQHYzXWqaTe1U9/UVddNUzNIM7puuo7/2s+t/AsAJ4GKse2qomqMu1pGvan6lVXVB04OAAAAAAAAAAAAAAAAAAAAwDMxY1dqSHbQY1upIwDHhunoLxkKxrpZhNQkjwAcG3brlKCrWQi6vVImItBTRwCOTd0qQdPm2oramtsdly55BODwqIDz6yhMDvk7/1/qCMDhkTqtO2lD10q4NHXUWf7KTyR/9dcAeA6/LhX163/tSYJmE5OCvijhstRRZ/nmr/9U8M3PYvyNn6X56W9kEnMZP+esv/HT8xTn4bMerDiJs/5Nqaj5508S9Nhxi2Ma2U6T42e/ljlfbh2VsXow4+ectRofzPiC4jx81oMVJ3vWpwm6GpWgmaiE64mkjhoI+kQKOlhxvkbQsojSbTfmfxQQ9IkUdLDifLGgh6abOpo+KiDoEynoYMX5fEG7UD2LM3WUQNAnUtDBivPVgt5FVtB17mrYgxk/56ysejDjC4rz8FkPVpzsWQ8paAAeBYIGRQFBg6KAoEFRQNCgKCBoUBQQNCgKCBoUBQQNigKCBkUBQYOigKBBUUDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDooCgQVFA0KAoIGhQFBA0KAoIGhQFBA2KAoIGRQFBg6KAoEFRQNCgKCBoUBQQNCgKCBoUBQQNiuI5glZLqg96SfaB5o8CCBp8Ck8RNBObBg3TPE8D/0c3zz1JHxUQNPgUniBodpOb1zc9of1ESHulbBrTRwUEDT6FJwi6boWg5TbebB74f4RcOpI6aiBo8Ck8bZ9CWslfnrI1MgCP8tSNN1nXk1oJl6aOOgsEDT6FJwqajjM3kS9KuCx11Fm+/bYVDK++fnA+/tZ3hl/Yfx6lop4n6KGT8oTJAT6Z7//C8EOY+DxBT8onx0QlXE/JowaCBo/yNYK+zZWAkHbM/yggaPAoXyPocZZw06Pppo6mjwoIGjzK5wvahVZV9iiBoMGjfLWgdwFBg0eBoEFRQNCgKCBoUBQQNCgKCBoUBQQNigKCBkUBQYOigKBBUUDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDooCgwen4279p+DtBGgQNTsffXUT7m0EaBA1Ox3cQNCgJCBoUBQQNigKCBkUBQYOigKBBUUDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDooCgQVFA0KAoXixotXnKoLcE2joKIGiQ47WCZmKfQtbNc7/jqICgQY5XCprdOiHo9krZNG4fFRA0yPFKQdetEDSbB0Iu3eZRA0GDHK81OcTGm1t7fGOvb3AHrxd0rQRLt446CwQNcrxe0BclWLZ11Fm+/bYVDK++ceCYPCDoUSoKJgc4Iq+voZmofOtp86iBoEGO1wuatOO+HwUEDXIcQNBD000d3T4qIGiQ4wixHLSqdh0lEDTIcQRB3wUEDXJA0KAoIGhQFBA0KAoIGhQFBA3Oxt/70fD3w0QIGpyNHxddfhcmQtDgbEDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDooCgQVFA0KAoIGhQFBA0KAoIGhQFBA2KAoIGRQFBg6KAoEFRQNCgKCBoUBQQNCgKCBoUBQQNigKCBkUBQYOigKBBUUDQoCggaFAUEDQoiuMLetC7ag40fxRA0G/P0QU9TPPccsmybp57kj4qIOi35+iCnkZCO67Y9krZNKaPCgj67Tm6oOdKbLdM2DwQcumSRw0E/fYcXdDNhZBrj72+wU6OLuiqmZqJkloJl6aO+tPf/NYoYK++q+BlPFvQtVTU0wRNu2t14zb0RQmXpY7647/9k0pAH/4+cHaeLehBKuppgq4ncc6ZweQA+zi4yTGK/h6dKyYqYa7u1FEDQb89Bxf0ILwYY0NIO+Z/FBD023NwQfPeYDc1XNRD000dTR8VEPTbc3RBE1ZV8kg3jhII+u05vKDvAoJ+eyBoUBQQNCgKCBoUBQQNiuKlgh6GJ18NBP32vFDQdTO31fRUTUPQb8/rBD3MddXSsXlmJBEE/fa8TtBjT6qWkK7a/uhuIOi354WCHiFo8HReJ+iqGbiga5gc4Jm8sFN4madmaupnXg0E/fa80m3H6vH23MklEPTb8zpBM2U818+cAAhBvz2vEjSrLr2YrHWb0CkET+RVgq7bbmoFV3QKwRN54cDKU7uDCgj67Xl5cBJsaPBMXhnLcRUmRwMbGjyRVw6sjF07dv32J/cDQb89Lx36vvWETugUgifyUkEPLSEtTA7wRF4n6HpiZGYEfmjwTF7YKWxbMjZTt+OTu4Gg34Fffr/wyyDxhZ1C4Ye+1U8N5oCg34FVen/xfZD4OkFfnlo3KyDod+Cggib9KJfefealQtDvwEEFXc2KZ14qBP0OHFTQnwEE/Q5A0KAoIGhQFBA0KAoIGhQFBA2K4uSCpnr1u4HmjwII+h04taDpdZ47Rgjr5lmETqeOCgj6HTi1oPuO0uuVkPZK2TSmjwoI+h04s6Cp2KeQjYSJ46VLHjUQ9DtwZkFXMxnE1t3YGhksnFnQt7mdxMabtRIuTR31xyHod+DMgh7nUW6NfFHCZamj/vi338rFa5690wU4FF8q6FEq6pkmh9y8HiYHWDhzDT0oQQ9MVML1RFJHDQT9DpxZ0GS6ENJzwbZj/kcBQb8Dpxb00HSiUyiPHU0fFRD0O3BqQROqJ2ltHSUQ9DtwbkHfBQT9DkDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDooCgQVFA0KAoIGhQFBA0KAoIGhQFBA2KAoIGRQFBg6KAoEFRQNCgKCBoUBQQNCgKCBoUBQQNigKCBkUBQYOigKBBUUDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDooCgQVFA0KAoIGhQFKcXtNpHc9BbA6WOAgj6HTi7oMeW/49189xnjgoI+h04uaCrWQi6vVI2jemjAoJ+B84taNpcuaDZzO2OS5c8aiDod+Dcgr6OwuTAXt9g4dSCrjtpQ9dKuDR11J/+7Z9UAvrw14ET8KWCHqSiniZoNjEp6IsSLksd9ce/+a1RwB7+PnACvlTQtVTU0wQ9dtzimEYGkwMsnNnkqEYlaCYq4XoiqaMGgi6FX/yg+Z3fDdLOLGiB9EO3Y/5HAUGXwiq9fxCkFSHooemmjqaPCgi6FEoWtIJWVfYogaBLoXxB7wKCLgUIWgJBlwIELYGgSwGClkDQpQBBSyDoUoCgJRB0KUDQEgi6FCBoCQRdChC0BIIuBQhaAkGXAgQtgaBLAYKWQNClAEFLIOhSgKAlEHQpQNASCLoUIGgJBF0KELQEgi4FCFoCQZcCBC2BoEsBgpZA0CfiH36/ECZC0BII+kT83qKgX4WJELQEgj4Rv5dTEAQtgaBPBAS9DQR9IiDobSDoEwFBbwNBnwgIehsI+kRA0NtA0CcCgt4Ggj4REPQ2EPSJgKC3gaBPBAS9DQR9IiDobSDoEwFBbwNBn4h3FfSgdx0caP4ogKBPxHsKepjmeRoIYd089yR9VEDQJ+I9Bd30hPYTIe2VsmlMHxUQ9Il4S0HLbbzZPPD/CLl0JHXUQNAn4i0FTcWebdWMrZEL5C0FLWBdT2olXJo66o9C0CfiTQVNx5mbyBclXJY66g9/+20rGD7lAYDncg5Bj1JRT/RydFKeMDnK4xyCVjxP0JPyyTFRCddT8qiBoE/EWwr6NlcCQtox/6OAoE/EWwp6nCXc9Gi6qaPpowKCPhFvKegVKurpzFECQX8K3//qB80/ChP/8e+YxF+Eib9v0n4VSu/NBb0LCPpTsBQUJmYV9ENGehD0NhD0pwBBQ9BFAUFD0EUBQUPQRQFBQ9BFAUFD0KdjfdY/BmkQNAR9RFaPcfZZQ9BhRgj6iPy4T0EQdJgRgn4VuaE5CBqCPh0/7HrWEDQEfRIgaAi6KCBoCLooIGgIuiggaAi6KCBoCLooIGgIuiggaAj6bPz4nSGUHgQNQb+Kf7KM6f3TIG2dxPf7YcbvHlUQBA1BfyIP31wIGoJ+Ef/M1LM//G6YCEFD0JscTNCfc3MhaAj6RUDQEPTHgKAhaAj684CgIeiP8QJBf7/wyyANgoagP8YLBP2rL7+5EDQE/YnsUxAEDUE/AgQNQUPQHwOChqA/DwgagoagPwYEDUF/HhA0BA1BfwwIGoJ+LgNdf88Kus2kjVUm8Z8vQXP/Ikz8l5mb+we5m/uHmZv7r3I39w9zZ91XnOxZQ0GvxYkI+g8eLc6/3lecUNBWcb7qnn+doFk3z/3yr88RdO7mQtAQ9FNpr5RN+/YphKAh6MMLms0DIZfO/PNhQf+bf2vm6f3ivpsLQUPQz+Sevb5zgn745kLQEPQzqZWgTb/wZ//u52n+/R8Z/kOQ9h//0vCfwoz/eUn8ozDxvyyJ/zVI+29L2n/PnfV/BGn/c19xImfdV5zsWf9Xpjh/+fPMWe8szsP33CrOV93zLxP0RQma6X9+OwPwGbzI5ADg3DBROdfTq4sBwJNoR/UDAK/fXl2AjzM03dTRj5/nQBTwVF7E6r+9l/o4N51W1cdPciim0i7oy3i4M1U3w6vLXjDjmboE2aotl1h/wmtL5+xJ08W5nOmWn4/pSH2Cuu1zFl22OUknUjbfon9vN3V+i31iULdsuuRyporDCJ3anpwCpp5G3c2Rx5JNVDyQUSU+nJHU17aJFIdliso2y5rKmEuU9N3Y3kiabIc8nchPG/5x6C6k36gr67GNGcq8KyWuoM/KMlGcS0uqZj6OEZ1H3rhxulVdd2cieTSjSHw4I3+i9dhEnouoXlIZZdXzSHHyiZzblK6e2VTzzP0DicLdGhHXbW4oa7KV7Nhd+rmOnbDrBqnN+4tDm/aP2Wk8ZVXDX73mJgbJb/clCivvoYwi8eGM0rE+RGxBYVmnMkqr+5Hi5BM5t6a69VIrPoPIVJNbyrGQTqy7aaSxjgKbu56MTfIV4g9E3J2L+wnWN80ojJWmSvUK82WtGn4ThtNU0dcrIfMwtO0w3JUorbxHMsrEhzOqR9JHahpuWSczCqv7oeLkEqUl0s5TfxOFdrk1M2/jq6ZnEQldJlH/honKwBm7263rqGvuKok2l3mgk1+Pslr25tQDocTrYwxNX93EO0lE1T1HrjFbVi52ykQ71edi146A7ibw174iXTfdiHWxJi2aqJFW3l0Z7cTgpLniLPBEKqvKam1WmXq+0rL2M9ppqbPWLFecaFm18FZLpLYetvhOyqZKqoCryf5ClbHniuW1pZ9ItE0lWh/ajLVVz/LaVX6wrbmsbjITHXUyvc4df0GoeiDCciCjVZtSaaKoz9bz2AbmSKKs+tZpsfMT0ibXVTgAjN/TeprbYez4lcp2PEwjkUTzGVHL3JXRTgxOmimOrH9kOyzO2oveTd3qOpFyoYqnoCxrLyOlVlrqOrh9nStOLFEJT1si1Ujq5Vmz602Up59GbT3RzrFVREZpNE3CovASdRapxnoitl+hneUbPI6sqUnbivRWiZZ24peqadUDkQbJOK0thmNk8L7dWnnTi5R5qqzi1i1iF03Q4V1341Q1t+ra/Mkk+s71pRnDNEojiUZck7wdd2S0E4OTJosjnfqqHSY8I6+Gb3VjbGghJS5qY1m7Z+WJVppXHFOJ8d5OrjjRsirhKUtkaOZJ64COzVUIg/fcxKelIUI7PyOd+IvWS4uC+r4MkUVWslyHgykhf0vYLAtQtbxcdOAVbVMv5ZSHgSfLX8XdmZTByyomXp+aVGM3qwyD5ZHhNbv8VKqs/NYtYufv93D4EVo6yVvX9qJxG1vH+bSkESdR+I1scYl/7MoYSfTS0sWRNYNuh0VG2jfdksh7SeTar5a1c1aeaKe5Z22trn2uOLFE+fwXS8Q86NukHLn8O6W2mHztxtbPSEQ1WzeMOomylhAGl6xkb81SEPmWjNPAr4bO0kAe53ExRzptao+NeiB07HhZ+WloP8+iPhaHbryNga01dp00ZOJlrSt+GavYx3k6fvzETZujMf/jkuYkCr+RIy6yM+NdiVaaNEiFU9+0w1YiM08jalnrxEia6vXTRmjVdO13ltXpIniWCGu5DVrpRP2ySx+kI2iRkVylL1CcnyfKenSpJbhNRdqprpcaWL8l3BTmxgWdBi513gKsJzRWgphrpx4Ir1nFa9/x16AS5shQyccUOLb5h3rxNbGyig6mfLkWsR813EAYecT0s5WVNlemcVOJbtra8hHtN7LE1UfOGmTMnjWWaH8jt+SkU9+0w1ZxJlG/DKLi4c/BtaytxCBN9/qlL2rp2u+8A04XwTNhel5rtkoQ/DtvQltUft1St4ucTGQUzppJqHJo/lTXo6aWkOpaG4T1LbmIpqkT9bFbiyw6FR+TRb5O3TR47xHRlozNMHObYr6QWFllB5OfwhL7IdFGnulnS3fuMj9LJ0bTbL9RIC73rF7G7FnzX6k+wusjXkV67bDg2olKVzazTe1a1lain2Z6/coX5Xbtt4vjdBFIYIkw1QxQ0XPznWt07SIIs1t96VqPmlrCbvaY/ZZI15k33EJ7ZvzVcja0eiAyGq1dvX6j6N5dw5BLfn3VJNa4CIe1ZQdTXMYi9kNijLylnz0242jqGJ0YTXP9Rp64/LM6GbNnzSYKBmmQSqe+0w7Lpr/uhMUgayLHsvYSPat77fWriWlW136zOH4XIWRUliZPHPwuVNetXQRq3qG1Hl1qidXA0TPn9FtSScW656TTjepRU39I3Aj6wrvYTd83rVNc/iaIb7o2l7rp3LLKdkTZGqKoB47hWJuvpZ9Nm+t4cxMjafL+OH4jS1zhWa2M2bNufaXygUqj0+/R1bN0f1EuWlWF2jawn+jax1avXw2HmK79ZnGkJZLsBUiJyK4FIX6ijF8yOamdttajSy1hqctYMOotuXpGhPhGkWfmlTzvF3hav2ohiltXX/1lVajoz/aybzk4Y+nUboHEZQzH9W1YzdfSz76xMDFIk3+0/Ua2uCJn/VNG9px14yuND1RUYoFTv5YGxU0cZZJbx7iJ3iNZe/3SF7XUkpniKMtaWSLRvgXREtGOecsm78kSvxTrIlj1qNMEKSrVeOi3hHnS0t8ozIZZmPV2Us90QUJbWr164hXRjmWqSyoHyE07olqgA6tZo5svq58tUUFYOtFL0zh+owUnY5CTbZ41k2h8oMKS8536dSVE28uRnSBQqWa5xMrq9StflPXIo8XRlrW2ROKGvqos5WndUXDeqTXxSzqnoxG7HrWbIP2btiPqeBzFUgZ9RVYK13qnLis0GcyL4FyFGSBf2pEj2xo2pvky/WyFGk3ViV6avAc9c/xGJJrRz3mxW8zIWfOJiw9U1hV2mgxa4KK9STtv9iNqpiqZaEcZC6NVNMSDXftHimO6CMYSiVjWq0bEK+h3apf4pXH2ctbJelQpmbW6E+i9JXY8Kx19W16/XUPTSlMkfBeWDGuI1zpAnmqBjodj5K39bIVqa1Win0bUAwv9RqJ6tjP6OaWrN3VWVZxEovSbLT5Q30msYoW5aKUaBv+BtmMyUeWM9vq118EvztpFMJbI//7GtaxVvvB+8ype9ER5HWzil/j9cG1Z/qYk6lFRDipfAHnm5S0JokiUYzt4WPKKWmGKMDujHdjN34R+0ezaVY61I8fENfJMP1ubToNqa1UideVs2tPAbySqZyejl1O5elNn1bfdTVRDkcpaXXygfl2hY4XrpvFdq2tUr53IvJyRXr+KwYmU1e4iaEvk/zB95/y5CHZleZu6uhLhbUZwIn7p4o22iT5Xoh4dm0sj7GI/tM6OIlHfGL5LlinCnIxOYLfzJlhd5aAdOSQpI2+JLdRGQ3eN5DWdD8tvpIa3xJPOZWRdpMVkbnHcRDkUafxmjg900c8aKzzO7pc6Ub1WojIZpPJUTr/Xv8TgxC9k6SK4hlEwF8GSyFW5Dmox2NaSJX5pHa1bXj2nHrWe1qQsocqrgO0oEusb82+Xyei8CO6bsHaVg3bkkCSMvNV00kaDZwGqG2T+tPiNTJiAqJ7jGU3Ir6q47URpWFvFcXPKocjFb+Y0xEo/TqxwbX+nH9W7JkoVK+XRyKQ6ZgWchReiTiD/5hlG7lwEt7I0Ufj8lvFO7RK/tJx8sF49ux5dn5ZRcusV2IkiWb8x93YtGcMXwTxPZnWVL8eP2qijRh5zYgsvjtkU2mr8gRm/0Tq8JZ70JWZvmZDfMPJdGdaR4lhDkcZv9mf2mVXdFMYK5yOQJUKvWnnheMgw28FxUYx32bOanLkIrkaodgUNOsLCWLL/Vx7ku5cIqF+cau7UwFwUyXJ3Ym9XPLDb67hOTle5O7rBURmfl9MMiXttxxZOzvN0bTXiPLC1Sy6f9BRrpPVgm3b1Ond+sRft4jhDkXEfn9RPECu8FYFswvuN8rzuF5VXaQWc2ahmhnh+s8QkBlsjwq2orlu0CFan1g4yjr16lriYMzUwF0Wy3p3I25UP7Car+bd2lavmyFU0laMh6xOwbkHrxBa6PVvXVnPbU6sVFNWz3yVm1Ar59cMO68Ww9orjDEVGfXzi436s8HYEsgnvN8pze5gtf4DXMRKDY0W8CGzLenP2g3QOmgiMyzI8IYdn7CDj4NUzD0wxOpEriSiS7bcrG9hN1jfI6iof2cVBu6lWgg56xNIna8UWupfhRvw6b4I1vCWrZ9dl3c7NajRQL+xQNBY6hsIrjhvC7rnxlukqiTCSTASyCe+Pz1e5Nh2tOxLE4Mho6WVmiVdp5Wc/aOfgoEco1uZIvnpOkPHy6kWdat5QQDyKZHtuUT6wm6yXHQ6QH5N6aqQ1ZomyVauVjGvlOTlhP+bj6w1yhkft4a3AY9mPLGU0mMZCBbn7nRZnKFJbq26ssNBPPIwkGYFcV0t4fzjthL8zl77vBhnw4Vki3NK3Zpa4ZCcxkMU5OIm4ZC8Oi7hBxktJ8041dYZ4FMnW2xXNuO0UOSSqXhN2hXwAls0wN0LSsufijTLkbDXj43OGtxw9103TqLDD2HCjaSyUYW3fQGnHBUOR1IsV9vWzGYEs2v41vD9QXt8MrOH16RQGfChLf51Z4hLTltKIsrqlYmnTt+Gr5wYZL4JOOdWygebqGuNv10Zg97ZT5EDQUfVldL0mbl09OS04f87jzCXNH1YwypCO+F19fKnhraG7SZ+HiJ4MjAZeGZjGIpjPI+04fygyjBWOTCzJRSCrtt8P/dcrLIl3nSu6q4IgY6ECZek7zcyWttR3SatbKfayTpSyXj07yNgadY861bKB5obY27UZ2J1zOR4NMUYlW2VTr8m6wNwiNdNXzE3quaTFY/ZMp3TErzU8Ghveqqt+MjFl3bgORUodmMpANxaBF3Qx5C11RWKFI/EFmQhkHabuhf7LFZb0u943UrNOcbQKhC1lNTPb2uIaWaxudeu8vrL2WjhBxlmnWjbQXJJ4u3YEdmdcjseCto2auhqv1/RMX6lzLukpciXJiF/LxxcOb8lJaOI1kjdn6UMZHZjKIGgsiBP95YSwR2KF3XyZCGR7YrozqVbZA8u73jd+aNOiAv7I12ZmW1siw2p1x0LVTJfFDjLOONXygeZWQKv/dmUDu+PLnxy3ehZzj8T/RRu31GuWvW9m+uoqRE4pW29Q6o03KzhY84f94S01CU0OyVmWtdHBUhlYjcXKUjw3hD0fKxyPQPbMrdjAoFxhybzrtqtORRMtKhCWvumb5rSlr7SSGjFWt9tauK+ek5Z2qmUCzd2AVv/tysaZ51ZjOSZiMT86zo2O1PLqNTPTV07/J4u1utGe6no9OX+YmNZ9Gu1gfKsrZCqDoB51utluCHsqVlh+2oynEcdHHJhb4cCgHGZZ3nXiZJXRRIsKVks/O4lBIbrQ/Cce9e2+el5SzqkWDzT3A1qDtysXZ55bjeWY6DitG1dPWK8tM33toJfN9tTU65rFx8d6a00jUd/J3k4sUs1UBqax2A6DrDNzLhLBIFFzy2v71TBL+K5b0USLCpwCpSYxEDlYItsC/hOPJU8E/6ubn1vZIRZoHga0Bm/XkjFWnMxqLMeE6jgtOXspKO8y03dZe29He7rU646PT9frTuse2I5GB35lsBkGmY4VVl8eu/SIuaXbd2U63pZhluBdt6KJslMRYqmyKRHvct38WTyWXLOGNW+tF5EJX48EtN5SGSOh7dnVWI6DvaL3TY3E+TanutBlpu/SvO9oT5d63fbx8Ta60o9ibd2HlA78lysRBrkSiRXeHA5Im1vSDrpcEyssESeaKFBBQluLh0KuDaK3G6OBrzJ893Ys3pAKXzcXGg9oDTOaTkBuNZZD4qzoLRfzs2bTMTWHalJLqoYzfXPtqXqYS72++viu5hTJ1l2fwDPSjAwSYZCyNKlY4c3hgLS5JSYlXrnc/RWWlou0oolovI71tWV5KORSCmK6gzM/xAtWNKfbcKp58eK+maIeSCyglaW6FtnVWA6Ks6K3s5ifiksQz0RegTPT186faE/Vw1zqdSuH8pNcsk5igdcVMjL4f/EwSJKLFXaGA8Ig9ZplzC1eAwtntD/Msl6kFU20lDXZ+9Q3zXgoxN2uu6RFRexQ/I3VEvx48WCOokyKBLSaxxxkzK7GclicFb372W6KZQSy+XfwZiZtNWZVFJF6XbTRYtZbwkls4enAyODPvaF1e0Hi1OLb9nBAaKbw55Ywt0RMR3MTHnR/mGW9SD+aKCOR5RYYD8Wlud2mfcGKW+tFJOPF3Zo79Jg4j9nKlluN5bB4K3q7VpUVgUzsmb76PiRsNedpxur126xmvcWdxM73u4v2aBn8sT+0no4VjsdIBg9PWrGeuaW+UgQWXkW9NNXeMIt1kW40EUlKxL4FxkPRz94OUplgxeziDXUiXjyouQOPSSJjdjWWo5Jd0duKQBYXusz03bLVcvW6WknKPIo7nT9GBm4Y5PWWjhXejpFczW7X3NL3R60zXgtr0mh93R9tidi0oonUVUclEvVQLNgjcX6w4krSqSb+HY8X92tuv7lIBpqTrMvxkCRW9Da3SLejVK0+bNiy1danKR6md4dkvuH+O+PKwA+miccKCzZiJO3Zsa65ZW6QGj0ktiLcxeDERV7crFGJbHko7JG42PPIOdV0eG08XjxVc0ce8x1dpGMSX9HbukVSIeKZ+JZ1ukG1nqbIaOp1p1of75hNKes1TwZhME00VpikYiTdbUC02e09Lzuec11QVqyW4O6PJhXrVZYRiWyH/dgjcZG2K+ZUM0kmvDYWL56rgIPHbCflVmM5ImKY7k+ivij7FskIZNcjkH/jnaeZmrJNd3eVVb2WkMHabYnHCgvi42nONiDeFD17hQ991tVjIldLWPdHC8d14hLZXs/RG4mz2PCYqIeiwmvDePHMTJ/8Y867sw+IGqaL+qLsWxREIKdtNZJ74b1q/bJzNqVZhT4ug7Xb4sUK58fTfKvbm6LnrPDhx3To1RKW9dqDKi8ukS0Phf7i2Ehc0mOiLtIMFqnwWu9p5Wb6qIyRx7zRRToqapjuz21flB4Vcm+RE5eQtdWyL7xfre8yx6zgg6QMdLfFjhXeWH89tLpds9td4WMd9bFWS1j3Rwvfy+RchKiHYnskLuExMeEDZghGh9e6VkN8po/8ziWj/5i3ukgHpBb2mR6mW31RZlTIv0WxGxSf20fSTzNryCWx6rV0N1vb42uscN5ajVrdxkqJrPBh7HV3tQRnf7R4ZRkGu4Yeij0jcXELz4x5LEMw0fDa2PPQ32lldB/zRhfpUKi+0NjV/Nb6cZBLAHL2FkVste16fcOQ2yizrtfiwWhk7baYzmfWWk1Y3UrQmRU++EU6qyU4Pr5EZRkUNfBQ7BmJi1YF62UsQzDWHMXs22W+c8noP+YNp8ixkLtJKivfHaazGvfILSIkaavtqdezU7Y3UfXakA5Gc4e+8tZq3Oo2U/RSK3zIi/QWbl8ddTsqy6iHYtdIXNyptl7GMgSzbA+bfbvW71wytjteoOMid5OUv7hxkPYWM/4tck0u11bbUa9npmxvlNWpgRMLm8oS+92W7ErpMat7SYmu8KEv0l0tYbE2cpVl1kOxPRKXcaqZy/AHizbervU7l4zjfqfIAREBuFLFdRgHyaz1ba1NggOTa71B2/W6JNlNSqC72fEa2BQrEymRHk9zAs68bUBEWnSFj8WGiS7cnqkst2M68iNxOafachnOEEz+7XK/MzZ287G29MsZTF+Iupumu3fIvdLA5LJvUKZedy3rVDcpytLNTtTAiVhhRT5I3Qk4i2x1EmrW3h8tteFforIkO2I6kiNxSaeafXJ5GXa9lH27/O8Mxm4ebku/Gt35l8Nioi8kXXWxtdG0jGO7NyZvULRe9y3r2JTtJEE329Rr2Vhhkzk5nmY1/X5c6mrB+Jp190eLbfin7lhYWeqSpztYqZG4vFPNJr6BSvLtCp5z5Ix3tqWvQfUp9LCY6AvRforHBAV3KGJyBUTq9cCyjvuUUuVtGhZPyS1sujmeZjf9TqpjF/iadfZHi234p84dVpbypmVHnaMjcVtONfd+RMc8Um+XVS77Oe9zOR4K8VCWYbE65yeP3aG0yaUI6vWIZX3PJDRbBV61llnYdNNajdb5+gKc6EBXs+7+aNeIoaYKHassE2E/uZG4Taea+wXRZ5l4u2yCOSkZJ9UBEcFt67BYTlzRO5QyuQz+w4xY1nf4M51utl+tpWOF89Zqdm1BNzpw0WxsfzTGUt8QVAVJD0VmJG7bqbaLxF5uziV7c1I2xmcOQ2smTpN1WOzuGY6bkUTpzUXuXZAk6Gbr+74dK5ywVnfs/eRFB65TgPP7o3kEc1KSHorMSNymU20ne8MvdjlFDoWuXOVWX8HK3LvZeuMzm4vctyBJspu9FSuctlYdszsW8ZuIDiTJ/dF237V4B2sjWHHTwtvD3rLuc4ocCVO5iuA2f2XuO3gg4Cr0mOwi1c3eiBVOB6k7Zvc94cDp/dEybHewssGK+lLzFt6T2XaKHAqzL880kg/sWPtIwNW2IWfY47JOxQrLtJwqXbN7dziwdJgk9kdLstnB2ghW1B/64mnV206RwyCeiq5cRfDNFy8PsrNa3+myTq/aE1fl1t5PmlSLIDttqf3REmx2sLaDFVWZvnYz1h1OkaNgbVr3Alt/X7WedVnH4vQjr2VMlen9BHZEfRufWtuR3ezqYKUnlth8cUj9F79Aj2B7OsV6crQ/aJB21mWdjdPftFYT+wnsiA5M7Y+WZ6uD5VhU+ZG4rw6pP/ycFMfTSbumndtj6jnrss7F6e8YDojvJ7Av6nv5/JhZBSdCtIPlbkQQm1jyag4/J8XzdNaXQ4/8xF3W2Tj9XcMBsS2cdkd9E91pu7MxDjtY4UYEhx64OCRbns6jEXVZZ+L0c9ZqfnZsNupbCPmjuzsFHaxgI4KDD1wckW1P58FIuqwTcfppa3XParPJMUxxzz68u5PbwYpsRHCCCuZQ7PJ0Ho1kNzu57lXcWt2xhRNJj2GKIZiP7+6UmpNympGLY7HT03k0wsgee/ZVdNWe0Frds5bLetJIg8Dv2cd3d0rOSTnFyMUB2efpPBiBCtzZV7FVe8LhgF1ruawnXbCHYD6jHk1sRAC2ySyhcxa8WOGMizRqp+Rnx5LoSZ0hmE+oR796KLsg0kvonAU/VjjnIo1qPW112/epiQY+ySGYT6hHTzASd1TOEKKd5Z5Ve/zV0De2cMp8aXJL5ydx+JG4o3KKEO0cH/GgZ1ab3SK/4d/HOfxI3FE5RYh2hsc86HtWm41l297wD7ycEzs6H/Wg75gdG/u2PRv+gRdzZkfnwx707bVcIuwbggEv5tyOzsc86I+Y3XuHYAB4jDtihT0eMrt3D8EAcB8fixW2ze7oFk65b941BAPAHXwwVtgxu++OW9k1BAPAfj4eK2yb3btr5+3AJwDu59FY4R17P+XZDnwC4H4eixXes/dTErY38AmAh7g7VvhDaws+NgQDwH7uixX+4NqCDw3BAHAH98UKf2xtwdpdNheAT+DuWOGH1xa0h2BOMzcNnI67e2YPrS3oD8GgggafxN09s0fWFvzYEAwAn8lDM5oeGoIB4CvYaaVEVxk96dxhUDK7rJTUKqMwN8AZ2bfKKACnYOce5ACcg9wqowCckgd3SgTgoDy0UyIAR+XBnRIBOChYUw6UBSL4QVEggh8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB4b/4/CK03/nkxilgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjEtMDctMzFUMDg6Mjc6NTcrMDc6MDBcWzrqAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIxLTA3LTMxVDA4OjI3OjU3KzA3OjAwLQaCVgAAACF0RVh0cHM6SGlSZXNCb3VuZGluZ0JveAA1MDR4NzIwKzUwKzUw1uIiwwAAABN0RVh0cHM6TGV2ZWwAQWRvYmUtMi4wCjmTdA0AAAAASUVORK5CYII=" />

=end html


Result formatted as table (split, part 4 of 5):

 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |       600 | 2         |                 0.00% |             63302.47% |   7e-05 |      20 |
 | Text::ANSITable               |      3800 | 0.26      |               561.71% |              9481.57% | 1.1e-06 |      20 |
 | Text::Table::More             |      9400 | 0.11      |              1536.77% |              3773.62% | 2.3e-07 |      26 |
 | Text::Table::Manifold         |     15000 | 0.066     |              2566.70% |              2277.56% | 4.3e-07 |      20 |
 | Text::Table::TinyBorderStyle  |     19200 | 0.0521    |              3255.04% |              1789.77% | 2.7e-08 |      20 |
 | Text::ASCIITable              |     22000 | 0.046     |              3691.71% |              1572.13% | 1.1e-07 |      20 |
 | Text::Table                   |     20000 | 0.04      |              3854.97% |              1503.11% | 5.5e-07 |      29 |
 | Text::Table::HTML::DataTables |     24000 | 0.041     |              4175.85% |              1382.81% | 9.9e-08 |      23 |
 | Text::MarkdownTable           |     31000 | 0.033     |              5234.80% |              1088.47% |   6e-08 |      25 |
 | Text::FormatTable             |     44000 | 0.023     |              7643.36% |               718.80% | 2.4e-08 |      24 |
 | Text::Table::TinyColorWide    |     57000 | 0.018     |              9828.97% |               538.56% | 2.3e-08 |      28 |
 | Text::Table::Tiny             |     68000 | 0.015     |             11863.81% |               429.95% |   2e-08 |      20 |
 | Text::Table::TinyWide         |     73855 | 0.01354   |             12802.16% |               391.41% | 2.2e-11 |      22 |
 | Text::TabularDisplay          |     78000 | 0.013     |             13497.23% |               366.29% | 2.7e-08 |      20 |
 | Text::Table::TinyColor        |    112390 | 0.0088976 |             19534.00% |               222.92% | 2.2e-11 |      20 |
 | Text::Table::Org              |    180000 | 0.0055    |             31569.47% |               100.20% | 6.7e-09 |      20 |
 | Text::Table::HTML             |    182000 | 0.0055    |             31670.29% |                99.57% |   5e-09 |      20 |
 | Text::Table::Any              |    250000 | 0.0039    |             44342.72% |                42.66% | 4.9e-09 |      21 |
 | Text::Table::Sprintf          |    350000 | 0.0029    |             60999.18% |                 3.77% | 3.3e-09 |      20 |
 | Text::Table::CSV              |    360000 | 0.0028    |             63302.47% |                 0.00% | 3.3e-09 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                     Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::Table::Manifold  Text::Table::TinyBorderStyle  Text::ASCIITable  Text::Table::HTML::DataTables  Text::Table  Text::MarkdownTable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::Tiny  Text::Table::TinyWide  Text::TabularDisplay  Text::Table::TinyColor  Text::Table::Org  Text::Table::HTML  Text::Table::Any  Text::Table::Sprintf  Text::Table::CSV 
  Text::UnicodeBox::Table           600/s                       --             -87%               -94%                   -96%                          -97%              -97%                           -97%         -98%                 -98%               -98%                        -99%               -99%                   -99%                  -99%                    -99%              -99%               -99%              -99%                  -99%              -99% 
  Text::ANSITable                  3800/s                     669%               --               -57%                   -74%                          -79%              -82%                           -84%         -84%                 -87%               -91%                        -93%               -94%                   -94%                  -95%                    -96%              -97%               -97%              -98%                  -98%              -98% 
  Text::Table::More                9400/s                    1718%             136%                 --                   -40%                          -52%              -58%                           -62%         -63%                 -70%               -79%                        -83%               -86%                   -87%                  -88%                    -91%              -95%               -95%              -96%                  -97%              -97% 
  Text::Table::Manifold           15000/s                    2930%             293%                66%                     --                          -21%              -30%                           -37%         -39%                 -50%               -65%                        -72%               -77%                   -79%                  -80%                    -86%              -91%               -91%              -94%                  -95%              -95% 
  Text::Table::TinyBorderStyle    19200/s                    3738%             399%               111%                    26%                            --              -11%                           -21%         -23%                 -36%               -55%                        -65%               -71%                   -74%                  -75%                    -82%              -89%               -89%              -92%                  -94%              -94% 
  Text::ASCIITable                22000/s                    4247%             465%               139%                    43%                           13%                --                           -10%         -13%                 -28%               -50%                        -60%               -67%                   -70%                  -71%                    -80%              -88%               -88%              -91%                  -93%              -93% 
  Text::Table::HTML::DataTables   24000/s                    4778%             534%               168%                    60%                           27%               12%                             --          -2%                 -19%               -43%                        -56%               -63%                   -66%                  -68%                    -78%              -86%               -86%              -90%                  -92%              -93% 
  Text::Table                     20000/s                    4900%             550%               175%                    65%                           30%               14%                             2%           --                 -17%               -42%                        -55%               -62%                   -66%                  -67%                    -77%              -86%               -86%              -90%                  -92%              -93% 
  Text::MarkdownTable             31000/s                    5960%             687%               233%                   100%                           57%               39%                            24%          21%                   --               -30%                        -45%               -54%                   -58%                  -60%                    -73%              -83%               -83%              -88%                  -91%              -91% 
  Text::FormatTable               44000/s                    8595%            1030%               378%                   186%                          126%              100%                            78%          73%                  43%                 --                        -21%               -34%                   -41%                  -43%                    -61%              -76%               -76%              -83%                  -87%              -87% 
  Text::Table::TinyColorWide      57000/s                   11011%            1344%               511%                   266%                          189%              155%                           127%         122%                  83%                27%                          --               -16%                   -24%                  -27%                    -50%              -69%               -69%              -78%                  -83%              -84% 
  Text::Table::Tiny               68000/s                   13233%            1633%               633%                   340%                          247%              206%                           173%         166%                 120%                53%                         19%                 --                    -9%                  -13%                    -40%              -63%               -63%              -74%                  -80%              -81% 
  Text::Table::TinyWide           73855/s                   14671%            1820%               712%                   387%                          284%              239%                           202%         195%                 143%                69%                         32%                10%                     --                   -3%                    -34%              -59%               -59%              -71%                  -78%              -79% 
  Text::TabularDisplay            78000/s                   15284%            1900%               746%                   407%                          300%              253%                           215%         207%                 153%                76%                         38%                15%                     4%                    --                    -31%              -57%               -57%              -70%                  -77%              -78% 
  Text::Table::TinyColor         112390/s                   22377%            2822%              1136%                   641%                          485%              416%                           360%         349%                 270%               158%                        102%                68%                    52%                   46%                      --              -38%               -38%              -56%                  -67%              -68% 
  Text::Table::Org               180000/s                   36263%            4627%              1900%                  1100%                          847%              736%                           645%         627%                 500%               318%                        227%               172%                   146%                  136%                     61%                --                 0%              -29%                  -47%              -49% 
  Text::Table::HTML              182000/s                   36263%            4627%              1900%                  1100%                          847%              736%                           645%         627%                 500%               318%                        227%               172%                   146%                  136%                     61%                0%                 --              -29%                  -47%              -49% 
  Text::Table::Any               250000/s                   51182%            6566%              2720%                  1592%                         1235%             1079%                           951%         925%                 746%               489%                        361%               284%                   247%                  233%                    128%               41%                41%                --                  -25%              -28% 
  Text::Table::Sprintf           350000/s                   68865%            8865%              3693%                  2175%                         1696%             1486%                          1313%        1279%                1037%               693%                        520%               417%                   366%                  348%                    206%               89%                89%               34%                    --               -3% 
  Text::Table::CSV               360000/s                   71328%            9185%              3828%                  2257%                         1760%             1542%                          1364%        1328%                1078%               721%                        542%               435%                   383%                  364%                    217%               96%                96%               39%                    3%                -- 
 
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


Result formatted as table (split, part 5 of 5):

 #table5#
 {dataset=>"wide (30x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |        52 |   19      |                 0.00% |             36279.12% |   0.00014 |      20 |
 | Text::ANSITable               |       142 |    7.03   |               173.85% |             13184.33% |   6e-06   |      20 |
 | Text::Table::More             |       320 |    3.2    |               508.80% |              5875.55% | 4.5e-06   |      20 |
 | Text::ASCIITable              |       630 |    1.6    |              1114.70% |              2894.90% | 3.6e-06   |      20 |
 | Text::FormatTable             |       880 |    1.14   |              1594.21% |              2047.27% | 6.9e-07   |      20 |
 | Text::Table::TinyColorWide    |      1080 |    0.922  |              1987.25% |              1642.92% | 4.3e-07   |      20 |
 | Text::Table                   |      1230 |    0.815  |              2259.82% |              1441.60% | 6.4e-07   |      20 |
 | Text::Table::TinyWide         |      1530 |    0.655  |              2839.82% |              1137.46% | 4.2e-07   |      21 |
 | Text::Table::Manifold         |      2040 |    0.49   |              3824.99% |               826.86% | 4.3e-07   |      20 |
 | Text::Table::Tiny             |      2450 |    0.408  |              4614.03% |               671.72% | 2.1e-07   |      20 |
 | Text::TabularDisplay          |      2750 |    0.364  |              5182.31% |               588.70% | 2.3e-07   |      26 |
 | Text::Table::TinyColor        |      3660 |    0.273  |              6946.22% |               416.29% | 2.1e-07   |      20 |
 | Text::Table::TinyBorderStyle  |      4060 |    0.246  |              7709.16% |               365.85% |   5e-08   |      23 |
 | Text::MarkdownTable           |      4330 |    0.231  |              8232.22% |               336.61% | 2.1e-07   |      21 |
 | Text::Table::HTML             |      4770 |    0.21   |              9077.91% |               296.38% | 1.6e-07   |      20 |
 | Text::Table::HTML::DataTables |      6200 |    0.16   |             11752.53% |               206.93% | 2.1e-07   |      20 |
 | Text::Table::Org              |     10900 |    0.0915 |             20941.40% |                72.89% |   7e-08   |      26 |
 | Text::Table::CSV              |     14000 |    0.07   |             27456.77% |                32.02% | 1.1e-07   |      20 |
 | Text::Table::Any              |     18000 |    0.055  |             35000.75% |                 3.64% |   8e-08   |      20 |
 | Text::Table::Sprintf          |     18900 |    0.0529 |             36279.12% |                 0.00% |   2e-08   |      34 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                    Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table  Text::Table::TinyWide  Text::Table::Manifold  Text::Table::Tiny  Text::TabularDisplay  Text::Table::TinyColor  Text::Table::TinyBorderStyle  Text::MarkdownTable  Text::Table::HTML  Text::Table::HTML::DataTables  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table           52/s                       --             -63%               -83%              -91%               -94%                        -95%         -95%                   -96%                   -97%               -97%                  -98%                    -98%                          -98%                 -98%               -98%                           -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                  142/s                     170%               --               -54%              -77%               -83%                        -86%         -88%                   -90%                   -93%               -94%                  -94%                    -96%                          -96%                 -96%               -97%                           -97%              -98%              -99%              -99%                  -99% 
  Text::Table::More                320/s                     493%             119%                 --              -50%               -64%                        -71%         -74%                   -79%                   -84%               -87%                  -88%                    -91%                          -92%                 -92%               -93%                           -95%              -97%              -97%              -98%                  -98% 
  Text::ASCIITable                 630/s                    1087%             339%               100%                --               -28%                        -42%         -49%                   -59%                   -69%               -74%                  -77%                    -82%                          -84%                 -85%               -86%                           -90%              -94%              -95%              -96%                  -96% 
  Text::FormatTable                880/s                    1566%             516%               180%               40%                 --                        -19%         -28%                   -42%                   -57%               -64%                  -68%                    -76%                          -78%                 -79%               -81%                           -85%              -91%              -93%              -95%                  -95% 
  Text::Table::TinyColorWide      1080/s                    1960%             662%               247%               73%                23%                          --         -11%                   -28%                   -46%               -55%                  -60%                    -70%                          -73%                 -74%               -77%                           -82%              -90%              -92%              -94%                  -94% 
  Text::Table                     1230/s                    2231%             762%               292%               96%                39%                         13%           --                   -19%                   -39%               -49%                  -55%                    -66%                          -69%                 -71%               -74%                           -80%              -88%              -91%              -93%                  -93% 
  Text::Table::TinyWide           1530/s                    2800%             973%               388%              144%                74%                         40%          24%                     --                   -25%               -37%                  -44%                    -58%                          -62%                 -64%               -67%                           -75%              -86%              -89%              -91%                  -91% 
  Text::Table::Manifold           2040/s                    3777%            1334%               553%              226%               132%                         88%          66%                    33%                     --               -16%                  -25%                    -44%                          -49%                 -52%               -57%                           -67%              -81%              -85%              -88%                  -89% 
  Text::Table::Tiny               2450/s                    4556%            1623%               684%              292%               179%                        125%          99%                    60%                    20%                 --                  -10%                    -33%                          -39%                 -43%               -48%                           -60%              -77%              -82%              -86%                  -87% 
  Text::TabularDisplay            2750/s                    5119%            1831%               779%              339%               213%                        153%         123%                    79%                    34%                12%                    --                    -24%                          -32%                 -36%               -42%                           -56%              -74%              -80%              -84%                  -85% 
  Text::Table::TinyColor          3660/s                    6859%            2475%              1072%              486%               317%                        237%         198%                   139%                    79%                49%                   33%                      --                           -9%                 -15%               -23%                           -41%              -66%              -74%              -79%                  -80% 
  Text::Table::TinyBorderStyle    4060/s                    7623%            2757%              1200%              550%               363%                        274%         231%                   166%                    99%                65%                   47%                     10%                            --                  -6%               -14%                           -34%              -62%              -71%              -77%                  -78% 
  Text::MarkdownTable             4330/s                    8125%            2943%              1285%              592%               393%                        299%         252%                   183%                   112%                76%                   57%                     18%                            6%                   --                -9%                           -30%              -60%              -69%              -76%                  -77% 
  Text::Table::HTML               4770/s                    8947%            3247%              1423%              661%               442%                        339%         288%                   211%                   133%                94%                   73%                     30%                           17%                  10%                 --                           -23%              -56%              -66%              -73%                  -74% 
  Text::Table::HTML::DataTables   6200/s                   11775%            4293%              1900%              900%               612%                        476%         409%                   309%                   206%               154%                  127%                     70%                           53%                  44%                31%                             --              -42%              -56%              -65%                  -66% 
  Text::Table::Org               10900/s                   20665%            7583%              3397%             1648%              1145%                        907%         790%                   615%                   435%               345%                  297%                    198%                          168%                 152%               129%                            74%                --              -23%              -39%                  -42% 
  Text::Table::CSV               14000/s                   27042%            9942%              4471%             2185%              1528%                       1217%        1064%                   835%                   599%               482%                  419%                    290%                          251%                 229%               199%                           128%               30%                --              -21%                  -24% 
  Text::Table::Any               18000/s                   34445%           12681%              5718%             2809%              1972%                       1576%        1381%                  1090%                   790%               641%                  561%                    396%                          347%                 320%               281%                           190%               66%               27%                --                   -3% 
  Text::Table::Sprintf           18900/s                   35816%           13189%              5949%             2924%              2055%                       1642%        1440%                  1138%                   826%               671%                  588%                    416%                          365%                 336%               296%                           202%               72%               32%                3%                    -- 
 
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
 | Text::UnicodeBox::Table       |     130   |             126.1 |                 0.00% |              3242.20% |   0.00018 |      20 |
 | Text::Table::Manifold         |      72   |              68.1 |                81.54% |              1741.01% |   0.00012 |      20 |
 | Text::ANSITable               |      38   |              34.1 |               242.78% |               875.03% |   0.00012 |      20 |
 | Text::MarkdownTable           |      34   |              30.1 |               278.89% |               782.11% |   0.0001  |      20 |
 | Text::Table::TinyColorWide    |      28   |              24.1 |               370.49% |               610.37% |   0.00015 |      20 |
 | Text::Table::TinyWide         |      26   |              22.1 |               401.17% |               566.87% |   0.00013 |      20 |
 | Text::Table::More             |      20   |              16.1 |               534.76% |               426.53% |   0.00017 |      21 |
 | Text::Table                   |      20   |              16.1 |               578.97% |               392.25% |   0.00021 |      20 |
 | Text::Table::Tiny             |      10   |               6.1 |               768.66% |               284.75% |   0.00023 |      20 |
 | Text::ASCIITable              |      10   |               6.1 |               782.49% |               278.72% |   0.0002  |      21 |
 | Text::FormatTable             |      10   |               6.1 |               930.81% |               224.23% |   0.00029 |      20 |
 | Text::Table::TinyColor        |      10   |               6.1 |              1012.41% |               200.45% |   0.00014 |      20 |
 | Text::Table::TinyBorderStyle  |      10   |               6.1 |              1195.28% |               158.03% |   0.00022 |      21 |
 | Text::TabularDisplay          |       9   |               5.1 |              1279.66% |               142.25% |   0.00019 |      20 |
 | Text::Table::HTML             |       8   |               4.1 |              1496.62% |               109.33% |   0.00016 |      20 |
 | Text::Table::HTML::DataTables |       8   |               4.1 |              1500.28% |               108.85% |   0.00019 |      20 |
 | Text::Table::Any              |       7   |               3.1 |              1706.85% |                84.97% | 7.5e-05   |      20 |
 | Text::Table::Org              |       6.9 |               3   |              1794.83% |                76.39% | 4.9e-05   |      20 |
 | Text::Table::CSV              |       7   |               3.1 |              1848.76% |                71.50% | 8.1e-05   |      21 |
 | Text::Table::Sprintf          |       6   |               2.1 |              1955.85% |                62.57% | 9.8e-05   |      20 |
 | perl -e1 (baseline)           |       3.9 |               0   |              3242.20% |                 0.00% | 2.3e-05   |      20 |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                    Rate  Text::UnicodeBox::Table  Text::Table::Manifold  Text::ANSITable  Text::MarkdownTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::Table::More  Text::Table  Text::Table::Tiny  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColor  Text::Table::TinyBorderStyle  Text::TabularDisplay  Text::Table::HTML  Text::Table::HTML::DataTables  Text::Table::Any  Text::Table::CSV  Text::Table::Org  Text::Table::Sprintf  perl -e1 (baseline) 
  Text::UnicodeBox::Table          7.7/s                       --                   -44%             -70%                 -73%                        -78%                   -80%               -84%         -84%               -92%              -92%               -92%                    -92%                          -92%                  -93%               -93%                           -93%              -94%              -94%              -94%                  -95%                 -97% 
  Text::Table::Manifold           13.9/s                      80%                     --             -47%                 -52%                        -61%                   -63%               -72%         -72%               -86%              -86%               -86%                    -86%                          -86%                  -87%               -88%                           -88%              -90%              -90%              -90%                  -91%                 -94% 
  Text::ANSITable                 26.3/s                     242%                    89%               --                 -10%                        -26%                   -31%               -47%         -47%               -73%              -73%               -73%                    -73%                          -73%                  -76%               -78%                           -78%              -81%              -81%              -81%                  -84%                 -89% 
  Text::MarkdownTable             29.4/s                     282%                   111%              11%                   --                        -17%                   -23%               -41%         -41%               -70%              -70%               -70%                    -70%                          -70%                  -73%               -76%                           -76%              -79%              -79%              -79%                  -82%                 -88% 
  Text::Table::TinyColorWide      35.7/s                     364%                   157%              35%                  21%                          --                    -7%               -28%         -28%               -64%              -64%               -64%                    -64%                          -64%                  -67%               -71%                           -71%              -75%              -75%              -75%                  -78%                 -86% 
  Text::Table::TinyWide           38.5/s                     400%                   176%              46%                  30%                          7%                     --               -23%         -23%               -61%              -61%               -61%                    -61%                          -61%                  -65%               -69%                           -69%              -73%              -73%              -73%                  -76%                 -85% 
  Text::Table::More               50.0/s                     550%                   260%              89%                  70%                         39%                    30%                 --           0%               -50%              -50%               -50%                    -50%                          -50%                  -55%               -60%                           -60%              -65%              -65%              -65%                  -70%                 -80% 
  Text::Table                     50.0/s                     550%                   260%              89%                  70%                         39%                    30%                 0%           --               -50%              -50%               -50%                    -50%                          -50%                  -55%               -60%                           -60%              -65%              -65%              -65%                  -70%                 -80% 
  Text::Table::Tiny              100.0/s                    1200%                   620%             280%                 240%                        179%                   160%               100%         100%                 --                0%                 0%                      0%                            0%                   -9%               -19%                           -19%              -30%              -30%              -30%                  -40%                 -61% 
  Text::ASCIITable               100.0/s                    1200%                   620%             280%                 240%                        179%                   160%               100%         100%                 0%                --                 0%                      0%                            0%                   -9%               -19%                           -19%              -30%              -30%              -30%                  -40%                 -61% 
  Text::FormatTable              100.0/s                    1200%                   620%             280%                 240%                        179%                   160%               100%         100%                 0%                0%                 --                      0%                            0%                   -9%               -19%                           -19%              -30%              -30%              -30%                  -40%                 -61% 
  Text::Table::TinyColor         100.0/s                    1200%                   620%             280%                 240%                        179%                   160%               100%         100%                 0%                0%                 0%                      --                            0%                   -9%               -19%                           -19%              -30%              -30%              -30%                  -40%                 -61% 
  Text::Table::TinyBorderStyle   100.0/s                    1200%                   620%             280%                 240%                        179%                   160%               100%         100%                 0%                0%                 0%                      0%                            --                   -9%               -19%                           -19%              -30%              -30%              -30%                  -40%                 -61% 
  Text::TabularDisplay           111.1/s                    1344%                   700%             322%                 277%                        211%                   188%               122%         122%                11%               11%                11%                     11%                           11%                    --               -11%                           -11%              -22%              -22%              -23%                  -33%                 -56% 
  Text::Table::HTML              125.0/s                    1525%                   800%             375%                 325%                        250%                   225%               150%         150%                25%               25%                25%                     25%                           25%                   12%                 --                             0%              -12%              -12%              -13%                  -25%                 -51% 
  Text::Table::HTML::DataTables  125.0/s                    1525%                   800%             375%                 325%                        250%                   225%               150%         150%                25%               25%                25%                     25%                           25%                   12%                 0%                             --              -12%              -12%              -13%                  -25%                 -51% 
  Text::Table::Any               142.9/s                    1757%                   928%             442%                 385%                        300%                   271%               185%         185%                42%               42%                42%                     42%                           42%                   28%                14%                            14%                --                0%               -1%                  -14%                 -44% 
  Text::Table::CSV               142.9/s                    1757%                   928%             442%                 385%                        300%                   271%               185%         185%                42%               42%                42%                     42%                           42%                   28%                14%                            14%                0%                --               -1%                  -14%                 -44% 
  Text::Table::Org               144.9/s                    1784%                   943%             450%                 392%                        305%                   276%               189%         189%                44%               44%                44%                     44%                           44%                   30%                15%                            15%                1%                1%                --                  -13%                 -43% 
  Text::Table::Sprintf           166.7/s                    2066%                  1100%             533%                 466%                        366%                   333%               233%         233%                66%               66%                66%                     66%                           66%                   50%                33%                            33%               16%               16%               15%                    --                 -35% 
  perl -e1 (baseline)            256.4/s                    3233%                  1746%             874%                 771%                        617%                   566%               412%         412%               156%              156%               156%                    156%                          156%                  130%               105%                           105%               79%               79%               76%                   53%                   -- 
 
 Legends:
   Text::ANSITable: mod_overhead_time=34.1 participant=Text::ANSITable
   Text::ASCIITable: mod_overhead_time=6.1 participant=Text::ASCIITable
   Text::FormatTable: mod_overhead_time=6.1 participant=Text::FormatTable
   Text::MarkdownTable: mod_overhead_time=30.1 participant=Text::MarkdownTable
   Text::Table: mod_overhead_time=16.1 participant=Text::Table
   Text::Table::Any: mod_overhead_time=3.1 participant=Text::Table::Any
   Text::Table::CSV: mod_overhead_time=3.1 participant=Text::Table::CSV
   Text::Table::HTML: mod_overhead_time=4.1 participant=Text::Table::HTML
   Text::Table::HTML::DataTables: mod_overhead_time=4.1 participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: mod_overhead_time=68.1 participant=Text::Table::Manifold
   Text::Table::More: mod_overhead_time=16.1 participant=Text::Table::More
   Text::Table::Org: mod_overhead_time=3 participant=Text::Table::Org
   Text::Table::Sprintf: mod_overhead_time=2.1 participant=Text::Table::Sprintf
   Text::Table::Tiny: mod_overhead_time=6.1 participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: mod_overhead_time=6.1 participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: mod_overhead_time=6.1 participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: mod_overhead_time=24.1 participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: mod_overhead_time=22.1 participant=Text::Table::TinyWide
   Text::TabularDisplay: mod_overhead_time=5.1 participant=Text::TabularDisplay
   Text::UnicodeBox::Table: mod_overhead_time=126.1 participant=Text::UnicodeBox::Table
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
