package Bencher::Scenario::ComparisonOps;

our $DATE = '2016-06-26'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark comparison operators',

    participants => [
        {name=>'1k-numeq'      , code_template=>'my $val =     1; for (1..1000) { if ($val ==     1) {} if ($val ==     2) {} }'},
        {name=>'1k-streq-len1' , code_template=>'my $val = "a"  ; for (1..1000) { if ($val eq "a"  ) {} if ($val eq "b"  ) {} }'},
        {name=>'1k-streq-len3' , code_template=>'my $val = "foo"; for (1..1000) { if ($val eq "foo") {} if ($val eq "bar") {} }'},
        {name=>'1k-streq-len10', code_template=>'my $val = "abcdefghij"; for (1..1000) { if ($val eq "abcdefghij") {} if ($val eq "klmnopqrst") {} }'},
    ],
};

1;
# ABSTRACT: Benchmark comparison operators

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ComparisonOps - Benchmark comparison operators

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::ComparisonOps (from Perl distribution Bencher-Scenario-ComparisonOps), released on 2016-06-26.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ComparisonOps

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1k-numeq (perl_code)

Code template:

 my $val =     1; for (1..1000) { if ($val ==     1) {} if ($val ==     2) {} }



=item * 1k-streq-len1 (perl_code)

Code template:

 my $val = "a"  ; for (1..1000) { if ($val eq "a"  ) {} if ($val eq "b"  ) {} }



=item * 1k-streq-len3 (perl_code)

Code template:

 my $val = "foo"; for (1..1000) { if ($val eq "foo") {} if ($val eq "bar") {} }



=item * 1k-streq-len10 (perl_code)

Code template:

 my $val = "abcdefghij"; for (1..1000) { if ($val eq "abcdefghij") {} if ($val eq "klmnopqrst") {} }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m ComparisonOps >>):

 +----------------+-----------+-----------+------------+---------+---------+
 | participant    | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------+-----------+-----------+------------+---------+---------+
 | 1k-streq-len10 |   17000   |   59      |    1       | 2.4e-07 |      20 |
 | 1k-streq-len3  |   17413.8 |   57.4256 |    1.03335 | 3.5e-11 |      28 |
 | 1k-streq-len1  |   17718.1 |   56.4395 |    1.0514  |   0     |      20 |
 | 1k-numeq       |   20903   |   47.8399 |    1.2404  |   0     |      22 |
 +----------------+-----------+-----------+------------+---------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ComparisonOps>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ComparisonOps>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ComparisonOps>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
