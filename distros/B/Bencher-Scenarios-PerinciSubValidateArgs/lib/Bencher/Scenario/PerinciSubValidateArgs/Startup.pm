package Bencher::Scenario::PerinciSubValidateArgs::Startup;

our $DATE = '2016-05-25'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of Perinci::Sub::ValidateArgs',
    participants => [
        {
            name => 'perl',
            summary => 'Load Perinci::Sub::ValidateArgs',
            perl_cmdline => ["-e1"],
        },
        {
            name => 'load_psv',
            summary => 'Load Perinci::Sub::ValidateArgs',
            perl_cmdline => ["-MPerinci::Sub::ValidateArgs", "-e1"],
        },
        {
            name => 'load_psv+first_run',
            summary => 'Load Perinci::Sub::ValidateArgs (PSV) and run a function that uses PSV for the first time',
            perl_cmdline => ["-MBencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSV", "-e", "Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingPSV::foo(a1=>1,a2=>1)"],
        },
    ],
};

1;
# ABSTRACT: Benchmark startup of Perinci::Sub::ValidateArgs

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciSubValidateArgs::Startup - Benchmark startup of Perinci::Sub::ValidateArgs

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::PerinciSubValidateArgs::Startup (from Perl distribution Bencher-Scenarios-PerinciSubValidateArgs), released on 2016-05-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciSubValidateArgs::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (command)

Load Perinci::Sub::ValidateArgs.



=item * load_psv (command)

Load Perinci::Sub::ValidateArgs.



=item * load_psv+first_run (command)

Load Perinci::Sub::ValidateArgs (PSV) and run a function that uses PSV for the first time.



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.1 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m PerinciSubValidateArgs::Startup >>):

 +--------------------+-----------+-----------+------------+---------+---------+
 | participant        | rate (/s) | time (ms) | vs_slowest | errors  | samples |
 +--------------------+-----------+-----------+------------+---------+---------+
 | load_psv+first_run | 15        | 68        | 1          | 9.3e-05 | 20      |
 | load_psv           | 89        | 11        | 6          | 2.2e-05 | 20      |
 | perl               | 2e+02     | 5         | 1e+01      | 5.1e-05 | 20      |
 +--------------------+-----------+-----------+------------+---------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciSubValidateArgs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciSubValidateArgs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciSubValidateArgs>

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
