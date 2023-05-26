package Bencher::Scenario::Complete::Util::complete_array_elem;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenarios-Complete-Util'; # DIST
our $VERSION = '0.051'; # VERSION

our $scenario = {
    summary => 'Benchmark complete_array_elem()',
    modules => {
        'Complete::Util' => {version=>0.57},
        'Text::Levenshtein::XS' => {version=>0},
        'Text::Levenshtein::Flexible' => {version=>0},
    },
    participants => [
        {
            name => 'prefix-noci-1000',
            code => sub {
                state $ary = do {
                    require Complete::Util;
                    my $ary = [];
                    for my $l1 (0..9) {
                        for my $l2 (0..9) {
                            for my $l3 (0..9) {
                                push @$ary, "aaa${l1}bbb${l2}ccc${l3}"; # 12char
                            }
                        }
                    }
                    $ary;
                };
                local $Complete::Common::OPT_CI = 0;
                local $Complete::Common::OPT_MAP_CASE = 0;
                #local $Complete::Common::OPT_WORD_MODE = 0; # should not been used, because normal prefix matching returns result
                #local $Complete::Common::OPT_CHAR_MODE = 0; # should not been used, because normal prefix matching returns result
                #local $Complete::Common::OPT_FUZZY     = 0; # should not been used, because normal prefix matching returns result
                Complete::Util::complete_array_elem(
                    word  => 'aaa9bbb9ccc9',
                    array => $ary,
                );
            },
        },
        {
            name => 'prefix-1000',
            code => sub {
                state $ary = do {
                    require Complete::Util;
                    my $ary = [];
                    for my $l1 (0..9) {
                        for my $l2 (0..9) {
                            for my $l3 (0..9) {
                                push @$ary, "aaa${l1}bbb${l2}ccc${l3}"; # 12char
                            }
                        }
                    }
                    $ary;
                };
                #local $Complete::Common::OPT_WORD_MODE = 0; # should not been used, because normal prefix matching returns result
                #local $Complete::Common::OPT_CHAR_MODE = 0; # should not been used, because normal prefix matching returns result
                #local $Complete::Common::OPT_FUZZY     = 0; # should not been used, because normal prefix matching returns result
                Complete::Util::complete_array_elem(
                    word  => 'aaa9bbb9ccc9',
                    array => $ary,
                );
            },
        },

        # note that wordmode, charmode, and fuzzy also does prefix matching

        {
            name => 'wordmode-1000',
            code => sub {
                state $ary = do {
                    require Complete::Util;
                    my $ary = [];
                    for my $l1 ('a'..'j') {
                        for my $l2 ('a'..'j') {
                            for my $l3 ('a'..'j') {
                                push @$ary, ($l1 x 3).'-'.($l2 x 3).'-'.($l3 x 3); # 12char
                            }
                        }
                    }
                    $ary;
                };
                #local $Complete::Common::OPT_WORD_MODE = 0;
                #local $Complete::Common::OPT_CHAR_MODE = 0; # should not been used, because normal prefix matching returns result
                #local $Complete::Common::OPT_FUZZY     = 0; # should not been used, because normal prefix matching returns result
                Complete::Util::complete_array_elem(
                    word  => 'j-j-j',
                    array => $ary,
                );
            },
        },
        {
            name => 'charmode-1000',
            code => sub {
                state $ary = do {
                    require Complete::Util;
                    my $ary = [];
                    for my $l1 (0..9) {
                        for my $l2 (0..9) {
                            for my $l3 (0..9) {
                                push @$ary, "aaa${l1}bbb${l2}ccc${l3}"; # 12char
                            }
                        }
                    }
                    $ary;
                };
                local $Complete::Common::OPT_WORD_MODE = 0;
                #local $Complete::Common::OPT_CHAR_MODE = 0;
                #local $Complete::Common::OPT_FUZZY     = 0; # should not been used, because char-mode returns result
                Complete::Util::complete_array_elem(
                    word  => 'a9b9c9',
                    array => $ary,
                );
            },
        },
        {
            name => 'fuzzy-xs-1000',
            code => sub {
                state $ary = do {
                    require Complete::Util;
                    my $ary = [];
                    for my $l1 ('a'..'j') {
                        for my $l2 ('a'..'j') {
                            for my $l3 ('a'..'j') {
                                push @$ary, ($l1 x 4).($l2 x 4).($l3 x 4); # 12char
                            }
                        }
                    }
                    $ary;
                };
                local $Complete::Common::OPT_WORD_MODE = 0;
                local $Complete::Common::OPT_CHAR_MODE = 0;
                undef $Complete::Util::code_editdist;
                local $ENV{COMPLETE_UTIL_LEVENSHTEIN} = 'xs';
                Complete::Util::complete_array_elem(
                    word  => 'jjjjkjjjjjjj',
                    array => $ary,
                );
            },
        },
        {
            name => 'fuzzy-flex-1000',
            code => sub {
                state $ary = do {
                    require Complete::Util;
                    my $ary = [];
                    for my $l1 ('a'..'j') {
                        for my $l2 ('a'..'j') {
                            for my $l3 ('a'..'j') {
                                push @$ary, ($l1 x 4).($l2 x 4).($l3 x 4); # 12char
                            }
                        }
                    }
                    $ary;
                };
                local $Complete::Common::OPT_WORD_MODE = 0;
                local $Complete::Common::OPT_CHAR_MODE = 0;
                undef $Complete::Util::code_editdist;
                local $ENV{COMPLETE_UTIL_LEVENSHTEIN} = 'flexible';
                Complete::Util::complete_array_elem(
                    word  => 'jjjjkjjjjjjj',
                    array => $ary,
                );
            },
        },
        {
            name => 'fuzzy-pp-1000',
            code => sub {
                state $ary = do {
                    require Complete::Util;
                    my $ary = [];
                    for my $l1 ('a'..'j') {
                        for my $l2 ('a'..'j') {
                            for my $l3 ('a'..'j') {
                                push @$ary, ($l1 x 4).($l2 x 4).($l3 x 4); # 12char
                            }
                        }
                    }
                    $ary;
                };
                local $Complete::Common::OPT_WORD_MODE = 0;
                local $Complete::Common::OPT_CHAR_MODE = 0;
                undef $Complete::Util::code_editdist;
                local $ENV{COMPLETE_UTIL_LEVENSHTEIN} = 'pp';
                Complete::Util::complete_array_elem(
                    word  => 'jjjjkjjjjjjj',
                    array => $ary,
                );
            },
        },
        {
            name => 'fuzzy-pp-100',
            code => sub {
                state $ary = do {
                    require Complete::Util;
                    my $ary = [];
                    for my $l1 ('a'..'j') {
                        for my $l2 ('a'..'j') {
                            push @$ary, ($l1 x 6).($l2 x 6); # 12char
                        }
                    }
                    $ary;
                };
                local $Complete::Common::OPT_WORD_MODE = 0;
                local $Complete::Common::OPT_CHAR_MODE = 0;
                undef $Complete::Util::code_editdist;
                local $ENV{COMPLETE_UTIL_LEVENSHTEIN} = 'pp';
                Complete::Util::complete_array_elem(
                    word  => 'jjjjjkjjjjj',
                    array => $ary,
                );
            },
        },
    ],
    #datasets => [
    #],
};

