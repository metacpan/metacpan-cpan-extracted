package Acme::CPANModules::TextTable;

use 5.010001;
use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-16'; # DATE
our $DIST = 'Acme-CPANModules-TextTable'; # DIST
our $VERSION = '0.014'; # VERSION

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

This document describes version 0.014 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2023-02-16.

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

L<Text::Table::Tiny> 1.02

L<Text::Table::TinyBorderStyle> 0.005

L<Text::Table::More> 0.025

L<Text::Table::Sprintf> 0.006

L<Text::Table::TinyColor> 0.002

L<Text::Table::TinyColorWide> 0.001

L<Text::Table::TinyWide> 0.001

L<Text::Table::Org> 0.031

L<Text::Table::CSV> 0.023

L<Text::Table::HTML> 0.009

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
 | Text::UnicodeBox::Table       |       1   |     990   |                 0.00% |             39075.07% |   0.0093  |      20 |
 | Text::ANSITable               |       2.3 |     440   |               122.45% |             17511.06% |   0.001   |      20 |
 | Text::Table::More             |       2.9 |     350   |               183.78% |             13704.67% |   0.00074 |      20 |
 | Text::ASCIITable              |      12   |      86   |              1044.26% |              3323.61% |   0.00015 |      20 |
 | Text::FormatTable             |      17   |      59   |              1583.12% |              2227.53% |   0.00017 |      21 |
 | Text::Table::TinyColorWide    |      17   |      58   |              1601.03% |              2203.02% |   0.0001  |      20 |
 | Text::Table::TinyWide         |      24   |      41   |              2297.54% |              1533.97% | 7.2e-05   |      20 |
 | Text::SimpleTable             |      32   |      32   |              3016.17% |              1157.16% |   0.00011 |      20 |
 | Text::Table::HTML             |      35   |      29   |              3312.65% |              1047.94% | 6.5e-05   |      20 |
 | Text::Table::Manifold         |      39   |      26   |              3719.11% |               925.76% | 8.6e-05   |      20 |
 | Text::Table::Tiny             |      41   |      24   |              3964.21% |               863.90% | 8.3e-05   |      20 |
 | Text::TabularDisplay          |      47   |      21   |              4546.04% |               743.19% |   0.0002  |      20 |
 | Text::Table::TinyColor        |      62   |      16   |              5986.13% |               543.68% | 4.5e-05   |      20 |
 | Text::MarkdownTable           |      86   |      12   |              8370.09% |               362.51% | 2.4e-05   |      20 |
 | Text::Table                   |     110   |       9.4 |             10414.16% |               272.59% | 3.3e-05   |      20 |
 | Text::Table::HTML::DataTables |     130   |       7.9 |             12381.60% |               213.86% | 2.7e-05   |      20 |
 | Text::Table::TinyBorderStyle  |     220   |       4.5 |             21965.23% |                77.54% | 1.4e-05   |      20 |
 | Text::Table::CSV              |     230   |       4.4 |             22292.34% |                74.95% | 1.7e-05   |      20 |
 | Text::Table::Org              |     230   |       4.3 |             22710.59% |                71.74% | 2.1e-05   |      20 |
 | Text::Table::Sprintf          |     360   |       2.8 |             35801.17% |                 9.12% |   1e-05   |      20 |
 | Text::Table::Any              |     400   |       2.5 |             39075.07% |                 0.00% | 1.3e-05   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                  Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::SimpleTable  Text::Table::HTML  Text::Table::Manifold  Text::Table::Tiny  Text::TabularDisplay  Text::Table::TinyColor  Text::MarkdownTable  Text::Table  Text::Table::HTML::DataTables  Text::Table::TinyBorderStyle  Text::Table::CSV  Text::Table::Org  Text::Table::Sprintf  Text::Table::Any 
  Text::UnicodeBox::Table          1/s                       --             -55%               -64%              -91%               -94%                        -94%                   -95%               -96%               -97%                   -97%               -97%                  -97%                    -98%                 -98%         -99%                           -99%                          -99%              -99%              -99%                  -99%              -99% 
  Text::ANSITable                2.3/s                     125%               --               -20%              -80%               -86%                        -86%                   -90%               -92%               -93%                   -94%               -94%                  -95%                    -96%                 -97%         -97%                           -98%                          -98%              -99%              -99%                  -99%              -99% 
  Text::Table::More              2.9/s                     182%              25%                 --              -75%               -83%                        -83%                   -88%               -90%               -91%                   -92%               -93%                  -94%                    -95%                 -96%         -97%                           -97%                          -98%              -98%              -98%                  -99%              -99% 
  Text::ASCIITable                12/s                    1051%             411%               306%                --               -31%                        -32%                   -52%               -62%               -66%                   -69%               -72%                  -75%                    -81%                 -86%         -89%                           -90%                          -94%              -94%              -95%                  -96%              -97% 
  Text::FormatTable               17/s                    1577%             645%               493%               45%                 --                         -1%                   -30%               -45%               -50%                   -55%               -59%                  -64%                    -72%                 -79%         -84%                           -86%                          -92%              -92%              -92%                  -95%              -95% 
  Text::Table::TinyColorWide      17/s                    1606%             658%               503%               48%                 1%                          --                   -29%               -44%               -50%                   -55%               -58%                  -63%                    -72%                 -79%         -83%                           -86%                          -92%              -92%              -92%                  -95%              -95% 
  Text::Table::TinyWide           24/s                    2314%             973%               753%              109%                43%                         41%                     --               -21%               -29%                   -36%               -41%                  -48%                    -60%                 -70%         -77%                           -80%                          -89%              -89%              -89%                  -93%              -93% 
  Text::SimpleTable               32/s                    2993%            1275%               993%              168%                84%                         81%                    28%                 --                -9%                   -18%               -25%                  -34%                    -50%                 -62%         -70%                           -75%                          -85%              -86%              -86%                  -91%              -92% 
  Text::Table::HTML               35/s                    3313%            1417%              1106%              196%               103%                        100%                    41%                10%                 --                   -10%               -17%                  -27%                    -44%                 -58%         -67%                           -72%                          -84%              -84%              -85%                  -90%              -91% 
  Text::Table::Manifold           39/s                    3707%            1592%              1246%              230%               126%                        123%                    57%                23%                11%                     --                -7%                  -19%                    -38%                 -53%         -63%                           -69%                          -82%              -83%              -83%                  -89%              -90% 
  Text::Table::Tiny               41/s                    4025%            1733%              1358%              258%               145%                        141%                    70%                33%                20%                     8%                 --                  -12%                    -33%                 -50%         -60%                           -67%                          -81%              -81%              -82%                  -88%              -89% 
  Text::TabularDisplay            47/s                    4614%            1995%              1566%              309%               180%                        176%                    95%                52%                38%                    23%                14%                    --                    -23%                 -42%         -55%                           -62%                          -78%              -79%              -79%                  -86%              -88% 
  Text::Table::TinyColor          62/s                    6087%            2650%              2087%              437%               268%                        262%                   156%               100%                81%                    62%                50%                   31%                      --                 -25%         -41%                           -50%                          -71%              -72%              -73%                  -82%              -84% 
  Text::MarkdownTable             86/s                    8150%            3566%              2816%              616%               391%                        383%                   241%               166%               141%                   116%               100%                   75%                     33%                   --         -21%                           -34%                          -62%              -63%              -64%                  -76%              -79% 
  Text::Table                    110/s                   10431%            4580%              3623%              814%               527%                        517%                   336%               240%               208%                   176%               155%                  123%                     70%                  27%           --                           -15%                          -52%              -53%              -54%                  -70%              -73% 
  Text::Table::HTML::DataTables  130/s                   12431%            5469%              4330%              988%               646%                        634%                   418%               305%               267%                   229%               203%                  165%                    102%                  51%          18%                             --                          -43%              -44%              -45%                  -64%              -68% 
  Text::Table::TinyBorderStyle   220/s                   21900%            9677%              7677%             1811%              1211%                       1188%                   811%               611%               544%                   477%               433%                  366%                    255%                 166%         108%                            75%                            --               -2%               -4%                  -37%              -44% 
  Text::Table::CSV               230/s                   22399%            9899%              7854%             1854%              1240%                       1218%                   831%               627%               559%                   490%               445%                  377%                    263%                 172%         113%                            79%                            2%                --               -2%                  -36%              -43% 
  Text::Table::Org               230/s                   22923%           10132%              8039%             1900%              1272%                       1248%                   853%               644%               574%                   504%               458%                  388%                    272%                 179%         118%                            83%                            4%                2%                --                  -34%              -41% 
  Text::Table::Sprintf           360/s                   35257%           15614%             12400%             2971%              2007%                       1971%                  1364%              1042%               935%                   828%               757%                  650%                    471%                 328%         235%                           182%                           60%               57%               53%                    --              -10% 
  Text::Table::Any               400/s                   39500%           17500%             13900%             3340%              2260%                       2220%                  1539%              1180%              1060%                   940%               860%                  740%                    540%                 380%         276%                           216%                           80%               76%               72%                   11%                -- 
 
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


 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |       7.8 |   130     |                 0.00% |             37283.05% |   0.0012  |      20 |
 | Text::ANSITable               |      20   |    50     |               155.65% |             14522.58% |   0.00018 |      20 |
 | Text::Table::More             |      25   |    40     |               218.34% |             11643.01% | 9.2e-05   |      20 |
 | Text::ASCIITable              |     100   |     8     |              1451.05% |              2310.18% |   0.0001  |      21 |
 | Text::FormatTable             |     160   |     6.3   |              1932.80% |              1738.99% | 1.1e-05   |      20 |
 | Text::Table::TinyColorWide    |     170   |     5.8   |              2113.73% |              1588.69% | 1.7e-05   |      20 |
 | Text::Table::TinyWide         |     250   |     4.1   |              3045.53% |              1088.45% | 1.3e-05   |      20 |
 | Text::SimpleTable             |     310   |     3.3   |              3791.86% |               860.54% | 7.8e-06   |      20 |
 | Text::TabularDisplay          |     340   |     2.9   |              4242.44% |               760.88% | 2.5e-05   |      20 |
 | Text::Table::Manifold         |     350   |     2.8   |              4380.44% |               734.36% | 1.6e-05   |      21 |
 | Text::Table::Tiny             |     380   |     2.6   |              4796.42% |               663.48% | 1.1e-05   |      20 |
 | Text::Table::HTML             |     400   |     2     |              5268.89% |               596.29% | 2.6e-05   |      20 |
 | Text::MarkdownTable           |     430   |     2.3   |              5342.75% |               586.84% | 5.8e-06   |      20 |
 | Text::Table                   |     510   |     2     |              6390.17% |               476.00% | 7.4e-06   |      20 |
 | Text::Table::TinyColor        |     590   |     1.7   |              7481.10% |               393.11% |   5e-06   |      21 |
 | Text::Table::HTML::DataTables |     990   |     1     |             12555.73% |               195.38% | 5.4e-06   |      20 |
 | Text::Table::TinyBorderStyle  |    1400   |     0.73  |             17384.03% |               113.81% | 1.1e-06   |      20 |
 | Text::Table::Org              |    1600   |     0.61  |             20935.91% |                77.71% | 3.8e-06   |      20 |
 | Text::Table::CSV              |    1800   |     0.556 |             22842.23% |                62.94% | 2.1e-07   |      20 |
 | Text::Table::Any              |    2880   |     0.348 |             36587.08% |                 1.90% | 2.1e-07   |      20 |
 | Text::Table::Sprintf          |    2930   |     0.341 |             37283.05% |                 0.00% | 2.7e-07   |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                   Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::SimpleTable  Text::TabularDisplay  Text::Table::Manifold  Text::Table::Tiny  Text::MarkdownTable  Text::Table::HTML  Text::Table  Text::Table::TinyColor  Text::Table::HTML::DataTables  Text::Table::TinyBorderStyle  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table         7.8/s                       --             -61%               -69%              -93%               -95%                        -95%                   -96%               -97%                  -97%                   -97%               -98%                 -98%               -98%         -98%                    -98%                           -99%                          -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                  20/s                     160%               --               -19%              -84%               -87%                        -88%                   -91%               -93%                  -94%                   -94%               -94%                 -95%               -96%         -96%                    -96%                           -98%                          -98%              -98%              -98%              -99%                  -99% 
  Text::Table::More                25/s                     225%              25%                 --              -80%               -84%                        -85%                   -89%               -91%                  -92%                   -93%               -93%                 -94%               -95%         -95%                    -95%                           -97%                          -98%              -98%              -98%              -99%                  -99% 
  Text::ASCIITable                100/s                    1525%             525%               400%                --               -21%                        -27%                   -48%               -58%                  -63%                   -65%               -67%                 -71%               -75%         -75%                    -78%                           -87%                          -90%              -92%              -93%              -95%                  -95% 
  Text::FormatTable               160/s                    1963%             693%               534%               26%                 --                         -7%                   -34%               -47%                  -53%                   -55%               -58%                 -63%               -68%         -68%                    -73%                           -84%                          -88%              -90%              -91%              -94%                  -94% 
  Text::Table::TinyColorWide      170/s                    2141%             762%               589%               37%                 8%                          --                   -29%               -43%                  -50%                   -51%               -55%                 -60%               -65%         -65%                    -70%                           -82%                          -87%              -89%              -90%              -94%                  -94% 
  Text::Table::TinyWide           250/s                    3070%            1119%               875%               95%                53%                         41%                     --               -19%                  -29%                   -31%               -36%                 -43%               -51%         -51%                    -58%                           -75%                          -82%              -85%              -86%              -91%                  -91% 
  Text::SimpleTable               310/s                    3839%            1415%              1112%              142%                90%                         75%                    24%                 --                  -12%                   -15%               -21%                 -30%               -39%         -39%                    -48%                           -69%                          -77%              -81%              -83%              -89%                  -89% 
  Text::TabularDisplay            340/s                    4382%            1624%              1279%              175%               117%                        100%                    41%                13%                    --                    -3%               -10%                 -20%               -31%         -31%                    -41%                           -65%                          -74%              -78%              -80%              -88%                  -88% 
  Text::Table::Manifold           350/s                    4542%            1685%              1328%              185%               125%                        107%                    46%                17%                    3%                     --                -7%                 -17%               -28%         -28%                    -39%                           -64%                          -73%              -78%              -80%              -87%                  -87% 
  Text::Table::Tiny               380/s                    4900%            1823%              1438%              207%               142%                        123%                    57%                26%                   11%                     7%                 --                 -11%               -23%         -23%                    -34%                           -61%                          -71%              -76%              -78%              -86%                  -86% 
  Text::MarkdownTable             430/s                    5552%            2073%              1639%              247%               173%                        152%                    78%                43%                   26%                    21%                13%                   --               -13%         -13%                    -26%                           -56%                          -68%              -73%              -75%              -84%                  -85% 
  Text::Table::HTML               400/s                    6400%            2400%              1900%              300%               215%                        190%                   104%                64%                   44%                    39%                30%                  14%                 --           0%                    -15%                           -50%                          -63%              -69%              -72%              -82%                  -82% 
  Text::Table                     510/s                    6400%            2400%              1900%              300%               215%                        190%                   104%                64%                   44%                    39%                30%                  14%                 0%           --                    -15%                           -50%                          -63%              -69%              -72%              -82%                  -82% 
  Text::Table::TinyColor          590/s                    7547%            2841%              2252%              370%               270%                        241%                   141%                94%                   70%                    64%                52%                  35%                17%          17%                      --                           -41%                          -57%              -64%              -67%              -79%                  -79% 
  Text::Table::HTML::DataTables   990/s                   12900%            4900%              3900%              700%               530%                        480%                   309%               229%                  190%                   179%               160%                 129%               100%         100%                     70%                             --                          -27%              -39%              -44%              -65%                  -65% 
  Text::Table::TinyBorderStyle   1400/s                   17708%            6749%              5379%              995%               763%                        694%                   461%               352%                  297%                   283%               256%                 215%               173%         173%                    132%                            36%                            --              -16%              -23%              -52%                  -53% 
  Text::Table::Org               1600/s                   21211%            8096%              6457%             1211%               932%                        850%                   572%               440%                  375%                   359%               326%                 277%               227%         227%                    178%                            63%                           19%                --               -8%              -42%                  -44% 
  Text::Table::CSV               1800/s                   23281%            8892%              7094%             1338%              1033%                        943%                   637%               493%                  421%                   403%               367%                 313%               259%         259%                    205%                            79%                           31%                9%                --              -37%                  -38% 
  Text::Table::Any               2880/s                   37256%           14267%             11394%             2198%              1710%                       1566%                  1078%               848%                  733%                   704%               647%                 560%               474%         474%                    388%                           187%                          109%               75%               59%                --                   -2% 
  Text::Table::Sprintf           2930/s                   38023%           14562%             11630%             2246%              1747%                       1600%                  1102%               867%                  750%                   721%               662%                 574%               486%         486%                    398%                           193%                          114%               78%               63%                2%                    -- 
 
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
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::UnicodeBox::Table       |       200 |    5      |                 0.00% |             49318.62% | 6.5e-05 |      20 |
 | Text::ANSITable               |       710 |    1.4    |               273.25% |             13140.15% | 5.4e-06 |      20 |
 | Text::Table::More             |      1000 |    0.99   |               432.26% |              9184.73% | 1.8e-06 |      20 |
 | Text::Table::TinyBorderStyle  |      3900 |    0.26   |              1949.48% |              2311.27% | 6.9e-07 |      20 |
 | Text::ASCIITable              |      4800 |    0.21   |              2417.39% |              1863.09% | 1.3e-06 |      21 |
 | Text::FormatTable             |      6800 |    0.15   |              3516.95% |              1266.30% | 6.9e-07 |      20 |
 | Text::Table                   |      7700 |    0.13   |              3978.23% |              1111.77% | 2.5e-07 |      22 |
 | Text::Table::Manifold         |      7800 |    0.13   |              4013.06% |              1101.50% | 2.1e-07 |      20 |
 | Text::Table::TinyColorWide    |      7900 |    0.13   |              4082.92% |              1081.44% | 2.1e-07 |      20 |
 | Text::Table::TinyWide         |     11000 |    0.089  |              5805.69% |               736.80% | 1.1e-07 |      20 |
 | Text::MarkdownTable           |     12000 |    0.081  |              6428.62% |               656.95% | 8.6e-08 |      31 |
 | Text::SimpleTable             |     13000 |    0.077  |              6777.54% |               618.55% |   1e-07 |      33 |
 | Text::TabularDisplay          |     15000 |    0.066  |              7937.39% |               514.86% | 4.3e-07 |      20 |
 | Text::Table::HTML::DataTables |     15000 |    0.066  |              7962.70% |               512.93% | 9.5e-08 |      25 |
 | Text::Table::Tiny             |     15300 |    0.0653 |              7993.91% |               510.57% | 2.6e-08 |      21 |
 | Text::Table::TinyColor        |     24000 |    0.0417 |             12569.86% |               290.05% | 1.3e-08 |      20 |
 | Text::Table::HTML             |     24800 |    0.0403 |             13012.25% |               276.89% | 1.3e-08 |      20 |
 | Text::Table::Org              |     52600 |    0.019  |             27683.28% |                77.87% | 6.1e-09 |      24 |
 | Text::Table::CSV              |     78900 |    0.0127 |             41573.53% |                18.59% |   5e-09 |      35 |
 | Text::Table::Any              |     80600 |    0.0124 |             42507.83% |                15.98% | 3.3e-09 |      20 |
 | Text::Table::Sprintf          |     93500 |    0.0107 |             49318.62% |                 0.00% |   3e-09 |      24 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                    Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::Table::TinyBorderStyle  Text::ASCIITable  Text::FormatTable  Text::Table  Text::Table::Manifold  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::MarkdownTable  Text::SimpleTable  Text::TabularDisplay  Text::Table::HTML::DataTables  Text::Table::Tiny  Text::Table::TinyColor  Text::Table::HTML  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table          200/s                       --             -72%               -80%                          -94%              -95%               -97%         -97%                   -97%                        -97%                   -98%                 -98%               -98%                  -98%                           -98%               -98%                    -99%               -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                  710/s                     257%               --               -29%                          -81%              -85%               -89%         -90%                   -90%                        -90%                   -93%                 -94%               -94%                  -95%                           -95%               -95%                    -97%               -97%              -98%              -99%              -99%                  -99% 
  Text::Table::More               1000/s                     405%              41%                 --                          -73%              -78%               -84%         -86%                   -86%                        -86%                   -91%                 -91%               -92%                  -93%                           -93%               -93%                    -95%               -95%              -98%              -98%              -98%                  -98% 
  Text::Table::TinyBorderStyle    3900/s                    1823%             438%               280%                            --              -19%               -42%         -50%                   -50%                        -50%                   -65%                 -68%               -70%                  -74%                           -74%               -74%                    -83%               -84%              -92%              -95%              -95%                  -95% 
  Text::ASCIITable                4800/s                    2280%             566%               371%                           23%                --               -28%         -38%                   -38%                        -38%                   -57%                 -61%               -63%                  -68%                           -68%               -68%                    -80%               -80%              -90%              -93%              -94%                  -94% 
  Text::FormatTable               6800/s                    3233%             833%               560%                           73%               39%                 --         -13%                   -13%                        -13%                   -40%                 -46%               -48%                  -55%                           -55%               -56%                    -72%               -73%              -87%              -91%              -91%                  -92% 
  Text::Table                     7700/s                    3746%             976%               661%                          100%               61%                15%           --                     0%                          0%                   -31%                 -37%               -40%                  -49%                           -49%               -49%                    -67%               -69%              -85%              -90%              -90%                  -91% 
  Text::Table::Manifold           7800/s                    3746%             976%               661%                          100%               61%                15%           0%                     --                          0%                   -31%                 -37%               -40%                  -49%                           -49%               -49%                    -67%               -69%              -85%              -90%              -90%                  -91% 
  Text::Table::TinyColorWide      7900/s                    3746%             976%               661%                          100%               61%                15%           0%                     0%                          --                   -31%                 -37%               -40%                  -49%                           -49%               -49%                    -67%               -69%              -85%              -90%              -90%                  -91% 
  Text::Table::TinyWide          11000/s                    5517%            1473%              1012%                          192%              135%                68%          46%                    46%                         46%                     --                  -8%               -13%                  -25%                           -25%               -26%                    -53%               -54%              -78%              -85%              -86%                  -87% 
  Text::MarkdownTable            12000/s                    6072%            1628%              1122%                          220%              159%                85%          60%                    60%                         60%                     9%                   --                -4%                  -18%                           -18%               -19%                    -48%               -50%              -76%              -84%              -84%                  -86% 
  Text::SimpleTable              13000/s                    6393%            1718%              1185%                          237%              172%                94%          68%                    68%                         68%                    15%                   5%                 --                  -14%                           -14%               -15%                    -45%               -47%              -75%              -83%              -83%                  -86% 
  Text::TabularDisplay           15000/s                    7475%            2021%              1400%                          293%              218%               127%          96%                    96%                         96%                    34%                  22%                16%                    --                             0%                -1%                    -36%               -38%              -71%              -80%              -81%                  -83% 
  Text::Table::HTML::DataTables  15000/s                    7475%            2021%              1400%                          293%              218%               127%          96%                    96%                         96%                    34%                  22%                16%                    0%                             --                -1%                    -36%               -38%              -71%              -80%              -81%                  -83% 
  Text::Table::Tiny              15300/s                    7556%            2043%              1416%                          298%              221%               129%          99%                    99%                         99%                    36%                  24%                17%                    1%                             1%                 --                    -36%               -38%              -70%              -80%              -81%                  -83% 
  Text::Table::TinyColor         24000/s                   11890%            3257%              2274%                          523%              403%               259%         211%                   211%                        211%                   113%                  94%                84%                   58%                            58%                56%                      --                -3%              -54%              -69%              -70%                  -74% 
  Text::Table::HTML              24800/s                   12306%            3373%              2356%                          545%              421%               272%         222%                   222%                        222%                   120%                 100%                91%                   63%                            63%                62%                      3%                 --              -52%              -68%              -69%                  -73% 
  Text::Table::Org               52600/s                   26215%            7268%              5110%                         1268%             1005%               689%         584%                   584%                        584%                   368%                 326%               305%                  247%                           247%               243%                    119%               112%                --              -33%              -34%                  -43% 
  Text::Table::CSV               78900/s                   39270%           10923%              7695%                         1947%             1553%              1081%         923%                   923%                        923%                   600%                 537%               506%                  419%                           419%               414%                    228%               217%               49%                --               -2%                  -15% 
  Text::Table::Any               80600/s                   40222%           11190%              7883%                         1996%             1593%              1109%         948%                   948%                        948%                   617%                 553%               520%                  432%                           432%               426%                    236%               225%               53%                2%                --                  -13% 
  Text::Table::Sprintf           93500/s                   46628%           12984%              9152%                         2329%             1862%              1301%        1114%                  1114%                       1114%                   731%                 657%               619%                  516%                           516%               510%                    289%               276%               77%               18%               15%                    -- 
 
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
 | Text::UnicodeBox::Table       |     400   | 3         |                 0.00% |             75061.76% | 7.2e-05 |      20 |
 | Text::ANSITable               |    2300   | 0.44      |               481.41% |             12827.45% | 1.3e-06 |      20 |
 | Text::Table::More             |    3000   | 0.33      |               673.26% |              9620.14% | 2.2e-06 |      20 |
 | Text::Table::TinyBorderStyle  |    4800   | 0.21      |              1127.95% |              6020.92% | 6.9e-07 |      20 |
 | Text::Table::Manifold         |   14000   | 0.073     |              3390.75% |              2053.17% | 1.1e-07 |      20 |
 | Text::ASCIITable              |   17000   | 0.06      |              4189.96% |              1652.04% | 3.5e-07 |      20 |
 | Text::Table                   |   20000   | 0.05      |              4719.47% |              1459.55% | 6.7e-07 |      20 |
 | Text::Table::HTML::DataTables |   21000   | 0.048     |              5262.00% |              1301.75% | 9.7e-08 |      24 |
 | Text::MarkdownTable           |   25000   | 0.04      |              6258.17% |              1082.13% | 1.1e-07 |      20 |
 | Text::FormatTable             |   34000   | 0.029     |              8611.91% |               762.75% | 1.1e-07 |      22 |
 | Text::Table::TinyColorWide    |   46000   | 0.022     |             11750.19% |               534.27% |   3e-08 |      24 |
 | Text::Table::Tiny             |   54000   | 0.018     |             13862.61% |               438.31% | 2.6e-08 |      21 |
 | Text::Table::TinyWide         |   60000   | 0.017     |             15386.79% |               385.33% |   2e-08 |      20 |
 | Text::TabularDisplay          |   62468.1 | 0.0160082 |             15911.46% |               369.42% |   0     |      20 |
 | Text::SimpleTable             |   64700   | 0.0155    |             16471.25% |               353.57% | 6.7e-09 |      20 |
 | Text::Table::TinyColor        |   91000   | 0.011     |             23131.41% |               223.54% | 1.3e-08 |      22 |
 | Text::Table::HTML             |  120000   | 0.0082    |             31181.42% |               140.28% |   1e-08 |      20 |
 | Text::Table::Org              |  142000   | 0.00703   |             36356.69% |               106.17% | 2.9e-09 |      26 |
 | Text::Table::Any              |  180000   | 0.0054    |             47266.53% |                58.68% | 6.5e-09 |      21 |
 | Text::Table::Sprintf          |  270000   | 0.0037    |             68997.45% |                 8.78% | 1.3e-08 |      20 |
 | Text::Table::CSV              |  293000   | 0.00341   |             75061.76% |                 0.00% | 1.4e-09 |      29 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                      Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::Table::TinyBorderStyle  Text::Table::Manifold  Text::ASCIITable  Text::Table  Text::Table::HTML::DataTables  Text::MarkdownTable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table::Tiny  Text::Table::TinyWide  Text::TabularDisplay  Text::SimpleTable  Text::Table::TinyColor  Text::Table::HTML  Text::Table::Org  Text::Table::Any  Text::Table::Sprintf  Text::Table::CSV 
  Text::UnicodeBox::Table            400/s                       --             -85%               -89%                          -93%                   -97%              -98%         -98%                           -98%                 -98%               -99%                        -99%               -99%                   -99%                  -99%               -99%                    -99%               -99%              -99%              -99%                  -99%              -99% 
  Text::ANSITable                   2300/s                     581%               --               -25%                          -52%                   -83%              -86%         -88%                           -89%                 -90%               -93%                        -95%               -95%                   -96%                  -96%               -96%                    -97%               -98%              -98%              -98%                  -99%              -99% 
  Text::Table::More                 3000/s                     809%              33%                 --                          -36%                   -77%              -81%         -84%                           -85%                 -87%               -91%                        -93%               -94%                   -94%                  -95%               -95%                    -96%               -97%              -97%              -98%                  -98%              -98% 
  Text::Table::TinyBorderStyle      4800/s                    1328%             109%                57%                            --                   -65%              -71%         -76%                           -77%                 -80%               -86%                        -89%               -91%                   -91%                  -92%               -92%                    -94%               -96%              -96%              -97%                  -98%              -98% 
  Text::Table::Manifold            14000/s                    4009%             502%               352%                          187%                     --              -17%         -31%                           -34%                 -45%               -60%                        -69%               -75%                   -76%                  -78%               -78%                    -84%               -88%              -90%              -92%                  -94%              -95% 
  Text::ASCIITable                 17000/s                    4900%             633%               450%                          250%                    21%                --         -16%                           -19%                 -33%               -51%                        -63%               -70%                   -71%                  -73%               -74%                    -81%               -86%              -88%              -91%                  -93%              -94% 
  Text::Table                      20000/s                    5900%             779%               560%                          319%                    45%               19%           --                            -4%                 -20%               -42%                        -56%               -64%                   -65%                  -67%               -69%                    -78%               -83%              -85%              -89%                  -92%              -93% 
  Text::Table::HTML::DataTables    21000/s                    6150%             816%               587%                          337%                    52%               25%           4%                             --                 -16%               -39%                        -54%               -62%                   -64%                  -66%               -67%                    -77%               -82%              -85%              -88%                  -92%              -92% 
  Text::MarkdownTable              25000/s                    7400%            1000%               725%                          425%                    82%               50%          25%                            19%                   --               -27%                        -45%               -55%                   -57%                  -59%               -61%                    -72%               -79%              -82%              -86%                  -90%              -91% 
  Text::FormatTable                34000/s                   10244%            1417%              1037%                          624%                   151%              106%          72%                            65%                  37%                 --                        -24%               -37%                   -41%                  -44%               -46%                    -62%               -71%              -75%              -81%                  -87%              -88% 
  Text::Table::TinyColorWide       46000/s                   13536%            1900%              1400%                          854%                   231%              172%         127%                           118%                  81%                31%                          --               -18%                   -22%                  -27%               -29%                    -50%               -62%              -68%              -75%                  -83%              -84% 
  Text::Table::Tiny                54000/s                   16566%            2344%              1733%                         1066%                   305%              233%         177%                           166%                 122%                61%                         22%                 --                    -5%                  -11%               -13%                    -38%               -54%              -60%              -70%                  -79%              -81% 
  Text::Table::TinyWide            60000/s                   17547%            2488%              1841%                         1135%                   329%              252%         194%                           182%                 135%                70%                         29%                 5%                     --                   -5%                -8%                    -35%               -51%              -58%              -68%                  -78%              -79% 
  Text::TabularDisplay           62468.1/s                   18640%            2648%              1961%                         1211%                   356%              274%         212%                           199%                 149%                81%                         37%                12%                     6%                    --                -3%                    -31%               -48%              -56%              -66%                  -76%              -78% 
  Text::SimpleTable                64700/s                   19254%            2738%              2029%                         1254%                   370%              287%         222%                           209%                 158%                87%                         41%                16%                     9%                    3%                 --                    -29%               -47%              -54%              -65%                  -76%              -78% 
  Text::Table::TinyColor           91000/s                   27172%            3900%              2900%                         1809%                   563%              445%         354%                           336%                 263%               163%                        100%                63%                    54%                   45%                40%                      --               -25%              -36%              -50%                  -66%              -69% 
  Text::Table::HTML               120000/s                   36485%            5265%              3924%                         2460%                   790%              631%         509%                           485%                 387%               253%                        168%               119%                   107%                   95%                89%                     34%                 --              -14%              -34%                  -54%              -58% 
  Text::Table::Org                142000/s                   42574%            6158%              4594%                         2887%                   938%              753%         611%                           582%                 468%               312%                        212%               156%                   141%                  127%               120%                     56%                16%                --              -23%                  -47%              -51% 
  Text::Table::Any                180000/s                   55455%            8048%              6011%                         3788%                  1251%             1011%         825%                           788%                 640%               437%                        307%               233%                   214%                  196%               187%                    103%                51%               30%                --                  -31%              -36% 
  Text::Table::Sprintf            270000/s                   80981%           11791%              8818%                         5575%                  1872%             1521%        1251%                          1197%                 981%               683%                        494%               386%                   359%                  332%               318%                    197%               121%               89%               45%                    --               -7% 
  Text::Table::CSV                293000/s                   87876%           12803%              9577%                         6058%                  2040%             1659%        1366%                          1307%                1073%               750%                        545%               427%                   398%                  369%               354%                    222%               140%              106%               58%                    8%                -- 
 
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
 | Text::UnicodeBox::Table       |        40 |   25      |                 0.00% |             38035.84% |   0.00013 |      21 |
 | Text::ANSITable               |        94 |   11      |               137.04% |             15988.38% | 4.2e-05   |      20 |
 | Text::Table::More             |       130 |    7.5    |               236.11% |             11246.27% | 3.4e-05   |      20 |
 | Text::ASCIITable              |       520 |    1.9    |              1211.61% |              2807.55% | 3.5e-06   |      20 |
 | Text::FormatTable             |       720 |    1.4    |              1700.78% |              2017.74% | 1.8e-06   |      21 |
 | Text::Table::TinyColorWide    |       880 |    1.1    |              2117.40% |              1619.84% |   3e-06   |      20 |
 | Text::Table                   |      1200 |    0.85   |              2868.25% |              1184.79% | 9.1e-07   |      20 |
 | Text::Table::TinyWide         |      1200 |    0.82   |              2979.82% |              1138.25% | 2.1e-06   |      20 |
 | Text::Table::TinyBorderStyle  |      1240 |    0.807  |              3010.24% |              1126.14% | 6.4e-07   |      20 |
 | Text::SimpleTable             |      1600 |    0.61   |              4019.62% |               825.71% | 8.8e-07   |      21 |
 | Text::Table::Manifold         |      1700 |    0.6    |              4093.25% |               809.46% | 8.5e-07   |      20 |
 | Text::Table::Tiny             |      2020 |    0.495  |              4977.95% |               651.01% | 4.8e-07   |      20 |
 | Text::TabularDisplay          |      2300 |    0.43   |              5776.56% |               548.95% | 1.4e-06   |      20 |
 | Text::Table::HTML             |      3000 |    0.33   |              7451.94% |               404.98% | 6.4e-07   |      20 |
 | Text::Table::TinyColor        |      3050 |    0.328  |              7559.95% |               397.86% | 1.9e-07   |      24 |
 | Text::MarkdownTable           |      3500 |    0.29   |              8665.15% |               335.08% | 4.3e-07   |      20 |
 | Text::Table::HTML::DataTables |      4800 |    0.21   |             11976.18% |               215.79% | 1.3e-06   |      20 |
 | Text::Table::Org              |      8600 |    0.12   |             21438.87% |                77.06% | 2.7e-07   |      20 |
 | Text::Table::CSV              |     12000 |    0.085  |             29353.92% |                29.48% | 2.1e-07   |      20 |
 | Text::Table::Any              |     14500 |    0.0688 |             36414.52% |                 4.44% | 2.7e-08   |      20 |
 | Text::Table::Sprintf          |     15200 |    0.0659 |             38035.84% |                 0.00% | 2.5e-08   |      22 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                    Rate  Text::UnicodeBox::Table  Text::ANSITable  Text::Table::More  Text::ASCIITable  Text::FormatTable  Text::Table::TinyColorWide  Text::Table  Text::Table::TinyWide  Text::Table::TinyBorderStyle  Text::SimpleTable  Text::Table::Manifold  Text::Table::Tiny  Text::TabularDisplay  Text::Table::HTML  Text::Table::TinyColor  Text::MarkdownTable  Text::Table::HTML::DataTables  Text::Table::Org  Text::Table::CSV  Text::Table::Any  Text::Table::Sprintf 
  Text::UnicodeBox::Table           40/s                       --             -56%               -70%              -92%               -94%                        -95%         -96%                   -96%                          -96%               -97%                   -97%               -98%                  -98%               -98%                    -98%                 -98%                           -99%              -99%              -99%              -99%                  -99% 
  Text::ANSITable                   94/s                     127%               --               -31%              -82%               -87%                        -90%         -92%                   -92%                          -92%               -94%                   -94%               -95%                  -96%               -97%                    -97%                 -97%                           -98%              -98%              -99%              -99%                  -99% 
  Text::Table::More                130/s                     233%              46%                 --              -74%               -81%                        -85%         -88%                   -89%                          -89%               -91%                   -92%               -93%                  -94%               -95%                    -95%                 -96%                           -97%              -98%              -98%              -99%                  -99% 
  Text::ASCIITable                 520/s                    1215%             478%               294%                --               -26%                        -42%         -55%                   -56%                          -57%               -67%                   -68%               -73%                  -77%               -82%                    -82%                 -84%                           -88%              -93%              -95%              -96%                  -96% 
  Text::FormatTable                720/s                    1685%             685%               435%               35%                 --                        -21%         -39%                   -41%                          -42%               -56%                   -57%               -64%                  -69%               -76%                    -76%                 -79%                           -85%              -91%              -93%              -95%                  -95% 
  Text::Table::TinyColorWide       880/s                    2172%             900%               581%               72%                27%                          --         -22%                   -25%                          -26%               -44%                   -45%               -55%                  -60%               -70%                    -70%                 -73%                           -80%              -89%              -92%              -93%                  -94% 
  Text::Table                     1200/s                    2841%            1194%               782%              123%                64%                         29%           --                    -3%                           -5%               -28%                   -29%               -41%                  -49%               -61%                    -61%                 -65%                           -75%              -85%              -90%              -91%                  -92% 
  Text::Table::TinyWide           1200/s                    2948%            1241%               814%              131%                70%                         34%           3%                     --                           -1%               -25%                   -26%               -39%                  -47%               -59%                    -60%                 -64%                           -74%              -85%              -89%              -91%                  -91% 
  Text::Table::TinyBorderStyle    1240/s                    2997%            1263%               829%              135%                73%                         36%           5%                     1%                            --               -24%                   -25%               -38%                  -46%               -59%                    -59%                 -64%                           -73%              -85%              -89%              -91%                  -91% 
  Text::SimpleTable               1600/s                    3998%            1703%              1129%              211%               129%                         80%          39%                    34%                           32%                 --                    -1%               -18%                  -29%               -45%                    -46%                 -52%                           -65%              -80%              -86%              -88%                  -89% 
  Text::Table::Manifold           1700/s                    4066%            1733%              1150%              216%               133%                         83%          41%                    36%                           34%                 1%                     --               -17%                  -28%               -44%                    -45%                 -51%                           -65%              -80%              -85%              -88%                  -89% 
  Text::Table::Tiny               2020/s                    4950%            2122%              1415%              283%               182%                        122%          71%                    65%                           63%                23%                    21%                 --                  -13%               -33%                    -33%                 -41%                           -57%              -75%              -82%              -86%                  -86% 
  Text::TabularDisplay            2300/s                    5713%            2458%              1644%              341%               225%                        155%          97%                    90%                           87%                41%                    39%                15%                    --               -23%                    -23%                 -32%                           -51%              -72%              -80%              -84%                  -84% 
  Text::Table::HTML               3000/s                    7475%            3233%              2172%              475%               324%                        233%         157%                   148%                          144%                84%                    81%                50%                   30%                 --                      0%                 -12%                           -36%              -63%              -74%              -79%                  -80% 
  Text::Table::TinyColor          3050/s                    7521%            3253%              2186%              479%               326%                        235%         159%                   149%                          146%                85%                    82%                50%                   31%                 0%                      --                 -11%                           -35%              -63%              -74%              -79%                  -79% 
  Text::MarkdownTable             3500/s                    8520%            3693%              2486%              555%               382%                        279%         193%                   182%                          178%               110%                   106%                70%                   48%                13%                     13%                   --                           -27%              -58%              -70%              -76%                  -77% 
  Text::Table::HTML::DataTables   4800/s                   11804%            5138%              3471%              804%               566%                        423%         304%                   290%                          284%               190%                   185%               135%                  104%                57%                     56%                  38%                             --              -42%              -59%              -67%                  -68% 
  Text::Table::Org                8600/s                   20733%            9066%              6150%             1483%              1066%                        816%         608%                   583%                          572%               408%                   400%               312%                  258%               175%                    173%                 141%                            75%                --              -29%              -42%                  -45% 
  Text::Table::CSV               12000/s                   29311%           12841%              8723%             2135%              1547%                       1194%         899%                   864%                          849%               617%                   605%               482%                  405%               288%                    285%                 241%                           147%               41%                --              -19%                  -22% 
  Text::Table::Any               14500/s                   36237%           15888%             10801%             2661%              1934%                       1498%        1135%                  1091%                         1072%               786%                   772%               619%                  525%               379%                    376%                 321%                           205%               74%               23%                --                   -4% 
  Text::Table::Sprintf           15200/s                   37836%           16591%             11280%             2783%              2024%                       1569%        1189%                  1144%                         1124%               825%                   810%               651%                  552%               400%                    397%                 340%                           218%               82%               28%                4%                    -- 
 
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

