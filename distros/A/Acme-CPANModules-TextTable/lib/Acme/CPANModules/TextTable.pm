package Acme::CPANModules::TextTable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-20'; # DATE
our $DIST = 'Acme-CPANModules-TextTable'; # DIST
our $VERSION = '0.009'; # VERSION

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

This is a common frontend for many text table modules as backends. The interface
is dead simple, following <pm:Text::Table::Tiny>. The main drawback is that it
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
rowspan/colspan. I plan to add more features to this module on an as-needed
basic. This module is now preferred than <pm:Text::ANSITable>, although
currently it does not nearly as many formatting options as Text::ANSITable.

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

This document describes version 0.009 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2021-02-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module TextTable

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module TextTable

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Table::Any> 0.100

L<Text::UnicodeBox::Table>

L<Text::Table::Manifold> 1.03

L<Text::ANSITable> 0.602

L<Text::ASCIITable> 0.22

L<Text::FormatTable> 1.03

L<Text::MarkdownTable> 0.3.1

L<Text::Table> 1.133

L<Text::Table::Tiny> 1.00

L<Text::Table::TinyBorderStyle> 0.004

L<Text::Table::More> 0.009

L<Text::Table::Sprintf> 0.001

L<Text::Table::TinyColor> 0.002

L<Text::Table::TinyColorWide> 0.001

L<Text::Table::TinyWide> 0.001

L<Text::Table::Org> 0.02

L<Text::Table::CSV> 0.023