1;
# ABSTRACT: Benchmark complete_array_elem()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Complete::Util::complete_array_elem - Benchmark complete_array_elem()

=head1 VERSION

This document describes version 0.051 of Bencher::Scenario::Complete::Util::complete_array_elem (from Perl distribution Bencher-Scenarios-Complete-Util), released on 2023-01-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Complete::Util::complete_array_elem

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Complete::Util> 0.615

L<Text::Levenshtein::Flexible> 0.09

L<Text::Levenshtein::XS> 0.503

=head1 BENCHMARK PARTICIPANTS

=over

=item * prefix-noci-1000 (perl_code)



=item * prefix-1000 (perl_code)



=item * wordmode-1000 (perl_code)



=item * charmode-1000 (perl_code)



=item * fuzzy-xs-1000 (perl_code)



=item * fuzzy-flex-1000 (perl_code)



=item * fuzzy-pp-1000 (perl_code)



=item * fuzzy-pp-100 (perl_code)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Complete::Util::complete_array_elem >>):

 #table1#
 +------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant      | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | fuzzy-pp-1000    |      4.68 |   214     |                 0.00% |             48711.74% |   0.00013 |      20 |
 | fuzzy-pp-100     |     35    |    28     |               651.85% |              6392.20% | 5.9e-05   |      21 |
 | fuzzy-xs-1000    |    100    |    10     |              2035.81% |              2185.40% |   0.00011 |      20 |
 | fuzzy-flex-1000  |    540    |     1.8   |             11506.23% |               320.56% | 3.9e-06   |      24 |
 | wordmode-1000    |    680    |     1.5   |             14444.06% |               235.61% | 1.6e-06   |      20 |
 | charmode-1000    |   1240    |     0.808 |             26340.48% |                84.61% | 2.7e-07   |      20 |
 | prefix-1000      |   1950    |     0.513 |             41602.02% |                17.05% | 2.1e-07   |      20 |
 | prefix-noci-1000 |   2280    |     0.438 |             48711.74% |                 0.00% | 2.1e-07   |      20 |
 +------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                      Rate  fuzzy-pp-1000  fuzzy-pp-100  fuzzy-xs-1000  fuzzy-flex-1000  wordmode-1000  charmode-1000  prefix-1000  prefix-noci-1000 
  fuzzy-pp-1000     4.68/s             --          -86%           -95%             -99%           -99%           -99%         -99%              -99% 
  fuzzy-pp-100        35/s           664%            --           -64%             -93%           -94%           -97%         -98%              -98% 
  fuzzy-xs-1000      100/s          2039%          179%             --             -82%           -85%           -91%         -94%              -95% 
  fuzzy-flex-1000    540/s         11788%         1455%           455%               --           -16%           -55%         -71%              -75% 
  wordmode-1000      680/s         14166%         1766%           566%              19%             --           -46%         -65%              -70% 
  charmode-1000     1240/s         26385%         3365%          1137%             122%            85%             --         -36%              -45% 
  prefix-1000       1950/s         41615%         5358%          1849%             250%           192%            57%           --              -14% 
  prefix-noci-1000  2280/s         48758%         6292%          2183%             310%           242%            84%          17%                -- 
 
 Legends:
   charmode-1000: participant=charmode-1000
   fuzzy-flex-1000: participant=fuzzy-flex-1000
   fuzzy-pp-100: participant=fuzzy-pp-100
   fuzzy-pp-1000: participant=fuzzy-pp-1000
   fuzzy-xs-1000: participant=fuzzy-xs-1000
   prefix-1000: participant=prefix-1000
   prefix-noci-1000: participant=prefix-noci-1000
   wordmode-1000: participant=wordmode-1000

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Complete-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Complete-Util>.

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Complete-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