=for html <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAPBQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADUlQDVlQDVlADUlADUlADUlADUlQDVlADUlADUlQDVlQDWlQDWlQDVlADUlQDVlADUlADUlQDVlADUlADVlADUlADVlADVhgDAjgDMkQDQZACQaQCXaACVZwCUMABFZgCTWAB+TgBwYQCLRwBmAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADUbQCb////JVoHRQAAAEx0Uk5TABFEZiKIu6qZM8x33e5VcD/S1ceJdfb07PH59+yn3zNEZo6Ix2l1W/XWUBHvn/FOIrd69vbx6PT3+Zntz77gtJ8gUGAw741AjpdOj294htgAAAABYktHRACIBR1IAAAACXBIWXMAAABIAAAASABGyWs+AAAAB3RJTUUH5wIRBC0YYb+IZQAAKspJREFUeNrtnQm77Dha3y1vZbvsApL0AOF202HIZAbCBMjSCUMSyEYWD9//40S7tdtVp84pWfX/PU/3uffqWF7016tX0iupqgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAF8EqcXPmrz6SQB4lKbVf6xX8XOt9T91K6V/9TMCcJh+U29A0Jehruvx1c8IwFHG6UpNdNN1NRN0y38yQdddx3TcN69+QADuoZmHuurnrlsaKuhlGNaOCfq6dMNKxbwKqQNwFpjL0VMj3V2ooK9VdV3btW5Xap6bhQp6FsIG4CQIH3q8Tb30odd6rZuZus71OrYdoRJfXv2MAByGCbpb+6FXgl6ooLulZ4jeIFnhdIDTQAV9W5jLwQRNuHzX+jZXfFi6Zt4G9z8AOAf9jXYMqXq5yzFQYc/U6SC0i8j+VDMtD9OrnxGAw1zmhkxzPw9LU0/TPC8jG+Volmmif2LOyDzDQIPzQGrqb9Q1qdhP/gf5z+JPbQ0HGgAAAAAAAAAAAAAAAAAAAGSEnL4iclZ2JOYP/ROAc9DyQEdyWdeppX+bVhZWI3/onwCcg/Y2cUEPEyGXS1X1F9LOnfqhfwJwDpqeC5qw2Ma2E/G610n+UH999UMCcBy+toL+b2QhYfIv6t/UTwBOA9frjcXqLmPVCAX/jvhB5F9Vv/B3f++fMH7vnwLwZKS0fvdJgu5W6ih3S3UVCv5n4kcr/6o2BPpu/Rnj9/8gwB/+7A+i/OwP42n/PJ70CVmm0j4hy9QbfEKWZ/7Ov8+ltX73JEHXwpGu0y7Hdwnno050HVPbUST2xvqELFNpn5Bl6g0+Icvzf+enCXqUPcOWWeNmlj8q9VMCQT/xDSDoAE8TdDVfq2qgyu07/p/8of8TQNBPfAMIOsDzBD0uE+sU8p8TUT/0TwEE/cQ3gKADPEPQEiJXcMqfzl8FEPQT3wCCDvBEQR8hJeg28Zh1G09LbPb2CVmm0j4hy9QbfEKW5//OGQkagI8DQYOigKBBUUDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDU/FH3yR/FE6HoMGp+PZbybdwOgQNTgUEDYoCggZFAUGDooCgQVFA0KAoIGhQFBA0KAoIGhQFBA2KAoIGRQFBg6KAoMHp+P4HxR97aRA0OB0/KNH+9kcvDYIGpwOCBkUBQYOieLmg9VZ94uTNxMGbEDTY59WCbpVKO7YFavLgTQga7PNaQauDN9nG50zQyYM3IWiwz2sFLQ/erCqyXPpq5+BNCBrs82qXQx5ydemYy/H4KVgACPIQdDNxHzp98OZ3a8doHr0VeAceE3TDpfU0QbdzywW9d/BmzRhf/clAzjwm6JFL62mC7ibqccxdC5cDfJQsXI66E4J+/OBNAARZCJrBx6EfPngTAEFegn744E0ABK8WtMOjB28CIMhM0CkgaLAPBA2KAoIGRQFBg6KAoEFRQNCgKCBoUBQQNCgKCBoUBQQNigKCBkUBQYOigKBBUUDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDooCgQVFA0KAoIGhQFBA0KAoIGhQFBA2KAoIGRQFBg6J4uaDlboyj3Kcf5xSCD/FqQYtzCsd5XecR5xSCD5PHOYXLUJFhxjmF4MNkcU4hP+mqXUecUwg+yqtdDr6DP6n5n3BoEPgwWQia0U7D7jmFr/5YIH8yETTp1m7/nMKe0T14J1AM/+IHxZ94aY8JuuPSep6gx6kfKxyNDI7xcy3aP/XS8rDQsxicwzmF4AjZC/omDj3GOYXgENkLuls5OKcQHCJnQTvgnEKwz4kEnQKCBgIIGhQFBA2KAoIGRQFBg6KAoEFRQNCgKCBoUBQQNCgKCBoUBQQNigKCBkUBQYOigKBBUUDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDooCgQVFA0KAoIGhQFBA0KAoIGhQFBA2KAoIGRQFBg6LIWtDq4E37pE0cvAni5CxocfCmc9ImDt4EKfIVtDp40zlpEwdvghT5CloevOmctImDN0GSfAVdGSddbcde4RQskCR7QasTNnHwJjhC9oJWJ2zi4E1whOcL+skHb8LlAPeQvYV2TtrEwZsgSfaCdk/axMGbIEX+gnZO2sTBmyBFzoKWOCdt4uBNkOAEgj4CBA0EEDQoCggaFAUEDYoCggZFAUGDooCgQVFA0KAoIGhQFBA0KAoIGhQFBA2KAoIGRQFBg6KAoEFRQNCgKCBoUBQQNCgKCBoUBQQNigKCBkUBQYOigKDB+fiXv5D8Ky/p1YIex6e8IQT9Vvwyrr7XCrpZ1r6en6BpCPqt+JapoMe1qXvSLeTA76aBoN+KXAXdDVXdV9VUH/jdNBD0W5GtoDsIGjxAroKul5EKuoHLAe4jV0FX13Ve5qXZ+a1RHjyBgzeBIFtBV23T3Xbs8ziva09w8CbYyFXQrXCemzb1S3NXkWnAwZtgI09Bt/V1qCm3OdkpXGt2EBEO3gQbeQq66aeZn5h1STody7WqLgNOwQIbeQqausd73UFGTbuNM6n2Dt5ktr5+zjw6yJ0vFfTIpXVPcFLShybTpb5RH3rv4M2OcaSCgPPzpYJuuLQOxnJcmMuxpHxofhbhuLZwOYAmV5ejXrqp76Yh9Tsd6/iRtcbBm0CTq6C7rroNFZlTncKRDWd0Cw7eBBsZC3rsqS6Tw3bNOs3LiIM3wUaugqYeREVdh/Q4dNXi4E1gk6ugq76n3sQ8HfnVNBD0W5GroGs2zHZrPh5sB0G/F7kK+voE2yyAoN+KXAVdDR2fhfn4G0LQb0Wugq5XwcffEIJ+K3IV9POAoN8KCBoUBQQNigKCBkUBQYOigKBBUUDQoCggaFAUEDQoCggaFAUEDYoCggZFAUGDooCgQVFA0KAoIGhQFBA0KAoIGhQFBA2KAoIGRQFBg6KAoEFRQNCgKCBoUBQnFzSRR6fg4E0gOLWgyWVdpxYHb4KNUwt6mAi5XHDwJtg4s6AJO5Ki7XDwJtg4s6DrtRprUuHgTbBxZkHf1n5mZ6zg4E2gyfzgzSTd2vFTsHDwJtBke/DmAbhbQagBhssBFGd2OUYh6BEHbwLNmQVdzdeqGmYcvAk2Ti1odsImDt4EJqcWtHvSJg7eBOcW9BEg6LcCggZFAUGDooCgQVFA0KAoIGhQFBA0KAoIGhQFBA2KAoIGRQFBg6KAoEFRQNCgKCBoUBQQNCgKCBoUBQQNigKCBkUBQYPT8atvkl/+6KVB0OB0PKg+CBrkCQQNigKCBkUBQYOigKBBUUDQoCggaFAUEDQoiqIFLY6awDmF70TJgu76CucUvhsFC7pemaBxTuF7Ua6gyXKhgsY5hW9GuYK+dMzlwKFBb0axgm4m7kPvnVP4+V8YfCmlCrqdWy7ovXMKe0b3+H1AZmQj6I5L63kHb07U45i7Fi7Hm5GNoAXPO3izE4LGOYVvRqmCZvBxaJxT+F4UL2icU/helCxoAc4pfCvKF3QKCLo4IGhQFBA0KAoIGhQFBA1Ox599r/gzLw2CBqfje62w7700CBqcDgg6BgR9SiDoGBD0KYGgY0DQpwSCjgFBnxIIOgYEfUog6BgQ9CmBoGNA0Nny5z8q/thLg6BjQNCvRYv2xz/3krSKfvAug6BjQNCv5V/HpQJBPwIE/Vp+gKCfCwT9WiDoJwNBvxYI+slA0K8Fgn4yEPRrgaCfDAT9WiDoJwNBvxYI+slA0K8Fgn4yEPRrgaCfDAT9WiDoJwNBvxYI+slA0K8Fgn4yEPRrgaDvYZQHT+DgzZfyF7/+Jvj1X3hpEPRxxnld5xEHb76cB9UHQTssQ0WGGQdvvhwI+inwo9vadcTBm68Ggn4KhO3TX684BevlQNBPo50GHLz5JXzCilYI2oV0a4eDN7+GT1Df6QX95IM3q3HqqbuMs76/BAj68y30LAbncPDmVwBBf7qgb2vNwMGbXwIE/emC7lYODt78EiBoHLxZFBA0gpPOx69+UHhJEDQEfT502f3WS4KgIeg8+V5b4X/jpUHQEPTp2MruF14aBA1Bnw4IGoIuCggagi4KCBqCLgoIGoIuCggagj4df/kLhT80B0FD0K/jT/5U8Zde2l+ppL/ykn6ekAoEDUG/jtSH/rVK+rWXBEFD0Hny4bKDoAMfBYJ+GRA0BO0AQUezhKA/miUHgr4DCBqCdoCgo1lC0B/NkgNBO/xcb3Xoj79B0BC0wwkE/fwPDUFD0K8Dgoag7yATQevVeqlpPQj6o1lC0F/F135oCBqC/mQgaAj6OUDQ0Swh6I9mySlX0Nt6an/HWQgagn4OXyjofD40BA1BP4F8PjQEDUE/gXw+NAQNQT+BfD40BF2WoI8evFknDqro6nhaH/7nfD40BF2SoI8fvAlBx7KEoA9lyfl0QR8/eBOCjmUJQR/KkvPZgr7j4M0HBP3XbJj537L//fWzvgoEDUGnuOMUrIigf/zlt2/f/t2/p//71Uk/NARdkKC9gze/C/Iffvrpp//4n+j/fvKS/uYfFb/x0v5Wp/2tl/YbnfY3XtpPKsm/3X/Wl/2X52f5m0SW/zWe5T9+xUc5/3fmfLagvYM3AfhUvtblAODcOAdvAnBy7IM3AVC0H8/iFdgHb4J7OGmRH2Mby72P5tVfxTp4E9zDXPKXe7Bj1Szjq58cPEqX6nukLNWDVqz5ygpE1tTdom9wRX/sxMyJzkfKfAfTSJ/WK2nX2wPP2PRD3KO8hW45irear6k3Dz9rW5G5H6qMacXXaKbV/ywiLZgkSVx2f5btY1nuX/fgU1bNpV/iWkn1tP20cbpWQ9q4DZOfY/LF1VV9rB40XR9ylGm3imU2pIQZfrtrX9XL+monOg3/it18q6cpmBZJ4iQueyBLbhQeyHLvugefkuqv6ZZgobdzQy8N6yGSdlsX0i4pm1i1a0BEqafk+c7xKtdN12FtQneappGr8543YJCl/7s28zGzeqEVbrmxSfJbKC2SxB2+xGUPZMk91gey3LvuwafkI/hjwNEc2SVNdYvU8nBau05D1cUMfjPNHQm67KmnZNyW+jZwffrFw17gat+yHZalY97PUkd6hcm3qxf6OGPmJvpyqap1HPt+HENpkSTu8CUueyBL7rE+kuXOdQ8+pSjvwTVjt2WlDXa9DK2vh+vMjKybJhS1XNeRzJ7d4z5FN91u1AKTkFebeEruiPTrPNzYL6kMG9afE8VDKqcbMC5DfWPVo2Kme/XfO/V2VOukZS3GEDHtr2VUL9pSIzRN863aXtBMc5IU3OFLXHZPli0vZuGx3pGluCx8naRpA7dTeQay1NA0wk1ivbXZ7H6knWteqFQaxlXC1R2oLqnls9OoMeR/7huqgxv/d9IZVpNlxpoBQi1nY5jT1FOK2xmOSKMkRi7rRGsV4cXDXIeqM+wp4T6PuEezdr3rjoTfTn5nqXWaHVke6bx+Ni399M289iO1D/TtePMaSnOS9K8wW5S47HiWhKpx1B7r8SwJ4Q1t+DoJda/9N9B5elnysSrZ/E9Un4RJRRi/9nJjjznMnXQDyGT6AEwF3EeZmdtgpfUrrxNd1y5N1fcsEKE32myWGdcci08wBhDiTylvpxyRmlUEeTsysazrpefFwz2cbt6st+Vk0N6dNt7kylUeeTv2nbXWWWOQ59BdN9fLrb4shLV0VBbXpQumOUmWw5e47HCWrDAI0R7r4SzpdbQuhK9TgqH9l8AbqDz/3smSzxlszT+ZpluzcB+adMul5Y/Jf5e38MQclGAqIDOtYwN3G1Qaqwbtym9Q9/S+ZKR2cbENI82Mm1KmtrHdf0p1O+WIjMs63/Q1/Me4dPxP7AVm4fK2dcuqXFPV3bSKJxi30RFq1/kvRd6OfmetdVrRxjynUMnMvyM1Cqyl63pz8MdK00ls6Mlx+BKXHcqSfXVqlS7D5rEezZJedxmq4HWs/6776s7tzDydLLnhMZp/MiwTT7vNYliW3o8LpeUy70xXkquA2eBmaYlMk9Wgm0f6rGTl/my3Gv4GNw3Up+Cm9LZEysf/luJ22hHZ5DVJJ5xmyIqHdBO9jL4RGdaV2WP2Y+punetjddPEHaPg2zU1fe9N6906ZxpJcZNOYmjQMZjGhp7CDt+DWbbqI7brf3M91lSW6jrf0xW9eLKwCqD66olHMbJkDjKbM9iaf/2UPfUouaDZ/UQ95oNppqCZq1td+CAhy5ylqWpAPVfqCpB5pJqlNr6S5lKbBupT9HPTLM3+U1pdioCXpfyEdh1F8VDbymrmRCtWzbyRseaF5o54098Z2P0Db8e6l+xum9bzigdgjWAl++PCY6MPK1s6kSa66m6a+EzMmnoO3+NZzswsjMxcdL3nscayNK+jX926Tvbi+eiS7quL68wsdZ7Gy1FHkc8Z+M3/QG1qL4qX3u/GhEL4vZTNZK5uS2XJx0ZmJlmatlUDNnRGe2nMenI1KXOpTANTkbbAoQ+2PaXVpfAcEUOoNGt+9WWe5tGuevwDOpVnXKlTsV6rwNvx7iXNwNB6RshGUPbH+SCrXp4l02RX3U4zhp7cEn84S/a5J2ZZeeO4/I7nsQaztK8jS2N4uroXL0aXzL66nWXgUZgxI2zOINj8c++T36Cp3Jlfsrm6zJ0VN2zNasB1Nqgu2GYulWnY2rq9D2Z3KVzvbGjVSDZbGi2Kh0em9dtwYMc6eBcv/JLeqZ7ZdhfevDbvXrL31lrPCNUIqv54RzsPqorLNN1VN9OsoSe7xB/NkjeezcT8Am4/muXvXY81lKV7nenpmr14sehM99XdLO08Kz6dQB1FPmcQbP5Zh67ij0lGp0c0TZurS0bz9qoa0L+O/BYiJ20utWnoD3wwWRJWl8KGzDciZzadSXYl6CvtXi7DsPTGpbQasN/oLsu1WSbr7XjLI3wNdrfsYji2RlD1x8ly6W52mu6qb2mVO/S0lfjjWTYrH+giVJnCBqlCTWUZuM5ykI1evJhqEH11P0v77cQQK/eC/V6pLHEihWXdj8cFKVeXmEnKRZH9p4vR5m/mUpsG6RSly0A4IpFeCn9IlttKLTztSNidvouUInu75mJvSUFmMc/C+qqjOTdPzLaA3W3MbWzDbARlf/y/B/xE1VW/Gc9vDT0ZJf6BLBvuNdzYT+6uqc+VyjJwnf2Vt148H12S5jCQpfkoaoiV/W5gzkCUuOiC6fvxyQYZFxRwyKni+EWqGrRGkmEu7cYg/sGEYy0ckVDnRj9kxRyHlfnYRtLQymf3fWlWD3iVkyPLRLwbnx5XLY9oC7JTs0Q1glt/vNJhVzLNSlJYQ0+6BIZolnIoOJ5lUzNlDnx2ZvH9tmCW/Lo2fl1TG714MbqkizCRpRpiZY6iM2egDB/P82Km0D6kiguSrq4scVnXZaPf+HEPprl0R+OCH0w61tIRCbn/lencyk+wpVCtT+IzeE7DVg+2DNX0uG558vM1TGQjqPvjjJvsOok0K0m89tBaQ0/q3+V1oSxVKFckSx5qQJV54/7ZOh15SsFcx64zw4mZo1lX5khEIks9xMpNkZWkC7xiknf6kDouqFsNV1coue1lH9CuBqJCRsxl5IPp0T/piHiOtRFbak2qV1uFHJeeeyJe7dK/roOwtunxcFuQD5YvuPXHGbKhE2l2kviUN3foSVhncV0wSz4UHM1ShP5SZfLCHcmhpxSP2oWvU3lGevGxLPn4mB5i9UesA716ajlZJ5QaWhUXRN9180vZfQiXOL/WqQasQkbM5RgsA2P0Tzoi/+N/6l6KG9IhRsOdkhOZ98wTaY3LnGowKNFuHWu75ckP2xcU/XHpLo2yPRZpxPHARLFaQ0/SOsvrrCzVd1mEOQhkWenQ32bxhhNCT6ku0nG6xnWtk6fXi9clZ2cpZj2FW6qHWGXnzAuqNwzfbZ6amoWqKe2wuKCrOXfWLdeFObFzsKFmnauQuRShP/4HM/1/6Yj8L32hGdIhHjLliViXRauB0bG2Wp68iPiCOppQ9cbdBtLysvTQE5/o4l9ZXudfpoaCzTQtlLkjcsC0W7fUyuijBLK04nS363hzLLQn8tx68a4Bs7Lks55qfMwZYvWC6rcSv4hxgIZNnfWVjgvSExrsDWbh59RuKLWukKa5VF9Lhv4EP6b2/113yQzp2B4yWSHVZTrEmqXZLZ3uWFstT16EfcHNXVK9cbuB5J9E/4MaepITXdw6y+ucdlWGBQuLaKQJofD5XhX626hE7nMbj+lk6cbp6uuYiqX2vHBiy4A5WfJZTz0+Zjf/VlC9bfhUiD79GLQPqeOCdNbsDZSSe+txrAppmMuKz8LoMDffSam03fA9MCukw/nOCU/EDBK301iF3DrW10yjNpqgL9ia0YRXy1XynTNarHLoSU908a98DbhYKiz44poaYVDEfK87LyB87sCCQe6Jh6OQOVQKSntunpYBM27F/89nPdX42D/Yb2EG1TsFLgd52Lw7u526TngzsoGxFvKJaOJU4Py4mkF8IZS9UY7ITkhHrEKGY9Ltru5sdaynLB2OWo9EmU0PLRIzmnC2B6Vs22bWY905F195DjSQcp5LDgUbcKHI+V6nT6R8bvsp28tNxEqHo5BldL/WrNvPsgyYyt2c9bTHx8KrCaw2q25kTqw1cPuQSg2tFWI1jckKSfiHNsLcDERTV3mjf3shHZEKuRfmrirk1rGul+xMNOHTIUZBbW/dm9GEdm/Wsm12o7s1pNw6O73glhhhwV6gIbu/mu+1x4Ia7XMbTykGYFnQcyROV0b3a+2540tBA2bNelpuaWqBAn8eNjAoe2isT+kNZ2k/SAUG8BkRQuIVklpzwmqVF/pjBJ7w29l2IxzSsVshk2HuW4U0OtbZDXGQaW6EoL1OMCsdI5rQb3TVJ7EbXWOii1tnq2/Tr8vWjhMz0FCvAwkG/7BGRIZfbH0UOQDLJiIiUcgyuv9/B6yNjEMIGDA74N5yS1MLFCo5MDjK+QZVCUI9MFlD5IzIZYhWSNbLnEgzVW6/lEd06xUw/iB4MKRjr0LGY9JVuvp4l1w7g+zh5mUS5aifsRc7nnTafupowrBzJn5NDvEZE13eGOXQtW47bof+MqF4wT+qEREx8rqvrgZg2b8Eo5CbWkX3e9oj8Zg0Z9bTHqNMLFCo9MDgzGKM9d3iPbAtIqoOV8ia1qXrMEwjD0qx3CXWpTBWwHiEQzp2KmTost0hkZwQVpE6FryYtsekdpRJmnVwnHmIhHOmhvjMiS7ba1iWRQQabu24G/obEopuRITPrR5lG4DlwfJenC5r/3V0v5VlS5w4BPNmzE0MzXrGClyWuPBmuS7JMpirqOx9BrYGxpgR6frIsoBhGduFGv7ZC0oRXYptBYzIcidePVIh05ftDom8HtKJvoS0ivQ7NrM13EOl0K1U0vRbufMQ0XjbbYgvPNFFxunGnWoWYKnacT/01+lICcOgGpGAz81rIpOPF0/A238rul8+CHN7jDiEgJvozHru6ETch3uzQpfX1bJh1j4DmxqMGRH6AmaFFBNO3NhQRU+1OV9VyScRXYpQSEciojtYIfcui1XIfGBzWbxNV1aRGQbVzRKre9nqpYFKmirBcZei8bbGjGhgoquph1nFnU1bOx4I/VVC4SrShkE2Ip5pEF4RexSvAyYCz43ofolwe8IGTM3bmLOeuzqhJa69WfFRRJbhfQbsbV3UDOxCjArJHBFlbIaFi9Z8A/kkzJ8LhHREY6UjFXI/xDpSIXOB9ItYvGoMkG3PL1f38hE3KunZf/zYqkBjiM+b6OLLzlgV4p/D6L8EQn/lFUJF2jB4jYgI6VADsI6ZNZadG9H9PEW5PcE4hNCs536B0xLfvNmj+wyo15ZNTt8ZFYs9uDI2VNFOZJZ+Eiq0QEhHIFaa24ZwhUxcFtnxJDfzzJYnsf+zBk9ZRaOBVKt7paXhy8jUJ4kt4VN7NhgLhu2JLrnsjOmLm+QtLRb6q7pL2jAYjYi8qdSejEKSi70sV8qaGBTzL4bbE4xD8GY9d2Pq2fadrMSVN3t0nwFnWYDdvtC+i3bBjKE6EfWkn4R1KUIhHU6stLANkQqZiEnfHRLJBbYjIC3ORcZ72QNkanUv3ztAlfDOEj5p1WMLhivV+s+dFx8fDv3dukvaMNgm2AjpMAZgPVfKcorE/Mvm9jhxCE4vXgXc7yxCqCreOab/hYLEk/sM2EFWVhmwuSDtgml01JN+ErdLEQwul7YhWiHjMem7QyK5IKO9buvor47Tq3uNyJnkEr5qs+oSNcTXDsY2Q8zU8H6P6TbEQn83FWnD0DmjrH7kScCVsjuKfP7FcHtkHMJ+iGV8EQKLY2GlTf8LhFEH9xmQFyaCrMRckGdsjKgn/SSuP+jHShtDKZEKGbxMfuXkGGU+EBntxRcVuU+pV/cObqMbXsJXGVbdHOJTe6iYrb87EBEP/dUqihiGkCPnu1I62lOPj1tujwpes2bxQ7342LoG0cCwetos/6C82b3dEGQRuEFWwmO96bmg2jU2RtRT4ElMB8acCzJamFCFNDsifmRTahOVlyNeXzSsNzHl5oQaO6t7A41ucAmfYdWNIT7aPgon2Gz93WKNhf6KAhQG1HBEQmHn5htGXCk1Pi7mXwy3p1YR9m2Vii3zC1x3l/iOIfIYMeHN7u+GIF7Aq5H8oa4X5WawxfPubk466imwrMFyYJzgctXCBKqB1REhXoXMeUmKtek33xFQL7iTgcbR1b2J9XaiwLVV10N8F3V9uPVPhv6qrD3DnAw7r2Ku1DY+rudfVEja/xE/7QilkG/j6MToLvENFrYgkdRuCMEIxe1WbK3ihY18h3aIYt/ZiHoyFNum1jXK8hG2waoGbaQjsrvjSTZYm35bOwLqQGNvda95dXi9nShwbdW33xeDJNfwLoNMUrHQ3w2vu5QOO2/asCu1dazc+Rely/8biFBK62TrLrEsG9UN3tkNIRGhyGBhruzvgbkg8Z2NqCcNK7zUukaeJG2DUQ1il+11l3LC2vR7MOay7EBjtz5GlvBZy0d8q87aRzYw5gwvmxsJR/bMNvC6S/Gw84o3QUFXyhgfd+dflC7/nxehtKsT1V26LrfbHNiXIdQFs30bp0Y2NX0WHqfrzQWp7+xEPW2FF4xlNyukZxvCl+13l/LB2fTbXqZjebDhVZTOEj57+UjAqt9WsW7OiTQyNxIOhP7aKBUdCDuvpCdruVISY3zcm+YWuvw7L0IpppPt9VR3aVjt46ASuyE4O4KaH5rHnV6YOaRP5MwFbd/ZiXpixRKOEvcqpGsbtsvMq/a7S9mQ2PTbDDQ2V/cmG92kVeeX9aos7V0GzY2EvdDfCLu7q28Oube5sr1iyO3bKF16u2YFdRIM6fDwvbPI8hHzloPYD71hPqyqj9shb9uKuMF+PXYHP0q88iuk08IYZR4ZowxvvpINsc3CKyfQ2Hi7dKPrFPjqT+KNzrfQob9GMD45uIAnHXZursXbXCllgOwVQxu2Lt2p84BO9kN/Yhss7C0fqVTcKUs2ZGjvP8e+sxX1JINqeeG5sewRw+2WeXyMsgqOq2dDdLNwN9DY+FypRtctcGnVLce6s2axjNBfIxg/vJWKRzDs3D7YQzrk9jY2/oohfmEgssEJzZx9nRwI6YhusJDaEdTc+YNsdY5tomAf8sYrltkfV0G1rPAcO9tEDLdb5vExytCOJ3nAZ+qCQ0HRQGN+WaqOB5ePuI61Oexmhf4awfgHBR0e4bcO9nAdclEf/RVD6cgG/guhAk+HdOxtsBCJUPR3/tjGe/gmCtshb8GgTRlUywvPDnycI4bbK/P4GKW3U0omyJm60FCQ8U28QOOocxZbPsJT7HXZxgF4duivDsYfk4clJaOQWaLpj7sOuaiP/oqh3ciGcIEnQzp2NlioYlNu1s4fjhsvN1HQUwW6ZvGPomaXRFCtXXhxCxwNLt+rkDmh9oA3hoLkVJD8KIFA45RzlrLqrlG3HTAj9PfI5n7p3dV5ouWP2w6529NVz3AksiFWyaMhHZENFnan3CI7fxibKGyHvJnNyzY5I4NqrcILVUjxKLHg8v0KmQcN89XUTJ0eClJTQertvEDjpHPG840UeMpx47+vQ38PzKQmXVadaPrj9lo8c5Xq9izRyIaQ4TsQ+iPvFvLO0lNu8Z0/7E0U7EPeVEfEiBIPrHnwykc9Siy4PLbjST7w/lI3NbQE3ChE9U3024W+ie+c7Vr1qGPNv1gi9Df8AimXdTOz9sEe+hAb0yfync9AZEPE8IVfwOstBStycsotvvMH/c7WJgrmOOT23ts2I/q+iQqpizwWXJ4eEskC1l8SBsqZqduaXPV2oSV8rnN2wKpHHWueGg39jZB0WbdE62AP5ZDbbW6gqfAiG/YNXyr0J1SR96bcIjt/8O/sbB2/DdRt760nZ7qkJ+IWeSS4fK9lzQJ2TiX/aUchGkJRb9eZblbYOdu36gnH+uHeRmp3dZUY9setNtfsLlmrtohX4r7h2wnpiFbkvSm38M4f8jvbmyiEOiLO7FKyQhqPEg4uT7SsGUH7S1zFjReFqLVgnyLsLeHTn2TXqouPFVuX/XhvI+yySlVKh1z740kn2AondFuKuOHbDelIVuRkhGJg54/NzYpvoqDe25ycSVZI+1H8OZ10y5oLo9y6hBhnlnvfxHo7bwmf8UniVn3XsY6E/u6RDDuX+lLD/0ecYDucsAoY2qDhq9KzSzsbLKQjFD3Rmqe8uVvHW99GvLdhpVIV0nkUfxlYokJmgAzJ5VNnXS9G6gIDvapztgVZ+Ev4umBHyirxlGO9E/q7QyjsXKZs7otpZnecYK8X77cUvuGTvxjZIDK9wUJ0Dnx7A0e09ilvztbxFsGOSKxCukUeyC5eIV+OGDeWU2fswMlhDq8Cc79JYAmfi2/V0471TuhvjFjYuSIYQLbb5jrhhCF8w8c/R3yDyMQGC9EpN8uBcURrnfJmnVroEuyIRCrk9iZmkR8ao8wB9lH01FmT8FcD3yS9hM+z6nuOdTL0N8qeyxo2s3ttbmSSxSZk+IIzyMkNFtJTbpYD44jWPuXtkggJCHZEwhXSYHuU3THKfGABbtvUWWJdY+ibeEv4bJwCTwyXCOKhvwn2XVbxa74qE21uLJzQwa3k4Rnk9AYLO1NudhCyEm3olLf26PhmrHw89KMcm5x5Nb3qxRr7yt65rpHsrLSJHuxhq8jc/ioc+psgHHbOHfK9zQIjbW4inNC7tz3YGI7hSW+wkJxyayo7CFkvQk6f8naUY9cdGBLJAmle+YFh7sbYR9mp4/GDPSwVmdtf3bs5SSzsnP3j3maB4Tb3I734nQ0iAy+3G6EYDELeOeXtKMeuOzIkkgPKvLIAN2dj7OPcbRu84RL+F2P7q/s2J4mGnTOHfHezwEh9vK8Xf6y7FPHODkQoBsNj0qe8PZ+9IZEsUEfzzF318Dm199uGkIis7a+Okwh65P+4v1mgcTrcfuBJ+BkOdpdIeOcbHaHo1cjtlAQ3CJkP8MVOefss9oZEXg77KrI4WYDOF24KEjLq0e2vkq8QclnNtXj7BkVvCbYbeBLheHfJr8hWhGKgFVENhdtS8B5k+JS3z2N3SOTVGEfffbGHr0R0aPurNAHfwFqLd9SgHAonDHBXdylQkc0IRXObdKehMB9FD/D1U/WlHI8S+2LM0Bm2ZI4MLwnN3t/+KvL4VokHfANrLd4hg3Is8CTEXd0lyzt7NEJxG+Br3bVxn02ua1LMeQgyLf3av0LPqe2vErglHgpKjZ0WEGV3fDzJvd2lD0UoVkZ3oFsO3O2J5LomxZ6HaK6vmO/Z2f4qilfioSJ/aPvL4Pj4Me7qLn0kQtGZJsp2u4AvJoeVBjvbX0UIlPh2jtjeUU57hMbHj3FPd+mxCMVj00TvSi4rDe7fbSdQ4tJlPXKU0w7B8fFjHO4uPRahyH//wDTR2xLbfOGreWi3nWCJH9jPZZ8P9OKPdpceilDkHJomelsiC7O/jo/stuOX+P4RPcd4vBd/T3fpzghFxaFponfF3/7mi/nIbjt+ie8f0XOML+rF3xWheN800XvSHI1R+ASesdtOYvVF5rtfCu6KUHxomujNcHfN+UKes9tOYvVF3rtfSu6KULx/muj9eJ3z/JzdduwS3zmTKUfuaZjunyYCX0bzGbvtxBfHZstdDVPWp6S9N4nQ34fYWxx7Yj48TQQ+m2To70PsL449K0+YJgKfzF7o7yNZ7hzRc1qeMk0EPhs/9PeD+YUXx56eZ00Tgc/DilZ/0hi46ZAXNRX8rGki8AnYe8AHdo5/EPe0gIIMNOdE00TvhLsH/NM2J9k7LeD8nGia6H3w9oB/4jhq9Cins3PCaaI3IbAH/Me6bsG1hDluf/khTjhN9CaE9oD/ALG1hOW4GwVPExVDfA/4ezm0lvDUlDtNVBKxPeDvJLWWsBSKnSYqir3Q34PE1xIWQ6nTRKXxvN12PrDNwAkodpqoOJ7Xt3l8m4HcKX2aqCie17f5wDYDeVP+NBEIku1mgR9/s1KniUCSkoZm32OaCCQpZ2i2/Gki8E6UP00E3oh3mCYCb8QbTBOBd6PsaSLwfpQ7TQTekmKnicCbUu40EXhPSpomAqCgaSIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADg5Px/VBiXCRcfuAUAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjMtMDItMTZUMjE6NDU6MjQrMDc6MDDU0tHdAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTAyLTE2VDIxOjQ1OjI0KzA3OjAwpY9pYQAAACF0RVh0cHM6SGlSZXNCb3VuZGluZ0JveAA1MDR4NzIwKzUwKzUw1uIiwwAAABN0RVh0cHM6TGV2ZWwAQWRvYmUtMi4wCjmTdA0AAAAASUVORK5CYII=" />


