package Bencher::Scenario::Perl::Startup;

our $DATE = '2021-06-10'; # DATE
our $VERSION = '0.051'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::perlbrew;
use File::Which;

my $participants = [];

my $pb = App::perlbrew->new;
for my $perl ($pb->installed_perls) {
    push @$participants, {
        name => "$perl->{name} -e1",
        cmdline => [$perl->{executable}, "-e1"],
    };
    if (version->parse($perl->{version}) >= version->parse("5.10.0")) {
        push @$participants, {
            name => "$perl->{name} -E1",
            cmdline => [$perl->{executable}, "-E1"],
        };
    }
}

our $scenario = {
    summary => 'Benchmark startup time of perls',
    default_precision => 0.005,
    participants => $participants,
};

1;
# ABSTRACT: Benchmark startup time of perls

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Perl::Startup - Benchmark startup time of perls

=head1 VERSION

This document describes version 0.051 of Bencher::Scenario::Perl::Startup (from Perl distribution Bencher-Scenario-Perl-Startup), released on 2021-06-10.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Perl::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Conclusion: in general newer versions of perl has larger startup overhead than
previous ones. If startup overhead is important to you, use C<-e> instead of
C<-E> unless necessary.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl-5.34.0 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/perl -e1



=item * perl-5.34.0 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.34.0/bin/perl -E1



=item * perl-5.32.1 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.32.1/bin/perl -e1



=item * perl-5.32.1 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.32.1/bin/perl -E1



=item * perl-5.30.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.30.3/bin/perl -e1



=item * perl-5.30.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.30.3/bin/perl -E1



=item * perl-5.30.0 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.30.0/bin/perl -e1



=item * perl-5.30.0 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.30.0/bin/perl -E1



=item * perl-5.28.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.28.3/bin/perl -e1



=item * perl-5.28.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.28.3/bin/perl -E1



=item * perl-5.26.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.26.3/bin/perl -e1



=item * perl-5.26.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.26.3/bin/perl -E1



=item * perl-5.24.4 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.24.4/bin/perl -e1



=item * perl-5.24.4 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.24.4/bin/perl -E1



=item * perl-5.22.4 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.22.4/bin/perl -e1



=item * perl-5.22.4 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.22.4/bin/perl -E1



=item * perl-5.20.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.20.3/bin/perl -e1



=item * perl-5.20.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.20.3/bin/perl -E1



=item * perl-5.18.4 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.18.4/bin/perl -e1



=item * perl-5.18.4 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.18.4/bin/perl -E1



=item * perl-5.16.3 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.16.3/bin/perl -e1



=item * perl-5.16.3 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.16.3/bin/perl -E1



=item * perl-5.14.4 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.14.4/bin/perl -e1



=item * perl-5.14.4 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.14.4/bin/perl -E1



=item * perl-5.12.5 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.12.5/bin/perl -e1



=item * perl-5.12.5 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.12.5/bin/perl -E1



=item * perl-5.10.1 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.10.1/bin/perl -e1



=item * perl-5.10.1 -E1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.10.1/bin/perl -E1



=item * perl-5.8.9 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.8.9/bin/perl -e1



=item * perl-5.6.2 -e1 (command)

Command line:

 /home/u1/perl5/perlbrew/perls/perl-5.6.2/bin/perl -e1



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m Perl::Startup >>):

 #table1#
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant     | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | perl-5.28.3 -E1 |       110 |      9.3  |                 0.00% |                51.99% | 1.6e-05 |      22 |
 | perl-5.32.1 -E1 |       110 |      9.1  |                 1.92% |                49.13% | 1.8e-05 |      20 |
 | perl-5.30.0 -E1 |       130 |      7.6  |                21.78% |                24.81% | 1.6e-05 |      20 |
 | perl-5.34.0 -E1 |       140 |      7.2  |                28.61% |                18.18% | 1.9e-05 |      20 |
 | perl-5.26.3 -E1 |       140 |      7.1  |                31.68% |                15.42% | 1.5e-05 |      20 |
 | perl-5.28.3 -e1 |       140 |      7    |                32.06% |                15.09% | 2.9e-05 |      28 |
 | perl-5.30.3 -E1 |       140 |      7    |                32.97% |                14.30% |   1e-05 |      20 |
 | perl-5.24.4 -E1 |       143 |      7    |                33.04% |                14.24% | 6.6e-06 |      24 |
 | perl-5.22.4 -E1 |       140 |      7    |                33.76% |                13.63% | 1.1e-05 |      21 |
 | perl-5.20.3 -E1 |       140 |      6.9  |                34.62% |                12.90% | 1.5e-05 |      20 |
 | perl-5.18.4 -E1 |       150 |      6.9  |                35.56% |                12.12% | 9.4e-06 |      20 |
 | perl-5.16.3 -E1 |       150 |      6.8  |                36.43% |                11.41% | 2.5e-05 |      24 |
 | perl-5.30.0 -e1 |       150 |      6.8  |                37.72% |                10.36% | 3.1e-05 |      22 |
 | perl-5.14.4 -E1 |       150 |      6.7  |                38.35% |                 9.86% | 1.1e-05 |      20 |
 | perl-5.12.5 -E1 |       150 |      6.65 |                39.89% |                 8.65% | 5.1e-06 |      20 |
 | perl-5.32.1 -e1 |       150 |      6.6  |                40.05% |                 8.52% | 1.2e-05 |      20 |
 | perl-5.10.1 -E1 |       152 |      6.59 |                41.33% |                 7.55% | 5.2e-06 |      20 |
 | perl-5.22.4 -e1 |       150 |      6.5  |                42.72% |                 6.49% | 1.5e-05 |      20 |
 | perl-5.34.0 -e1 |       150 |      6.5  |                43.23% |                 6.12% | 2.6e-05 |      30 |
 | perl-5.30.3 -e1 |       150 |      6.5  |                43.96% |                 5.58% | 1.3e-05 |      21 |
 | perl-5.24.4 -e1 |       150 |      6.5  |                44.26% |                 5.36% | 2.2e-05 |      20 |
 | perl-5.20.3 -e1 |       150 |      6.5  |                44.26% |                 5.36% | 1.5e-05 |      21 |
 | perl-5.26.3 -e1 |       160 |      6.4  |                44.75% |                 5.00% | 9.2e-06 |      20 |
 | perl-5.14.4 -e1 |       160 |      6.4  |                46.24% |                 3.93% | 1.3e-05 |      20 |
 | perl-5.18.4 -e1 |       160 |      6.3  |                46.79% |                 3.55% | 1.2e-05 |      21 |
 | perl-5.16.3 -e1 |       158 |      6.34 |                46.92% |                 3.45% |   5e-06 |      20 |
 | perl-5.12.5 -e1 |       158 |      6.32 |                47.30% |                 3.18% |   5e-06 |      20 |
 | perl-5.10.1 -e1 |       160 |      6.3  |                48.33% |                 2.47% | 6.7e-06 |      20 |
 | perl-5.8.9 -e1  |       160 |      6.2  |                49.15% |                 1.91% | 1.3e-05 |      20 |
 | perl-5.6.2 -e1  |       160 |      6.1  |                51.99% |                 0.00% | 1.4e-05 |      20 |
 +-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Perl-Startup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Perl-Startup>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Perl-Startup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::Interpreters>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
