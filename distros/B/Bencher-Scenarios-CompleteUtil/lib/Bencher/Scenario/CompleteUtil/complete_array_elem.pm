package Bencher::Scenario::CompleteUtil::complete_array_elem;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

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

Bencher::Scenario::CompleteUtil::complete_array_elem - Benchmark complete_array_elem()

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::CompleteUtil::complete_array_elem (from Perl distribution Bencher-Scenarios-CompleteUtil), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CompleteUtil::complete_array_elem

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Complete::Util> 0.58

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m CompleteUtil::complete_array_elem >>):

 #table1#
 +------------------+-----------+-----------+------------+-----------+---------+
 | participant      | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +------------------+-----------+-----------+------------+-----------+---------+
 | fuzzy-pp-1000    |       4.5 |   220     |        1   |   0.00049 |      20 |
 | fuzzy-pp-100     |      33   |    30     |        7.5 |   0.00022 |      20 |
 | fuzzy-xs-1000    |      90   |    10     |       20   |   0.00012 |      21 |
 | fuzzy-flex-1000  |     470   |     2.1   |      110   | 3.4e-06   |      20 |
 | wordmode-1000    |     606   |     1.65  |      135   | 9.1e-07   |      20 |
 | charmode-1000    |    1000   |     1     |      200   | 1.9e-05   |      27 |
 | prefix-1000      |    2080   |     0.481 |      465   | 5.3e-08   |      20 |
 | prefix-noci-1000 |    2680   |     0.373 |      600   |   2e-07   |      22 |
 +------------------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-CompleteUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-CompleteUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-CompleteUtil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
