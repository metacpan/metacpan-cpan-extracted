package Acme::CPANModules::TextTable;

use 5.010001;
use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-15'; # DATE
our $DIST = 'Acme-CPANModules-TextTable'; # DIST
our $VERSION = '0.015'; # VERSION

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
# ABSTRACT: Modules that generate text tables

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::TextTable - Modules that generate text tables

=head1 VERSION

This document describes version 0.015 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2023-06-15.

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
 | Text::Table::Any              | N/A *22)       | N/A *23)         | N/A *24)      | N/A *25)     | N/A *26)       | N/A *27)        | N/A *28)    | N/A *29)          | N/A *30)         | N/A *31)            | N/A *32)     | N/A *33)   | N/A *34)         | N/A *35)           | N/A *36)        | N/A *37)       | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::SimpleTable             | no             | no               | no            | no           | no             | no              | no          | yes *38)          | no               | no                  | no           | yes *39)   | no               | no                 | no              | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::UnicodeBox::Table       | no             | yes              | N/A           | no           | yes            | no              | no          | yes               | no               | no                  | no           | yes        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::Manifold         | no             | yes              | N/A           | N/A          | yes            | no              | no          | no *40)           | no               | no                  | no           | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::ANSITable               | yes            | yes              | yes           | yes          | yes            | yes             | no          | yes               | yes              | yes                 | no           | yes        | yes              | yes                | yes             | yes            | yes               | yes      | yes                   | yes                 | yes             | yes       |
 | Text::ASCIITable              | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::FormatTable             | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::MarkdownTable           | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | no *41)             | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table                   | N/A            | N/A              | N/A           | N/A *42)     | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::Tiny             | N/A            | N/A              | N/A           | yes          | yes            | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyBorderStyle  | N/A            | N/A              | N/A           | yes          | no             | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::More             | yes            | yes              | yes           | yes          | yes            | no              | yes         | yes               | no               | yes                 | yes          | yes        | yes              | yes                | yes             | yes            | no                | no       | no                    | no                  | no              | no        |
 | Text::Table::Sprintf          | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | yes *43)   | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyColor        | N/A            | N/A              | N/A           | no           | yes            | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyColorWide    | N/A            | N/A              | N/A           | no           | yes            | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::TinyWide         | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | N/A                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::Org              | N/A            | N/A              | N/A           | no           | no             | N/A             | N/A         | N/A               | N/A              | no                  | N/A          | N/A        | N/A              | N/A                | N/A             | no             | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::CSV              | N/A            | N/A              | N/A           | N/A *44)     | no             | N/A             | N/A         | N/A               | N/A              | yes *45)            | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::HTML             | N/A            | N/A              | N/A           | no           | no *46)        | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::Table::HTML::DataTables | N/A            | N/A              | N/A           | no           | no *47)        | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
 | Text::TabularDisplay          | N/A            | N/A              | N/A           | N/A *48)     | no             | N/A             | N/A         | N/A               | N/A              | yes                 | N/A          | N/A        | N/A              | N/A                | N/A             | yes            | N/A               | N/A      | N/A                   | N/A                 | N/A             | N/A       |
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

=item 23. Depends on backend

=item 24. Depends on backend

=item 25. Depends on backend

=item 26. Depends on backend

=item 27. Depends on backend

=item 28. Depends on backend

=item 29. Depends on backend

=item 30. Depends on backend

=item 31. Depends on backend

=item 32. Depends on backend

=item 33. Depends on backend

=item 34. Depends on backend

=item 35. Depends on backend

=item 36. Depends on backend

=item 37. Depends on backend

=item 38. Limited choice of 1 ASCII style and 1 UTF style

=item 39. Slightly slower than Text::Table::Tiny

=item 40. But this module can pass rendering to other module like Text::UnicodeBox::Table

=item 41. Newlines stripped

=item 42. Does not draw borders

=item 43. The fastest among the others in this list

=item 44. Irrelevant

=item 45. But make sure your CSV parser can handle multiline cell

=item 46. Not converted to HTML color elements

=item 47. Not converted to HTML color elements

=item 48. Irrelevant

=back

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Table::Any> 0.114

L<Text::SimpleTable> 2.07

L<Text::UnicodeBox::Table>

L<Text::Table::Manifold> 1.03

L<Text::ANSITable> 0.608

L<Text::ASCIITable> 0.22

L<Text::FormatTable> 1.03

L<Text::MarkdownTable> 0.3.1