L<Text::Table::HTML> 0.003

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.10 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher --cpanmodules-module TextTable >>):

 #table1#
 {dataset=>"large (30x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |       1   |     970   |                 0.00% |             39484.05% |   0.0022  |      20 |
 | Text::ANSITable               |       2.4 |     420   |               131.74% |             16981.42% |   0.00087 |      20 |
 | Text::Table::More             |       5.2 |     190   |               406.72% |              7711.84% |   0.00029 |      20 |
 | Text::ASCIITable              |      12   |      86   |              1026.60% |              3413.58% |   0.00026 |      22 |
 | Text::FormatTable             |      17   |      60   |              1529.60% |              2329.06% |   0.00022 |      20 |
 | Text::Table::TinyColorWide    |      17   |      58.8 |              1556.30% |              2289.90% | 5.3e-05   |      20 |
 | Text::Table::TinyWide         |      24   |      41   |              2259.87% |              1577.38% | 7.6e-05   |      20 |
 | Text::Table::Manifold         |      39   |      26   |              3665.29% |               951.29% | 3.8e-05   |      20 |
 | Text::TabularDisplay          |      44   |      23   |              4151.12% |               831.14% |   0.0001  |      20 |
 | Text::Table::TinyColor        |      62   |      16   |              5958.76% |               553.34% | 3.7e-05   |      20 |
 | Text::Table::Tiny             |      64   |      16   |              6174.05% |               530.92% | 4.7e-05   |      20 |
 | Text::Table::Any              |      65   |      15   |              6222.54% |               526.08% | 6.8e-05   |      20 |
 | Text::MarkdownTable           |      82   |      12   |              7857.77% |               397.43% | 7.2e-05   |      20 |
 | Text::Table                   |     100   |       9.6 |             10093.51% |               288.33% | 5.7e-05   |      20 |
 | Text::Table::HTML::DataTables |     110   |       8.9 |             10851.19% |               261.46% | 8.8e-05   |      20 |
 | Text::Table::HTML             |     120   |       8.1 |             11889.99% |               230.14% | 7.2e-05   |      21 |
 | Text::Table::CSV              |     230   |       4.3 |             22339.48% |                76.40% | 1.8e-05   |      20 |
 | Text::Table::TinyBorderStyle  |     200   |       4   |             23298.18% |                69.18% | 4.2e-05   |      20 |
 | Text::Table::Org              |     240   |       4.2 |             23335.57% |                68.91% | 1.9e-05   |      20 |
 | Text::Table::Sprintf          |     400   |       2   |             39484.05% |                 0.00% | 3.2e-05   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |       8.2 |   120     |                 0.00% |             41406.41% |   0.00042 |      20 |
 | Text::ANSITable               |      22   |    46     |               166.08% |             15499.31% |   0.00015 |      20 |
 | Text::Table::More             |      49   |    21     |               493.69% |              6891.21% | 8.8e-05   |      20 |
 | Text::ASCIITable              |     100   |     8     |              1371.68% |              2720.35% |   0.00011 |      21 |
 | Text::FormatTable             |     150   |     6.5   |              1768.23% |              2121.69% | 5.6e-05   |      20 |
 | Text::Table::TinyColorWide    |     170   |     6     |              1949.23% |              1925.46% | 3.1e-05   |      20 |
 | Text::Table::TinyWide         |     200   |     4     |              2664.36% |              1401.48% | 5.2e-05   |      20 |
 | Text::TabularDisplay          |     300   |     3.3   |              3561.61% |              1033.56% | 3.3e-05   |      20 |
 | Text::Table::Manifold         |     350   |     2.9   |              4185.03% |               868.64% | 1.3e-05   |      20 |
 | Text::MarkdownTable           |     410   |     2.4   |              4941.74% |               723.26% | 1.8e-05   |      21 |
 | Text::Table                   |     490   |     2     |              5886.85% |               593.29% | 1.4e-05   |      21 |
 | Text::Table::Any              |     570   |     1.8   |              6841.50% |               497.95% | 7.2e-06   |      20 |
 | Text::Table::Tiny             |     580   |     1.7   |              6954.00% |               488.41% | 5.1e-06   |      20 |
 | Text::Table::TinyColor        |     600   |     1.7   |              7181.51% |               470.03% | 1.3e-05   |      20 |
 | Text::Table::HTML::DataTables |     950   |     1.1   |             11545.75% |               256.41% | 9.6e-06   |      20 |
 | Text::Table::HTML             |    1110   |     0.901 |             13475.05% |               205.76% | 8.5e-07   |      20 |
 | Text::Table::TinyBorderStyle  |    1800   |     0.57  |             21361.42% |                93.40% | 2.9e-06   |      20 |
 | Text::Table::Org              |    1800   |     0.55  |             22236.24% |                85.83% | 1.4e-06   |      20 |
 | Text::Table::CSV              |    1840   |     0.544 |             22392.40% |                84.54% | 4.8e-07   |      20 |
 | Text::Table::Sprintf          |    3390   |     0.295 |             41406.41% |                 0.00% | 2.1e-07   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

 #table3#
 {dataset=>"small (3x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |       190 | 5.2       |                 0.00% |             52622.69% | 4.8e-05 |      20 |
 | Text::ANSITable               |       850 | 1.2       |               340.98% |             11855.81% | 4.9e-06 |      20 |
 | Text::Table::More             |      2100 | 0.48      |               986.91% |              4750.69% | 1.3e-06 |      20 |
 | Text::ASCIITable              |      4900 | 0.2       |              2469.54% |              1951.83% | 9.1e-07 |      20 |
 | Text::FormatTable             |      7000 | 0.14      |              3572.36% |              1335.66% | 2.1e-07 |      21 |
 | Text::Table                   |      7700 | 0.13      |              3933.76% |              1207.04% |   2e-07 |      22 |
 | Text::Table::Manifold         |      7800 | 0.13      |              3981.37% |              1191.79% | 2.1e-07 |      20 |
 | Text::Table::TinyColorWide    |      7900 | 0.13      |              4011.29% |              1182.39% | 2.1e-07 |      20 |
 | Text::Table::TinyWide         |     11200 | 0.0895    |              5724.02% |               805.26% | 7.8e-08 |      21 |
 | Text::Table::TinyBorderStyle  |     12000 | 0.086     |              5937.79% |               773.21% | 1.3e-07 |      20 |
 | Text::MarkdownTable           |     12000 | 0.08      |              6383.09% |               713.23% | 2.1e-07 |      20 |
 | Text::Table::HTML::DataTables |     10000 | 0.08      |              6790.67% |               665.13% | 7.7e-07 |      20 |
 | Text::TabularDisplay          |     15000 | 0.067     |              7719.69% |               574.23% | 2.4e-07 |      20 |
 | Text::Table::TinyColor        |     20000 | 0.05      |              9510.69% |               448.58% | 2.6e-06 |      22 |
 | Text::Table::Any              |     20000 | 0.049     |             10442.21% |               400.11% | 1.1e-07 |      20 |
 | Text::Table::Tiny             |     21000 | 0.048     |             10673.61% |               389.37% | 5.7e-08 |      27 |
 | Text::Table::HTML             |     47000 | 0.021     |             24414.86% |               115.06% | 2.7e-08 |      20 |
 | Text::Table::Org              |     56000 | 0.018     |             28940.37% |                81.55% | 2.7e-08 |      20 |
 | Text::Table::CSV              |     78800 | 0.0127    |             41005.07% |                28.26% |   6e-09 |      25 |
 | Text::Table::Sprintf          |    101130 | 0.0098881 |             52622.69% |                 0.00% | 2.1e-11 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |       500 |   2       |                 0.00% |             61292.33% | 7.3e-05 |      20 |
 | Text::ANSITable               |      3000 |   0.34    |               528.88% |              9662.22% | 2.3e-06 |      22 |
 | Text::Table::More             |      7700 |   0.13    |              1524.09% |              3680.11% |   2e-07 |      23 |
 | Text::Table::Manifold         |     14000 |   0.073   |              2805.73% |              2012.80% |   1e-07 |      21 |
 | Text::Table::TinyBorderStyle  |     15000 |   0.066   |              3132.40% |              1799.28% | 1.3e-07 |      22 |
 | Text::ASCIITable              |     18000 |   0.056   |              3670.77% |              1528.11% | 1.3e-07 |      22 |
 | Text::Table                   |     21000 |   0.048   |              4295.45% |              1296.72% | 1.1e-07 |      20 |
 | Text::Table::HTML::DataTables |     21000 |   0.048   |              4341.79% |              1282.15% | 1.2e-07 |      20 |
 | Text::MarkdownTable           |     25000 |   0.041   |              5115.47% |              1077.12% | 1.1e-07 |      20 |
 | Text::FormatTable             |     34000 |   0.029   |              7133.04% |               748.78% | 6.4e-08 |      22 |
 | Text::Table::TinyColorWide    |     45000 |   0.022   |              9403.75% |               545.98% | 2.4e-08 |      24 |
 | Text::TabularDisplay          |     56000 |   0.018   |             11798.72% |               415.96% |   8e-08 |      20 |
 | Text::Table::TinyWide         |     58000 |   0.017   |             12203.74% |               398.97% | 3.3e-08 |      20 |
 | Text::Table::Any              |     59000 |   0.017   |             12427.69% |               390.05% | 2.7e-08 |      20 |
 | Text::Table::Tiny             |     63000 |   0.016   |             13217.27% |               361.00% | 2.7e-08 |      20 |
 | Text::Table::TinyColor        |     94000 |   0.011   |             19914.10% |               206.75% | 1.3e-08 |      20 |
 | Text::Table::Org              |    147000 |   0.0068  |             31110.94% |                96.70% |   3e-09 |      24 |
 | Text::Table::HTML             |    183000 |   0.00546 |             38769.80% |                57.94% | 1.6e-09 |      23 |
 | Text::Table::Sprintf          |    288000 |   0.00347 |             61087.88% |                 0.33% | 1.6e-09 |      23 |
 | Text::Table::CSV              |    289000 |   0.00346 |             61292.33% |                 0.00% | 1.4e-09 |      29 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table5#
 {dataset=>"wide (30x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |     38    | 26        |                 0.00% |             42439.84% |   0.00017 |      20 |
 | Text::ANSITable               |    110    |  9.4      |               180.50% |             15065.71% | 4.4e-05   |      22 |
 | Text::Table::More             |    200    |  4        |               541.40% |              6532.38% | 6.9e-05   |      20 |
 | Text::ASCIITable              |    510    |  2        |              1237.96% |              3079.46% | 1.4e-05   |      20 |
 | Text::FormatTable             |    700    |  1.4      |              1754.40% |              2194.00% | 6.5e-06   |      20 |
 | Text::Table::TinyColorWide    |    870    |  1.1      |              2209.99% |              1741.56% | 3.1e-06   |      20 |
 | Text::Table                   |   1200    |  0.86     |              2996.76% |              1273.69% | 3.4e-06   |      20 |
 | Text::Table::TinyWide         |   1200    |  0.84     |              3039.14% |              1255.14% | 6.9e-06   |      23 |
 | Text::Table::Manifold         |   1700    |  0.6      |              4352.22% |               855.47% | 1.1e-06   |      20 |
 | Text::TabularDisplay          |   2200    |  0.45     |              5784.98% |               622.85% | 2.2e-06   |      21 |
 | Text::Table::Tiny             |   2900    |  0.35     |              7520.63% |               458.22% |   2e-06   |      20 |
 | Text::Table::Any              |   3000    |  0.33     |              7872.28% |               433.60% | 4.3e-07   |      20 |
 | Text::Table::TinyColor        |   3100    |  0.32     |              8138.17% |               416.38% | 3.7e-07   |      20 |
 | Text::Table::TinyBorderStyle  |   3280    |  0.305    |              8579.95% |               390.09% | 2.1e-07   |      20 |
 | Text::MarkdownTable           |   3500    |  0.28     |              9233.10% |               355.80% | 8.8e-07   |      21 |
 | Text::Table::HTML::DataTables |   5000    |  0.2      |             13148.63% |               221.09% | 9.6e-07   |      20 |
 | Text::Table::HTML             |   6600    |  0.15     |             17449.76% |               142.40% | 2.1e-07   |      20 |
 | Text::Table::Org              |   9158.85 |  0.109184 |             24163.82% |                75.32% | 2.3e-11   |      20 |
 | Text::Table::CSV              |  12200    |  0.0818   |             32273.50% |                31.40% | 2.5e-08   |      22 |
 | Text::Table::Sprintf          |  16100    |  0.0623   |             42439.84% |                 0.00% | 2.6e-08   |      21 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Benchmark module startup overhead (C<< bencher --cpanmodules-module TextTable --module-startup >>):

 #table6#
 +-------------------------------+-----------+---------------------+-----------------------+-----------------------+-----------+---------+
 | participant                   | time (ms) | mod_overhead_time   | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+---------------------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |     170   | 161.1               |                 0.00% |              1833.19% |   0.00081 |      20 |
 | Text::Table::Manifold         |      89   |  80.1               |                93.41% |               899.52% |   0.00023 |      20 |
 | Text::ANSITable               |      48   |  39.1               |               255.87% |               443.24% |   0.00016 |      26 |
 | Text::MarkdownTable           |      44   |  35.1               |               293.61% |               391.15% |   0.00016 |      20 |
 | Text::Table::TinyColorWide    |      34   |  25.1               |               409.02% |               279.79% | 9.1e-05   |      20 |
 | Text::Table::TinyWide         |      33   |  24.1               |               428.82% |               265.56% |   0.00026 |      20 |
 | Text::Table::More             |      24   |  15.1               |               606.64% |               173.57% | 5.8e-05   |      20 |
 | Text::Table                   |      24   |  15.1               |               624.82% |               166.71% |   0.00017 |      23 |
 | Text::ASCIITable              |      19   |  10.1               |               812.81% |               111.78% | 4.7e-05   |      22 |
 | Text::Table::Tiny             |      17   |   8.1               |               899.58% |                93.40% | 4.9e-05   |      20 |
 | Text::FormatTable             |      15   |   6.1               |              1016.34% |                73.17% | 5.6e-05   |      20 |
 | Text::Table::TinyColor        |      14   |   5.1               |              1090.20% |                62.43% | 4.7e-05   |      20 |
 | Text::Table::TinyBorderStyle  |      12   |   3.1               |              1323.11% |                35.84% | 4.5e-05   |      21 |
 | Text::TabularDisplay          |      12   |   3.1               |              1387.51% |                29.96% | 3.6e-05   |      20 |
 | Text::Table::HTML             |      11   |   2.1               |              1475.23% |                22.72% | 5.2e-05   |      20 |
 | Text::Table::HTML::DataTables |      11   |   2.1               |              1489.90% |                21.59% | 3.8e-05   |      20 |
 | Text::Table::Any              |       9.8 |   0.9               |              1648.24% |                10.58% | 4.5e-05   |      20 |
 | Text::Table::Org              |       9.3 |   0.4               |              1747.29% |                 4.65% | 8.8e-05   |      20 |
 | Text::Table::Sprintf          |       9.3 |   0.4               |              1750.16% |                 4.49% | 8.5e-05   |      20 |
 | Text::Table::CSV              |       9.1 |   0.199999999999999 |              1790.16% |                 2.28% |   5e-05   |      20 |
 | perl -e1 (baseline)           |       8.9 |   0                 |              1833.19% |                 0.00% | 6.2e-05   |      20 |
 +-------------------------------+-----------+---------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

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

=head1 ACME::MODULES ENTRIES

=over

=item * L<Text::Table::Any>

This is a common frontend for many text table modules as backends. The interface
is dead simple, following L<Text::Table::Tiny>. The main drawback is that it
currently does not allow passing (some, any) options to each backend.


=item * L<Text::UnicodeBox::Table>

The main feature of this module is the various border style it provides drawn
using Unicode box-drawing characters. It allows per-row style. The rendering
speed is particularly slow compared to other modules.


=item * L<Text::Table::Manifold>

Two main features of this module is per-column aligning and wide character
support. This module, aside from doing its rendering, can also be told to pass
rendering to HTML, CSV, or other text table module like
L<Text::UnicodeBox::Table>); so in this way it is similar to
L<Text::Table::Any>.


=item * L<Text::ANSITable>

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


=item * L<Text::ASCIITable>

=item * L<Text::FormatTable>

=item * L<Text::MarkdownTable>

=item * L<Text::Table>

=item * L<Text::Table::Tiny>

=item * L<Text::Table::TinyBorderStyle>

=item * L<Text::Table::More>

A module I wrote in early 2021. Main distinguishing feature is support for
rowspan/colspan. I plan to add more features to this module on an as-needed
basic. This module is now preferred than L<Text::ANSITable>, although
currently it does not nearly as many formatting options as Text::ANSITable.


=item * L<Text::Table::Sprintf>

=item * L<Text::Table::TinyColor>

=item * L<Text::Table::TinyColorWide>

=item * L<Text::Table::TinyWide>

=item * L<Text::Table::Org>

=item * L<Text::Table::CSV>

=item * L<Text::Table::HTML>

=item * L<Text::Table::HTML::DataTables>

=item * L<Text::TabularDisplay>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

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

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-TextTable/issues>

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
