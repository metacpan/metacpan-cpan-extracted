package Acme::CPANModules::TextTable;

use 5.010001;
use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-TextTable'; # DIST
our $VERSION = '0.016'; # VERSION

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
    summary => 'List of modules that generate text tables',
    description => <<'_',

Currently excluded from this list are:

- <pm:Text::SimpleTable::AutoWidth> (wrapper to <pm:Text::SimpleTable>);
- <pm:Text::ASCIITable::EasyTable> (wrapper to <pm:Text::ASCIITable>);

_
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
            module => 'Text::SimpleTable',
            description => <<'_',

As its name implies, a simple table-generating module with minimal documentation
and a few choices or border characters. You have to set the width of all columns
manually.

_
            bench_code => sub {
                my ($table) = @_;
                my @colspec = map {[9, $_]} @{ $table->[0] };
                my $ts = Text::SimpleTable->new(@colspec);
                for (1 .. $#{$table}) { $ts->row(@{ $table->[$_] }) }
                $ts->draw;
            },
            features => {
                align_cell     => {value=>0},
                align_column   => {value=>0},
                align_row      => {value=>0},
                box_char       => {value=>0},
                color_data     => {value=>0},
                color_theme    => {value=>0},
                colspan        => {value=>0},
                custom_border  => {value=>1, summary=>"Limited choice of 1 ASCII style and 1 UTF style"},
                custom_color   => {value=>0},
                multiline_data => {value=>0},
                rowspan        => {value=>0},
                speed          => {value=>'fast', summary=>'Slightly slower than Text::Table::Tiny'},
                valign_cell    => {value=>0},
                valign_column  => {value=>0},
                valign_row     => {value=>0},
                wide_char_data => {value=>0},
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
                speed => {value=>"fast", summary=>"The fastest among the others in this list"},
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
# ABSTRACT: List of modules that generate text tables

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::TextTable - List of modules that generate text tables

=head1 VERSION

This document describes version 0.016 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2023-10-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module TextTable

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module TextTable

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Currently excluded from this list are:

=over

=item * L<Text::SimpleTable::AutoWidth> (wrapper to L<Text::SimpleTable>);

=item * L<Text::ASCIITable::EasyTable> (wrapper to L<Text::ASCIITable>);

=back

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Text::Table::Any>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

This is a frontend for many text table modules as backends. The interface is
dead simple, following L<Text::Table::Tiny>. The main drawback is that it
currently does not allow passing (some, any) options to each backend.


=item L<Text::SimpleTable>

Author: L<MRAMBERG|https://metacpan.org/author/MRAMBERG>

As its name implies, a simple table-generating module with minimal documentation
and a few choices or border characters. You have to set the width of all columns
manually.


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
 | Text::SimpleTable             | no             | no               | no            | no           | no             | no              | no          | yes *23)          | no               | no                  | no           | fast *24)  | no               | no                 | no              | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::UnicodeBox::Table       | no             | yes              | N/A           | no           | yes            | no              | no          | yes               | no               | no                  | no           | slow       | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::Manifold         | no             | yes              | N/A           | N/A          | yes            | no              | no          | no *25)           | no               | no                  | no           | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::ANSITable               | yes            | yes              | yes           | yes          | yes            | yes             | no          | yes               | yes              | yes                 | no           | slow       | yes              | yes                | yes             | yes            | yes               | yes      | yes                   | yes                 | yes             | yes       |
 | Text::ASCIITable              | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::FormatTable             | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::MarkdownTable           | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | no *26)             | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table                   | N/A            | N/A              | N/A           | N/A *27)     | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::Tiny             | N/A            | N/A              | N/A           | yes          | yes            | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyBorderStyle  | N/A            | N/A              | N/A           | yes          | no             | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::More             | yes            | yes              | yes           | yes          | yes            | no              | yes         | yes               | no               | yes                 | yes          | slow       | yes              | yes                | yes             | yes            | no                | no       | no                    | no                  | no              | no        |
 | Text::Table::Sprintf          | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | fast *28)  | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyColor        | N/A            | N/A              | N/A           | no           | yes            | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyColorWide    | N/A            | N/A              | N/A           | no           | yes            | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyWide         | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | N/A                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::Org              | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::CSV              | N/A            | N/A              | N/A           | N/A *29)     | no             | N/A             | N/A         | N/A               | N/A              | yes *30)            | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::HTML             | N/A            | N/A              | N/A           | no           | no *31)        | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::HTML::DataTables | N/A            | N/A              | N/A           | no           | no *31)        | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::TabularDisplay          | N/A            | N/A              | N/A           | N/A *29)     | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
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

=item 23. Limited choice of 1 ASCII style and 1 UTF style

=item 24. Slightly slower than Text::Table::Tiny

=item 25. But this module can pass rendering to other module like Text::UnicodeBox::Table

=item 26. Newlines stripped

=item 27. Does not draw borders

=item 28. The fastest among the others in this list

=item 29. Irrelevant

=item 30. But make sure your CSV parser can handle multiline cell

=item 31. Not converted to HTML color elements

=back

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Table::Any> 0.115

L<Text::SimpleTable> 2.07

L<Text::UnicodeBox::Table>

L<Text::Table::Manifold> 1.03

L<Text::ANSITable> 0.609

L<Text::ASCIITable> 0.22

L<Text::FormatTable> 1.03

L<Text::MarkdownTable> 0.3.1

L<Text::Table> 1.135

L<Text::Table::Tiny> 1.03

L<Text::Table::TinyBorderStyle> 0.005

L<Text::Table::More> 0.025

L<Text::Table::Sprintf> 0.006

L<Text::Table::TinyColor> 0.002

L<Text::Table::TinyColorWide> 0.001

L<Text::Table::TinyWide> 0.001

L<Text::Table::Org> 0.031

L<Text::Table::CSV> 0.023

L<Text::Table::HTML> 0.010

L<Text::Table::HTML::DataTables> 0.012

L<Text::TabularDisplay> 1.38

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::Table::Any (perl_code)

L<Text::Table::Any>



=item * Text::SimpleTable (perl_code)

L<Text::SimpleTable>



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

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher --cpanmodules-module TextTable