L<Text::Table> 1.134

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher --cpanmodules-module TextTable >>):

 #table1#
 {dataset=>"large (30x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |       1   |     980   |                 0.00% |             32984.80% |   0.0085  |      20 |
 | Text::ANSITable               |       2   |     500   |               106.59% |             15914.37% |   0.0054  |      20 |
 | Text::Table::More             |       2.8 |     350   |               175.52% |             11908.00% |   0.0018  |      20 |
 | Text::ASCIITable              |      10   |     100   |               883.88% |              3262.69% |   0.001   |      20 |
 | Text::FormatTable             |      16   |      63   |              1456.20% |              2025.99% |   0.00023 |      23 |
 | Text::Table::TinyColorWide    |      20   |      60   |              1485.47% |              1986.75% |   0.00071 |      20 |
 | Text::Table::TinyWide         |      20   |      40   |              2164.65% |              1360.92% |   0.00047 |      20 |
 | Text::SimpleTable             |      33   |      31   |              3074.33% |               942.26% | 3.5e-05   |      21 |
 | Text::Table::Manifold         |      30   |      30   |              3114.15% |               929.35% |   0.00068 |      20 |
 | Text::Table::Tiny             |      38   |      26   |              3638.79% |               784.91% |   0.00014 |      20 |
 | Text::TabularDisplay          |      47   |      21   |              4511.67% |               617.41% | 4.7e-05   |      23 |
 | Text::Table::HTML             |      58   |      17   |              5520.76% |               488.62% | 3.8e-05   |      20 |
 | Text::Table::TinyColor        |      60   |      20   |              5578.82% |               482.60% |   0.00024 |      20 |
 | Text::MarkdownTable           |      70   |      10   |              6860.53% |               375.32% |   0.00018 |      20 |
 | Text::Table                   |      80   |      10   |              7859.90% |               315.64% |   0.00013 |      20 |
 | Text::Table::HTML::DataTables |     130   |       7.8 |             12361.49% |               165.50% | 1.3e-05   |      20 |
 | Text::Table::Org              |     200   |       6   |             14923.75% |               120.22% |   0.00029 |      21 |
 | Text::Table::TinyBorderStyle  |     220   |       4.6 |             21244.12% |                55.01% | 1.2e-05   |      20 |
 | Text::Table::CSV              |     220   |       4.5 |             21542.65% |                52.87% | 9.4e-06   |      20 |
 | Text::Table::Any              |     300   |       3   |             30477.53% |                 8.20% | 8.4e-05   |      20 |
 | Text::Table::Sprintf          |     300   |       3   |             32984.80% |                 0.00% | 4.1e-05   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                  Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::SimpleTable  Text::Table::Manifold  Text::Table::Tiny  Text::TabularDisplay  Text::Table::TinyColor  Text::Table::HTML  Text::MarkdownTable  Text::Table  Text::Table::HTML::DataTables  Text::Table::Org  Text::Table::TinyBorderStyle  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table          1/s                       --             -48%               -64%              -89%               -93%                        -93%                   -95%               -96%                   -96%               -97%                  -97%                    -97%               -98%                 -98%         -98%                           -99%              -99%                          -99%              -99%              -99%                  -99% 
  Text::ANSITable                  2/s                      96%               --               -30%              -80%               -87%                        -88%                   -92%               -93%                   -94%               -94%                  -95%                    -96%               -96%                 -98%         -98%                           -98%              -98%                          -99%              -99%              -99%                  -99% 
  Text::Table::More              2.8/s                     179%              42%                 --              -71%               -82%                        -82%                   -88%               -91%                   -91%               -92%                  -94%                    -94%               -95%                 -97%         -97%                           -97%              -98%                          -98%              -98%              -99%                  -99% 
  Text::ASCIITable                10/s                     880%             400%               250%                --               -37%                        -40%                   -60%               -69%                   -70%               -74%                  -79%                    -80%               -83%                 -90%         -90%                           -92%              -94%                          -95%              -95%              -97%                  -97% 
  Text::FormatTable               16/s                    1455%             693%               455%               58%                 --                         -4%                   -36%               -50%                   -52%               -58%                  -66%                    -68%               -73%                 -84%         -84%                           -87%              -90%                          -92%              -92%              -95%                  -95% 
  Text::Table::TinyColorWide      20/s                    1533%             733%               483%               66%                 5%                          --                   -33%               -48%                   -50%               -56%                  -65%                    -66%               -71%                 -83%         -83%                           -87%              -90%                          -92%              -92%              -95%                  -95% 
  Text::Table::TinyWide           20/s                    2350%            1150%               775%              150%                57%                         50%                     --               -22%                   -25%               -35%                  -47%                    -50%               -57%                 -75%         -75%                           -80%              -85%                          -88%              -88%              -92%                  -92% 
  Text::SimpleTable               33/s                    3061%            1512%              1029%              222%               103%                         93%                    29%                 --                    -3%               -16%                  -32%                    -35%               -45%                 -67%         -67%                           -74%              -80%                          -85%              -85%              -90%                  -90% 
  Text::Table::Manifold           30/s                    3166%            1566%              1066%              233%               110%                        100%                    33%                 3%                     --               -13%                  -30%                    -33%               -43%                 -66%         -66%                           -74%              -80%                          -84%              -85%              -90%                  -90% 
  Text::Table::Tiny               38/s                    3669%            1823%              1246%              284%               142%                        130%                    53%                19%                    15%                 --                  -19%                    -23%               -34%                 -61%         -61%                           -70%              -76%                          -82%              -82%              -88%                  -88% 
  Text::TabularDisplay            47/s                    4566%            2280%              1566%              376%               200%                        185%                    90%                47%                    42%                23%                    --                     -4%               -19%                 -52%         -52%                           -62%              -71%                          -78%              -78%              -85%                  -85% 
  Text::Table::TinyColor          60/s                    4800%            2400%              1650%              400%               215%                        200%                   100%                55%                    50%                30%                    5%                      --               -15%                 -50%         -50%                           -61%              -70%                          -77%              -77%              -85%                  -85% 
  Text::Table::HTML               58/s                    5664%            2841%              1958%              488%               270%                        252%                   135%                82%                    76%                52%                   23%                     17%                 --                 -41%         -41%                           -54%              -64%                          -72%              -73%              -82%                  -82% 
  Text::MarkdownTable             70/s                    9700%            4900%              3400%              900%               530%                        500%                   300%               210%                   200%               160%                  110%                    100%                70%                   --           0%                           -21%              -40%                          -54%              -55%              -70%                  -70% 
  Text::Table                     80/s                    9700%            4900%              3400%              900%               530%                        500%                   300%               210%                   200%               160%                  110%                    100%                70%                   0%           --                           -21%              -40%                          -54%              -55%              -70%                  -70% 
  Text::Table::HTML::DataTables  130/s                   12464%            6310%              4387%             1182%               707%                        669%                   412%               297%                   284%               233%                  169%                    156%               117%                  28%          28%                             --              -23%                          -41%              -42%              -61%                  -61% 
  Text::Table::Org               200/s                   16233%            8233%              5733%             1566%               950%                        900%                   566%               416%                   400%               333%                  250%                    233%               183%                  66%          66%                            30%                --                          -23%              -25%              -50%                  -50% 
  Text::Table::TinyBorderStyle   220/s                   21204%           10769%              7508%             2073%              1269%                       1204%                   769%               573%                   552%               465%                  356%                    334%               269%                 117%         117%                            69%               30%                            --               -2%              -34%                  -34% 
  Text::Table::CSV               220/s                   21677%           11011%              7677%             2122%              1300%                       1233%                   788%               588%                   566%               477%                  366%                    344%               277%                 122%         122%                            73%               33%                            2%                --              -33%                  -33% 
  Text::Table::Any               300/s                   32566%           16566%             11566%             3233%              2000%                       1900%                  1233%               933%                   900%               766%                  600%                    566%               466%                 233%         233%                           160%              100%                           53%               50%                --                    0% 
  Text::Table::Sprintf           300/s                   32566%           16566%             11566%             3233%              2000%                       1900%                  1233%               933%                   900%               766%                  600%                    566%               466%                 233%         233%                           160%              100%                           53%               50%                0%                    -- 
 
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

=for html <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAQVQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAQFgAfEQAYBgAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFgAfJQA1EwAbAAAAAAAAlADUlQDVlADUlQDWAAAAAAAAlADUlADUlADUlADUlQDVlQDVAAAAlQDVlADUlQDWlQDVlADVlADUlADVlADVlADUlQDVlADUMQBGVgB7PABWAAAAawCZMABFWAB+ZgCTYQCLaQCXRwBmTgBwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJwA5lADUbQCb////zx6WAgAAAFJ0Uk5TABFEZiK7Vcwzd4jdme6qcM7Vx87V0srSP4n69uzx+fb99fR1iOzfddpOEUQzIvWnvo7HXGn0Zrd61p/xzXWntvmZz+3g9LS+n1AggDBgW6ZAl3eplasAAAABYktHRACIBR1IAAAACXBIWXMAAABIAAAASABGyWs+AAAAB3RJTUUH5wYPEQcgeX0bJAAAK5VJREFUeNrtnQm/7Dh61r2WXV6qQwiEIQRCmplk0tPTQwhLCBCSkIUhE8Ak3/+roN3a7aryUtZ5/r/uW+ceXats6ZH06tUrOcsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD7khfihyLXf128kBUAZ1FW8qdiEj9Muoar6bn8ADiVWqnXJ+jq1kDQ4EK0zb3Kyq4rqKAr9skEXXRdS34sawgaXImyH4q677qxJIIeh2HqmKDvYzdMJf0HBQQNrgQxOWpiRncPIt17lt2nigi6mkj3XI40HYIGl4LZ0O2tqYV0Sfc8FWVfEKiqIWhwLYigu6keainokQq6G2sKBA0uR13cRmpyUEHnWZazHvrWZ9IvDUGDS1HfSqLenJkcAxF2T62OnMwR2Y8QNLgYj/6bpq/7YSyLpun7sWVmdDk2Df0RggYXIy+qrCjyrKArhoVa9c4LcwEcAAAAAAAAAAAAAAAAAAAAgA+iEPvh2lz/AOCSlOM01UTDVTPRsBrxAcA1oRFheUMkXD/yqu/kBwDXhIWBdXXGtgvdG/Fx9l0B8A6PBxd2MYmPs28IgNep+z7PSq7kb/iHmhf+2j9i/DoAa/nHvyH5J26iSvuNf2on/SaT2m/+s7cFXZTEaL5zJf+If6hzgKZ//luUf+Hjt/2/5vzLSNpv/fZlLoylvfz8iRfcv/p/kt9xE39HJf5rO+l3mdSmbzfoo29TyOSIZV/E5o51JK0rLnNhLO3l50+84P7N30t+7Cb+RCX+nv/qdwXd0bsiCq5or1z24mNV9onXy2IaBO3/9bmCZsdGDETBdcf+Fx9rsk+8XhbTIGj/r88VdDZMNdvT2Y5N3+TyY032idfLYhoE7f/1yYLOqoLfdM4/xceK7BOvl8U0CNr/67MFHSWWfRV72DKSVlSXuTCW9vLzJ15wlxU0AD4gaJAUEDRICggaJAUEDZICggZJAUGDpICgQVJA0CApIGiQFBA0SAoIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKSBokBQQNEgKCBokBQQNkgKCBkkBQYOkgKBBUkDQICkgaJAUEDRICggaJAUEDZICggZJAUGDpICgQVJA0CApIGiQFBA0SAoIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKU4XdGu+LbTNtb9A0OBZThZ0209T32ZZNxHqrGqmadgwe/DlOFnQ45DlQ59lj6EoijarH3nVzy9Xh6DBs5wr6GIiFkY1ESWzV5HTn7J7s1n24OtxrqDzIqOqrrKp7LqC/MT+uln24Otx+qSQ2M3Eap76bpjKkgtazQshaPAsZws67yZiM1cdEfF9vHNBK7/H9Ps15ewyAhfiVUF3TGrvezmaupU/59O3MDnAm5zcQ/fcSVfQOWE1/ZR2zmW/Xfbgy3GuoG9TQSG9MumnhyariflRw20HXudcQbP1lGmiP9R932bt2PTNvFYIQYNnOXtSKKkK6sHLcv6xefbgq/Apgj4je5AgEDRICggaJAUEDZICggZJAUGDpICgQVJA0CApIGiQFBA0SAoIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKSBokBQQNEgKCBokBQQNkgKCBkkBQYOkgKBBUkDQICkgaJAUEDRICggafCJ/8J3CTfyZSvveSYOgwSfynZLez93EWZc/OGkQNPhEvlunSwgaXAMIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKSBokBQQNEgKCBokBQQNkgKCBkkBQYOkuK6g20p85vrHZtmDa3JVQbf9NPVtllXNNA3qY7PswVW5qqDHIcuHPsvqR171nfzYLHtwVS4q6GIiFkY1teS/LLs34mOz7MFluaig8yKjqq6KiX2Kj82yB5flooKmVM2QlVzJ3/APNS+EoL8slxV03k3EZr5zJf+If1Qq+190lNNKFezKv/1Dyb9z0g4XdMmk9r6Xo6mJ2ZyFTI6hoBxczuAgYro8XNAtk9rbgu65k66ivXLZiw+VCpMjaT5K0Jx3FXebRBdcd+x/8bFV9uCjSVDQ3cQgHf7Y9E0uP7bKHnw0CQp6Juemcm5YzBB00iQt6DOyB+cCQYOkgKBBUkDQICkgaJAUEDRICggaJAUEDZICggZJAUGDpICgQVJA0CApIGiQFBA0SAoIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKSBokBQQNEgKCBokBQQNkgKCBkkBQYOkgKBBUkDQICkgaJAUEDRICggaJAUEDZICggZJAUGDpICgQVJA0CApIGiQFBcWdNu+9MQQdNJcVtDlONVF/4KmIeikuaqg26ks6rwb8xX/9oXswVW5qqC7ISvqLGuefwk9BJ00lxV0B0EDD1cVdDG2RNAlTA5gclVBZ/epH/uxDKSaHXeryx6CTprLCjqryu4W6p+rif7ZTYQ6q5ppGp7OHlyTqwq64n1wWfnSbg0T9GMoiqLN6kde9d1z2YOrck1BV8WdirW49b5JYVlzQdfMIKmmlhgozTPZg+tyTUETyfY15eE3Ogom6KnsuoL/zH+xNntwXa4paDLPK2OpQtB9N0xlyQWtlD+xvv15dx+4BB8l6JZJ7Zku1GtDC0FXHRHxfbxzQat/OP2io5xQ1uAAPkrQJZPayliOBzU5Rn9PO1sY+fQtTI6vxEcJmrNyYaVr6q4ZAqlMxNQqqaaf0s657J/LHlyVqwqa2Ay3Icv7yKSwoO6NoclqYl7UcNt9ES4s6LYmQo2ZHN1U932btWPTN/lz2YOrclVBl32VEVuij3orKu7MyA2fBgSdNFcVdFbXWTf2zZp/+kr24KJcVdBsxncrnw+2g6DT5qqCvr/QNz+RPbgqVxV0NnQvLvhB0ElzVUEXE+f5J4agk+aqgn4dCDppIGiQFBA0SAoIGiQFBA2SAoIGSQFBg6SAoEFSQNAgKSBokBQQNLga3/+gcBMhaHA1Zl3+vZsIQYOrAUEfmT3YHQj6yOzB7kDQR2YPdgeCPjJ7sDsQ9JHZg92BoI/MHuwOBH1k9mB3IOgjswe7A0EfmT3YHQj6yOzB7kDQR2YPdgeCPjJ7sDsQ9JHZg92BoI/MHuwOBH1k9mB3IOgjswe7A0EfmT3YHQj6yOzB7kDQR2YPdgeCPjJ7sDsQ9JHZg92BoI/MHuwOBH1k9mB3IOgjswe78xUFLV731ub6x3bZgzP5goKu2OveqmaaBvWxYfbgVL6coKtbwwRdP/Kq7+THZtmDk/lygi5rJuhqaukrlMXHdtmDk/lygqbvmZ3/mH/eLHtwKl9V0CVX8jf8Q80LIeir81UFfedK/hH/qFT2v19T9iptsDvXEXTHpAaTA0S5jqA5Wwm6or1y2YuPLbMHp/JVBZ3VHftffGyYPTiVLyvodmz6JpcfG2YPTuULClqQF4X2sXn24By+rqDPyB7sDgR9ZPZgdyDoI7MHuwNBH5k92B0I+sjswe5A0EdmD3YHgj4ye7A7EPSR2YPdgaCPzB7sDgR9ZPZgdyDoI7MHuwNBH5k92B0I+sjswe5A0EdmD3YHgj4ye7A7EPSR2YPdgaCPzB5swqySP3TSIOgjswebAEGvBoK+AhD0aiDoKwBBrwaCvgIQ9Gog6CsAQa8Ggr4CEPRqIOgrAEGvBoK+AhD0aiDoKwBBrwaC/hS+U/yBkwZBrwaC/hR+rpTwnZMGQa8Ggv4UfgxBbwEE/SlA0JsAQX8KEPQmQNCfAgS9CRD0pwBBbwIE/SlA0JsAQX8KEPQmQNCfAgS9CRD0pwBBbwIEvTGxFewoEPQmQNAbE1vBjgJBbwIEvTExXX6veu+fPXchBL0aCHpjYrr8QaX95LkLIejVQNAbA0FD0EkBQR8u6DbX/gJBbwwEfZSgu4lQZ1UzTcMO2QMOBH2UoB9DURRtVj/yqu+2zx5wIOijBF2X9M9qarPs3myfPeBA0EcJeiq7rsiKifzI/tg4e8CBoA8TdN8NU1lyQat54fSLjrLRdwAIOizokkltK0FXHRHxfbxzQVfy1xO1rItim+8AEHRE0C2T2qY2QT59C5NjXyDog0yOgs4Jq+mntHMu+82z/0q8HJIBQWcbCpq6N4Ymq4m9XMNt9w4v6xKCzjZdWKn7vs3asembea0Qgn4eCPojBJ1VfO6XG1NACPp5IOjPEPQZ2ScJBA1BJwUEDUEnBQQNQScFBA1BJwUEDUEnBQQNQV+OP/o9iXu8BgQNQV+O2PEaEDQEfTl20SUEnUHQJwFBQ9BJAUFD0EkBQUPQn8i//7Hg53/03IUQNAT9iSwWbwgIGoL+RCBoCDopYsX7H34i+Y/uhRA0BP2JxIo3Wi8QNAT9iUDQEHRSQNAQdFJA0BB0UkDQEHRSQNAQdFJA0BB0UkDQEHRSQNAQdFJA0BD0J/KDWqX+T07az1TaH7sXQtAQ9CeyQb1A0C8WHAS9AxA0BL0SCBqChqD34PsfJP/ZTYSgIeiVfIyg5+L9EzcRgoagV/KBgn6yeCFoCPq47NcDQUPQWwBBQ9AQ9B5A0BD0FkDQEDQE/Sp/LI99+RN3nzUEDUFvwaGCXlcvEPSLBQdB75996GEh6KcuhKBXA0FD0BD0q0DQEPQOimtz7S+x7IsukksdSesK/+8haAh6c0FXzTQN67KHoCHozxd0/cirflYqBA1BX1rQ1dRm2b1ZlX1I0N9/R/gv9I+fvVq8EPRTF0LQQYpJ/hHPnsr1v/43+udz7+mDoCHoQwVdckGreeH0p996+e//IPkzJ+3PVdpfOGl/ptL+wc30L1Ta/4hc+JexC//81Qv/ykn769iFf/ni8+9z4bqCi5b4ywXnXvjX6y50S5yxsaDvXNCVEjQAx7KvyQHApalo51z2Z98GABtRd/x/AKJU72dxCO3Y9E3+fj4JcJUqOwXNtfsc5dHFmhfF+5kkQY+CCPPqPKsc27Nv/cvSRacS0Z4mllgm0U7yKfYY4ee/Y352Hn1sLhHtv8OJeTXdvL+v99J5WQ8RE/L29Ne2vFT6+wvPX2V5Xw/ZJ1Hx0imbyS2mWJrk+Qt5YiDTKpypSIxlGv/GRz1GlBCdOYcTh8aT1Db3bAh1XW+WOPnC+hZIy8qu9tjC0RKnsyz66yGmy8Dz3+usGKcPm5uwCun6W9E0T6VxXrmQJobSWFcQS4xlGk0c+rIb/ZVW9SW5NlCh0UTqF/XU9W0a82oMdXlvlfitjzTKrrkPU/lcidOAzKZl4nz6+fOx/pvq03xoxUha2Hijq+S3Z9IyZj2+ciFNDKUxOzeWGMs0lsgc8q3XUGzJNWV2C7XZcGLZ9F3us8yrqRmyLjQevFHiRNBjcRuYAj21QZ/x7vnaQIlXwzhSNeb1WARmhW3s+Um+JOP207roxyPLprat67Z9Ko1Zj69cSBODadTOjSXGMo0l8voa3G7oNk5NXoxD5anQe0/7XzeRj+Fdc7s1TW4an1xN431q8z7Urb9Y4txmqKd+uNF/pW6mpFM2Xht55p8peEu8HYfiNjKJ0359cm+GlU0WKBwi9rxiY18stPg4WvncFem2mqa/ZdojyURfmoRZj89cqH+jk2nFap/buXYiT+OJsUyDt0oS/yfrnAptQGa55lVf0FohlatfxhU7EMWSvstOzIRlQLv7fOxKrUskfR37h3VJavnGLso7mfx6ibPb0W2GUmkof0wNaXY5qw1qHWSd02OWla/Ec2YTiZsrp662bRVZNtbzi9oQYidflo9Bm/5IKlJVZT/VLelpyPOwAdlN9KSpf0N7r2cu1L/RSsuJiltl5zqJbITlibFMrQtLMYkkdgFJHOjUp6xl11Y9bvwbOz4i540xHNN6ZFZKTy0KK1FYBkw4ZZ/p0/x6Yk2m66qxzOqaptfV8q0ulTi9HWkzFF1WKgnlDc2+GGtWG8zK6fpHZkLmHk6J255nMrlTPXt+ZzJXZWM9Py03JXY6VnyI667ri/FWPMacDppELfexcxN/6UlTIunZU6+/UP9GM41WUJ4rO9dJJIKXibFMjQu5y5/bBVne/6+muZWjsKHzbnxULFf2r2mt5Ia7gmm8J01pYBZFbvsy6BWsPySyaJViH7dqYt9f1OS+8pZ0e2O54lYXS5zejrQZ2nHqb/NV7KMdO/YTfcZeGbXyvsi0zSrxqqhIgZakcTSTuMN29p2QTp9eOpeN9fyk3JTYSUNsP2QNNu9ZjZD+hQ6aXW04g1SimUb9UZpI2F9WXeh+o5FG5lDZY5jtXDvxMWQqMZapnsj7DWEXkMRfDmMj0m4986aQXLkiaPdILtVLh9Uj7WbLscqNRNaaqWXA+sPbqG6ENZKub8n95hOzZbupy9fc6lLBsduZbQZNP40w4Mm90NrIu4ZcKKa+1G+hfBR6iefDNJH+mP7ZdLfOMdG6puGdgSob4/kLUm6z2Lup/5TIipswK71uRpVopFF/lC6SPFt5YfgbK1l0XjtXJBL95E5i7DGIocdd/tIu0L+xJjYhrSWqStEqO1vQNC17MHcXzZ8k0l4tU62ZWAZZ3Zel6oFFIyGWKTED8r4lUidjzpslrpvdXtNPmgLV1PLaIL1nOf4tc1/kI2060kcx55o3pOEVxFRpC1Z/jied5DTQ55rLZi4cOvlkrVmJ/eSFUjIs0g82f+fGH7k7OWjyRD63l4mtXinMH6WJZHAzdS70ZToP01lPO4OW9hJdbdm5WiIpUCMx+hisllru8pd2gZY4kG6zZhVEq+lGdZDTUVv1idSWrahiSQ9U9FSV7fgr3qup1swqe+5IVSOhbjMyQ6M9Z77i+RdK3DC7XdNPEyPJk13/6Jv+77j7gjnVlI9izrWzvBK93Ue0E7EppvtcNlrhsMknyUET+5nwYVHO35lbdt6fJRLF3N5K1PxRtkjMTK0L45nSGmhop8vGy/Eb3c41EvOxzOfE6GPI+/0lc/lbdoFSCuvpc9oP2Uu3+WzLUnOVj8eqV1OtWR+eKq2R8FUcNcOKPv9i4Zhmt22kDJWKT6GboXltFIV0X3CnmuujqZWfsaPTu4cbjElupOjp6RfusjabfNJyU2I/EzEsqvl7R+YSqs2LRDW3NxINf5QpEjtT48JopmxALRs6KrJew7BzrcSSdnwiMfoY/GJmILPZkWEX6Ephy8HkSVrLLmia2ZbNpRLmXk215nkMF1vceCMhf2vZDSw/fzRRlLthdmdWGpkti8VPfaF9dl/wG7N9NFLQ9/swDsNYG/nSVkIe7THey7HJzbLhI1cvyu38GI55WJTz93x8dPaYqeb2WmJm+6NmkbiZahcuZFpOzDmWE9Hyjkm3LO1ElRZ9DAZzkVJDj7n8Pf1axucAmWPL0sAfacvmeprWq8nWrFW26Jt5I8keSvzR518qcW6IhMxu+hj0224T6eOrQQ/i1NwXfAHG8tE8hBJJ6ZQP+0wV2kroAMOMMHPJaB652M20p/s2tGFRzt9/5TEs1dz+ZlrPmj9KE4kn0/nCpUxLZlDc6Ccz0tpIYluteYxsdpFSQ8/j8s+Fz4vNsWZbllUyD/zxzR7mXs3X5Re8CxSNpFpXqJFEZlkLQ8Q7Q5gfg9oGEzWy9YpW7gvmVNPHF9oOSuHW65wVPtlKhGNZTgL4Crk+cn2AmgViWNTm76wEBj3RTJMY/ihVdEM4U+FeimRaFlS0A1ufseOGyioLJwa/kd2TcJFSQ892+csaozTG+gNdLRCBP8KWNapM69WMLl/8JEb80hPWEC1UbyK3rKUh4p8h6OarcFbMpaq5L7hTTRM0bQcN/6trM8hWYnydXCGfR67TbQ0dOSzK+TvjJmYNPNFMYw9KdaD7ozLzQm+mMn4rmCmNPiCivTGjbLLCX6h1GUwMfSNDuUhpV2IJLJ+XJIjmTeMxV4E/3WTZsmUV6tW4kqtaTAIbe5Eu8vyhROn/k4aIY1lrcaB55xjWWnw2Nb9pVtJHIZtzO9bMTHFbn8xNC+KaV8i9fq8T4cajGBbn+TtDDH080UrLhA4cfxTtnvmF/kyZHzScKY8kJqLlY79VM3UsMfSN3P2lXKQeZ69nWk66RjrXpH2wCPwhN26alkRhgV6N3kfOGgDL2WwkbaRQDVNeS5xnCNIQ+eU8JeExUVpMR+WED/JS9bsvVHNua2qmVFqmVisZZs3OU0zfyHUm4nFEXyPm78I+asUQzhNzQ3lqmDb9Ubx7FheamcqiGHkf4Ms0U5HE5Wj7ILQIXDdRFrz5jXwFU1idykXKuxJvjc0P0TdlQYPNlDbKmjQMUwp0ChTo1brxPlIL1g2t49E7oec3Tfk5UbOspSEym91MrCoOlD6GNHOtUvW4L9iXqp/awsw03Eq0KaYzcp0Ha3LicfRhUUUQiiHcN2bO04/ZH8VXzWjBiwt9Y63wgxqJcvOEigWha6fmtUZ48pxod0/GN7IVTOX+slyksRp78Jl8Sde+6kwF/sxuAdW69F5NL9aej+eF1Veq6B37VqssZsqL++OWtWOl8JgoGQeqPQZ3Y7I2y0t1dl8421VsM8UMwdZaiWCeYjoj13kEbMfZPhJDuDVm8mJQv5H+KBELwLpncaFlkMpIYt6N6olsoUmPBSHfol9qhyfPiWb3ZH4jW8Gcg4lMwyBWYzIK/1Gz1QIZ+KMy11uX1qtpxSqVXBs+rmoOVTNvlU0sIqY8v6uem7q2lcbccHNMh/YYfSbbbG5vDrS3qzhmihGCbaayjnCeYt4/JGyj9NqOlRFBeDdtIycCl+pA+KPmVTNa8HefUSUjiR9O98PixnyxILHwZHWlJ0xdW8FU7i9r2hKrMeGyocvr7HaEYfm/2Ucs+F8Ner5dfO30t3OomnkZm1gs6EL0Erk3Wtob09HP8aX2CoyxXUVrzoHwbHOmrLU8OlQ1H2FwFMp3pY82tAr1CEIrilaPwJVPLdCcQLTge9+YKQZ/4QfVoZsn7FiQxfBkeaUT+26sYNq+MX/QvDEEFaXIi3Xsc3XpMb++1qXVdeXES+W06LRQNaMyRmWGuy4KPq5lrv9Pj5b2hfOyfRGyzdoTV327ilaN0fBsdn/SMJqnmMV4eheds8UQ+Qx670QNCC2C0Jq+6hG41jCtDa60e7bnvVWuDf5ucCG5BydgaDE8Wd29U/DGCqZldS5tU2AuLhmBcc+MiCE95tfXurSG0VmRIjWp+kfnj94p1cTCqg0tGIbdjtVL6NHSTnCp2Bch26x4DP8GodzN0xuenWlNVptinu7iyJu+5IJm/YEuLuaw1CIIrXvVI3DNYVpbNWPds7mCVU+jNvgbwYVy84gdMLQcnsyiCDJf92RG1FtWZ3ybAndxtWK9QD0Fb11GzK9qXe6BAKRYbe/yY2zysvFG79DBUgRYmJMvFrusdsi4XaERLW0htz5YbTayQcjKM/OGYGs3766Qn0jZjw1/bHVPNT8EpZs7zzmC0B+By/+h8PHpq2aOW3LoKmfwNyOJSX9grB4vhyfnWk/iFLyxgun4xmJB89LF1dMQYiV1FTFU+FqXcyCANcUqSIO6D0NDIzAdn7UYLPneAfM6alprO2RcgmHmZaG2PlhtNrxByM5TC5SJ+jjPhveIxK5g1arZDNNIJc0mRLYLPhKBK318xqqZGY41jiMPLtQG/9yKJLa3qyyEJ1e5iiJwI86ImeddwXSqTAvvH3i0glqCycehdluXGfOrBO3MsOw+eBjbaiR9PxnbrKmpGiz5xMKeuVHTet4hw28mFmYuMiXj7Lz1wWyz/g1CC5HkC17pU8g7PrcQPSKpkbI3RmJSCN1EJE3KznXBByNwZx9faNWsbW7M50HKLxZJ7FnBC4YnMwtGRRE4V1Izb1VEvSYDtj6kL8HctY1Sc+vSY3614H/vDEue90T7D6LopjAWoHga6fLkYGlNLOidctPaGNeiYebqfvnTWPsiBJ4eeDGSfMkrfQJ07YsN6LJHpF2M3BzK9/PSTU0DkTQtA9s+CkbgamugvlWzshioxc0U1HTRSGJPMEAoPJlbMN6IM+U3eyKiXlSZslb5I1q3I9wWRsxvfIbFz3sS/ccwMl1KrbPWJbs8MVgaBS7ulBpv+qQ2Gmau3SuNt7f3RQQ3yCxHksd8nKeQ1yPfuqpts5/vWOznZe42Iuned7+hCFzNx+eumrGtZrQVsSLQpzSeSGLjfiPhycqC8UYR+FYwVwXNPx6hJRh5o7wD1WN+4zMsZrrI/oMoWnmmZYcouzxnsNTulChpHteiYeaidObl1nzeF2GEnlrNORpJvuzjPIkHK006dMoeUbPq5X5e0TOxjWNzMYTatTynQdslbK+a8a1mbL3KsqzjkcT+8GS+yKJZMN4oAmcFc0XQPD2dk1aZfwnGbF1GWnyGxc57khbV7KuTHaLq8rTBUgZFqTulprUa18Jh5pZBaR/cZISeWs05Gkm+5iiWU6CHBBIBjCICzOwR5X5edm7ArImFYVr068Fdwpkc+nq238zagB+IJGbfG4pp4IssswVjRxGYs/CVEfUM6voj//vDk83WZSWFjmCQ6xrKolJlMgfOyS6v1pwpIihqvlPbZ+8N+nYMSsMwtENP7eYciyRf8HGeh4j/upHic3pEtZ/XiKVZGqZlvy5QPr6KdWja0McmUcaIGo4kzrJYTANbZNEsGBlFsCKCMhxRn+d8az753xOevBAxFD6CQKxrOP2H1rpkl6cGSy0oar5T2/5zg749BqW+3OqEntrN2Zupqoyoj/M8chH/xXYh2bel9vMOTwzTql83fHyiWzeGPsckDUcS8zyc32i+bsOCkcOCEaLk85tFIurZYEEbXTn+Hzfwx9e6YpYYNzpval3Da1HJDtE5J2kOisoCjcsb9O0alN7zGbwjUCwgnj1K5ESVw5GOIzoS3/hSlGOtGvt5nxmmVb+u+/jI2FeIGp6HPsd/4UYSx1330tfNF1k0C0ZKzAhRslcn/EHzykPBTv8Q7wUzlmCsqEKVX/xcB3pn90cWOO9JIFevnHOS5qCoNti43DDzqEHJ/kEo9NSf6QpX9zkYB4WzQwLnfXiVGE6D+3kjwzTXiOrXZx/fQ2bhGfpEnoFI4pjrfvZ1q0UWUZnt/xX/xAhRsteHvUHzmoeCHZagjrDwWTBa61qyxOiGxQfRV+hIJ/FEnu6OlKoeFKULNjNsH9f0CRuUojl7Qk+rUED8Klf3ORgHhZuHBNIwAVbV7n5e/frAxj+mEdWv6wXL/CT3kHfZOCnb8InEXPfznMpeZFGq9IUoLQTNzx4KmmmpT2qtIGt9sWTREqO+Der9Da1rcHwbZ2mpakFRM3a0tB3SUVZhg1Jc5oSezgKwM13n6j4J46DwQT8kkEXgyr+6BwwF9rapfp3+7OnX6ZhJvWn2XIifBxA9KTviutd83fYii1KlG6K0FDQ/eyju4+3Wh/eA6K1r0RIrC3JD9E496xo6di8rStUJilJ1FXH+EgF6DMrKaM5OCzIEoF217Oo+D+ugcGvfjr6kZ/sEQnvbjGbt69dvE99MZ8+FmjZ0UvYa173m67amJkqVbojSYtD87KEYJuuFToYFY3tMIkcQsNDTB+3R+lJf13BxA+fk0QdGUBSrhGi0dCbsf9OgdHtguwUFMo2eqHIy/oPCRSFpEbjGft4qOkxH+3U+v5Q1rB1Z+GDnPAdOyl503dNsZ1+3PTVRqnRClPw15o3CUfj3gNgaCh9BMPAj0Utqh646p2J+z5ucC+tBUfw5+lC0dKZPSaxTp50e2GpBZSzTyPkmJxI4KFwUkhjX2B4q7XmClpX8qxQJvdDeAUqva51lCT7FeAyhk7KDrvtKy5ZjnYhpqtI+v8tXY0tROAt7QAwfl8cNIUJP6cVrl4fN97yRUr0bp0eL4FJvtLQ5JRnMU6etqrIxBBBosaFTQ84i6DjSI3BZVesF6LesBJpI2CFx0iuQ6TtzzIWteYpR+E/KDrruuQ0ssjXjWXk3a6nS7Lu9QfPLUTjRPSCWj8sMs9ZDT3u/b8OGHrNgvueNrb/r3yeDS41oafN9JmJKYgnPqirzKWwBaEkLXumTYMt0IceRGYFrzZej7dpo1qEty4ZHSlul6mrfSdmsYvyue962pGmp+bpFNxuJDfMHzS+f5xjeAxL0cXlP/yjW9WrsmIX5PW/eqEwRXGpGSxvvM/FubgxU1aIAgq7uUxHLdEHHUSAC1zTX7HYdbtbW7Et/JZ42xSAzcP2k7MVT1MWYKfOafd2ym42o0h80v3SeI8/d27pilph5+kf5xIZRcczCoP5qBJfKVSYeXDrXlb230d3cGOmBeZ4eASy6us9EHievO454IcmVOF8Erm6uue060qzt2Zc/kJhWtfIgL5/pbU9bVW5znx9WZbjJ+uc7i60rZolFT/8IoR2zML/nzRiA1MKOCC41ZgHG3kZ767C/qtgzqsUiWwBLru7TKKnZJ5fpZseRjLCQz+OJwDXMNV8Id0gksfkyQ1rVdWdFlMdc97MNbGard7M+VZr9mvuqD898Z0XrCvi4Vpz+4cU8ZsF8z5sKLp2jpbXH8O5tdEK83KoSz6gWi2wBrDoY5FjYTKFrSlJjTsiiLCTteTx1rZtrehROtF8Pb1nOrCnGvLK8uNpm2MButqqbdVVp92uhm9HmOytal7/NRk//iFQUKVTjmAXd46YNQOpAjfleAnsb2cuLolUlBaAWi2wBLLm6z4DOFHiXZi/TqWJQz2O7uIxikO3a1ohPJJEty5k9xZAsrraZY6an1xfdrKvKQL/muRk531mxlh30ccVO/wghY+2Ng+Jnj5v+VhaxsONd9TDeZ9KOv4pW1SwAtVi0xsd5OvQdleyzMJfp5mJQz9NpEwy3GPgDORpxRRLdshydYkQP/LbGzNzKdO7zHVX6+7Wwh2JN6wrPsKKnf/iRhWoes2CdyaOd3epuEPHtbVyoqvkZVZ6Wzzoyyp4ImSkwFZe160HlxWC/Xdja26YXg0cjvojY4OxraYrhrrbFp616cGCsz3f7tYW1oizeusKTYXI7sdM/fGiOw9gxC2IAchZ2eGt29jauqirxjL7FovgoexatWLvI9XeYO4VkPI+zt00vBo9GZLNenn0FIom1WnFW2xamrUZwYBbp891+Lb5WpBWOYzQEfVw83/4WlaVLpRWqc8yCcce8Hpy9aaxZOnsbI1XlPKPb1UVH2dPgi0ZdzT11vomJKAbfSyGDxeDVSHT2FY0k1mvFXm1bmrYuRCZoNeZ5I3Z4vhM8MT/m49JMmJgsHfigLme09kHxOr7di7PRFHlnS2Qfax6MAI2MsmdQzYtG9D2UQx/Y9mUXg2dvm4NHIwuzr3AkcSw8eXnaagYHegn0a9H5jr91xX1chgkTk6WDOAmKF6pxzIKNOwDFAucCVWVhCGCdj/MUau242egyVfhQ+GAxOBqJz76yWCRxLDw5Mm0VleFfZTHx9VwhD0Us+H/Bx2VFHEZk6dzLpJkM2jELnn/pVmR8eAqaKRrunpSwj/NESCHNi0axjYzhQ+HDxRDp1j1epSyLRBIvue6901Z566HgQBOnyQY9FJHWtejjMk2YmCxnjPe8iUKtFl18qhbWHJLobc5mKdp7UiI+zhOhhaQWjZ7dyJgvba0Jd+um9IyD372RxIuue8+0lf/rSHCgiRM0H/ZQhFvXko/LMmHWydJ8z9vqQIk1L7iKVZU/06VR9mTYK8S8x2ivYaldR7p1M3ZZP57UZ8Isu+6daav4dSQ2bPnx/POdpT0gYR/XQiBxCPM9b+sDJVYczxCtKh/Lo+zJ0Og23zHaK4vs+bAqr7lmHE/qmjBrXPehxvXkLHw5DCu6B0Q8jdfHFVlkWSD8nrcoseMZ3mHZKXImfbc2xsvDK2FV/i3LgeNJs/Wue93vsajKAIthWPE9IPIfeU2xFwcL5nELvOdticjxDG+x7BQ5ERprdewpIL5uPXwo1mrXvWpcK4IDAyyGYfn3gDgERouXXLZs8ul/z1uIwJRkO1Y4Rc7jeJNeKW/h4HfJkzpYFxzoYdmfPd/MQuua2+zLgwVD+QZ973kLP8jSlORtlp0iZ5EPp8ViR7ecvuy6X6VKP0v+7MAeEB+yzb4+WIgyCr/nLcbClGQDPmtPisZUn6Xn2JbTN1z3i6sscbz+bDOq0NwDsuoZnx4sFOrWu/GZqyJTkm34mD0pNmct8ES3nL7ruo+tsizh+rPdE/NX3swbg0XmrIc8dx5AeEoC9iGy5XQD131olWUFjj/biSpcfTMvDhZPrYcYF8bemAD2J3DEzgau+8AqyyrM+Y4nqvCpm3llsDBDtNYGza/Y2wh2JnzEzruu+3dm4cZ8Z01U4YpnfGqwMEO0VnbPK/Y2gv1YPGLnXdf9G7NwZ76zFFUYf9IXBgtjPWRV97xmbyPYkcUjdt513W86C1+KKozyxGDhP+xxDctvTAD7EN1yqvNJrvvFqMIo6weLpcMeF66O7xwGe7C85VTxSa77t1rXE4PFwmGPi1eHzukFe7Fiy6nko1z3B7Wu0GGPi9ctnNMLdmLxNPlP5ajW9eJb0CLn9IIdWY4k/oq88xa01VMSsDn28aSfcobDybz1FrQnpiRgYxaPJ/2avPcWtCemJGBz3ONJvzxvvgXtslOSq+M/nhS8+RY0TEmOxzwU64lI4q/Di29Bw5TkBNxDsT7oRJKP4aW3oGFKcgLOoVgINjd56y1omJIcjOdQLMxbTJ5+C5pvxy2mJAfhORQLCF57C1pgxy3MjeOIHIr1lXntLWjv77gFbxM6+P1r88pb0N7bcQs24r1I4kR5aT3kzeMZwEZ8Upz+h/D6esg7xzOAjUAAmMGqwx6DvHE8A9gIBIDprDzsMXj5G8czALAH6w57DF4NCw6cj+/kyRfXQ2DBgbMJnDz5mgcZFhw4mc9+aRQAT/HpL40C4Ck+/qVRADzLZ780CoBn+eiXRgHwLB/90igAngbrISAtsB4CkgLrIQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMBF+P8XnwduTO/WTgAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMy0wNi0xNVQxMDowNzozMiswNzowMK7TAogAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjMtMDYtMTVUMTA6MDc6MzIrMDc6MDDfjro0AAAAIXRFWHRwczpIaVJlc0JvdW5kaW5nQm94ADUwNHg3MjArNTArNTDW4iLDAAAAE3RFWHRwczpMZXZlbABBZG9iZS0yLjAKOZN0DQAAAABJRU5ErkJggg==" />


 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |       8.1 |   120     |                 0.00% |             36473.49% |   0.00084 |      20 |
 | Text::Table::More             |      20   |    60     |               120.32% |             16500.15% |   0.00079 |      20 |
 | Text::ANSITable               |      19   |    52     |               138.95% |             15205.67% |   0.0005  |      20 |
 | Text::ASCIITable              |     100   |    10     |              1178.21% |              2761.30% |   0.00019 |      21 |
 | Text::FormatTable             |     100   |     8     |              1406.88% |              2327.10% |   0.00021 |      20 |
 | Text::Table::TinyColorWide    |     160   |     6.1   |              1935.67% |              1696.63% | 4.1e-05   |      20 |
 | Text::Table::TinyWide         |     220   |     4.5   |              2658.16% |              1226.01% | 3.3e-05   |      21 |
 | Text::SimpleTable             |     280   |     3.5   |              3421.37% |               938.61% | 3.3e-05   |      20 |
 | Text::MarkdownTable           |     300   |     3     |              4092.38% |               772.38% | 7.9e-05   |      20 |
 | Text::Table::Manifold         |     340   |     2.9   |              4103.12% |               770.15% | 1.4e-05   |      20 |
 | Text::TabularDisplay          |     350   |     2.9   |              4220.60% |               746.49% | 1.5e-05   |      20 |
 | Text::Table::Tiny             |     370   |     2.7   |              4431.41% |               707.11% | 2.2e-05   |      20 |
 | Text::Table                   |     400   |     3     |              4703.50% |               661.39% | 6.6e-05   |      20 |
 | Text::Table::TinyColor        |     610   |     1.6   |              7411.08% |               386.93% | 2.2e-06   |      20 |
 | Text::Table::HTML             |     660   |     1.5   |              8088.89% |               346.62% | 2.5e-06   |      20 |
 | Text::Table::HTML::DataTables |    1000   |     0.98  |             12537.94% |               189.39% | 1.4e-06   |      20 |
 | Text::Table::TinyBorderStyle  |    1300   |     0.75  |             16280.36% |               123.28% | 2.7e-06   |      20 |
 | Text::Table::Org              |    1700   |     0.59  |             20844.22% |                74.62% | 1.1e-06   |      20 |
 | Text::Table::CSV              |    1700   |     0.58  |             21345.46% |                70.54% | 1.7e-06   |      21 |
 | Text::Table::Any              |    2600   |     0.39  |             31913.18% |                14.25% | 3.1e-06   |      21 |
 | Text::Table::Sprintf          |    2960   |     0.338 |             36473.49% |                 0.00% | 5.3e-08   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                   Rate  Text::UnicodeBox::Table  Text::Table::More  Text::ANSITable  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::SimpleTable  Text::MarkdownTable  Text::Table  Text::Table::Manifold  Text::TabularDisplay  Text::Table::Tiny  Text::Table::TinyColor  Text::Table::HTML  Text::Table::HTML::DataTables  Text::Table::TinyBorderStyle  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table         8.1/s                       --               -50%             -56%              -91%               -93%                        -94%                   -96%               -97%                 -97%         -97%                   -97%                  -97%               -97%                    -98%               -98%                           -99%                          -99%              -99%              -99%              -99%                  -99% 
  Text::Table::More                20/s                     100%                 --             -13%              -83%               -86%                        -89%                   -92%               -94%                 -95%         -95%                   -95%                  -95%               -95%                    -97%               -97%                           -98%                          -98%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                  19/s                     130%                15%               --              -80%               -84%                        -88%                   -91%               -93%                 -94%         -94%                   -94%                  -94%               -94%                    -96%               -97%                           -98%                          -98%              -98%              -98%              -99%                  -99% 
  Text::ASCIITable                100/s                    1100%               500%             420%                --               -19%                        -39%                   -55%               -65%                 -70%         -70%                   -71%                  -71%               -73%                    -84%               -85%                           -90%                          -92%              -94%              -94%              -96%                  -96% 
  Text::FormatTable               100/s                    1400%               650%             550%               25%                 --                        -23%                   -43%               -56%                 -62%         -62%                   -63%                  -63%               -66%                    -80%               -81%                           -87%                          -90%              -92%              -92%              -95%                  -95% 
  Text::Table::TinyColorWide      160/s                    1867%               883%             752%               63%                31%                          --                   -26%               -42%                 -50%         -50%                   -52%                  -52%               -55%                    -73%               -75%                           -83%                          -87%              -90%              -90%              -93%                  -94% 
  Text::Table::TinyWide           220/s                    2566%              1233%            1055%              122%                77%                         35%                     --               -22%                 -33%         -33%                   -35%                  -35%               -39%                    -64%               -66%                           -78%                          -83%              -86%              -87%              -91%                  -92% 
  Text::SimpleTable               280/s                    3328%              1614%            1385%              185%               128%                         74%                    28%                 --                 -14%         -14%                   -17%                  -17%               -22%                    -54%               -57%                           -72%                          -78%              -83%              -83%              -88%                  -90% 
  Text::MarkdownTable             300/s                    3900%              1900%            1633%              233%               166%                        103%                    50%                16%                   --           0%                    -3%                   -3%                -9%                    -46%               -50%                           -67%                          -75%              -80%              -80%              -87%                  -88% 
  Text::Table                     400/s                    3900%              1900%            1633%              233%               166%                        103%                    50%                16%                   0%           --                    -3%                   -3%                -9%                    -46%               -50%                           -67%                          -75%              -80%              -80%              -87%                  -88% 
  Text::Table::Manifold           340/s                    4037%              1968%            1693%              244%               175%                        110%                    55%                20%                   3%           3%                     --                    0%                -6%                    -44%               -48%                           -66%                          -74%              -79%              -80%              -86%                  -88% 
  Text::TabularDisplay            350/s                    4037%              1968%            1693%              244%               175%                        110%                    55%                20%                   3%           3%                     0%                    --                -6%                    -44%               -48%                           -66%                          -74%              -79%              -80%              -86%                  -88% 
  Text::Table::Tiny               370/s                    4344%              2122%            1825%              270%               196%                        125%                    66%                29%                  11%          11%                     7%                    7%                 --                    -40%               -44%                           -63%                          -72%              -78%              -78%              -85%                  -87% 
  Text::Table::TinyColor          610/s                    7400%              3650%            3150%              525%               400%                        281%                   181%               118%                  87%          87%                    81%                   81%                68%                      --                -6%                           -38%                          -53%              -63%              -63%              -75%                  -78% 
  Text::Table::HTML               660/s                    7900%              3900%            3366%              566%               433%                        306%                   200%               133%                 100%         100%                    93%                   93%                80%                      6%                 --                           -34%                          -50%              -60%              -61%              -74%                  -77% 
  Text::Table::HTML::DataTables  1000/s                   12144%              6022%            5206%              920%               716%                        522%                   359%               257%                 206%         206%                   195%                  195%               175%                     63%                53%                             --                          -23%              -39%              -40%              -60%                  -65% 
  Text::Table::TinyBorderStyle   1300/s                   15900%              7900%            6833%             1233%               966%                        713%                   500%               366%                 300%         300%                   286%                  286%               260%                    113%               100%                            30%                            --              -21%              -22%              -48%                  -54% 
  Text::Table::Org               1700/s                   20238%             10069%            8713%             1594%              1255%                        933%                   662%               493%                 408%         408%                   391%                  391%               357%                    171%               154%                            66%                           27%                --               -1%              -33%                  -42% 
  Text::Table::CSV               1700/s                   20589%             10244%            8865%             1624%              1279%                        951%                   675%               503%                 417%         417%                   400%                  400%               365%                    175%               158%                            68%                           29%                1%                --              -32%                  -41% 
  Text::Table::Any               2600/s                   30669%             15284%           13233%             2464%              1951%                       1464%                  1053%               797%                 669%         669%                   643%                  643%               592%                    310%               284%                           151%                           92%               51%               48%                --                  -13% 
  Text::Table::Sprintf           2960/s                   35402%             17651%           15284%             2858%              2266%                       1704%                  1231%               935%                 787%         787%                   757%                  757%               698%                    373%               343%                           189%                          121%               74%               71%               15%                    -- 
 
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

=for html <img src="data:image/png;base64,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" />


 #table3#
 {dataset=>"small (3x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |     200   | 6         |                 0.00% |             57200.69% |   0.00016 |      20 |
 | Text::ANSITable               |     700   | 1.4       |               327.06% |             13317.43% |   5e-06   |      21 |
 | Text::Table::More             |     960   | 1         |               481.52% |              9753.56% | 3.5e-06   |      24 |
 | Text::Table::TinyBorderStyle  |    3000   | 0.3       |              1817.31% |              2888.60% | 7.1e-06   |      20 |
 | Text::ASCIITable              |    4000   | 0.2       |              2604.90% |              2018.40% | 3.1e-06   |      20 |
 | Text::Table                   |    6400   | 0.16      |              3764.07% |              1382.91% | 8.8e-07   |      21 |
 | Text::FormatTable             |    6900   | 0.14      |              4098.28% |              1264.86% | 2.1e-07   |      20 |
 | Text::Table::Manifold         |    7600   | 0.13      |              4501.95% |              1145.14% | 4.8e-07   |      20 |
 | Text::Table::TinyColorWide    |    7900   | 0.13      |              4692.26% |              1095.69% | 2.1e-07   |      21 |
 | Text::SimpleTable             |   10000   | 0.09      |              6693.33% |               743.48% | 1.9e-06   |      22 |
 | Text::Table::TinyWide         |   11200   | 0.089     |              6730.07% |               738.95% |   8e-08   |      20 |
 | Text::MarkdownTable           |   12000   | 0.084     |              7176.55% |               687.47% | 4.5e-07   |      20 |
 | Text::Table::Tiny             |   10000   | 0.08      |              7941.48% |               612.56% | 1.1e-06   |      20 |
 | Text::Table::HTML::DataTables |   16000   | 0.064     |              9325.07% |               507.96% | 9.9e-08   |      23 |
 | Text::TabularDisplay          |   15600   | 0.064     |              9401.21% |               503.09% | 2.5e-08   |      23 |
 | Text::Table::TinyColor        |   24000   | 0.0416    |             14492.65% |               292.67% |   4e-08   |      20 |
 | Text::Table::HTML             |   32106.5 | 0.0311463 |             19411.77% |               193.67% |   0       |      20 |
 | Text::Table::Org              |   52000   | 0.019     |             31554.46% |                81.02% | 2.7e-08   |      20 |
 | Text::Table::CSV              |   78700   | 0.0127    |             47736.28% |                19.78% | 5.8e-09   |      26 |
 | Text::Table::Any              |   81700   | 0.0122    |             49565.77% |                15.37% | 3.2e-09   |      22 |
 | Text::Table::Sprintf          |   94000   | 0.011     |             57200.69% |                 0.00% | 1.3e-08   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                      Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::Table::TinyBorderStyle  Text::ASCIITable  Text::Table  Text::FormatTable  Text::Table::Manifold  Text::Table::TinyColorWide  Text::SimpleTable  Text::Table::TinyWide  Text::MarkdownTable  Text::Table::Tiny  Text::Table::HTML::DataTables  Text::TabularDisplay  Text::Table::TinyColor  Text::Table::HTML  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table            200/s                       --             -76%               -83%                          -95%              -96%         -97%               -97%                   -97%                        -97%               -98%                   -98%                 -98%               -98%                           -98%                  -98%                    -99%               -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                    700/s                     328%               --               -28%                          -78%              -85%         -88%               -90%                   -90%                        -90%               -93%                   -93%                 -94%               -94%                           -95%                  -95%                    -97%               -97%              -98%              -99%              -99%                  -99% 
  Text::Table::More                  960/s                     500%              39%                 --                          -70%              -80%         -84%               -86%                   -87%                        -87%               -91%                   -91%                 -91%               -92%                           -93%                  -93%                    -95%               -96%              -98%              -98%              -98%                  -98% 
  Text::Table::TinyBorderStyle      3000/s                    1900%             366%               233%                            --              -33%         -46%               -53%                   -56%                        -56%               -70%                   -70%                 -72%               -73%                           -78%                  -78%                    -86%               -89%              -93%              -95%              -95%                  -96% 
  Text::ASCIITable                  4000/s                    2900%             599%               400%                           49%                --         -20%               -29%                   -35%                        -35%               -55%                   -55%                 -58%               -60%                           -68%                  -68%                    -79%               -84%              -90%              -93%              -93%                  -94% 
  Text::Table                       6400/s                    3650%             775%               525%                           87%               25%           --               -12%                   -18%                        -18%               -43%                   -44%                 -47%               -50%                           -60%                  -60%                    -74%               -80%              -88%              -92%              -92%                  -93% 
  Text::FormatTable                 6900/s                    4185%             899%               614%                          114%               42%          14%                 --                    -7%                         -7%               -35%                   -36%                 -40%               -42%                           -54%                  -54%                    -70%               -77%              -86%              -90%              -91%                  -92% 
  Text::Table::Manifold             7600/s                    4515%             976%               669%                          130%               53%          23%                 7%                     --                          0%               -30%                   -31%                 -35%               -38%                           -50%                  -50%                    -68%               -76%              -85%              -90%              -90%                  -91% 
  Text::Table::TinyColorWide        7900/s                    4515%             976%               669%                          130%               53%          23%                 7%                     0%                          --               -30%                   -31%                 -35%               -38%                           -50%                  -50%                    -68%               -76%              -85%              -90%              -90%                  -91% 
  Text::SimpleTable                10000/s                    6566%            1455%              1011%                          233%              122%          77%                55%                    44%                         44%                 --                    -1%                  -6%               -11%                           -28%                  -28%                    -53%               -65%              -78%              -85%              -86%                  -87% 
  Text::Table::TinyWide            11200/s                    6641%            1473%              1023%                          237%              124%          79%                57%                    46%                         46%                 1%                     --                  -5%               -10%                           -28%                  -28%                    -53%               -65%              -78%              -85%              -86%                  -87% 
  Text::MarkdownTable              12000/s                    7042%            1566%              1090%                          257%              138%          90%                66%                    54%                         54%                 7%                     5%                   --                -4%                           -23%                  -23%                    -50%               -62%              -77%              -84%              -85%                  -86% 
  Text::Table::Tiny                10000/s                    7400%            1650%              1150%                          275%              150%         100%                75%                    62%                         62%                12%                    11%                   5%                 --                           -19%                  -19%                    -48%               -61%              -76%              -84%              -84%                  -86% 
  Text::Table::HTML::DataTables    16000/s                    9275%            2087%              1462%                          368%              212%         150%               118%                   103%                        103%                40%                    39%                  31%                25%                             --                    0%                    -35%               -51%              -70%              -80%              -80%                  -82% 
  Text::TabularDisplay             15600/s                    9275%            2087%              1462%                          368%              212%         150%               118%                   103%                        103%                40%                    39%                  31%                25%                             0%                    --                    -35%               -51%              -70%              -80%              -80%                  -82% 
  Text::Table::TinyColor           24000/s                   14323%            3265%              2303%                          621%              380%         284%               236%                   212%                        212%               116%                   113%                 101%                92%                            53%                   53%                      --               -25%              -54%              -69%              -70%                  -73% 
  Text::Table::HTML              32106.5/s                   19163%            4394%              3110%                          863%              542%         413%               349%                   317%                        317%               188%                   185%                 169%               156%                           105%                  105%                     33%                 --              -38%              -59%              -60%                  -64% 
  Text::Table::Org                 52000/s                   31478%            7268%              5163%                         1478%              952%         742%               636%                   584%                        584%               373%                   368%                 342%               321%                           236%                  236%                    118%                63%                --              -33%              -35%                  -42% 
  Text::Table::CSV                 78700/s                   47144%           10923%              7774%                         2262%             1474%        1159%              1002%                   923%                        923%               608%                   600%                 561%               529%                           403%                  403%                    227%               145%               49%                --               -3%                  -13% 
  Text::Table::Any                 81700/s                   49080%           11375%              8096%                         2359%             1539%        1211%              1047%                   965%                        965%               637%                   629%                 588%               555%                           424%                  424%                    240%               155%               55%                4%                --                   -9% 
  Text::Table::Sprintf             94000/s                   54445%           12627%              8990%                         2627%             1718%        1354%              1172%                  1081%                       1081%               718%                   709%                 663%               627%                           481%                  481%                    278%               183%               72%               15%               10%                    -- 
 
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

=for html <img src="data:image/png;base64,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" />


 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |       400 |   3       |                 0.00% |             76394.30% | 8.4e-05 |      20 |
 | Text::ANSITable               |      2200 |   0.45    |               491.32% |             12836.29% | 6.4e-07 |      20 |
 | Text::Table::More             |      3200 |   0.31    |               739.15% |              9015.70% | 9.1e-07 |      20 |
 | Text::Table::TinyBorderStyle  |      4500 |   0.22    |              1078.26% |              6392.13% | 1.3e-06 |      22 |
 | Text::Table::Manifold         |     10000 |   0.09    |              2969.15% |              2392.36% | 1.5e-06 |      20 |
 | Text::FormatTable             |     10000 |   0.07    |              3590.40% |              1972.79% | 7.7e-07 |      20 |
 | Text::ASCIITable              |     10000 |   0.07    |              3819.94% |              1851.41% | 9.9e-07 |      20 |
 | Text::Table                   |     20000 |   0.05    |              4900.21% |              1429.82% | 9.6e-07 |      20 |
 | Text::Table::HTML::DataTables |     21000 |   0.048   |              5434.33% |              1282.18% | 1.2e-07 |      20 |
 | Text::MarkdownTable           |     20000 |   0.05    |              5697.87% |              1219.35% | 8.9e-07 |      20 |
 | Text::Table::TinyColorWide    |     45000 |   0.022   |             11759.61% |               545.00% | 2.6e-08 |      21 |
 | Text::Table::Tiny             |     52000 |   0.019   |             13686.75% |               454.84% |   6e-08 |      20 |
 | Text::SimpleTable             |     57000 |   0.017   |             14982.89% |               407.16% | 1.7e-07 |      20 |
 | Text::Table::TinyWide         |     58000 |   0.017   |             15207.88% |               399.71% | 7.8e-08 |      21 |
 | Text::TabularDisplay          |     62000 |   0.016   |             16326.67% |               365.67% | 1.8e-08 |      24 |
 | Text::Table::TinyColor        |     93000 |   0.011   |             24400.42% |               212.22% | 1.3e-08 |      20 |
 | Text::Table::Any              |    100000 |   0.01    |             25184.05% |               202.54% |   5e-07 |      20 |
 | Text::Table::Org              |    140000 |   0.007   |             37466.60% |               103.62% | 1.3e-08 |      20 |
 | Text::Table::HTML             |    157000 |   0.00636 |             41389.63% |                84.37% | 2.6e-09 |      32 |
 | Text::Table::Sprintf          |    300000 |   0.004   |             67320.30% |                13.46% | 4.8e-08 |      20 |
 | Text::Table::CSV              |    290000 |   0.0034  |             76394.30% |                 0.00% | 8.3e-09 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                     Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::Table::TinyBorderStyle  Text::Table::Manifold  Text::FormatTable  Text::ASCIITable  Text::Table  Text::MarkdownTable  Text::Table::HTML::DataTables  Text::Table::TinyColorWide  Text::Table::Tiny  Text::SimpleTable  Text::Table::TinyWide  Text::TabularDisplay  Text::Table::TinyColor  Text::Table::Any  Text::Table::Org  Text::Table::HTML  Text::Table::Sprintf  Text::Table::CSV 
  Text::UnicodeBox::Table           400/s                       --             -85%               -89%                          -92%                   -97%               -97%              -97%         -98%                 -98%                           -98%                        -99%               -99%               -99%                   -99%                  -99%                    -99%              -99%              -99%               -99%                  -99%              -99% 
  Text::ANSITable                  2200/s                     566%               --               -31%                          -51%                   -80%               -84%              -84%         -88%                 -88%                           -89%                        -95%               -95%               -96%                   -96%                  -96%                    -97%              -97%              -98%               -98%                  -99%              -99% 
  Text::Table::More                3200/s                     867%              45%                 --                          -29%                   -70%               -77%              -77%         -83%                 -83%                           -84%                        -92%               -93%               -94%                   -94%                  -94%                    -96%              -96%              -97%               -97%                  -98%              -98% 
  Text::Table::TinyBorderStyle     4500/s                    1263%             104%                40%                            --                   -59%               -68%              -68%         -77%                 -77%                           -78%                        -90%               -91%               -92%                   -92%                  -92%                    -95%              -95%              -96%               -97%                  -98%              -98% 
  Text::Table::Manifold           10000/s                    3233%             400%               244%                          144%                     --               -22%              -22%         -44%                 -44%                           -46%                        -75%               -78%               -81%                   -81%                  -82%                    -87%              -88%              -92%               -92%                  -95%              -96% 
  Text::FormatTable               10000/s                    4185%             542%               342%                          214%                    28%                 --                0%         -28%                 -28%                           -31%                        -68%               -72%               -75%                   -75%                  -77%                    -84%              -85%              -90%               -90%                  -94%              -95% 
  Text::ASCIITable                10000/s                    4185%             542%               342%                          214%                    28%                 0%                --         -28%                 -28%                           -31%                        -68%               -72%               -75%                   -75%                  -77%                    -84%              -85%              -90%               -90%                  -94%              -95% 
  Text::Table                     20000/s                    5900%             800%               519%                          339%                    79%                40%               40%           --                   0%                            -4%                        -56%               -62%               -65%                   -65%                  -68%                    -78%              -80%              -86%               -87%                  -92%              -93% 
  Text::MarkdownTable             20000/s                    5900%             800%               519%                          339%                    79%                40%               40%           0%                   --                            -4%                        -56%               -62%               -65%                   -65%                  -68%                    -78%              -80%              -86%               -87%                  -92%              -93% 
  Text::Table::HTML::DataTables   21000/s                    6150%             837%               545%                          358%                    87%                45%               45%           4%                   4%                             --                        -54%               -60%               -64%                   -64%                  -66%                    -77%              -79%              -85%               -86%                  -91%              -92% 
  Text::Table::TinyColorWide      45000/s                   13536%            1945%              1309%                          900%                   309%               218%              218%         127%                 127%                           118%                          --               -13%               -22%                   -22%                  -27%                    -50%              -54%              -68%               -71%                  -81%              -84% 
  Text::Table::Tiny               52000/s                   15689%            2268%              1531%                         1057%                   373%               268%              268%         163%                 163%                           152%                         15%                 --               -10%                   -10%                  -15%                    -42%              -47%              -63%               -66%                  -78%              -82% 
  Text::SimpleTable               57000/s                   17547%            2547%              1723%                         1194%                   429%               311%              311%         194%                 194%                           182%                         29%                11%                 --                     0%                   -5%                    -35%              -41%              -58%               -62%                  -76%              -80% 
  Text::Table::TinyWide           58000/s                   17547%            2547%              1723%                         1194%                   429%               311%              311%         194%                 194%                           182%                         29%                11%                 0%                     --                   -5%                    -35%              -41%              -58%               -62%                  -76%              -80% 
  Text::TabularDisplay            62000/s                   18650%            2712%              1837%                         1275%                   462%               337%              337%         212%                 212%                           200%                         37%                18%                 6%                     6%                    --                    -31%              -37%              -56%               -60%                  -75%              -78% 
  Text::Table::TinyColor          93000/s                   27172%            3990%              2718%                         1900%                   718%               536%              536%         354%                 354%                           336%                        100%                72%                54%                    54%                   45%                      --               -9%              -36%               -42%                  -63%              -69% 
  Text::Table::Any               100000/s                   29900%            4400%              3000%                         2100%                   800%               600%              600%         400%                 400%                           380%                        119%                89%                70%                    70%                   60%                      9%                --              -30%               -36%                  -60%              -66% 
  Text::Table::Org               140000/s                   42757%            6328%              4328%                         3042%                  1185%               900%              900%         614%                 614%                           585%                        214%               171%               142%                   142%                  128%                     57%               42%                --                -9%                  -42%              -51% 
  Text::Table::HTML              157000/s                   47069%            6975%              4774%                         3359%                  1315%              1000%             1000%         686%                 686%                           654%                        245%               198%               167%                   167%                  151%                     72%               57%               10%                 --                  -37%              -46% 
  Text::Table::Sprintf           300000/s                   74900%           11150%              7650%                         5400%                  2150%              1650%             1650%        1150%                1150%                          1100%                        450%               375%               325%                   325%                  300%                    175%              150%               75%                59%                    --              -15% 
  Text::Table::CSV               290000/s                   88135%           13135%              9017%                         6370%                  2547%              1958%             1958%        1370%                1370%                          1311%                        547%               458%               400%                   400%                  370%                    223%              194%              105%                87%                   17%                -- 
 
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

=for html <img src="data:image/png;base64,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" />


 #table5#
 {dataset=>"wide (30x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |        38 |   27      |                 0.00% |             40512.32% |   0.0002  |      21 |
 | Text::Table::More             |        70 |   10      |                86.60% |             21664.71% |   0.00051 |      20 |
 | Text::ANSITable               |        94 |   11      |               150.42% |             16117.93% | 2.1e-05   |      20 |
 | Text::ASCIITable              |       400 |    2      |              1076.87% |              3350.89% | 4.4e-05   |      20 |
 | Text::FormatTable             |       690 |    1.4    |              1735.53% |              2112.56% |   5e-06   |      20 |
 | Text::Table::TinyColorWide    |       840 |    1.2    |              2128.10% |              1722.73% | 5.6e-06   |      20 |
 | Text::Table::TinyBorderStyle  |       800 |    1      |              2132.79% |              1718.90% | 3.7e-05   |      21 |
 | Text::Table                   |      1000 |    1      |              2485.92% |              1470.52% | 2.7e-05   |      21 |
 | Text::Table::TinyWide         |      1200 |    0.81   |              3185.19% |              1136.22% | 1.3e-06   |      20 |
 | Text::Table::Manifold         |      1600 |    0.63   |              4119.82% |               862.42% | 3.6e-06   |      20 |
 | Text::SimpleTable             |      1600 |    0.63   |              4131.88% |               859.68% | 1.8e-06   |      20 |
 | Text::Table::Tiny             |      1900 |    0.53   |              4880.95% |               715.35% | 3.1e-06   |      21 |
 | Text::TabularDisplay          |      2300 |    0.43   |              6043.25% |               561.09% | 1.4e-06   |      20 |
 | Text::Table::TinyColor        |      3000 |    0.33   |              7955.73% |               404.14% | 4.3e-07   |      20 |
 | Text::MarkdownTable           |      3300 |    0.3    |              8706.27% |               361.17% | 1.8e-06   |      20 |
 | Text::Table::HTML             |      3720 |    0.269  |              9786.13% |               310.80% | 2.1e-07   |      20 |
 | Text::Table::HTML::DataTables |      5000 |    0.2    |             13199.23% |               205.37% | 4.3e-07   |      20 |
 | Text::Table::Org              |      8600 |    0.12   |             22757.70% |                77.67% | 2.1e-07   |      20 |
 | Text::Table::CSV              |     11800 |    0.0848 |             31278.91% |                29.43% | 2.3e-08   |      26 |
 | Text::Table::Any              |     15000 |    0.069  |             38641.46% |                 4.83% | 9.4e-08   |      26 |
 | Text::Table::Sprintf          |     15300 |    0.0655 |             40512.32% |                 0.00% | 2.6e-08   |      21 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                    Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyBorderStyle  Text::Table  Text::Table::TinyWide  Text::Table::Manifold  Text::SimpleTable  Text::Table::Tiny  Text::TabularDisplay  Text::Table::TinyColor  Text::MarkdownTable  Text::Table::HTML  Text::Table::HTML::DataTables  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table           38/s                       --             -59%               -62%              -92%               -94%                        -95%                          -96%         -96%                   -97%                   -97%               -97%               -98%                  -98%                    -98%                 -98%               -99%                           -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                   94/s                     145%               --                -9%              -81%               -87%                        -89%                          -90%         -90%                   -92%                   -94%               -94%               -95%                  -96%                    -97%                 -97%               -97%                           -98%              -98%              -99%              -99%                  -99% 
  Text::Table::More                 70/s                     170%              10%                 --              -80%               -86%                        -88%                          -90%         -90%                   -91%                   -93%               -93%               -94%                  -95%                    -96%                 -97%               -97%                           -98%              -98%              -99%              -99%                  -99% 
  Text::ASCIITable                 400/s                    1250%             450%               400%                --               -30%                        -40%                          -50%         -50%                   -59%                   -68%               -68%               -73%                  -78%                    -83%                 -85%               -86%                           -90%              -94%              -95%              -96%                  -96% 
  Text::FormatTable                690/s                    1828%             685%               614%               42%                 --                        -14%                          -28%         -28%                   -42%                   -55%               -55%               -62%                  -69%                    -76%                 -78%               -80%                           -85%              -91%              -93%              -95%                  -95% 
  Text::Table::TinyColorWide       840/s                    2150%             816%               733%               66%                16%                          --                          -16%         -16%                   -32%                   -47%               -47%               -55%                  -64%                    -72%                 -75%               -77%                           -83%              -90%              -92%              -94%                  -94% 
  Text::Table::TinyBorderStyle     800/s                    2600%            1000%               900%              100%                39%                         19%                            --           0%                   -18%                   -37%               -37%               -47%                  -57%                    -67%                 -70%               -73%                           -80%              -88%              -91%              -93%                  -93% 
  Text::Table                     1000/s                    2600%            1000%               900%              100%                39%                         19%                            0%           --                   -18%                   -37%               -37%               -47%                  -57%                    -67%                 -70%               -73%                           -80%              -88%              -91%              -93%                  -93% 
  Text::Table::TinyWide           1200/s                    3233%            1258%              1134%              146%                72%                         48%                           23%          23%                     --                   -22%               -22%               -34%                  -46%                    -59%                 -62%               -66%                           -75%              -85%              -89%              -91%                  -91% 
  Text::Table::Manifold           1600/s                    4185%            1646%              1487%              217%               122%                         90%                           58%          58%                    28%                     --                 0%               -15%                  -31%                    -47%                 -52%               -57%                           -68%              -80%              -86%              -89%                  -89% 
  Text::SimpleTable               1600/s                    4185%            1646%              1487%              217%               122%                         90%                           58%          58%                    28%                     0%                 --               -15%                  -31%                    -47%                 -52%               -57%                           -68%              -80%              -86%              -89%                  -89% 
  Text::Table::Tiny               1900/s                    4994%            1975%              1786%              277%               164%                        126%                           88%          88%                    52%                    18%                18%                 --                  -18%                    -37%                 -43%               -49%                           -62%              -77%              -84%              -86%                  -87% 
  Text::TabularDisplay            2300/s                    6179%            2458%              2225%              365%               225%                        179%                          132%         132%                    88%                    46%                46%                23%                    --                    -23%                 -30%               -37%                           -53%              -72%              -80%              -83%                  -84% 
  Text::Table::TinyColor          3000/s                    8081%            3233%              2930%              506%               324%                        263%                          203%         203%                   145%                    90%                90%                60%                   30%                      --                  -9%               -18%                           -39%              -63%              -74%              -79%                  -80% 
  Text::MarkdownTable             3300/s                    8900%            3566%              3233%              566%               366%                        300%                          233%         233%                   170%                   110%               110%                76%                   43%                     10%                   --               -10%                           -33%              -60%              -71%              -77%                  -78% 
  Text::Table::HTML               3720/s                    9937%            3989%              3617%              643%               420%                        346%                          271%         271%                   201%                   134%               134%                97%                   59%                     22%                  11%                 --                           -25%              -55%              -68%              -74%                  -75% 
  Text::Table::HTML::DataTables   5000/s                   13400%            5400%              4900%              900%               599%                        499%                          400%         400%                   305%                   215%               215%               165%                  114%                     64%                  49%                34%                             --              -40%              -57%              -65%                  -67% 
  Text::Table::Org                8600/s                   22400%            9066%              8233%             1566%              1066%                        900%                          733%         733%                   575%                   425%               425%               341%                  258%                    175%                 150%               124%                            66%                --              -29%              -42%                  -45% 
  Text::Table::CSV               11800/s                   31739%           12871%             11692%             2258%              1550%                       1315%                         1079%        1079%                   855%                   642%               642%               525%                  407%                    289%                 253%               217%                           135%               41%                --              -18%                  -22% 
  Text::Table::Any               15000/s                   39030%           15842%             14392%             2798%              1928%                       1639%                         1349%        1349%                  1073%                   813%               813%               668%                  523%                    378%                 334%               289%                           189%               73%               22%                --                   -5% 
  Text::Table::Sprintf           15300/s                   41121%           16693%             15167%             2953%              2037%                       1732%                         1426%        1426%                  1136%                   861%               861%               709%                  556%                    403%                 358%               310%                           205%               83%               29%                5%                    -- 
 
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

=for html <img src="data:image/png;base64,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" />


Benchmark module startup overhead (C<< bencher --cpanmodules-module TextTable --module-startup >>):

 #table6#
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                   | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |     170   |             161.9 |                 0.00% |              1964.19% |   0.00076 |      20 |
 | Text::Table::Manifold         |      94   |              85.9 |                78.43% |              1056.83% |   0.00068 |      20 |
 | Text::MarkdownTable           |      60   |              51.9 |               185.25% |               623.63% |   0.0026  |      20 |
 | Text::ANSITable               |      60   |              51.9 |               194.56% |               600.77% |   0.0011  |      20 |
 | Text::Table::TinyColorWide    |      35   |              26.9 |               380.86% |               329.27% |   0.00015 |      20 |
 | Text::Table::TinyWide         |      31   |              22.9 |               439.97% |               282.28% | 4.1e-05   |      21 |
 | Text::Table                   |      30   |              21.9 |               448.34% |               276.44% |   0.0011  |      20 |
 | Text::Table::More             |      24   |              15.9 |               584.22% |               201.68% | 2.9e-05   |      20 |
 | Text::Table::Tiny             |      20   |              11.9 |               734.43% |               147.38% | 8.3e-05   |      20 |
 | Text::ASCIITable              |      19   |              10.9 |               762.11% |               139.44% |   0.00013 |      20 |
 | Text::FormatTable             |      18   |               9.9 |               823.19% |               123.59% |   0.00016 |      21 |
 | Text::Table::TinyColor        |      16   |               7.9 |               973.92% |                92.21% | 5.1e-05   |      24 |
 | Text::Table::TinyBorderStyle  |      10   |               1.9 |              1186.11% |                60.50% |   0.00015 |      20 |
 | Text::Table::Any              |      13   |               4.9 |              1237.81% |                54.30% | 3.8e-05   |      21 |
 | Text::Table::HTML             |      11   |               2.9 |              1372.11% |                40.22% | 9.2e-05   |      20 |
 | Text::TabularDisplay          |      11   |               2.9 |              1385.72% |                38.94% | 1.8e-05   |      20 |
 | Text::SimpleTable             |      11   |               2.9 |              1395.75% |                38.00% | 2.4e-05   |      20 |
 | Text::Table::HTML::DataTables |      10.7 |               2.6 |              1472.30% |                31.29% |   1e-05   |      20 |
 | Text::Table::Org              |      10   |               1.9 |              1506.60% |                28.48% | 1.8e-05   |      20 |
 | Text::Table::CSV              |       9   |               0.9 |              1710.18% |                14.03% |   0.00014 |      20 |
 | Text::Table::Sprintf          |       8.5 |               0.4 |              1865.69% |                 5.01% | 1.2e-05   |      20 |
 | perl -e1 (baseline)           |       8.1 |               0   |              1964.19% |                 0.00% | 1.2e-05   |      20 |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                    Rate  Text::UnicodeBox::Table  Text::Table::Manifold  Text::MarkdownTable  Text::ANSITable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::Table  Text::Table::More  Text::Table::Tiny  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColor  Text::Table::Any  Text::Table::HTML  Text::TabularDisplay  Text::SimpleTable  Text::Table::HTML::DataTables  Text::Table::TinyBorderStyle  Text::Table::Org  Text::Table::CSV  Text::Table::Sprintf  perl -e1 (baseline) 
  Text::UnicodeBox::Table          5.9/s                       --                   -44%                 -64%             -64%                        -79%                   -81%         -82%               -85%               -88%              -88%               -89%                    -90%              -92%               -93%                  -93%               -93%                           -93%                          -94%              -94%              -94%                  -95%                 -95% 
  Text::Table::Manifold           10.6/s                      80%                     --                 -36%             -36%                        -62%                   -67%         -68%               -74%               -78%              -79%               -80%                    -82%              -86%               -88%                  -88%               -88%                           -88%                          -89%              -89%              -90%                  -90%                 -91% 
  Text::MarkdownTable             16.7/s                     183%                    56%                   --               0%                        -41%                   -48%         -50%               -60%               -66%              -68%               -70%                    -73%              -78%               -81%                  -81%               -81%                           -82%                          -83%              -83%              -85%                  -85%                 -86% 
  Text::ANSITable                 16.7/s                     183%                    56%                   0%               --                        -41%                   -48%         -50%               -60%               -66%              -68%               -70%                    -73%              -78%               -81%                  -81%               -81%                           -82%                          -83%              -83%              -85%                  -85%                 -86% 
  Text::Table::TinyColorWide      28.6/s                     385%                   168%                  71%              71%                          --                   -11%         -14%               -31%               -42%              -45%               -48%                    -54%              -62%               -68%                  -68%               -68%                           -69%                          -71%              -71%              -74%                  -75%                 -76% 
  Text::Table::TinyWide           32.3/s                     448%                   203%                  93%              93%                         12%                     --          -3%               -22%               -35%              -38%               -41%                    -48%              -58%               -64%                  -64%               -64%                           -65%                          -67%              -67%              -70%                  -72%                 -73% 
  Text::Table                     33.3/s                     466%                   213%                 100%             100%                         16%                     3%           --               -19%               -33%              -36%               -40%                    -46%              -56%               -63%                  -63%               -63%                           -64%                          -66%              -66%              -70%                  -71%                 -73% 
  Text::Table::More               41.7/s                     608%                   291%                 150%             150%                         45%                    29%          25%                 --               -16%              -20%               -25%                    -33%              -45%               -54%                  -54%               -54%                           -55%                          -58%              -58%              -62%                  -64%                 -66% 
  Text::Table::Tiny               50.0/s                     750%                   370%                 200%             200%                         75%                    55%          50%                19%                 --               -5%                -9%                    -19%              -35%               -44%                  -44%               -44%                           -46%                          -50%              -50%              -55%                  -57%                 -59% 
  Text::ASCIITable                52.6/s                     794%                   394%                 215%             215%                         84%                    63%          57%                26%                 5%                --                -5%                    -15%              -31%               -42%                  -42%               -42%                           -43%                          -47%              -47%              -52%                  -55%                 -57% 
  Text::FormatTable               55.6/s                     844%                   422%                 233%             233%                         94%                    72%          66%                33%                11%                5%                 --                    -11%              -27%               -38%                  -38%               -38%                           -40%                          -44%              -44%              -50%                  -52%                 -55% 
  Text::Table::TinyColor          62.5/s                     962%                   487%                 275%             275%                        118%                    93%          87%                50%                25%               18%                12%                      --              -18%               -31%                  -31%               -31%                           -33%                          -37%              -37%              -43%                  -46%                 -49% 
  Text::Table::Any                76.9/s                    1207%                   623%                 361%             361%                        169%                   138%         130%                84%                53%               46%                38%                     23%                --               -15%                  -15%               -15%                           -17%                          -23%              -23%              -30%                  -34%                 -37% 
  Text::Table::HTML               90.9/s                    1445%                   754%                 445%             445%                        218%                   181%         172%               118%                81%               72%                63%                     45%               18%                 --                    0%                 0%                            -2%                           -9%               -9%              -18%                  -22%                 -26% 
  Text::TabularDisplay            90.9/s                    1445%                   754%                 445%             445%                        218%                   181%         172%               118%                81%               72%                63%                     45%               18%                 0%                    --                 0%                            -2%                           -9%               -9%              -18%                  -22%                 -26% 
  Text::SimpleTable               90.9/s                    1445%                   754%                 445%             445%                        218%                   181%         172%               118%                81%               72%                63%                     45%               18%                 0%                    0%                 --                            -2%                           -9%               -9%              -18%                  -22%                 -26% 
  Text::Table::HTML::DataTables   93.5/s                    1488%                   778%                 460%             460%                        227%                   189%         180%               124%                86%               77%                68%                     49%               21%                 2%                    2%                 2%                             --                           -6%               -6%              -15%                  -20%                 -24% 
  Text::Table::TinyBorderStyle   100.0/s                    1600%                   840%                 500%             500%                        250%                   210%         200%               140%               100%               89%                80%                     60%               30%                10%                   10%                10%                             6%                            --                0%               -9%                  -15%                 -19% 
  Text::Table::Org               100.0/s                    1600%                   840%                 500%             500%                        250%                   210%         200%               140%               100%               89%                80%                     60%               30%                10%                   10%                10%                             6%                            0%                --               -9%                  -15%                 -19% 
  Text::Table::CSV               111.1/s                    1788%                   944%                 566%             566%                        288%                   244%         233%               166%               122%              111%               100%                     77%               44%                22%                   22%                22%                            18%                           11%               11%                --                   -5%                 -10% 
  Text::Table::Sprintf           117.6/s                    1900%                  1005%                 605%             605%                        311%                   264%         252%               182%               135%              123%               111%                     88%               52%                29%                   29%                29%                            25%                           17%               17%                5%                    --                  -4% 
  perl -e1 (baseline)            123.5/s                    1998%                  1060%                 640%             640%                        332%                   282%         270%               196%               146%              134%               122%                     97%               60%                35%                   35%                35%                            32%                           23%               23%               11%                    4%                   -- 
 
 Legends:
   Text::ANSITable: mod_overhead_time=51.9 participant=Text::ANSITable
   Text::ASCIITable: mod_overhead_time=10.9 participant=Text::ASCIITable
   Text::FormatTable: mod_overhead_time=9.9 participant=Text::FormatTable
   Text::MarkdownTable: mod_overhead_time=51.9 participant=Text::MarkdownTable
   Text::SimpleTable: mod_overhead_time=2.9 participant=Text::SimpleTable
   Text::Table: mod_overhead_time=21.9 participant=Text::Table
   Text::Table::Any: mod_overhead_time=4.9 participant=Text::Table::Any
   Text::Table::CSV: mod_overhead_time=0.9 participant=Text::Table::CSV
   Text::Table::HTML: mod_overhead_time=2.9 participant=Text::Table::HTML
   Text::Table::HTML::DataTables: mod_overhead_time=2.6 participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: mod_overhead_time=85.9 participant=Text::Table::Manifold
   Text::Table::More: mod_overhead_time=15.9 participant=Text::Table::More
   Text::Table::Org: mod_overhead_time=1.9 participant=Text::Table::Org
   Text::Table::Sprintf: mod_overhead_time=0.4 participant=Text::Table::Sprintf
   Text::Table::Tiny: mod_overhead_time=11.9 participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: mod_overhead_time=1.9 participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: mod_overhead_time=7.9 participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: mod_overhead_time=26.9 participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: mod_overhead_time=22.9 participant=Text::Table::TinyWide
   Text::TabularDisplay: mod_overhead_time=2.9 participant=Text::TabularDisplay
   Text::UnicodeBox::Table: mod_overhead_time=161.9 participant=Text::UnicodeBox::Table
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

=for html <img src="data:image/png;base64,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" />


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
 <link rel="stylesheet" type="text/css" href="file:///home/u1/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/auto/share/dist/Text-Table-HTML-DataTables/datatables-1.10.22/datatables.css">
 <script src="file:///home/u1/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/auto/share/dist/Text-Table-HTML-DataTables/jquery-2.2.4/jquery-2.2.4.min.js"></script>
 <script src="file:///home/u1/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/auto/share/dist/Text-Table-HTML-DataTables/datatables-1.10.22/datatables.js"></script>
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
