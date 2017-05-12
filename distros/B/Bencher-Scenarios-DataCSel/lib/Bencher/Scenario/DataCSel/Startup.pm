package Bencher::Scenario::DataCSel::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of loading Data::CSel and parsing expressions',
    participants => [
        { name => 'perl',            perl_cmdline => ["-e1"] },
        { name => 'load_csel',       perl_cmdline => ["-MData::CSel", "-e1"] },
        { name => 'load_csel_parse', perl_cmdline => ["-MData::CSel=parse_csel", "-e", "parse_csel(q(E F))"] },
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of loading Data::CSel and parsing expressions

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataCSel::Startup - Benchmark startup overhead of loading Data::CSel and parsing expressions

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::DataCSel::Startup (from Perl distribution Bencher-Scenarios-DataCSel), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataCSel::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (command)



=item * load_csel (command)



=item * load_csel_parse (command)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataCSel::Startup >>):

 #table1#
 +-----------------+-----------+-----------+------------+---------+---------+
 | participant     | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------+-----------+-----------+------------+---------+---------+
 | load_csel_parse |        71 |      14   |        1   | 9.2e-05 |      21 |
 | load_csel       |        73 |      14   |        1   | 4.4e-05 |      21 |
 | perl            |       150 |       6.5 |        2.2 | 1.1e-05 |      20 |
 +-----------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataCSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataCSel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataCSel>

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