Result formatted as table (split, part 1 of 5):

 #table1#
 {dataset=>"large (30x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |      0.92 |    1100   |                 0.00% |             35566.44% |   0.0024  |      20 |
 | Text::ANSITable               |      1.8  |     560   |                94.68% |             18220.90% |   0.0012  |      20 |
 | Text::Table::More             |      2.5  |     400   |               167.94% |             13211.33% |   0.00094 |      20 |
 | Text::ASCIITable              |      9.6  |     100   |               934.43% |              3347.94% |   0.00076 |      20 |
 | Text::Table::TinyColorWide    |     10    |      70   |              1365.67% |              2333.45% |   0.0008  |      20 |
 | Text::FormatTable             |     15    |      69   |              1474.71% |              2164.95% |   0.00063 |      20 |
 | Text::Table::TinyWide         |     20    |      50   |              1927.24% |              1659.36% |   0.00058 |      20 |
 | Text::SimpleTable             |     26    |      38   |              2719.79% |              1164.86% |   0.00033 |      20 |
 | Text::Table::Manifold         |     30    |      30   |              3432.47% |               909.67% |   0.00039 |      20 |
 | Text::Table::Tiny             |     30    |      30   |              3660.87% |               848.36% |   0.00043 |      20 |
 | Text::TabularDisplay          |     40    |      30   |              4123.89% |               744.40% |   0.00046 |      20 |
 | Text::Table::HTML             |     50    |      20   |              4776.96% |               631.33% |   0.00036 |      20 |
 | Text::Table::TinyColor        |     50    |      20   |              5139.30% |               580.75% |   0.00056 |      20 |
 | Text::MarkdownTable           |     60    |      20   |              6854.90% |               412.82% |   0.00035 |      20 |
 | Text::Table                   |     90    |      10   |              9175.49% |               284.52% |   0.00026 |      20 |
 | Text::Table::HTML::DataTables |    100    |      10   |             10410.10% |               239.35% |   0.00018 |      20 |
 | Text::Table::TinyBorderStyle  |    200    |       6   |             19509.01% |                81.89% |   0.00011 |      20 |
 | Text::Table::Org              |    200    |       5   |             20190.87% |                75.78% |   0.00013 |      20 |
 | Text::Table::CSV              |    200    |       4.9 |             21769.21% |                63.09% | 4.3e-05   |      20 |
 | Text::Table::Sprintf          |    300    |       4   |             28690.71% |                23.88% | 7.4e-05   |      20 |
 | Text::Table::Any              |    300    |       3   |             35566.44% |                 0.00% | 3.3e-05   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                   Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::Table::TinyColorWide  Text::FormatTable  Text::Table::TinyWide  Text::SimpleTable  Text::Table::Manifold  Text::Table::Tiny  Text::TabularDisplay  Text::Table::HTML  Text::Table::TinyColor  Text::MarkdownTable  Text::Table  Text::Table::HTML::DataTables  Text::Table::TinyBorderStyle  Text::Table::Org  Text::Table::CSV  Text::Table::Sprintf  Text::Table::Any 
  Text::UnicodeBox::Table        0.92/s                       --             -49%               -63%              -90%                        -93%               -93%                   -95%               -96%                   -97%               -97%                  -97%               -98%                    -98%                 -98%         -99%                           -99%                          -99%              -99%              -99%                  -99%              -99% 
  Text::ANSITable                 1.8/s                      96%               --               -28%              -82%                        -87%               -87%                   -91%               -93%                   -94%               -94%                  -94%               -96%                    -96%                 -96%         -98%                           -98%                          -98%              -99%              -99%                  -99%              -99% 
  Text::Table::More               2.5/s                     175%              39%                 --              -75%                        -82%               -82%                   -87%               -90%                   -92%               -92%                  -92%               -95%                    -95%                 -95%         -97%                           -97%                          -98%              -98%              -98%                  -99%              -99% 
  Text::ASCIITable                9.6/s                    1000%             459%               300%                --                        -30%               -31%                   -50%               -62%                   -70%               -70%                  -70%               -80%                    -80%                 -80%         -90%                           -90%                          -94%              -95%              -95%                  -96%              -97% 
  Text::Table::TinyColorWide       10/s                    1471%             700%               471%               42%                          --                -1%                   -28%               -45%                   -57%               -57%                  -57%               -71%                    -71%                 -71%         -85%                           -85%                          -91%              -92%              -93%                  -94%              -95% 
  Text::FormatTable                15/s                    1494%             711%               479%               44%                          1%                 --                   -27%               -44%                   -56%               -56%                  -56%               -71%                    -71%                 -71%         -85%                           -85%                          -91%              -92%              -92%                  -94%              -95% 
  Text::Table::TinyWide            20/s                    2100%            1019%               700%              100%                         39%                37%                     --               -24%                   -40%               -40%                  -40%               -60%                    -60%                 -60%         -80%                           -80%                          -88%              -90%              -90%                  -92%              -94% 
  Text::SimpleTable                26/s                    2794%            1373%               952%              163%                         84%                81%                    31%                 --                   -21%               -21%                  -21%               -47%                    -47%                 -47%         -73%                           -73%                          -84%              -86%              -87%                  -89%              -92% 
  Text::Table::Manifold            30/s                    3566%            1766%              1233%              233%                        133%               129%                    66%                26%                     --                 0%                    0%               -33%                    -33%                 -33%         -66%                           -66%                          -80%              -83%              -83%                  -86%              -90% 
  Text::Table::Tiny                30/s                    3566%            1766%              1233%              233%                        133%               129%                    66%                26%                     0%                 --                    0%               -33%                    -33%                 -33%         -66%                           -66%                          -80%              -83%              -83%                  -86%              -90% 
  Text::TabularDisplay             40/s                    3566%            1766%              1233%              233%                        133%               129%                    66%                26%                     0%                 0%                    --               -33%                    -33%                 -33%         -66%                           -66%                          -80%              -83%              -83%                  -86%              -90% 
  Text::Table::HTML                50/s                    5400%            2700%              1900%              400%                        250%               245%                   150%                89%                    50%                50%                   50%                 --                      0%                   0%         -50%                           -50%                          -70%              -75%              -75%                  -80%              -85% 
  Text::Table::TinyColor           50/s                    5400%            2700%              1900%              400%                        250%               245%                   150%                89%                    50%                50%                   50%                 0%                      --                   0%         -50%                           -50%                          -70%              -75%              -75%                  -80%              -85% 
  Text::MarkdownTable              60/s                    5400%            2700%              1900%              400%                        250%               245%                   150%                89%                    50%                50%                   50%                 0%                      0%                   --         -50%                           -50%                          -70%              -75%              -75%                  -80%              -85% 
  Text::Table                      90/s                   10900%            5500%              3900%              900%                        600%               590%                   400%               280%                   200%               200%                  200%               100%                    100%                 100%           --                             0%                          -40%              -50%              -51%                  -60%              -70% 
  Text::Table::HTML::DataTables   100/s                   10900%            5500%              3900%              900%                        600%               590%                   400%               280%                   200%               200%                  200%               100%                    100%                 100%           0%                             --                          -40%              -50%              -51%                  -60%              -70% 
  Text::Table::TinyBorderStyle    200/s                   18233%            9233%              6566%             1566%                       1066%              1050%                   733%               533%                   400%               400%                  400%               233%                    233%                 233%          66%                            66%                            --              -16%              -18%                  -33%              -50% 
  Text::Table::Org                200/s                   21900%           11100%              7900%             1900%                       1300%              1280%                   900%               660%                   500%               500%                  500%               300%                    300%                 300%         100%                           100%                           19%                --               -1%                  -19%              -40% 
  Text::Table::CSV                200/s                   22348%           11328%              8063%             1940%                       1328%              1308%                   920%               675%                   512%               512%                  512%               308%                    308%                 308%         104%                           104%                           22%                2%                --                  -18%              -38% 
  Text::Table::Sprintf            300/s                   27400%           13900%              9900%             2400%                       1650%              1625%                  1150%               850%                   650%               650%                  650%               400%                    400%                 400%         150%                           150%                           50%               25%               22%                    --              -25% 
  Text::Table::Any                300/s                   36566%           18566%             13233%             3233%                       2233%              2200%                  1566%              1166%                   900%               900%                  900%               566%                    566%                 566%         233%                           233%                          100%               66%               63%                   33%                -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::SimpleTable: participant=Text::SimpleTable
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

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAQhQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAQFgAfEQAYBgAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFgAfJQA1EwAbAAAAAAAAlADUlQDVlADUlQDWAAAAAAAAAAAAlQDVlADUlQDWlADUlADVlQDVlADUlADUlADUlADUlADUlQDVlQDVlQDVlADVlADUmADalADUlADVlgDXlADUigDFjwDNAAAAbACbMABFWAB+ZgCTYQCLaQCXRwBmTgBwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJwA5lADUbQCb////HYmWXAAAAFN0Uk5TABFEZiK7Vcwzd4jdme6qcM7Vx87V0srSP4n69uzx+fb99fR1iOzfddpOvo7HXCK3p0TxM9YR9Z9QemYg704w9/DntvyZz+3g9LS+UCCAMI9gQJfdpy7zAAAAAWJLR0QAiAUdSAAAAAlwSFlzAAAASAAAAEgARslrPgAAAAd0SU1FB+cKHxQOJ6X5TbsAACrBSURBVHja7Z0Jv+08VcabDrvdHTYOKCKi6OvLPIMozgMgIiJa4ft/FDM3c7vH7uY8/9+9d597cpLTJk+SlZXVtCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADPhZTyi5KY3y5vKAqAvahq9VU5yy9mU8P1fF15AOxKo9UbEnR9aiFocCC69lwXVd+XTNA1/+SCLvu+o19WDQQNjkQ1jGUz9P1UUUFP4zj3XNDnqR/niv1ACUGDI0FNjoaa0f2FSvdcFOe5poKuZzo8VxNLh6DBoeA2dHdqGyldOjzPZTWUFKZqCBocCyrofm7GRgl6YoLup4YBQYPD0ZSniZkcTNCkKAgfoU9DofzSEDQ4FM2pouol3OQYqbAHZnUQukbkX0LQ4GBchs+0QzOMU1W27TBMHTejq6lt2ZcQNDgYpKyLsiRFyXYMS73rTUp7AxwAAAAAAAAAAAAAAAAAAACAN6KUz8N1xPwA4JBU0zw3VMN1O7OwGvkBwDFhEWGkpRJuLqQeevUBwDHhYWB9U/DHhc6t/Nj7qgC4h8tFCLuc5cfeFwTA7TTDQIpKKPkz4kOvC3/ndzm/B8BWfv+zij/wE3XaZ//QTfocl9rn/uhuQZcVNZrPQsmfFx/6HKD5j7/A+JMQXwx/W/CnibQvfPEwGVNpN99/5hX3Z/+n+JKf+CWd+Odu0l9wqc2fPGCMPs0xkyNVfJlaOzaJtL48TMZU2s33n3nF/eVvFJ/6iV/WiV8J575X0D27Kqrgmo3K1SA/NhWfebuspkHQ4W/vK2h+bMRIFdz0/K/82FJ85u2ymgZBh7+9r6CLcW74M53d1A4tUR9bis+8XVbTIOjwt3cWdFGX4qKJ+JQfG4rPvF1W0yDo8Lf3FnSSVPF16marRFpZHyZjKu3m+8+84g4raABCQNAgKyBokBUQNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmQFBA2yAoIGWQFBg6yAoEFWQNAgKyBokBUQNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVbsLujOfltoR4z/QNDgWnYWdDfM89AVRT9TmqJu53l8YPHgw7GzoKexIONQFJexLMuuaC6kHpaXq0PQ4Fr2FXQ5UwujnqmS+avI2VfFuX1Y8eDjsa+gSVkwVdfFXPV9Sb/i/31Y8eDjsfuikNrN1Gqeh36cq0oIWq8LIWhwLXsLmvQztZnrnor4PJ2FoLXfY/5qw9i7jsCBuFXQPZfa/V6OtunU12T+BCYHuJOdR+hBOOlKtias56+xwbkaHlc8+HDsK+jTXDLoqEzH6bEtGmp+NHDbgdvZV9B8P2We2RfNMHRFN7VDu+wVQtDgWvZeFCrqknnwCiI+Hl48+Ci8i6D3KB5kCAQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmQFBA2yAoIGWQFBg6yAoEFWQNAgKyBokBUQNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmQFBA2yYndBd7X8JObHw4oHH4ydBd0N8zx0RVG38zzqj4cVDz4cOwt6GgsyDkXRXEg99OrjYcWDD8e+gi5namHUc0f/FMW5lR8PKx58PPYVNCkLpuq6nPmn/HhY8eDjsfuikNrNY1EJJX9GfOh1IQQNrmVvQZN+pjbzWSj58+Kj1sV/vWfsXUfgOXzjm4pveWnf1mnfuS7jrYKuuNTu93K0DTWbi5jJMZaMF9czeBGLvL7rpX1Pp33/uoy3CrrjUrtb0INw0tVsVK4G+aFTYXJkzTZBf3pdxn1NjtMsh+Cm53/lx6OKB29NhoLuZw4d8Kd2aIn6eFTx4K3JUNALRJjKxLKYIeisyVrQexQP9gWCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmQFBA2yAoIGWQFBg6yAoEFWQNAgKyBokBUQNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArDizorrvpjiHorDmsoKtpbsrhBk1D0FlzVEF3c1U2pJ/Ihp+9oXhwVI4q6H4syqYo2utfQg9BZ81hBd1D0CDAUQVdTh0VdAWTA9gcVdDFeR6mYaoiqfbA3Zmyh6Cz5rCCLuqqP8XG53pm//YzpSnqdp7Hq4sHx+Sogq7FGFzVobRTywV9Gcuy7IrmQuqhv654cFSOKei6PDOxlqchtCisGiHohhsk9dxRA6W9pnhwXI4paCrZoWFcwkZHyQU9V31fiq/FN7YWD47LMQVN13lVKlUKeujHuaqEoLXyZz62X+/uA4fgrQTdcaldM4QGbWgp6LqnIj5PZyFo/YPz13vGy2savIS3EnTFpbYxluPCTI4pPNIuFgaZP4HJ8ZF4K0ELNm6s9G3Tt2MklYuYWSX1/DU2OFfDdcWDo3JUQVOb4TQWZEgsCkvm3hjboqHmRQO33QfhwILuGirUlMnRz80wdEU3tUNLriseHJWjCroa6oLaEkPSW1ELZwaxfBoQdNYcVdBF0xT9NLRbfvSW4sFBOaqg+YrvVF0fbAdB581RBX2+YWy+onhwVI4q6GLsb9zwg6Cz5qiCLmfB9XcMQWfNUQV9OxB01kDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmQFBA2yAoIGWQFBg6yAoEFWQNAgKyBokBUQNMgKCBpkBQQNsgKCBlkBQYOsgKBBVkDQICsgaJAVEDTICggaZAUEDbICggZZAUGDrICgQVZA0CArIGiQFRA0yAoIGmRFpoKWr3vriPnxuOLB25KnoGv+ure6nedRfzywePC+5Cjo+tRyQTcXUg+9+nhY8eCdyVHQVcMFXc8de4Wy/Hhc8eCdyVHQ7D2zyz/L1w8rHrwvGQu6Ekr+jPjQ60IIOmsyFvRZKPnz4qPWxX+1YbymesET+MGXNX7iWwm651KDyQGSLLr8jZ/4VoIWPErQNRuVq0F+PLJ4sCsfVdBF0/O/8uOBxYNd+bCC7qZ2aIn6eGDxYFc+oKAlpCyNj4cXD/bh4wp6j+LB04GgX1k8eDoQ9CuLB08Hgn5l8eDpQNCvLB48HQj6lcWDh/DDTyXf/46XBkG/snjwEBaVfNNLg6BfWTx4CBD0ZiDoIwBBbwaCPgIQ9GYg6CMAQW8Ggj4CEPRmIOgjAEFvBoI+AhD0ZiDoIwBBbwaCPgIQ9GYg6CMAQW8Ggj4CEPRmIOgjAEFvBoI+AhD0ZiDoIwBBbwaCPgIQ9GYg6CMAQW8Ggj4CEPRmIOgjAEFvBoI+AhD0ZiDoIwBBbwaCPgIQ9GYg6CMAQW8Ggj4CEPRmIOgjAEFvBoI+AhD0ZiDoIwBBbwaCPgIQ9GYg6CMAQW8Ggj4CEPRmIOgjAEFvBoJ+F76n+SsvDYLeDAT9LvxIK+F7XhoEvRkI+l34FIJ+BBD0uwBBPwQI+l2AoB8CBP0uQNC30hHjPxD0uwBBX0k/U5qibud5fELx4E4g6Cu5jGVZdkVzIfXQP754cCcQ9JU0Ffu3nruiOLePLx7cCQR9JXPV92VRzvRL/s+Diwd3AkFfyTz041xVQtB6XTh/vWc86HeA4q+/q/i2l/Y3Ou3Hfsb8BV1xqT1K0HVPRXyezkLQtfr2zCzrsnzM7wBF8f2ELr+r077sZ8xf0B2X2kNtAjJ/ApPjuaR0+cEFLXiU4kq2Jqznr7HBuRoeXjyQQNCvEjRzb4xt0VB7uYHb7mlA0C8SdNHPzTB0RTe1Q7vsFULQDwaCfpWgi1qs/Yi1BISgHwwE/TJB71H8xwOChqCzAoKGoLMCgoagswKChqCPxre+qfiGnwhBQ9BH42ZdQtAFBP2GQNAQdFZA0BB0VkDQEHRWQNAQdFZA0BB0VkDQEHRWQNAQdFZA0BB0VkDQEPQ78rdfVnzHT/yhTvyBlwZBQ9DvSLJdnqJLCLqAoJ8HBA1BZwUEDUEfjm99RfF3XhoEDUEfjr9PVC8EDUEfjlT1QtAQ9OGAoCHorICgIeisgKAh6KyAoCHoo/EDvUn9Qz8Rgoagj8bGdoGgb6w4PyME/VQgaAj6dcW/AAgagn5d8S8AgoagX1f8g/gHHZLxj14aBA1Bv674B/GAdoGgb6w4PyMEfTcQNAS9EQgagoagXw4EDUFvBIKGoCHoW/mxftf1t7y07/3oU8k/pWrpu35GCBqCflnxsZtNtcuV1QtBQ9CvKz52sxD0VRkh6M1A0BA0BH0rEDQE/QTFdcT4T6r4sk+U0iTS+jL8fQgagn64oOt2nsdtxUPQEPT7C7q5kHpYlApBQ9CHFnQ9d0VxbjcVf4ug+QNR//wv7N/UzULQV2WEoKOUs/pnvfiYoFPtsrF6IeirMkLQUSohaL0unP/1kyD/9lvFT7y0n+q0n3lpP9Fpv/UL/ZlO+/dExp+nMv701oz/4aX9IpXx5zfe/3Mybqu4ZI3fXHF+xl9sy+jXOOfBgj4LQdda0AC8lueaHAAcmpoNztWw92UA8CCaXvwFIEl9fxEvoZvaoSX3l5MBR2myXTBcuz7VO1UdKcv7C8mCARURJ7XOqqZu78sDAfrkUiI5Ct08RFVH6URkjl/p+faKA89kSK0lkuN3OJE0K3Il9Xx6+F1UzXijCXkKXm4namU4hzNRuZKhGaOFvtvEV4vaqdrZr6ZUmuKGjPVdGcNpyYwisbo0U0IJyZVzILFrz8W44j4a20Chd9Y4LbM5XVWopOqboJ1MV1ksyxjW7Lmh5sg0J0bhd3M58Drvh1PZtlelCW7JyLv0rRljacmMLHEcqn4KN1o9VDRvZBCKJZ7midRTZFhTeedQY99V46chLNjVjH17HucqeJVt2wnlBiATnRDqiGiTFbcX5UR733Riu+Sna9IKbiDekpHbsrdmjKUlM9JE7pDvgoZiR/NUxSnWZyOJ9dyORR8d86t26EnYbL+jxqmgp/I0cgVek5G2FLv/s3259ThNTKmkmcrYqrCcJl5xoSF6peL24nIpirnrmqbrrkrjBuItGbkte2vGaFoy4+Ui2mv0h6HTNLeknMY60KDngQ2xXqJQxXSeOzJ4w5OY/Pv2dKJjJQlapjfWuLAnmnkYT+yntmSsK7ZkEy1FCmcV0U1jeZq4/NnYPYdcGR2p+dh/ZcXtQafurabDVtsOp8K4JZUYSlNwA/GajLVofGHL3poxli95qTTxP/nAVRqTLi+V1EPJmow2rplNqHKkqqRjl5NIxzP+n6airXziCaQ3Rj4uADYVEDr8VcaYeHuN88sx7YnK1VdVBzKSy9zSLkl4SzHroOiNkZZwe0leXjX3jWGPyBoXmmV5yOSM+5GK25GaNlU1zE1HRxN6P3xe8RMDafpn2Oh1RUZC+EQpbdlbM0bz+bdRyUUkn/vbkS19qkYNbfXlxEodh15M16S1pmomAW6lDMxosBObmXeLvq+nqmgaFlrQGDMyn/y5cFjIgeEfuKPG2eUoe6Jk3cQ1K+jywstIWnZZ5dTwluLWUT8sQ7ttY9CFnzl6s7pRmuXTgXbdkTPvA7GK25F+KKdTeZkImxepWs5T7yf+MpBmGYjbM9JGIKTQtuytGWP5vNsQ2wF67v+vtj1Vk7ShST9dal4q/2nWZMTySPCmGmhXGrnRoBNpP6BXwn9H2dDfTTo6tE32WouVxsdDJpmu3nCpqzXOLkfZE900D4uEZPF01eYVKg34bur5V+z+B2kM12VNb6OinaOd5dV3tu+E1o3SLO1r3bLPSkd99mWs4naEDLzW6RDC5sW+sW5IJ9ppzFflGIjbMrIKHYvLWCy27K0ZY/nc2xBjyjL3/3KcWpl2GrinhZYqWp0NjzSrWTt8WGJDcDXVRCWKfkDzdPSayMxt0n427Q3W1X9FfycfD0/T/TW+XM5iTxh95NwsrgY3Yyvtd3otrKVI39I0Xh/jPNPxmP3b9qc+YDJUJa0brdl+NlwrfduKkSJScTtykmZl0JWoE6005qsKG4jJjLWsAWrnEc+WvTdj8DaoESi2A5a5XyfWDbX7mKCZ2Sl7Ze+2C0srLuzbAyufJ8p+wKxPOp2ToaOSJUQPeYXq6nTyL5qhqqZqy6Wm7t80ux1DRLgomFdNuxqcQpUpUM+daCk66rIvSEt7ZUnNka7k7eeNsGwRye5fa9b0DdESRnZjsYp7NWzOLOT6Xdh39MrVvCgSxdpeJZpzpvBV+QaiWWgo48D6dEdHAnrvli37kIzebfBW6sR2QGDuH+mQ2vBGYE1xYm1N2MyshzZmy9ZMlXR0KgemWJao+wF3f9GVFhsBRY+WQ57q6v/N2lqPlaFK3Vrjltlt2RPSRcG9asrV0Nm+NS1U+vt42ZehpZ3QE+Dg9ju+iKQ/tWjWoJupMTKfgxX3euScKdfv3C27PJ8lE+Xa3kk0fFWuSOxCvYysJls2sNLqIVNFFlv2QRkD+djP/JJvBwTn/oIbkEx7lbVsExkXW5aZq3I+ro1+IHdq9CpKD3mqqxtTV7JS0zXOsMxuw55QLgrhVQu4GshYKyc4e1BatJSIU2u0K7FnS7+LF4zJF5GsbpRmLehVlgM7GqPZf0dFzZlq/d7T9YLu8zJRr+2tRMtXZYvELdTOyCfNqmXTIhsZKja2SVv2YRmtfCIzN5D5Cig49zOl8O1weifOuEZt1cWWJUom8im2Wlo8JdOPltAy5Kmu3myq1GSirHfL7F5YXBTCq+a5GshwInJj1N2gV4I+n8dpHKfGLJdPTsLWYL/Q1iztJCx7f5nO1dQSt+JezjJnqvU7mS79yUnUa3sjsXB9VYtI/ELtjNXMHWCECpMPPrqpH5jRvlLpPmVGIN8OcBdfo5hWhHIcs5MF/ihbllhpcmzu5fLoYk7bxpAnu7ps62SlrtW4MEQiZrfhouDLV8vVwG+RXchMx39qazuD90WqlNZOdbHOVCHGdMB/oa1Zwr0rI18Fdyu7/q/AnDPl+v3XAcNSr+1PtvVs+KoMkQQKtTNW3Gg4sU9mbOkqemTGX5v5lPuUGYEB845InxdfYy22LG9kEfgTXD2UYgiU/aCozbRlyHPmg2SlJhK5ZS0NkeAKoTBcFMKrZhrG6haZaTAzA9xIolqv5O6KkUVugqvJSUwHjpppTt6ZpUf6TR4aUXPmsn7ntTOaiXaawvJV6Wod44UKqpIJc+R7MGZsUL2SsaqLcMZi7Tcq9ykzAt1IXt0qlNbaPmY7CTLwR9qyqjll15UTdxWIajCGPN/hlqzUYKKwrJUhElwhVKXhouBeNWulZ+xOlnZGrvVW/OxiT6hNcD05BezjpZfMb6JlgZwz9fqdc5JLCpFop/GbYTowfVWFnTFYKM/IogioME/cKJuXMJZzUyQz8si6UMbUbQi0+5QNM476iLElUdpOR0J04E8/m7asUHLdyDVg64ZRVHVgyPMuNXSl4URpWWtDxLeszTBrZmKXhqvBCCC1NuR1MxbshxtuiqirWTbBI9OB+Cn1xfwmAdDCeJRzprF+Z8ipTyQ6aYXUgeur4sOzyBgutFABwVSYYn5fKpj5T1MZhcUYyKjzhzIK95d2nwacvYHBhQ6NbK3JhlkZ+EMvzjAt2a8iXOM8c+k636n8vCFP0CUq1TLlTW/K4hyUhsgvnRWCqlXHRSGDooyAj9pVnu7OXcNMEa3ZZYXpTE5+lDXrJOPei0H7duRwItfv0njq5BQuEoklLj1N274qMTzLjHahCzIguJpcP4OISgxnNKJs/Yyqcu2MYgdTWp3afSqGmXCr6JsY2qpkwWa6+auGdgxTtP10npghOoTdVGzt5Ax5omS2NI1VqmPKL4mGZa0MEWFZG2WLWnVdFFzlKuCD36I/DOivutIqT68w7cnJj7Ku32R4VutefpHGnKkjCNXqvfXjEg3jSfuqxMYYq3iZ0cinBWQEBPezU66MSgz9QivKdsnojkBWRr6Dqd1fjvs01SoXsViv2L5YU+jAn8VnwGpuEPN56TWm7nrOkFcsS1PvUusiZcrL6xOWtWWlCE+l6JaiVh0XhQiKkgEfyy3Kx3USloi5wrQnJyfKmuV8E/s5YjsuxpNavdsTqqgG/R3lq1IbY2x4lhnNfEJAdkBwZRQro4zFEOvO4G6U7ZLRGoGcjHwHcwkmsuf+VKuoCP1Lw3cSVODPUjirOaXkxvZUdWbwvzXkMRmpaDTnUvniIWHKi6sahKlrWilcxLJbxsOsdcCH3RypQZb1rmWFaU9OdpT1uwzPRRW0HWsrgvA8Ow3iROAyHUhf1bIxxir+7C37xVARjfdQUcZOkHoqPNko1ot9N3YwtfvLWdIkWoVIlw3bXueXqhxnIlWOpNbDeGascBEJcO/mX+loNBuxeFgZ5+QoYVspgxFCGg2zDsT6snpLDbJG72ITjphVwuHZbzI8l9p3Zc42rAnNCMLBrnszAlfdmWRZzPOKH7xG4wIKBATLgqRhIPyn6rvp8GRdrBv7bu1gur6x9VZhTkVRFh/YvSidQd28acmbscLBrkdY1S3RaHZjTItzwZv7xdxVhJyD4rEI3S1jYdaBWF9Wb7FBVpuiywpTzBhbAuL3gfDNEHXv5u0wA8KIICztOjQjcJ1+bcy8bHguvcpnvyYYEFzUxDAMlqjE1fBkXaxXudYOpuMbW2sV7v6SKzC2qvR9Veqmex0MwvY8jFjh0K5zQ3Vx6YORPdSCqltzRF1urljmrsK3rOVjEbpbRsOsF0e4OXLHBlk9OhsrzNoqNBwQvx+kHapSxvI6617uzDQiCJ3WNCNw7X5tbIzx4dna3pPPhwSDgkgzT4ZhoKMS18OTZYhBYASyo+0d39hKq3D3Vyc3E5KuKtVJRM8zY4UDXe8ytaRqg5E9bLIUv8qZ+5lpvTwh41nW6umG4GAZifcwR+7oIKt/3llhroRn70k1TK2oE33BjTggpV/s/yWCMByBK35Q+vjMjTEtBOH3MJaCgaCgsa8DhsF6eDIJjkASawfT840lW0W6vwYWJrzJVaWjiYxYYbvrlbRDncex7QK7bWqyFM8OOHM/Oy1geULGacJSP90QHCwj8R7myG3mS/sxvULf6NwNMVxSu4I3q2EzzBOTNF8QuRGE8Qhc7eOzNsbU6kn4PcyloCOgapomEZToGAYr4ck1cUIMTKgNGNzBTLSKaE5jC4ZMo/UQVdQpsux52LHC1lwyTl090bGfzm2OBaMnS7F4sK9VmNbLEzJmPjqVLk83bAuzFhnNkdt6lCXaZVcD4neB9GJtIYdLWuvVYM3EtIb6mUqa1p3nno9G4Bo+Pm9jTPs9As+HyJ/o2hP3h9C6DewLRsOTuZVihBi4xVLdeDuYK63C94fMLZjz3G9yVS09z4oVpl1PnQXFxg+q6La0NqBEGh0O1WRpPdIkrlSY1sGAj1FcsPWI74ZI6iL+gIzVZQ1TdFOhr4ftffHJXg2XbBhRD4eKR3bZQ00jlTSroKjx5I6HxgapuzGmx6jwUpDOmSOzxrm62t7fUIyHJwsrJTgC6RW6E22/1irq1BlmrYpblIVucVVJf4cTKyzOgpLjxzhxXVpjnhoO5WRpVbi8Uma8BQM+RLi9+Yjvhkjq1Mhtd9mAQRUPz94B0kzi0dXFc2Z0T/nILne3UUkPIU95rF8bPj53Y0z7PcLPhrJH1FgP43XnxgQlwpO1leKEGMicgR3MTa1yuYS3YDa5quTCw44V5qaLGj+oorXbWj1ao4ZDb7I0rpSqzJu7+KAvDKPlEd+VMGsj9NTpzuGDQciGQvfkwmuTTY9quDQmVPXIrhyZ+LNhSzXE+rU6isF4StjeGFv8HqHnQ8Qjanyja7G6dZOHwpPFJothpTghBjKrvuXFL7naKqeSN2dwCybtFLGDu+y74GdBKXNr8dWpR2v0cGhMliooSl8pM63F3KVsRjnoe/uCiUhqO/TU6c7Jg0HWAuJ3gx0gSAUwyfAwe7hUj+yyowEMTaxM03Jcjz4lbPo9Ah4eMWcO/Dk1Oy0a0yA2WRYrxQkxcFbodWCBGWsV5vqjf4PWatopYgd3WbXKNz20uaXvewmcU8PhMgPpoKjlSpVprW1GNeiHnq4Ph1m7oadOd04eDBItdG9kcNiJVp83XOpHdq1Am7VpWo3rEvcp4WBAcM3HMyNCiS+i3Cc5ozENfJPFsFJUiMGGIMl4qxAinr6nf8PhyVFXVSy4iyM3Pbzxw+hdajjUk6URFLVcqXiubLEZF6MxEOcXiKT2Q0+d7pw8GCRS6P4QGRzGn0JyL1k/sjteMU3rcT38lHAgIFidyGJGKIVaJXSWs/Z1W1aKmhY2BElGW4VPJKxjVdP/aGt17SQFWad+zxMW6Wk5CypkbqlNc++cpCUoyr3SxWbUg77/MFQwzDoQeupUTfRgkFh49m4oxxGbiU9iK8qtW37N+pHda6ZpPa77Twkz/IBgOmnygcKKUNL2ccqtr3zdYpPFsFKUjCJBkqlW0WuhjkddiPeCSU/L+kkK4koDzit+ZedL/Cwojtq98s5JWoKiHP0sNmPkDAbL9iFBB6jVSdY91vHw7N2wDhHnBwguz+HV0lhl1xx5ZDc6TQuN6HHd9fGFA4IvqvhghFIqPHnxdetNFlm33f/KH4kESSZaxVgLNTx1CYVInqTgmzf2jhp7YPFCxRc9C0rcUcDxRWvVDIpy9LPYjM6gXydtH9md3dDTNTdmXayFZ++CdYi4fYAgCxPgTU2K+CO70acJuUb0uG5nigUEi/m0Pofd0qnw5GVN5W6yaFWGQpRWguaXtRArtFqig1ZOUnAisD17nY6yzDXsbnrYhJ6qZbVqBEXZP18bNqM1sOuG1BVJ3EILL/R0bX20Uuh+WIeIj+beF4/AVf/1DxiKGU9mz7XH9dWAYDafMk9bZMpMhCcbvm53k0Wr0g9RWguaX9ZC5+l0GkLGVtDasswbz16vSnpB7EqdTQ8Xd8yTteoGRemGLKM2o9mQJvYga/ag9fVRtNB9cQ4RtwZZIwK38B/ZjRlPVs91xvXVgODTLJ7Cs6fMLTtxhq/bXbYoVfohSqtB88taaJydlzalDkSwzBvXXmfBihc23A2Vuenh4455qlbdoCgJN/Ftm1G2cSyU2h1kjR60vj5aCg1FKO1F5BBxUQ9GBC695uWR3bTxFB3XVwOCWaGN+pYpvNWdOPthINfToFXpuWXDLR08z9EncCBC+BkQp+eJI9ErZqNuOuNteQecWgs7QVHmisQ/dJpfXTiU2h1kvdDTuHO5Wh7ufJ8HrJZo2ZCvXEfg8meojGteMZ7snqvzbQgIZoV2Qa98dCeuXnJKHF+3rUr3/K5QS284zzF6rsPqMyCFCj1l6VsnbPuIOVqrblCU8XTw6CTJyFPdkNbvXBtk485l/iyTLvR9Buj4IeJGBC5vauOa08ZTZffc0fYKhAOCzUV4H3r7WGwnTtjAcrawfd1imHVUaY/dwaD59fMc3a0/09UQeQZEXa4RejqEfRsu7JgF+x1wfP9dfGW+z0SuSBzh6chT3ZDxprLyxTzWpjiChe4G34qLOY7sCFz3MKlUv7bG9WUSTwYEW0N+0FsV24kTfUuZloavWw6zCVWGg+ZXznN0nCK+pyoScRg4/aP0XRgh+DELyzvg7PHQXJLE3sEjI08DDRluKnUfcY/18ixToNDdkFtxUcdRJALXtsi8fu2O64p4QLD4njnkL6/EWw8aF31L/fzi69Yn5kdOGY0GzafPc3SdImXiwQCr69mnf1RXOLjkMQuj/q+uVXdJYqxIRMWpHSgReeo0ZKyp0h5rJzzbV8d+yK04y3EUqgc7Ate1yBzTMjGuxwKCGc7SzAr/SgaNO8tW/ZuWyITgKaMyc6zLxt0XMafI6o5a8vSPGMYxC8s74Jah2luSqBWJfp+L3NeRkad2Q0aaKr4+CoZnF29hblTMslNbcYvjKFIPwWqIGU9RkfBvhgKCi9jzzBvCkxcb2MppDbO2KqX/QvbZUJc1LtRfDIWdIpvfXxA7/SOIfcyC+w644JJEGHBqdtL7Ombk6VpTxdZHG8Kz94CvIvq2oi3mhSxuqwffIrM1Eh7XrVB8tzUtU2570LhlA/uzhR5mDVWqVlF91m+V1LGUN/W85OkfiYailWods2C74yJLEiboJWk5iaM3Sl1pqojHOhmevSdsFSGGNGcrLlUPsjWDFpmrkWDXtbdg7KSIKbfq17fnzMBsIYdZQ5W6VZZhxm2VuPuiiDhFrnp/wcboShVrbx0Ub7rjwksSviJZkvQOVG+tk5NNFe6yyfDsnSFEbDeTMnZivFsPjvFkW2SeRnyRJONXklb3StC4NWcS5zcu3hKlSqNVVJ81X+a2shaKniRw1fsLtkVXqkq1j1nwz+SJLUlkkrMDtaGpwpNlOjx7b+gqgqu4amInxrtvF3aMJ7MaAhqJH4rFK8xf3qesbt+vn162msGB3nxgtIrqs0urrAbaJE8SSDwYwN4oFT/9I4ThOIwcs2AFx/lLEp1knaix3lRRF5V5j291FlIhInr43XrvMA/Xg288mdUQ0IjVdZ0jSJfKWfOmROKeVpatVnBgERpma+NMamv3PLlXJC70up6nymVvlEqc/uFTG5XqHbOgC11qJ3Rivkoyhqy1plpzUUXDs3dExLj1jfDUhS7Kq4eA8eRONmGNBI8gVb9lgzclGPe0tmxdiUwwWiXwRuzgWoj3PH2h8fVuNOKQXU5ElmGEja6GQ/eg+CIaHOcQTIp2Z5Up5aKKbHjtRL1sKLH3UI5DpJO59RAwnjzCGokfQZqUZSI8eX3ZagcHBlGt4p7NFFwLyZ5nXGh0vZuMOAzIMo48CUpUqv1SQ/MXurXjEkwKNNX61sNSSfMGZ+OLaIzjZpPbVPFD4aPGU1gjsSNI07JMhScnlq2ywsO7LDbBVgmvhVTP0xdqTQgrz4DYEYeeLOOIl8CpSr34lmF6CkomeU21YbI0eJdHUgr+MvJlQynlcYkfCh83nsI9N3IEaVqWa+HJwWWruvRYcKCN72gJr4WWnqcv1Ky4zRGH7HIuoQWLh/USOFmp1ksNV85I3IDTVBu3YCL3uCeskvSG0rVH6K0aT9arVxJHkBY6KSbL5JnejMCyVfx0IjiwcH7Ftu36pefpCzWvaHPEIbucelON2y+BMyt1wwkMG7FKXbXh3hf+frHgMdpbWDOeTI0kjiBdiMkyeqa3dSOFP1msrdDTtxddC0lrK3AbVbLrRdy5K9gvgbM6nv2I4h0RyGapqzbcO8Mi2ELHaG/jGuMpegSpQUSW0TO9DWKdK71C99i4FpLWlncb8WdA1ty5yaqLvgTOfknMAyOQUzbcezP0W2O8AlxjPEWPIDVZ2QNPNZnp99i+Qnd+19a1UPgkgdQzILdOFnyBGX0JnPOSmAeOo7HJ8u1hcSuvOX86esSOycoeeKLJdOe6boVuXeH2tVCo590VcRiDLzD9l8CZTwc/ZRyNTJbvz5PN/S1H7JhcuQce4MoVunGpV62FQtZW4BmQmycLjva8N+6byc2ng58zjr6Td3k7ZHyqx+Xm89u3hSeHMt6+Qr9uLRR6naj3DMjtk4WsP+X/q71n4cyng58zjr6Rd3k7c/NMPd96fvt6eHKUO1fo16+F7E1w+xmQmyeLpSbUF71/Gp3xdPBTeCPv8nae+WjBzee3bwhPTv/iO1boV66F/E1wY7f+Lneus1nix0q/4yul8ubG89vT4cmbuGOFft1ayNsEN6/0xskitVmy6Zxe8ERuOL89GZ68jXtW6FeshQKb4H1wB+a6ySK6WbLhnF7wbG47v30tnnGNe1bo29dCgU3wyP1fNVnENkuS5/SCZ3Pf+e2x8OSt3LFCv24tFN8El9Vww2QR3CxZO6cXPJn7zm+PhCdv5nUr9NgmuOKKySK5WbJ2Ti94Gg85v/0wbv2rQg7TrG6WJM/pBU/iQee3H8atf03I4QqrmyXRg27A83jQ+e3Hces/ruslNkvSB92A51G95/ntT+SBXS++WZI86AY8j9QRpCDEymbJ6jm94HmkjyAFAdY2Szac0wuexWpAMHBZ3SxZfXkReCbxQ+FBgPXNkmr16WDwHJKHwoMwq5slqUcUwXNIHUEK1km8FcBYkWBJ8iJSR5CCTcQ2S6wVCYbn15A8ghSssLZZYq5IMDy/gA1HkIIEoc2S0MOUWJG8iC1HkIIA0c2SyMOUsDZex1ue3/7mRDdL7n2YEjyA9zu//e2JbJY84GFKcD9vdX77IYhtljzgYUrwAA4Tiv8mJDdL7n2YEjwABIBtZ3Wz5N6HKcH9IABsM+ubJfc+TAnAS1ndLIEFB96d6zZLYMGBt+bazRJYcOCdwWYJyAhsloCswGYJyA5sloC8wGYJyApsloC8wGYJyAtsloCswGYJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAcBD+H14yn27SmH6+AAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIzLTEwLTMxVDEzOjE0OjM5KzA3OjAwwxGyagAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMy0xMC0zMVQxMzoxNDozOSswNzowMLJMCtYAAAAhdEVYdHBzOkhpUmVzQm91bmRpbmdCb3gANTA0eDcyMCs1MCs1MNbiIsMAAAATdEVYdHBzOkxldmVsAEFkb2JlLTIuMAo5k3QNAAAAAElFTkSuQmCC" />

=end html


Result formatted as table (split, part 2 of 5):

 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |       7.4 |   140     |                 0.00% |             35069.88% |   0.0005  |      20 |
 | Text::ANSITable               |      17   |    58     |               132.94% |             14998.05% |   0.00043 |      21 |
 | Text::Table::More             |      21   |    49     |               178.85% |             12512.60% |   0.00046 |      20 |
 | Text::ASCIITable              |     100   |    10     |              1223.05% |              2558.25% |   0.00022 |      22 |
 | Text::FormatTable             |     100   |     8     |              1644.13% |              1916.47% |   0.00026 |      21 |
 | Text::Table::TinyColorWide    |     100   |     7     |              1789.53% |              1761.30% |   0.00016 |      20 |
 | Text::Table::TinyWide         |     200   |     5     |              2638.44% |              1184.31% | 6.1e-05   |      20 |
 | Text::SimpleTable             |     200   |     4     |              3188.50% |               969.48% | 8.7e-05   |      20 |
 | Text::Table::Manifold         |     300   |     3     |              3871.99% |               785.45% | 5.4e-05   |      21 |
 | Text::TabularDisplay          |     350   |     2.8   |              4714.43% |               630.51% | 8.9e-06   |      20 |
 | Text::Table::Tiny             |     380   |     2.7   |              4992.67% |               590.60% | 5.5e-06   |      20 |
 | Text::MarkdownTable           |     410   |     2.5   |              5417.46% |               537.43% | 6.7e-06   |      20 |
 | Text::Table                   |     500   |     2     |              6071.61% |               469.87% | 3.6e-05   |      20 |
 | Text::Table::TinyColor        |     570   |     1.8   |              7628.23% |               355.08% | 4.2e-06   |      20 |
 | Text::Table::HTML             |     590   |     1.7   |              7913.19% |               338.90% | 3.4e-06   |      20 |
 | Text::Table::HTML::DataTables |     890   |     1.1   |             12003.16% |               190.58% | 5.1e-06   |      20 |
 | Text::Table::TinyBorderStyle  |    1200   |     0.83  |             16229.83% |               115.37% | 6.6e-06   |      20 |
 | Text::Table::Org              |    1600   |     0.62  |             21670.38% |                61.55% | 6.6e-07   |      20 |
 | Text::Table::CSV              |    1730   |     0.579 |             23360.70% |                49.91% | 2.3e-07   |      20 |
 | Text::Table::Any              |    2500   |     0.4   |             33906.20% |                 3.42% | 4.3e-07   |      20 |
 | Text::Table::Sprintf          |    2590   |     0.386 |             35069.88% |                 0.00% | 1.6e-07   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                   Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::SimpleTable  Text::Table::Manifold  Text::TabularDisplay  Text::Table::Tiny  Text::MarkdownTable  Text::Table  Text::Table::TinyColor  Text::Table::HTML  Text::Table::HTML::DataTables  Text::Table::TinyBorderStyle  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table         7.4/s                       --             -58%               -65%              -92%               -94%                        -95%                   -96%               -97%                   -97%                  -98%               -98%                 -98%         -98%                    -98%               -98%                           -99%                          -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                  17/s                     141%               --               -15%              -82%               -86%                        -87%                   -91%               -93%                   -94%                  -95%               -95%                 -95%         -96%                    -96%               -97%                           -98%                          -98%              -98%              -99%              -99%                  -99% 
  Text::Table::More                21/s                     185%              18%                 --              -79%               -83%                        -85%                   -89%               -91%                   -93%                  -94%               -94%                 -94%         -95%                    -96%               -96%                           -97%                          -98%              -98%              -98%              -99%                  -99% 
  Text::ASCIITable                100/s                    1300%             480%               390%                --               -19%                        -30%                   -50%               -60%                   -70%                  -72%               -73%                 -75%         -80%                    -82%               -83%                           -89%                          -91%              -93%              -94%              -96%                  -96% 
  Text::FormatTable               100/s                    1650%             625%               512%               25%                 --                        -12%                   -37%               -50%                   -62%                  -65%               -66%                 -68%         -75%                    -77%               -78%                           -86%                          -89%              -92%              -92%              -95%                  -95% 
  Text::Table::TinyColorWide      100/s                    1900%             728%               600%               42%                14%                          --                   -28%               -42%                   -57%                  -60%               -61%                 -64%         -71%                    -74%               -75%                           -84%                          -88%              -91%              -91%              -94%                  -94% 
  Text::Table::TinyWide           200/s                    2700%            1060%               880%              100%                60%                         39%                     --               -19%                   -40%                  -44%               -46%                 -50%         -60%                    -64%               -66%                           -78%                          -83%              -87%              -88%              -92%                  -92% 
  Text::SimpleTable               200/s                    3400%            1350%              1125%              150%               100%                         75%                    25%                 --                   -25%                  -30%               -32%                 -37%         -50%                    -55%               -57%                           -72%                          -79%              -84%              -85%              -90%                  -90% 
  Text::Table::Manifold           300/s                    4566%            1833%              1533%              233%               166%                        133%                    66%                33%                     --                   -6%                -9%                 -16%         -33%                    -40%               -43%                           -63%                          -72%              -79%              -80%              -86%                  -87% 
  Text::TabularDisplay            350/s                    4900%            1971%              1650%              257%               185%                        150%                    78%                42%                     7%                    --                -3%                 -10%         -28%                    -35%               -39%                           -60%                          -70%              -77%              -79%              -85%                  -86% 
  Text::Table::Tiny               380/s                    5085%            2048%              1714%              270%               196%                        159%                    85%                48%                    11%                    3%                 --                  -7%         -25%                    -33%               -37%                           -59%                          -69%              -77%              -78%              -85%                  -85% 
  Text::MarkdownTable             410/s                    5500%            2220%              1860%              300%               220%                        179%                   100%                60%                    19%                   11%                 8%                   --         -19%                    -28%               -32%                           -55%                          -66%              -75%              -76%              -84%                  -84% 
  Text::Table                     500/s                    6900%            2800%              2350%              400%               300%                        250%                   150%               100%                    50%                   39%                35%                  25%           --                     -9%               -15%                           -44%                          -58%              -69%              -71%              -80%                  -80% 
  Text::Table::TinyColor          570/s                    7677%            3122%              2622%              455%               344%                        288%                   177%               122%                    66%                   55%                50%                  38%          11%                      --                -5%                           -38%                          -53%              -65%              -67%              -77%                  -78% 
  Text::Table::HTML               590/s                    8135%            3311%              2782%              488%               370%                        311%                   194%               135%                    76%                   64%                58%                  47%          17%                      5%                 --                           -35%                          -51%              -63%              -65%              -76%                  -77% 
  Text::Table::HTML::DataTables   890/s                   12627%            5172%              4354%              809%               627%                        536%                   354%               263%                   172%                  154%               145%                 127%          81%                     63%                54%                             --                          -24%              -43%              -47%              -63%                  -64% 
  Text::Table::TinyBorderStyle   1200/s                   16767%            6887%              5803%             1104%               863%                        743%                   502%               381%                   261%                  237%               225%                 201%         140%                    116%               104%                            32%                            --              -25%              -30%              -51%                  -53% 
  Text::Table::Org               1600/s                   22480%            9254%              7803%             1512%              1190%                       1029%                   706%               545%                   383%                  351%               335%                 303%         222%                    190%               174%                            77%                           33%                --               -6%              -35%                  -37% 
  Text::Table::CSV               1730/s                   24079%            9917%              8362%             1627%              1281%                       1108%                   763%               590%                   418%                  383%               366%                 331%         245%                    210%               193%                            89%                           43%                7%                --              -30%                  -33% 
  Text::Table::Any               2500/s                   34900%           14400%             12150%             2400%              1900%                       1650%                  1150%               900%                   650%                  599%               575%                 525%         400%                    350%               325%                           175%                          107%               54%               44%                --                   -3% 
  Text::Table::Sprintf           2590/s                   36169%           14925%             12594%             2490%              1972%                       1713%                  1195%               936%                   677%                  625%               599%                 547%         418%                    366%               340%                           184%                          115%               60%               49%                3%                    -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::SimpleTable: participant=Text::SimpleTable
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
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |       200 |    6      |                 0.00% |             55334.94% |   0.00017 |      20 |
 | Text::ANSITable               |       690 |    1.5    |               340.32% |             12489.56% | 5.2e-06   |      20 |
 | Text::Table::More             |       990 |    1      |               531.41% |              8679.51% | 2.9e-06   |      20 |
 | Text::Table::TinyBorderStyle  |      3800 |    0.26   |              2336.25% |              2175.42% | 3.8e-07   |      22 |
 | Text::Table::TinyWide         |      4000 |    0.3    |              2408.28% |              2110.08% | 2.7e-06   |      20 |
 | Text::ASCIITable              |      4700 |    0.21   |              2923.90% |              1733.22% | 6.5e-07   |      20 |
 | Text::TabularDisplay          |      6500 |    0.154  |              4055.56% |              1233.99% | 5.6e-08   |      24 |
 | Text::FormatTable             |      7070 |    0.141  |              4424.33% |              1125.26% | 1.1e-07   |      21 |
 | Text::Table::Manifold         |      7300 |    0.14   |              4558.22% |              1090.05% | 6.6e-07   |      20 |
 | Text::Table::HTML::DataTables |      7410 |    0.135  |              4639.87% |              1069.55% | 1.2e-07   |      20 |
 | Text::Table::TinyColorWide    |      7600 |    0.13   |              4790.08% |              1033.62% | 1.5e-07   |      21 |
 | Text::Table                   |      7700 |    0.13   |              4851.51% |              1019.56% | 2.1e-07   |      20 |
 | Text::MarkdownTable           |     12400 |    0.0805 |              7842.12% |               597.99% | 5.7e-08   |      20 |
 | Text::SimpleTable             |     13000 |    0.077  |              8169.66% |               570.34% | 8.8e-08   |      21 |
 | Text::Table::Tiny             |     14800 |    0.0676 |              9362.84% |               485.82% | 4.6e-08   |      20 |
 | Text::Table::TinyColor        |     22000 |    0.044  |             14278.48% |               285.54% | 1.8e-07   |      20 |
 | Text::Table::HTML             |     29000 |    0.034  |             18554.36% |               197.17% |   7e-08   |      20 |
 | Text::Table::CSV              |     45000 |    0.022  |             28952.94% |                90.81% | 2.6e-08   |      24 |
 | Text::Table::Org              |     51700 |    0.0193 |             32959.88% |                67.68% | 8.2e-09   |      21 |
 | Text::Table::Any              |     74100 |    0.0135 |             47322.43% |                16.90% | 8.8e-09   |      20 |
 | Text::Table::Sprintf          |     86700 |    0.0115 |             55334.94% |                 0.00% | 5.7e-09   |      21 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                    Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::Table::TinyWide  Text::Table::TinyBorderStyle  Text::ASCIITable  Text::TabularDisplay  Text::FormatTable  Text::Table::Manifold  Text::Table::HTML::DataTables  Text::Table::TinyColorWide  Text::Table  Text::MarkdownTable  Text::SimpleTable  Text::Table::Tiny  Text::Table::TinyColor  Text::Table::HTML  Text::Table::CSV  Text::Table::Org  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table          200/s                       --             -75%               -83%                   -95%                          -95%              -96%                  -97%               -97%                   -97%                           -97%                        -97%         -97%                 -98%               -98%               -98%                    -99%               -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                  690/s                     300%               --               -33%                   -80%                          -82%              -86%                  -89%               -90%                   -90%                           -91%                        -91%         -91%                 -94%               -94%               -95%                    -97%               -97%              -98%              -98%              -99%                  -99% 
  Text::Table::More                990/s                     500%              50%                 --                   -70%                          -74%              -79%                  -84%               -85%                   -86%                           -86%                        -87%         -87%                 -91%               -92%               -93%                    -95%               -96%              -97%              -98%              -98%                  -98% 
  Text::Table::TinyWide           4000/s                    1900%             400%               233%                     --                          -13%              -30%                  -48%               -53%                   -53%                           -54%                        -56%         -56%                 -73%               -74%               -77%                    -85%               -88%              -92%              -93%              -95%                  -96% 
  Text::Table::TinyBorderStyle    3800/s                    2207%             476%               284%                    15%                            --              -19%                  -40%               -45%                   -46%                           -48%                        -50%         -50%                 -69%               -70%               -74%                    -83%               -86%              -91%              -92%              -94%                  -95% 
  Text::ASCIITable                4700/s                    2757%             614%               376%                    42%                           23%                --                  -26%               -32%                   -33%                           -35%                        -38%         -38%                 -61%               -63%               -67%                    -79%               -83%              -89%              -90%              -93%                  -94% 
  Text::TabularDisplay            6500/s                    3796%             874%               549%                    94%                           68%               36%                    --                -8%                    -9%                           -12%                        -15%         -15%                 -47%               -50%               -56%                    -71%               -77%              -85%              -87%              -91%                  -92% 
  Text::FormatTable               7070/s                    4155%             963%               609%                   112%                           84%               48%                    9%                 --                     0%                            -4%                         -7%          -7%                 -42%               -45%               -52%                    -68%               -75%              -84%              -86%              -90%                  -91% 
  Text::Table::Manifold           7300/s                    4185%             971%               614%                   114%                           85%               49%                    9%                 0%                     --                            -3%                         -7%          -7%                 -42%               -45%               -51%                    -68%               -75%              -84%              -86%              -90%                  -91% 
  Text::Table::HTML::DataTables   7410/s                    4344%            1011%               640%                   122%                           92%               55%                   14%                 4%                     3%                             --                         -3%          -3%                 -40%               -42%               -49%                    -67%               -74%              -83%              -85%              -90%                  -91% 
  Text::Table::TinyColorWide      7600/s                    4515%            1053%               669%                   130%                          100%               61%                   18%                 8%                     7%                             3%                          --           0%                 -38%               -40%               -48%                    -66%               -73%              -83%              -85%              -89%                  -91% 
  Text::Table                     7700/s                    4515%            1053%               669%                   130%                          100%               61%                   18%                 8%                     7%                             3%                          0%           --                 -38%               -40%               -48%                    -66%               -73%              -83%              -85%              -89%                  -91% 
  Text::MarkdownTable            12400/s                    7353%            1763%              1142%                   272%                          222%              160%                   91%                75%                    73%                            67%                         61%          61%                   --                -4%               -16%                    -45%               -57%              -72%              -76%              -83%                  -85% 
  Text::SimpleTable              13000/s                    7692%            1848%              1198%                   289%                          237%              172%                  100%                83%                    81%                            75%                         68%          68%                   4%                 --               -12%                    -42%               -55%              -71%              -74%              -82%                  -85% 
  Text::Table::Tiny              14800/s                    8775%            2118%              1379%                   343%                          284%              210%                  127%               108%                   107%                            99%                         92%          92%                  19%                13%                 --                    -34%               -49%              -67%              -71%              -80%                  -82% 
  Text::Table::TinyColor         22000/s                   13536%            3309%              2172%                   581%                          490%              377%                  250%               220%                   218%                           206%                        195%         195%                  82%                75%                53%                      --               -22%              -50%              -56%              -69%                  -73% 
  Text::Table::HTML              29000/s                   17547%            4311%              2841%                   782%                          664%              517%                  352%               314%                   311%                           297%                        282%         282%                 136%               126%                98%                     29%                 --              -35%              -43%              -60%                  -66% 
  Text::Table::CSV               45000/s                   27172%            6718%              4445%                  1263%                         1081%              854%                  600%               540%                   536%                           513%                        490%         490%                 265%               250%               207%                    100%                54%                --              -12%              -38%                  -47% 
  Text::Table::Org               51700/s                   30988%            7672%              5081%                  1454%                         1247%              988%                  697%               630%                   625%                           599%                        573%         573%                 317%               298%               250%                    127%                76%               13%                --              -30%                  -40% 
  Text::Table::Any               74100/s                   44344%           11011%              7307%                  2122%                         1825%             1455%                 1040%               944%                   937%                           900%                        862%         862%                 496%               470%               400%                    225%               151%               62%               42%                --                  -14% 
  Text::Table::Sprintf           86700/s                   52073%           12943%              8595%                  2508%                         2160%             1726%                 1239%              1126%                  1117%                          1073%                       1030%        1030%                 600%               569%               487%                    282%               195%               91%               67%               17%                    -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::SimpleTable: participant=Text::SimpleTable
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


Result formatted as table (split, part 4 of 5):

 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |       400 |   3       |                 0.00% |             81511.84% |   7e-05 |      20 |
 | Text::ANSITable               |      2000 |   0.6     |               345.42% |             18222.60% | 1.7e-05 |      20 |
 | Text::Table::More             |      3100 |   0.32    |               765.49% |              9329.53% | 1.4e-06 |      20 |
 | Text::Table::TinyBorderStyle  |      4500 |   0.22    |              1159.08% |              6381.86% | 9.5e-07 |      20 |
 | Text::Table::Manifold         |     14000 |   0.074   |              3687.92% |              2054.53% | 1.5e-07 |      20 |
 | Text::ASCIITable              |     18000 |   0.056   |              4864.62% |              1543.87% | 9.3e-08 |      21 |
 | Text::Table::HTML::DataTables |     19000 |   0.054   |              5093.75% |              1471.35% | 7.7e-08 |      21 |
 | Text::Table::TinyWide         |     20000 |   0.05    |              5409.22% |              1381.37% | 7.5e-07 |      20 |
 | Text::Table                   |     21300 |   0.0469  |              5845.42% |              1272.68% |   4e-08 |      20 |
 | Text::MarkdownTable           |     25000 |   0.04    |              6865.20% |              1071.71% | 1.5e-07 |      20 |
 | Text::TabularDisplay          |     30000 |   0.03    |              9444.99% |               755.02% | 1.4e-06 |      30 |
 | Text::FormatTable             |     35700 |   0.028   |              9856.57% |               719.68% | 2.7e-08 |      20 |
 | Text::Table::TinyColorWide    |     45400 |   0.022   |             12542.38% |               545.54% | 1.2e-08 |      20 |
 | Text::Table::Tiny             |     52400 |   0.0191  |             14513.24% |               458.48% | 1.7e-08 |      20 |
 | Text::Table::TinyColor        |     50000 |   0.02    |             15110.40% |               436.55% |   9e-07 |      25 |
 | Text::Table::HTML             |     62200 |   0.0161  |             17223.24% |               371.11% | 5.9e-09 |      22 |
 | Text::SimpleTable             |     64700 |   0.0154  |             17934.63% |               352.53% | 1.3e-08 |      20 |
 | Text::Table::Org              |    145000 |   0.00691 |             40228.25% |               102.37% |   2e-09 |      20 |
 | Text::Table::Any              |    191000 |   0.00525 |             52985.72% |                53.74% | 2.6e-09 |      20 |
 | Text::Table::Sprintf          |    272000 |   0.00367 |             75724.38% |                 7.63% | 1.7e-09 |      22 |
 | Text::Table::CSV              |    293000 |   0.00341 |             81511.84% |                 0.00% | 2.1e-09 |      21 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                     Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::Table::TinyBorderStyle  Text::Table::Manifold  Text::ASCIITable  Text::Table::HTML::DataTables  Text::Table::TinyWide  Text::Table  Text::MarkdownTable  Text::TabularDisplay  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyColor  Text::Table::Tiny  Text::Table::HTML  Text::SimpleTable  Text::Table::Org  Text::Table::Any  Text::Table::Sprintf  Text::Table::CSV 
  Text::UnicodeBox::Table           400/s                       --             -80%               -89%                          -92%                   -97%              -98%                           -98%                   -98%         -98%                 -98%                  -99%               -99%                        -99%                    -99%               -99%               -99%               -99%              -99%              -99%                  -99%              -99% 
  Text::ANSITable                  2000/s                     400%               --               -46%                          -63%                   -87%              -90%                           -91%                   -91%         -92%                 -93%                  -95%               -95%                        -96%                    -96%               -96%               -97%               -97%              -98%              -99%                  -99%              -99% 
  Text::Table::More                3100/s                     837%              87%                 --                          -31%                   -76%              -82%                           -83%                   -84%         -85%                 -87%                  -90%               -91%                        -93%                    -93%               -94%               -94%               -95%              -97%              -98%                  -98%              -98% 
  Text::Table::TinyBorderStyle     4500/s                    1263%             172%                45%                            --                   -66%              -74%                           -75%                   -77%         -78%                 -81%                  -86%               -87%                        -90%                    -90%               -91%               -92%               -93%              -96%              -97%                  -98%              -98% 
  Text::Table::Manifold           14000/s                    3954%             710%               332%                          197%                     --              -24%                           -27%                   -32%         -36%                 -45%                  -59%               -62%                        -70%                    -72%               -74%               -78%               -79%              -90%              -92%                  -95%              -95% 
  Text::ASCIITable                18000/s                    5257%             971%               471%                          292%                    32%                --                            -3%                   -10%         -16%                 -28%                  -46%               -50%                        -60%                    -64%               -65%               -71%               -72%              -87%              -90%                  -93%              -93% 
  Text::Table::HTML::DataTables   19000/s                    5455%            1011%               492%                          307%                    37%                3%                             --                    -7%         -13%                 -25%                  -44%               -48%                        -59%                    -62%               -64%               -70%               -71%              -87%              -90%                  -93%              -93% 
  Text::Table::TinyWide           20000/s                    5900%            1099%               540%                          339%                    47%               11%                             7%                     --          -6%                 -20%                  -40%               -44%                        -56%                    -60%               -61%               -67%               -69%              -86%              -89%                  -92%              -93% 
  Text::Table                     21300/s                    6296%            1179%               582%                          369%                    57%               19%                            15%                     6%           --                 -14%                  -36%               -40%                        -53%                    -57%               -59%               -65%               -67%              -85%              -88%                  -92%              -92% 
  Text::MarkdownTable             25000/s                    7400%            1400%               700%                          450%                    84%               39%                            34%                    25%          17%                   --                  -25%               -30%                        -45%                    -50%               -52%               -59%               -61%              -82%              -86%                  -90%              -91% 
  Text::TabularDisplay            30000/s                    9900%            1900%               966%                          633%                   146%               86%                            80%                    66%          56%                  33%                    --                -6%                        -26%                    -33%               -36%               -46%               -48%              -76%              -82%                  -87%              -88% 
  Text::FormatTable               35700/s                   10614%            2042%              1042%                          685%                   164%              100%                            92%                    78%          67%                  42%                    7%                 --                        -21%                    -28%               -31%               -42%               -44%              -75%              -81%                  -86%              -87% 
  Text::Table::TinyColorWide      45400/s                   13536%            2627%              1354%                          900%                   236%              154%                           145%                   127%         113%                  81%                   36%                27%                          --                     -9%               -13%               -26%               -29%              -68%              -76%                  -83%              -84% 
  Text::Table::TinyColor          50000/s                   14900%            2900%              1500%                         1000%                   270%              179%                           169%                   150%         134%                 100%                   50%                39%                          9%                      --                -4%               -19%               -23%              -65%              -73%                  -81%              -82% 
  Text::Table::Tiny               52400/s                   15606%            3041%              1575%                         1051%                   287%              193%                           182%                   161%         145%                 109%                   57%                46%                         15%                      4%                 --               -15%               -19%              -63%              -72%                  -80%              -82% 
  Text::Table::HTML               62200/s                   18533%            3626%              1887%                         1266%                   359%              247%                           235%                   210%         191%                 148%                   86%                73%                         36%                     24%                18%                 --                -4%              -57%              -67%                  -77%              -78% 
  Text::SimpleTable               64700/s                   19380%            3796%              1977%                         1328%                   380%              263%                           250%                   224%         204%                 159%                   94%                81%                         42%                     29%                24%                 4%                 --              -55%              -65%                  -76%              -77% 
  Text::Table::Org               145000/s                   43315%            8583%              4530%                         3083%                   970%              710%                           681%                   623%         578%                 478%                  334%               305%                        218%                    189%               176%               132%               122%                --              -24%                  -46%              -50% 
  Text::Table::Any               191000/s                   57042%           11328%              5995%                         4090%                  1309%              966%                           928%                   852%         793%                 661%                  471%               433%                        319%                    280%               263%               206%               193%               31%                --                  -30%              -35% 
  Text::Table::Sprintf           272000/s                   81643%           16248%              8619%                         5894%                  1916%             1425%                          1371%                  1262%        1177%                 989%                  717%               662%                        499%                    444%               420%               338%               319%               88%               43%                    --               -7% 
  Text::Table::CSV               293000/s                   87876%           17495%              9284%                         6351%                  2070%             1542%                          1483%                  1366%        1275%                1073%                  779%               721%                        545%                    486%               460%               372%               351%              102%               53%                    7%                -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::SimpleTable: participant=Text::SimpleTable
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
 | Text::UnicodeBox::Table       |        33 |   30      |                 0.00% |             40107.73% |   0.00028 |      20 |
 | Text::ANSITable               |        70 |   10      |               112.30% |             18838.85% |   0.00034 |      20 |
 | Text::Table::More             |       100 |    9      |               242.25% |             11648.22% |   0.00016 |      20 |
 | Text::ASCIITable              |       450 |    2.2    |              1269.60% |              2835.73% | 1.8e-05   |      21 |
 | Text::FormatTable             |       650 |    1.5    |              1867.35% |              1943.75% | 1.2e-05   |      20 |
 | Text::Table::TinyColorWide    |       830 |    1.2    |              2401.71% |              1507.21% | 3.5e-06   |      20 |
 | Text::Table::TinyBorderStyle  |       900 |    1      |              2611.90% |              1382.64% | 1.7e-05   |      20 |
 | Text::Table                   |      1200 |    0.87   |              3377.43% |              1056.25% | 1.5e-06   |      20 |
 | Text::Table::Tiny             |      1000 |    0.8    |              3482.31% |              1022.40% | 3.8e-05   |      29 |
 | Text::Table::TinyWide         |      1200 |    0.83   |              3524.20% |              1009.42% |   1e-06   |      20 |
 | Text::SimpleTable             |      1580 |    0.633  |              4667.39% |               743.39% | 5.8e-07   |      21 |
 | Text::Table::Manifold         |      1700 |    0.6    |              4936.57% |               698.32% | 7.9e-07   |      20 |
 | Text::TabularDisplay          |      2300 |    0.44   |              6812.25% |               481.69% | 7.1e-07   |      20 |
 | Text::Table::TinyColor        |      2900 |    0.35   |              8603.40% |               361.98% |   5e-07   |      20 |
 | Text::Table::HTML             |      3370 |    0.297  |             10075.60% |               295.14% | 1.7e-07   |      20 |
 | Text::MarkdownTable           |      3400 |    0.3    |             10085.88% |               294.74% | 3.2e-07   |      20 |
 | Text::Table::HTML::DataTables |      4100 |    0.24   |             12334.13% |               223.37% | 7.8e-07   |      20 |
 | Text::Table::Sprintf          |      5260 |    0.19   |             15772.29% |               153.32% | 5.1e-08   |      21 |
 | Text::Table::Org              |      7800 |    0.13   |             23583.00% |                69.77% | 2.8e-07   |      20 |
 | Text::Table::CSV              |     11000 |    0.088  |             34210.03% |                17.19% | 1.6e-07   |      20 |
 | Text::Table::Any              |     13300 |    0.0751 |             40107.73% |                 0.00% | 4.5e-08   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                                    Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyBorderStyle  Text::Table  Text::Table::TinyWide  Text::Table::Tiny  Text::SimpleTable  Text::Table::Manifold  Text::TabularDisplay  Text::Table::TinyColor  Text::MarkdownTable  Text::Table::HTML  Text::Table::HTML::DataTables  Text::Table::Sprintf  Text::Table::Org  Text::Table::CSV  Text::Table::Any 
  Text::UnicodeBox::Table           33/s                       --             -66%               -70%              -92%               -95%                        -96%                          -96%         -97%                   -97%               -97%               -97%                   -98%                  -98%                    -98%                 -99%               -99%                           -99%                  -99%              -99%              -99%              -99% 
  Text::ANSITable                   70/s                     200%               --                -9%              -78%               -85%                        -88%                          -90%         -91%                   -91%               -92%               -93%                   -94%                  -95%                    -96%                 -97%               -97%                           -97%                  -98%              -98%              -99%              -99% 
  Text::Table::More                100/s                     233%              11%                 --              -75%               -83%                        -86%                          -88%         -90%                   -90%               -91%               -92%                   -93%                  -95%                    -96%                 -96%               -96%                           -97%                  -97%              -98%              -99%              -99% 
  Text::ASCIITable                 450/s                    1263%             354%               309%                --               -31%                        -45%                          -54%         -60%                   -62%               -63%               -71%                   -72%                  -80%                    -84%                 -86%               -86%                           -89%                  -91%              -94%              -96%              -96% 
  Text::FormatTable                650/s                    1900%             566%               500%               46%                 --                        -20%                          -33%         -42%                   -44%               -46%               -57%                   -60%                  -70%                    -76%                 -80%               -80%                           -84%                  -87%              -91%              -94%              -94% 
  Text::Table::TinyColorWide       830/s                    2400%             733%               650%               83%                25%                          --                          -16%         -27%                   -30%               -33%               -47%                   -50%                  -63%                    -70%                 -75%               -75%                           -80%                  -84%              -89%              -92%              -93% 
  Text::Table::TinyBorderStyle     900/s                    2900%             900%               800%              120%                50%                         19%                            --         -13%                   -17%               -19%               -36%                   -40%                  -56%                    -65%                 -70%               -70%                           -76%                  -81%              -87%              -91%              -92% 
  Text::Table                     1200/s                    3348%            1049%               934%              152%                72%                         37%                           14%           --                    -4%                -8%               -27%                   -31%                  -49%                    -59%                 -65%               -65%                           -72%                  -78%              -85%              -89%              -91% 
  Text::Table::TinyWide           1200/s                    3514%            1104%               984%              165%                80%                         44%                           20%           4%                     --                -3%               -23%                   -27%                  -46%                    -57%                 -63%               -64%                           -71%                  -77%              -84%              -89%              -90% 
  Text::Table::Tiny               1000/s                    3650%            1150%              1025%              175%                87%                         49%                           25%           8%                     3%                 --               -20%                   -25%                  -45%                    -56%                 -62%               -62%                           -70%                  -76%              -83%              -89%              -90% 
  Text::SimpleTable               1580/s                    4639%            1479%              1321%              247%               136%                         89%                           57%          37%                    31%                26%                 --                    -5%                  -30%                    -44%                 -52%               -53%                           -62%                  -69%              -79%              -86%              -88% 
  Text::Table::Manifold           1700/s                    4900%            1566%              1400%              266%               150%                        100%                           66%          44%                    38%                33%                 5%                     --                  -26%                    -41%                 -50%               -50%                           -60%                  -68%              -78%              -85%              -87% 
  Text::TabularDisplay            2300/s                    6718%            2172%              1945%              400%               240%                        172%                          127%          97%                    88%                81%                43%                    36%                    --                    -20%                 -31%               -32%                           -45%                  -56%              -70%              -80%              -82% 
  Text::Table::TinyColor          2900/s                    8471%            2757%              2471%              528%               328%                        242%                          185%         148%                   137%               128%                80%                    71%                   25%                      --                 -14%               -15%                           -31%                  -45%              -62%              -74%              -78% 
  Text::MarkdownTable             3400/s                    9900%            3233%              2900%              633%               400%                        300%                          233%         190%                   176%               166%               111%                   100%                   46%                     16%                   --                -1%                           -19%                  -36%              -56%              -70%              -74% 
  Text::Table::HTML               3370/s                   10001%            3267%              2930%              640%               405%                        304%                          236%         192%                   179%               169%               113%                   102%                   48%                     17%                   1%                 --                           -19%                  -36%              -56%              -70%              -74% 
  Text::Table::HTML::DataTables   4100/s                   12400%            4066%              3650%              816%               525%                        400%                          316%         262%                   245%               233%               163%                   150%                   83%                     45%                  25%                23%                             --                  -20%              -45%              -63%              -68% 
  Text::Table::Sprintf            5260/s                   15689%            5163%              4636%             1057%               689%                        531%                          426%         357%                   336%               321%               233%                   215%                  131%                     84%                  57%                56%                            26%                    --              -31%              -53%              -60% 
  Text::Table::Org                7800/s                   22976%            7592%              6823%             1592%              1053%                        823%                          669%         569%                   538%               515%               386%                   361%                  238%                    169%                 130%               128%                            84%                   46%                --              -32%              -42% 
  Text::Table::CSV               11000/s                   33990%           11263%             10127%             2400%              1604%                       1263%                         1036%         888%                   843%               809%               619%                   581%                  400%                    297%                 240%               237%                           172%                  115%               47%                --              -14% 
  Text::Table::Any               13300/s                   39846%           13215%             11884%             2829%              1897%                       1497%                         1231%        1058%                  1005%               965%               742%                   698%                  485%                    366%                 299%               295%                           219%                  152%               73%               17%                -- 
 
 Legends:
   Text::ANSITable: participant=Text::ANSITable
   Text::ASCIITable: participant=Text::ASCIITable
   Text::FormatTable: participant=Text::FormatTable
   Text::MarkdownTable: participant=Text::MarkdownTable
   Text::SimpleTable: participant=Text::SimpleTable
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
 +-------------------------------+-----------+----------------------+-----------------------+-----------------------+-----------+---------+
 | participant                   | time (ms) |  mod_overhead_time   | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+----------------------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |     190   | 181                  |                 0.00% |              2053.49% |   0.00061 |      20 |
 | Text::Table::Manifold         |     110   | 101                  |                75.66% |              1125.93% |   0.00039 |      20 |
 | Text::ANSITable               |      48   |  39                  |               286.81% |               456.73% |   0.00026 |      20 |
 | Text::MarkdownTable           |      46   |  37                  |               301.84% |               435.91% |   0.00031 |      21 |
 | Text::Table::TinyColorWide    |      40   |  31                  |               366.96% |               361.18% |   0.00029 |      20 |
 | Text::Table::TinyWide         |      36   |  27                  |               413.28% |               319.56% |   0.00014 |      22 |
 | Text::Table::More             |      28   |  19                  |               553.94% |               229.31% |   0.00019 |      20 |
 | Text::Table                   |      28   |  19                  |               568.31% |               222.23% |   0.00027 |      20 |
 | Text::ASCIITable              |      20   |  11                  |               781.19% |               144.38% |   0.00028 |      20 |
 | Text::Table::Tiny             |      21   |  12                  |               795.31% |               140.53% |   0.00017 |      20 |
 | Text::Table::TinyColor        |      20   |  11                  |               951.17% |               104.87% |   0.00042 |      21 |
 | Text::FormatTable             |      17   |   8                  |               988.23% |                97.89% |   0.00017 |      20 |
 | Text::Table::Any              |      10   |   1                  |              1195.57% |                66.22% |   0.00021 |      20 |
 | Text::Table::TinyBorderStyle  |      10   |   1                  |              1201.51% |                65.46% |   0.00019 |      21 |
 | Text::TabularDisplay          |      10   |   1                  |              1342.19% |                49.32% |   0.0002  |      20 |
 | Text::Table::Org              |      10   |   1                  |              1396.46% |                43.91% |   0.0002  |      20 |
 | Text::Table::HTML             |      10   |   1                  |              1400.52% |                43.52% |   0.00019 |      20 |
 | Text::SimpleTable             |      12   |   3                  |              1421.63% |                41.53% |   0.00011 |      20 |
 | Text::Table::HTML::DataTables |      10   |   1                  |              1463.78% |                37.71% |   0.00012 |      20 |
 | Text::Table::Sprintf          |       9.1 |   0.0999999999999996 |              1954.13% |                 4.84% | 7.3e-05   |      20 |
 | Text::Table::CSV              |       8.7 |  -0.300000000000001  |              2029.97% |                 1.10% | 3.8e-05   |      20 |
 | perl -e1 (baseline)           |       9   |   0                  |              2053.49% |                 0.00% | 8.9e-05   |      20 |
 +-------------------------------+-----------+----------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                    Rate  Text::UnicodeBox::Table  Text::Table::Manifold  Text::ANSITable  Text::MarkdownTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::Table::More  Text::Table  Text::Table::Tiny  Text::ASCIITable  Text::Table::TinyColor  Text::FormatTable  Text::SimpleTable  Text::Table::Any  Text::Table::TinyBorderStyle  Text::TabularDisplay  Text::Table::Org  Text::Table::HTML  Text::Table::HTML::DataTables  Text::Table::Sprintf  perl -e1 (baseline)  Text::Table::CSV 
  Text::UnicodeBox::Table          5.3/s                       --                   -42%             -74%                 -75%                        -78%                   -81%               -85%         -85%               -88%              -89%                    -89%               -91%               -93%              -94%                          -94%                  -94%              -94%               -94%                           -94%                  -95%                 -95%              -95% 
  Text::Table::Manifold            9.1/s                      72%                     --             -56%                 -58%                        -63%                   -67%               -74%         -74%               -80%              -81%                    -81%               -84%               -89%              -90%                          -90%                  -90%              -90%               -90%                           -90%                  -91%                 -91%              -92% 
  Text::ANSITable                 20.8/s                     295%                   129%               --                  -4%                        -16%                   -25%               -41%         -41%               -56%              -58%                    -58%               -64%               -75%              -79%                          -79%                  -79%              -79%               -79%                           -79%                  -81%                 -81%              -81% 
  Text::MarkdownTable             21.7/s                     313%                   139%               4%                   --                        -13%                   -21%               -39%         -39%               -54%              -56%                    -56%               -63%               -73%              -78%                          -78%                  -78%              -78%               -78%                           -78%                  -80%                 -80%              -81% 
  Text::Table::TinyColorWide      25.0/s                     375%                   175%              19%                  14%                          --                    -9%               -30%         -30%               -47%              -50%                    -50%               -57%               -70%              -75%                          -75%                  -75%              -75%               -75%                           -75%                  -77%                 -77%              -78% 
  Text::Table::TinyWide           27.8/s                     427%                   205%              33%                  27%                         11%                     --               -22%         -22%               -41%              -44%                    -44%               -52%               -66%              -72%                          -72%                  -72%              -72%               -72%                           -72%                  -74%                 -75%              -75% 
  Text::Table::More               35.7/s                     578%                   292%              71%                  64%                         42%                    28%                 --           0%               -25%              -28%                    -28%               -39%               -57%              -64%                          -64%                  -64%              -64%               -64%                           -64%                  -67%                 -67%              -68% 
  Text::Table                     35.7/s                     578%                   292%              71%                  64%                         42%                    28%                 0%           --               -25%              -28%                    -28%               -39%               -57%              -64%                          -64%                  -64%              -64%               -64%                           -64%                  -67%                 -67%              -68% 
  Text::Table::Tiny               47.6/s                     804%                   423%             128%                 119%                         90%                    71%                33%          33%                 --               -4%                     -4%               -19%               -42%              -52%                          -52%                  -52%              -52%               -52%                           -52%                  -56%                 -57%              -58% 
  Text::ASCIITable                50.0/s                     850%                   450%             140%                 129%                        100%                    80%                39%          39%                 5%                --                      0%               -15%               -40%              -50%                          -50%                  -50%              -50%               -50%                           -50%                  -54%                 -55%              -56% 
  Text::Table::TinyColor          50.0/s                     850%                   450%             140%                 129%                        100%                    80%                39%          39%                 5%                0%                      --               -15%               -40%              -50%                          -50%                  -50%              -50%               -50%                           -50%                  -54%                 -55%              -56% 
  Text::FormatTable               58.8/s                    1017%                   547%             182%                 170%                        135%                   111%                64%          64%                23%               17%                     17%                 --               -29%              -41%                          -41%                  -41%              -41%               -41%                           -41%                  -46%                 -47%              -48% 
  Text::SimpleTable               83.3/s                    1483%                   816%             300%                 283%                        233%                   200%               133%         133%                75%               66%                     66%                41%                 --              -16%                          -16%                  -16%              -16%               -16%                           -16%                  -24%                 -25%              -27% 
  Text::Table::Any               100.0/s                    1800%                  1000%             380%                 359%                        300%                   260%               179%         179%               110%              100%                    100%                70%                19%                --                            0%                    0%                0%                 0%                             0%                   -9%                  -9%              -13% 
  Text::Table::TinyBorderStyle   100.0/s                    1800%                  1000%             380%                 359%                        300%                   260%               179%         179%               110%              100%                    100%                70%                19%                0%                            --                    0%                0%                 0%                             0%                   -9%                  -9%              -13% 
  Text::TabularDisplay           100.0/s                    1800%                  1000%             380%                 359%                        300%                   260%               179%         179%               110%              100%                    100%                70%                19%                0%                            0%                    --                0%                 0%                             0%                   -9%                  -9%              -13% 
  Text::Table::Org               100.0/s                    1800%                  1000%             380%                 359%                        300%                   260%               179%         179%               110%              100%                    100%                70%                19%                0%                            0%                    0%                --                 0%                             0%                   -9%                  -9%              -13% 
  Text::Table::HTML              100.0/s                    1800%                  1000%             380%                 359%                        300%                   260%               179%         179%               110%              100%                    100%                70%                19%                0%                            0%                    0%                0%                 --                             0%                   -9%                  -9%              -13% 
  Text::Table::HTML::DataTables  100.0/s                    1800%                  1000%             380%                 359%                        300%                   260%               179%         179%               110%              100%                    100%                70%                19%                0%                            0%                    0%                0%                 0%                             --                   -9%                  -9%              -13% 
  Text::Table::Sprintf           109.9/s                    1987%                  1108%             427%                 405%                        339%                   295%               207%         207%               130%              119%                    119%                86%                31%                9%                            9%                    9%                9%                 9%                             9%                    --                  -1%               -4% 
  perl -e1 (baseline)            111.1/s                    2011%                  1122%             433%                 411%                        344%                   300%               211%         211%               133%              122%                    122%                88%                33%               11%                           11%                   11%               11%                11%                            11%                    1%                   --               -3% 
  Text::Table::CSV               114.9/s                    2083%                  1164%             451%                 428%                        359%                   313%               221%         221%               141%              129%                    129%                95%                37%               14%                           14%                   14%               14%                14%                            14%                    4%                   3%                -- 
 
 Legends:
   Text::ANSITable: mod_overhead_time=39 participant=Text::ANSITable
   Text::ASCIITable: mod_overhead_time=11 participant=Text::ASCIITable
   Text::FormatTable: mod_overhead_time=8 participant=Text::FormatTable
   Text::MarkdownTable: mod_overhead_time=37 participant=Text::MarkdownTable
   Text::SimpleTable: mod_overhead_time=3 participant=Text::SimpleTable
   Text::Table: mod_overhead_time=19 participant=Text::Table
   Text::Table::Any: mod_overhead_time=1 participant=Text::Table::Any
   Text::Table::CSV: mod_overhead_time=-0.300000000000001 participant=Text::Table::CSV
   Text::Table::HTML: mod_overhead_time=1 participant=Text::Table::HTML
   Text::Table::HTML::DataTables: mod_overhead_time=1 participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: mod_overhead_time=101 participant=Text::Table::Manifold
   Text::Table::More: mod_overhead_time=19 participant=Text::Table::More
   Text::Table::Org: mod_overhead_time=1 participant=Text::Table::Org
   Text::Table::Sprintf: mod_overhead_time=0.0999999999999996 participant=Text::Table::Sprintf
   Text::Table::Tiny: mod_overhead_time=12 participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: mod_overhead_time=1 participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: mod_overhead_time=11 participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: mod_overhead_time=31 participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: mod_overhead_time=27 participant=Text::Table::TinyWide
   Text::TabularDisplay: mod_overhead_time=1 participant=Text::TabularDisplay
   Text::UnicodeBox::Table: mod_overhead_time=181 participant=Text::UnicodeBox::Table
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

=item * L</Text::SimpleTable>

 .-----------+-----------+-----------.
 | col1      | col2      | col3      |
 +-----------+-----------+-----------+
 | row1.1    | row1.2    | row1.3    |
 | row2.1    | row2.2    | row2.3    |
 | row3.1    | row3.2    | row3.3    |
 | row4.1    | row4.2    | row4.3    |
 | row5.1    | row5.2    | row5.3    |
 '-----------+-----------+-----------'

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
 <link rel="stylesheet" type="text/css" href="file:///home/u1/perl5/perlbrew/perls/perl-5.38.0/lib/site_perl/5.38.0/auto/share/dist/Text-Table-HTML-DataTables/datatables-1.10.22/datatables.css">
 <script src="file:///home/u1/perl5/perlbrew/perls/perl-5.38.0/lib/site_perl/5.38.0/auto/share/dist/Text-Table-HTML-DataTables/jquery-2.2.4/jquery-2.2.4.min.js"></script>
 <script src="file:///home/u1/perl5/perlbrew/perls/perl-5.38.0/lib/site_perl/5.38.0/auto/share/dist/Text-Table-HTML-DataTables/datatables-1.10.22/datatables.js"></script>
 <script>var dt_opts = {"buttons":["colvis","print"],"dom":"lQfrtip"}; $(document).ready(function() { $("table").DataTable(dt_opts); $("select[name=DataTables_Table_0_length]").val(1000); $("select[name=DataTables_Table_0_length]").trigger("change"); });</script>
 
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
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-TextTable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-TextTable>.

=head1 SEE ALSO

Related lists: L<Acme::CPANModules::HTMLTable>,
L<Acme::CPANModules::BrowsingTableInteractively>.

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023, 2021, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-TextTable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
