package Bencher::Scenario::Perl::Startup;

our $DATE = '2019-10-20'; # DATE
our $VERSION = '0.050'; # VERSION

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

This document describes version 0.050 of Bencher::Scenario::Perl::Startup (from Perl distribution Bencher-Scenarios-Perl), released on 2019-10-20.

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

=item * perl-5.26.2 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.26.2/bin/perl -e1



=item * perl-5.26.2 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.26.2/bin/perl -E1



=item * perl-5.24.1 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.24.1/bin/perl -e1



=item * perl-5.24.1 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.24.1/bin/perl -E1



=item * perl-5.24.0 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.24.0/bin/perl -e1



=item * perl-5.24.0 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.24.0/bin/perl -E1



=item * perl-5.24.0-vanilla -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.24.0-vanilla/bin/perl -e1



=item * perl-5.24.0-vanilla -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.24.0-vanilla/bin/perl -E1



=item * perl-5.22.2 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.22.2/bin/perl -e1



=item * perl-5.22.2 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.22.2/bin/perl -E1



=item * cperl-5.22.1 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/cperl-5.22.1/bin/perl -e1



=item * cperl-5.22.1 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/cperl-5.22.1/bin/perl -E1



=item * stableperl-5.22.0 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/stableperl-5.22.0/bin/perl -e1



=item * stableperl-5.22.0 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/stableperl-5.22.0/bin/perl -E1



=item * perl-5.20.3 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.20.3/bin/perl -e1



=item * perl-5.20.3 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.20.3/bin/perl -E1



=item * perl-5.18.4 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.18.4/bin/perl -e1



=item * perl-5.18.4 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.18.4/bin/perl -E1



=item * perl-5.16.3 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.16.3/bin/perl -e1



=item * perl-5.16.3 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.16.3/bin/perl -E1



=item * perl-5.14.4 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.14.4/bin/perl -e1



=item * perl-5.14.4 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.14.4/bin/perl -E1



=item * perl-5.12.5 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.12.5/bin/perl -e1



=item * perl-5.12.5 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.12.5/bin/perl -E1



=item * perl-5.10.1 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.10.1/bin/perl -e1



=item * perl-5.10.1 -E1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.10.1/bin/perl -E1



=item * perl-5.8.9 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.8.9/bin/perl -e1



=item * perl-5.6.2 -e1 (command)

Command line:

 /home/s1/perl5/perlbrew/perls/perl-5.6.2/bin/perl -e1



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m Perl::Startup >>):

 #table1#
 +-------------------------+-----------+-----------+------------+---------+---------+
 | participant             | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------+-----------+-----------+------------+---------+---------+
 | perl-5.24.1 -E1         |       280 |      3.6  |       1    | 1.6e-05 |      20 |
 | perl-5.20.3 -E1         |       280 |      3.6  |       1    | 1.8e-05 |      45 |
 | perl-5.24.0 -E1         |       290 |      3.5  |       1    | 1.7e-05 |      34 |
 | perl-5.22.2 -E1         |       300 |      3.4  |       1.1  | 4.1e-06 |      20 |
 | perl-5.24.0-vanilla -E1 |       300 |      3.4  |       1.1  | 3.6e-06 |      20 |
 | perl-5.26.2 -E1         |       300 |      3.3  |       1.1  | 4.5e-06 |      20 |
 | stableperl-5.22.0 -E1   |       300 |      3.3  |       1.1  | 8.3e-06 |      20 |
 | cperl-5.22.1 -E1        |       302 |      3.31 |       1.08 | 1.5e-06 |      20 |
 | perl-5.18.4 -E1         |       310 |      3.3  |       1.1  | 8.7e-06 |      20 |
 | perl-5.16.3 -E1         |       320 |      3.2  |       1.1  | 3.6e-06 |      20 |
 | perl-5.14.4 -E1         |       330 |      3.1  |       1.2  | 3.3e-06 |      20 |
 | perl-5.12.5 -E1         |       330 |      3    |       1.2  | 4.3e-06 |      20 |
 | perl-5.24.0 -e1         |       330 |      3    |       1.2  | 1.5e-05 |      36 |
 | perl-5.10.1 -E1         |       330 |      3    |       1.2  | 6.7e-06 |      20 |
 | perl-5.20.3 -e1         |       340 |      3    |       1.2  | 1.4e-05 |      26 |
 | perl-5.22.2 -e1         |       350 |      2.9  |       1.2  | 2.9e-06 |      20 |
 | perl-5.24.0-vanilla -e1 |       354 |      2.83 |       1.26 | 2.7e-06 |      20 |
 | perl-5.24.1 -e1         |       350 |      2.8  |       1.3  | 2.9e-06 |      21 |
 | perl-5.18.4 -e1         |       350 |      2.8  |       1.3  | 5.8e-06 |      20 |
 | perl-5.26.2 -e1         |       360 |      2.8  |       1.3  | 3.8e-06 |      20 |
 | cperl-5.22.1 -e1        |       360 |      2.8  |       1.3  | 2.9e-06 |      20 |
 | perl-5.16.3 -e1         |       360 |      2.8  |       1.3  | 7.1e-06 |      20 |
 | stableperl-5.22.0 -e1   |       360 |      2.8  |       1.3  |   8e-06 |      20 |
 | perl-5.14.4 -e1         |       360 |      2.7  |       1.3  |   7e-06 |      20 |
 | perl-5.12.5 -e1         |       370 |      2.7  |       1.3  | 3.8e-06 |      20 |
 | perl-5.10.1 -e1         |       370 |      2.7  |       1.3  | 8.3e-06 |      20 |
 | perl-5.8.9 -e1          |       372 |      2.69 |       1.32 | 2.7e-06 |      21 |
 | perl-5.6.2 -e1          |       390 |      2.5  |       1.4  | 4.3e-06 |      20 |
 +-------------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::Interpreters>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
