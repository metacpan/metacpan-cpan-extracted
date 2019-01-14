package Acme::CPANModules::TextTable;

our $DATE = '2019-01-11'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub _make_table {
    my ($cols, $rows) = @_;
    my $res = [];
    push @$res, [];
    for (0..$cols-1) { $res->[0][$_] = "col" . ($_+1) }
    for my $row (1..$rows) {
        push @$res, [ map { "row$row.$_" } 1..$cols ];
    }
    $res;
}

our $LIST = {
    summary => 'Modules that generate text tables',
    entry_features => {
        wide_char => {summary => 'Whether the use of wide characters (e.g. Kanji) in cells does not cause the table to be misaligned'},
        color => {summary => 'Whether the module supports ANSI colors'},
        box_char => {summary => 'Whether the module can utilize box-drawing characters'},
    },
    entries => [
        {
            module => 'Text::ANSITable',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::ANSITable->new(
                    use_utf8 => 0,
                    use_box_chars => 0,
                    use_color => 0,
                    columns => $table->[0],
                    border_style => 'Default::single_ascii',
                );
                $t->add_row($table->[$_]) for 1..@$table-1;
                $t->draw;
            },
            features => {
                wide_char => 1,
                color => 1,
                box_char => 1,
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
                wide_char => 0,
                color => 0,
                box_char => 0,
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
                wide_char => 0,
                color => 0,
                box_char => 0,
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
                wide_char => 0,
                color => 0,
                box_char => 0,
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
                wide_char => 0,
                color => 0,
                box_char => {value=>undef, summary=>'Does not draw borders'},
            },
        },
        {
            module => 'Text::Table::Tiny',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::Tiny::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 0,
                color => 0,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::TinyColor',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyColor::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 0,
                color => 1,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::TinyColorWide',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyColorWide::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 1,
                color => 1,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::TinyWide',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::TinyWide::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 1,
                color => 0,
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
                wide_char => 0,
                color => 0,
                box_char => 0,
            },
        },
        {
            module => 'Text::Table::CSV',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::CSV::table(rows=>$table, header_row=>1);
            },
            features => {
                wide_char => 1,
                color => 0,
                box_char => {value=>undef, summary=>"Irrelevant"},
            },
        },
        {
            module => 'Text::Table::HTML',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::HTML::table(rows=>$table, header_row=>1);
            },
            features => {
            },
        },
        {
            module => 'Text::Table::HTML::DataTables',
            bench_code => sub {
                my ($table) = @_;
                Text::Table::HTML::DataTables::table(rows=>$table, header_row=>1);
            },
            features => {
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
                wide_char => 1,
                color => 0,
                box_char => {value=>undef, summary=>"Irrelevant"},
            },
        },
    ],

    bench_datasets => [
        {name=>'tiny (1x1)'    , argv => [_make_table( 1, 1)],},
        {name=>'small (3x5)'   , argv => [_make_table( 3, 5)],},
        {name=>'wide (30x5)'   , argv => [_make_table(30, 5)],},
        {name=>'long (3x300)'  , argv => [_make_table( 3, 300)],},
        {name=>'large (30x300)', argv => [_make_table(30, 300)],},
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

This document describes version 0.001 of Acme::CPANModules::TextTable (from Perl distribution Acme-CPANModules-TextTable), released on 2019-01-11.

=head1 DESCRIPTION

Modules that generate text tables.

=head1 INCLUDED MODULES

=over

=item * L<Text::ANSITable>

=item * L<Text::ASCIITable>

=item * L<Text::FormatTable>

=item * L<Text::MarkdownTable>

=item * L<Text::Table>

=item * L<Text::Table::Tiny>

=item * L<Text::Table::TinyColor>

=item * L<Text::Table::TinyColorWide>

=item * L<Text::Table::TinyWide>

=item * L<Text::Table::Org>

=item * L<Text::Table::CSV>

=item * L<Text::Table::HTML>

=item * L<Text::Table::HTML::DataTables>

=item * L<Text::TabularDisplay>

=back

=head1 FEATURE COMPARISON MATRIX

 +-------------------------------+--------------+-----------+---------------+
 | module                        | box_char *1) | color *2) | wide_char *3) |
 +-------------------------------+--------------+-----------+---------------+
 | Text::ANSITable               | yes          | yes       | yes           |
 | Text::ASCIITable              | no           | no        | no            |
 | Text::FormatTable             | no           | no        | no            |
 | Text::MarkdownTable           | no           | no        | no            |
 | Text::Table                   | N/A *4)      | no        | no            |
 | Text::Table::Tiny             | no           | no        | no            |
 | Text::Table::TinyColor        | no           | yes       | no            |
 | Text::Table::TinyColorWide    | no           | yes       | yes           |
 | Text::Table::TinyWide         | no           | no        | yes           |
 | Text::Table::Org              | no           | no        | no            |
 | Text::Table::CSV              | N/A *5)      | no        | yes           |
 | Text::Table::HTML             | N/A          | N/A       | N/A           |
 | Text::Table::HTML::DataTables | N/A          | N/A       | N/A           |
 | Text::TabularDisplay          | N/A *6)      | no        | yes           |
 +-------------------------------+--------------+-----------+---------------+


Notes:

=over

=item 1. box_char: Whether the module can utilize box-drawing characters

=item 2. color: Whether the module supports ANSI colors

=item 3. wide_char: Whether the use of wide characters (e.g. Kanji) in cells does not cause the table to be misaligned

=item 4. Does not draw borders

=item 5. Irrelevant

=item 6. Irrelevant

=back

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

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
