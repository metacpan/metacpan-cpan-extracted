package Acme::CPANModules::HTMLTable;

use 5.010001;
use strict;
use warnings;
#use utf8;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-HTMLTable'; # DIST
our $VERSION = '0.002'; # VERSION

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
    summary => 'List of modules that generate HTML tables',
    entry_features => {
    },
    entries => [
        {
            module => 'Text::Table::Any',
            description => <<'_',

This is a common frontend for many text table modules as backends,
L<Text::Table::HTML> being one.

_
            bench_code => sub {
                my ($table) = @_;
                Text::Table::Any::table(rows=>$table, header_row=>1, backend=>'Text::Table::HTML');
            },
            features => {
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
            module => 'Text::Table::Manifold',
            bench_code => sub {
                my ($table) = @_;
                my $t = Text::Table::Manifold->new(format => Text::Table::Manifold::format_html_table());
                $t->headers($table->[0]);
                $t->data([ @{$table}[1 .. $#{$table}] ]);
                join("\n", @{$t->render(padding => 1)}) . "\n";
            },
            features => {
            },
        },

    ], # entries

    bench_datasets => [
        {name=>'tiny (1x1)'          , argv => [_make_table( 1, 1)],},
        {name=>'small (3x5)'         , argv => [_make_table( 3, 5)],},
        {name=>'wide (30x5)'         , argv => [_make_table(30, 5)],},
        {name=>'long (3x300)'        , argv => [_make_table( 3, 300)],},
        {name=>'large (30x300)'      , argv => [_make_table(30, 300)],},
    ],

};

1;
# ABSTRACT: List of modules that generate HTML tables

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::HTMLTable - List of modules that generate HTML tables

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::HTMLTable (from Perl distribution Acme-CPANModules-HTMLTable), released on 2023-10-29.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module HTMLTable

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module HTMLTable

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Text::Table::Any>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

This is a common frontend for many text table modules as backends,
L<Text::Table::HTML> being one.


=item L<Text::Table::HTML>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::HTML::DataTables>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Table::Manifold>

Author: L<RSAVAGE|https://metacpan.org/author/RSAVAGE>

=back

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Table::Any> 0.115

L<Text::Table::HTML> 0.010

L<Text::Table::HTML::DataTables> 0.012

L<Text::Table::Manifold> 1.03

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::Table::Any (perl_code)

L<Text::Table::Any>



=item * Text::Table::HTML (perl_code)

L<Text::Table::HTML>



=item * Text::Table::HTML::DataTables (perl_code)

L<Text::Table::HTML::DataTables>



=item * Text::Table::Manifold (perl_code)

L<Text::Table::Manifold>



=back

=head1 BENCHMARK DATASETS

=over

=item * tiny (1x1)

=item * small (3x5)

=item * wide (30x5)

=item * long (3x300)

=item * large (30x300)

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher --cpanmodules-module HTMLTable

Result formatted as table (split, part 1 of 5):

 #table1#
 {dataset=>"large (30x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::Table::Manifold         |      15.8 |     63.3  |                 0.00% |               636.27% | 4.9e-05 |      21 |
 | Text::Table::HTML             |      68   |     15    |               328.81% |                71.70% | 1.9e-05 |      21 |
 | Text::Table::Any              |      68.3 |     14.7  |               331.76% |                70.53% | 1.2e-05 |      20 |
 | Text::Table::HTML::DataTables |     116   |      8.59 |               636.27% |                 0.00% | 4.6e-06 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

           Rate  TT:M  TT:H  TT:A  TTH:D 
  TT:M   15.8/s    --  -76%  -76%   -86% 
  TT:H     68/s  322%    --   -2%   -42% 
  TT:A   68.3/s  330%    2%    --   -41% 
  TTH:D   116/s  636%   74%   71%     -- 
 
 Legends:
   TT:A: participant=Text::Table::Any
   TT:H: participant=Text::Table::HTML
   TT:M: participant=Text::Table::Manifold
   TTH:D: participant=Text::Table::HTML::DataTables

Result formatted as table (split, part 2 of 5):

 #table2#
 {dataset=>"long (3x300)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::Table::Manifold         |       129 |      7.73 |                 0.00% |               598.03% | 6.3e-06 |      21 |
 | Text::Table::HTML             |       620 |      1.6  |               378.42% |                45.90% | 1.8e-06 |      20 |
 | Text::Table::Any              |       625 |      1.6  |               383.35% |                44.41% | 5.8e-07 |      20 |
 | Text::Table::HTML::DataTables |       903 |      1.11 |               598.03% |                 0.00% | 2.7e-07 |      23 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

          Rate  TT:M  TT:H  TT:A  TTH:D 
  TT:M   129/s    --  -79%  -79%   -85% 
  TT:H   620/s  383%    --    0%   -30% 
  TT:A   625/s  383%    0%    --   -30% 
  TTH:D  903/s  596%   44%   44%     -- 
 
 Legends:
   TT:A: participant=Text::Table::Any
   TT:H: participant=Text::Table::HTML
   TT:M: participant=Text::Table::Manifold
   TTH:D: participant=Text::Table::HTML::DataTables

Result formatted as table (split, part 3 of 5):

 #table3#
 {dataset=>"small (3x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::Table::Manifold         |      4400 |     230   |                 0.00% |               559.84% | 3.2e-07 |      23 |
 | Text::Table::HTML::DataTables |     13000 |      74   |               205.38% |               116.07% | 1.3e-07 |      30 |
 | Text::Table::Any              |     27200 |      36.8 |               516.53% |                 7.03% | 3.3e-08 |      31 |
 | Text::Table::HTML             |     29100 |      34.3 |               559.84% |                 0.00% | 6.5e-09 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

            Rate  TT:M  TTH:D  TT:A  TT:H 
  TT:M    4400/s    --   -67%  -84%  -85% 
  TTH:D  13000/s  210%     --  -50%  -53% 
  TT:A   27200/s  525%   101%    --   -6% 
  TT:H   29100/s  570%   115%    7%    -- 
 
 Legends:
   TT:A: participant=Text::Table::Any
   TT:H: participant=Text::Table::HTML
   TT:M: participant=Text::Table::Manifold
   TTH:D: participant=Text::Table::HTML::DataTables

Result formatted as table (split, part 4 of 5):

 #table4#
 {dataset=>"tiny (1x1)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::Table::Manifold         |      9700 |    100    |                 0.00% |              1436.99% | 1.3e-07 |      20 |
 | Text::Table::HTML::DataTables |     18000 |     55    |                87.14% |               721.28% | 7.8e-08 |      22 |
 | Text::Table::Any              |    114000 |      8.81 |              1072.17% |                31.12% | 5.6e-09 |      22 |
 | Text::Table::HTML             |    149000 |      6.72 |              1436.99% |                 0.00% | 2.9e-09 |      20 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

             Rate   TT:M  TTH:D  TT:A  TT:H 
  TT:M     9700/s     --   -44%  -91%  -93% 
  TTH:D   18000/s    81%     --  -83%  -87% 
  TT:A   114000/s  1035%   524%    --  -23% 
  TT:H   149000/s  1388%   718%   31%    -- 
 
 Legends:
   TT:A: participant=Text::Table::Any
   TT:H: participant=Text::Table::HTML
   TT:M: participant=Text::Table::Manifold
   TTH:D: participant=Text::Table::HTML::DataTables

Result formatted as table (split, part 5 of 5):

 #table5#
 {dataset=>"wide (30x5)"}
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Text::Table::Manifold         |       830 |      1200 |                 0.00% |               434.10% | 1.7e-06 |      20 |
 | Text::Table::Any              |      3390 |       295 |               307.45% |                31.08% | 1.4e-07 |      20 |
 | Text::Table::HTML             |      3430 |       291 |               313.00% |                29.32% | 1.3e-07 |      26 |
 | Text::Table::HTML::DataTables |      4400 |       230 |               434.10% |                 0.00% | 2.3e-07 |      21 |
 +-------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

           Rate  TT:M  TT:A  TT:H  TTH:D 
  TT:M    830/s    --  -75%  -75%   -80% 
  TT:A   3390/s  306%    --   -1%   -22% 
  TT:H   3430/s  312%    1%    --   -20% 
  TTH:D  4400/s  421%   28%   26%     -- 
 
 Legends:
   TT:A: participant=Text::Table::Any
   TT:H: participant=Text::Table::HTML
   TT:M: participant=Text::Table::Manifold
   TTH:D: participant=Text::Table::HTML::DataTables


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher --cpanmodules-module HTMLTable --module-startup

Result formatted as table:

 #table6#
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                   | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Text::Table::Manifold         |     91    |             84.55 |                 0.00% |              1310.03% | 4.8e-05 |      20 |
 | Text::Table::Any              |     11    |              4.55 |               727.82% |                70.33% | 5.1e-06 |      22 |
 | Text::Table::HTML::DataTables |      9.37 |              2.92 |               870.91% |                45.23% | 6.8e-06 |      20 |
 | Text::Table::HTML             |      9.13 |              2.68 |               897.27% |                41.39% | 4.9e-06 |      20 |
 | perl -e1 (baseline)           |      6.45 |              0    |              1310.03% |                 0.00% | 3.2e-06 |      20 |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate   TT:M  TT:A  TTH:D  TT:H  perl -e1 (baseline) 
  TT:M                  11.0/s     --  -87%   -89%  -89%                 -92% 
  TT:A                  90.9/s   727%    --   -14%  -16%                 -41% 
  TTH:D                106.7/s   871%   17%     --   -2%                 -31% 
  TT:H                 109.5/s   896%   20%     2%    --                 -29% 
  perl -e1 (baseline)  155.0/s  1310%   70%    45%   41%                   -- 
 
 Legends:
   TT:A: mod_overhead_time=4.55 participant=Text::Table::Any
   TT:H: mod_overhead_time=2.68 participant=Text::Table::HTML
   TT:M: mod_overhead_time=84.55 participant=Text::Table::Manifold
   TTH:D: mod_overhead_time=2.92 participant=Text::Table::HTML::DataTables
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n HTMLTable

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries HTMLTable | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=HTMLTable -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::HTMLTable -E'say $_->{module} for @{ $Acme::CPANModules::HTMLTable::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module contains benchmark instructions. You can run a
benchmark for some/all the modules listed in this Acme::CPANModules module using
the L<bencher> CLI (from L<Bencher> distribution):

    % bencher --cpanmodules-module HTMLTable

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-HTMLTable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-HTMLTable>.

=head1 SEE ALSO

L<Acme::CPANModules::TextTable>

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-HTMLTable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