Benchmark module startup overhead (C<< bencher --cpanmodules-module TextTable --module-startup >>):

 #table6#
 +-------------------------------+-----------+---------------------+-----------------------+-----------------------+-----------+---------+
 | participant                   | time (ms) | mod_overhead_time   | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------+-----------+---------------------+-----------------------+-----------------------+-----------+---------+
 | Text::UnicodeBox::Table       |     170   | 161.4               |                 0.00% |              1830.18% |   0.00027 |      20 |
 | Text::Table::Manifold         |      92   |  83.4               |                81.30% |               964.64% |   0.00016 |      20 |
 | Text::ANSITable               |      47   |  38.4               |               257.06% |               440.57% | 5.5e-05   |      20 |
 | Text::MarkdownTable           |      42   |  33.4               |               294.86% |               388.83% | 5.6e-05   |      20 |
 | Text::Table::TinyColorWide    |      35   |  26.4               |               380.00% |               302.12% | 6.6e-05   |      20 |
 | Text::Table::TinyWide         |      32.1 |  23.5               |               419.12% |               271.82% | 2.7e-05   |      20 |
 | Text::Table::More             |      25   |  16.4               |               559.15% |               192.83% | 7.8e-05   |      20 |
 | Text::Table                   |      24   |  15.4               |               601.85% |               175.01% |   0.00011 |      20 |
 | Text::ASCIITable              |      19   |  10.4               |               777.55% |               119.95% | 9.1e-05   |      20 |
 | Text::Table::Tiny             |      19   |  10.4               |               787.87% |               117.39% |   0.00011 |      20 |
 | Text::FormatTable             |      16   |   7.4               |               960.14% |                82.07% | 3.8e-05   |      20 |
 | Text::Table::TinyColor        |      15   |   6.4               |               998.71% |                75.68% | 6.9e-05   |      20 |
 | Text::Table::TinyBorderStyle  |      13   |   4.4               |              1185.52% |                50.15% |   0.00011 |      20 |
 | Text::Table::Any              |      12.5 |   3.9               |              1234.89% |                44.60% | 1.1e-05   |      20 |
 | Text::SimpleTable             |      12   |   3.4               |              1314.31% |                36.48% | 5.5e-05   |      20 |
 | Text::TabularDisplay          |      12   |   3.4               |              1320.89% |                35.84% | 5.7e-05   |      20 |
 | Text::Table::HTML::DataTables |      11   |   2.4               |              1410.81% |                27.76% | 2.6e-05   |      20 |
 | Text::Table::HTML             |      11   |   2.4               |              1417.70% |                27.18% | 4.1e-05   |      22 |
 | Text::Table::Org              |      11   |   2.4               |              1433.01% |                25.91% | 2.3e-05   |      20 |
 | Text::Table::CSV              |       8.9 |   0.300000000000001 |              1759.70% |                 3.79% | 1.6e-05   |      20 |
 | Text::Table::Sprintf          |       8.8 |   0.200000000000001 |              1789.17% |                 2.17% | 1.8e-05   |      20 |
 | perl -e1 (baseline)           |       8.6 |   0                 |              1830.18% |                 0.00% |   5e-05   |      20 |
 +-------------------------------+-----------+---------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                    Rate  Text::UnicodeBox::Table  Text::Table::Manifold  Text::ANSITable  Text::MarkdownTable  Text::Table::TinyColorWide  Text::Table::TinyWide  Text::Table::More  Text::Table  Text::ASCIITable  Text::Table::Tiny  Text::FormatTable  Text::Table::TinyColor  Text::Table::TinyBorderStyle  Text::Table::Any  Text::SimpleTable  Text::TabularDisplay  Text::Table::HTML::DataTables  Text::Table::HTML  Text::Table::Org  Text::Table::CSV  Text::Table::Sprintf  perl -e1 (baseline) 
  Text::UnicodeBox::Table          5.9/s                       --                   -45%             -72%                 -75%                        -79%                   -81%               -85%         -85%              -88%               -88%               -90%                    -91%                          -92%              -92%               -92%                  -92%                           -93%               -93%              -93%              -94%                  -94%                 -94% 
  Text::Table::Manifold           10.9/s                      84%                     --             -48%                 -54%                        -61%                   -65%               -72%         -73%              -79%               -79%               -82%                    -83%                          -85%              -86%               -86%                  -86%                           -88%               -88%              -88%              -90%                  -90%                 -90% 
  Text::ANSITable                 21.3/s                     261%                    95%               --                 -10%                        -25%                   -31%               -46%         -48%              -59%               -59%               -65%                    -68%                          -72%              -73%               -74%                  -74%                           -76%               -76%              -76%              -81%                  -81%                 -81% 
  Text::MarkdownTable             23.8/s                     304%                   119%              11%                   --                        -16%                   -23%               -40%         -42%              -54%               -54%               -61%                    -64%                          -69%              -70%               -71%                  -71%                           -73%               -73%              -73%              -78%                  -79%                 -79% 
  Text::Table::TinyColorWide      28.6/s                     385%                   162%              34%                  19%                          --                    -8%               -28%         -31%              -45%               -45%               -54%                    -57%                          -62%              -64%               -65%                  -65%                           -68%               -68%              -68%              -74%                  -74%                 -75% 
  Text::Table::TinyWide           31.2/s                     429%                   186%              46%                  30%                          9%                     --               -22%         -25%              -40%               -40%               -50%                    -53%                          -59%              -61%               -62%                  -62%                           -65%               -65%              -65%              -72%                  -72%                 -73% 
  Text::Table::More               40.0/s                     580%                   268%              87%                  68%                         39%                    28%                 --          -4%              -24%               -24%               -36%                    -40%                          -48%              -50%               -52%                  -52%                           -56%               -56%              -56%              -64%                  -64%                 -65% 
  Text::Table                     41.7/s                     608%                   283%              95%                  75%                         45%                    33%                 4%           --              -20%               -20%               -33%                    -37%                          -45%              -47%               -50%                  -50%                           -54%               -54%              -54%              -62%                  -63%                 -64% 
  Text::ASCIITable                52.6/s                     794%                   384%             147%                 121%                         84%                    68%                31%          26%                --                 0%               -15%                    -21%                          -31%              -34%               -36%                  -36%                           -42%               -42%              -42%              -53%                  -53%                 -54% 
  Text::Table::Tiny               52.6/s                     794%                   384%             147%                 121%                         84%                    68%                31%          26%                0%                 --               -15%                    -21%                          -31%              -34%               -36%                  -36%                           -42%               -42%              -42%              -53%                  -53%                 -54% 
  Text::FormatTable               62.5/s                     962%                   475%             193%                 162%                        118%                   100%                56%          50%               18%                18%                 --                     -6%                          -18%              -21%               -25%                  -25%                           -31%               -31%              -31%              -44%                  -44%                 -46% 
  Text::Table::TinyColor          66.7/s                    1033%                   513%             213%                 179%                        133%                   114%                66%          60%               26%                26%                 6%                      --                          -13%              -16%               -19%                  -19%                           -26%               -26%              -26%              -40%                  -41%                 -42% 
  Text::Table::TinyBorderStyle    76.9/s                    1207%                   607%             261%                 223%                        169%                   146%                92%          84%               46%                46%                23%                     15%                            --               -3%                -7%                   -7%                           -15%               -15%              -15%              -31%                  -32%                 -33% 
  Text::Table::Any                80.0/s                    1260%                   636%             276%                 236%                        179%                   156%               100%          92%               52%                52%                28%                     19%                            4%                --                -4%                   -4%                           -12%               -12%              -12%              -28%                  -29%                 -31% 
  Text::SimpleTable               83.3/s                    1316%                   666%             291%                 250%                        191%                   167%               108%         100%               58%                58%                33%                     25%                            8%                4%                 --                    0%                            -8%                -8%               -8%              -25%                  -26%                 -28% 
  Text::TabularDisplay            83.3/s                    1316%                   666%             291%                 250%                        191%                   167%               108%         100%               58%                58%                33%                     25%                            8%                4%                 0%                    --                            -8%                -8%               -8%              -25%                  -26%                 -28% 
  Text::Table::HTML::DataTables   90.9/s                    1445%                   736%             327%                 281%                        218%                   191%               127%         118%               72%                72%                45%                     36%                           18%               13%                 9%                    9%                             --                 0%                0%              -19%                  -19%                 -21% 
  Text::Table::HTML               90.9/s                    1445%                   736%             327%                 281%                        218%                   191%               127%         118%               72%                72%                45%                     36%                           18%               13%                 9%                    9%                             0%                 --                0%              -19%                  -19%                 -21% 
  Text::Table::Org                90.9/s                    1445%                   736%             327%                 281%                        218%                   191%               127%         118%               72%                72%                45%                     36%                           18%               13%                 9%                    9%                             0%                 0%                --              -19%                  -19%                 -21% 
  Text::Table::CSV               112.4/s                    1810%                   933%             428%                 371%                        293%                   260%               180%         169%              113%               113%                79%                     68%                           46%               40%                34%                   34%                            23%                23%               23%                --                   -1%                  -3% 
  Text::Table::Sprintf           113.6/s                    1831%                   945%             434%                 377%                        297%                   264%               184%         172%              115%               115%                81%                     70%                           47%               42%                36%                   36%                            25%                25%               25%                1%                    --                  -2% 
  perl -e1 (baseline)            116.3/s                    1876%                   969%             446%                 388%                        306%                   273%               190%         179%              120%               120%                86%                     74%                           51%               45%                39%                   39%                            27%                27%               27%                3%                    2%                   -- 
 
 Legends:
   Text::ANSITable: mod_overhead_time=38.4 participant=Text::ANSITable
   Text::ASCIITable: mod_overhead_time=10.4 participant=Text::ASCIITable
   Text::FormatTable: mod_overhead_time=7.4 participant=Text::FormatTable
   Text::MarkdownTable: mod_overhead_time=33.4 participant=Text::MarkdownTable
   Text::SimpleTable: mod_overhead_time=3.4 participant=Text::SimpleTable
   Text::Table: mod_overhead_time=15.4 participant=Text::Table
   Text::Table::Any: mod_overhead_time=3.9 participant=Text::Table::Any
   Text::Table::CSV: mod_overhead_time=0.300000000000001 participant=Text::Table::CSV
   Text::Table::HTML: mod_overhead_time=2.4 participant=Text::Table::HTML
   Text::Table::HTML::DataTables: mod_overhead_time=2.4 participant=Text::Table::HTML::DataTables
   Text::Table::Manifold: mod_overhead_time=83.4 participant=Text::Table::Manifold
   Text::Table::More: mod_overhead_time=16.4 participant=Text::Table::More
   Text::Table::Org: mod_overhead_time=2.4 participant=Text::Table::Org
   Text::Table::Sprintf: mod_overhead_time=0.200000000000001 participant=Text::Table::Sprintf
   Text::Table::Tiny: mod_overhead_time=10.4 participant=Text::Table::Tiny
   Text::Table::TinyBorderStyle: mod_overhead_time=4.4 participant=Text::Table::TinyBorderStyle
   Text::Table::TinyColor: mod_overhead_time=6.4 participant=Text::Table::TinyColor
   Text::Table::TinyColorWide: mod_overhead_time=26.4 participant=Text::Table::TinyColorWide
   Text::Table::TinyWide: mod_overhead_time=23.5 participant=Text::Table::TinyWide
   Text::TabularDisplay: mod_overhead_time=3.4 participant=Text::TabularDisplay
   Text::UnicodeBox::Table: mod_overhead_time=161.4 participant=Text::UnicodeBox::Table
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
 <script>var dt_opts = {"dom":"lQfrtip","buttons":["colvis","print"]}; $(document).ready(function() { $("table").DataTable(dt_opts); $("select[name=DataTables_Table_0_length]").val(1000); $("select[name=DataTables_Table_0_length]").trigger("change"); });</script>
 
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

L<Acme::CPANModules::HTMLTable>

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
