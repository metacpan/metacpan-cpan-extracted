package Bencher::Scenario::PerinciEnvRes;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

our $scenario = {
    summary => 'Compare returning enveloped result vs naked/list',
    participants => [
        {name=>'envres'             , code_template => 'return [200, "OK", "foo"]'},
        {name=>'envres_with_resmeta', code_template => 'return [200, "OK", "foo", {}]'},
        {name=>'str'                , code_template => 'return "foo"'},
        {name=>'list'               , code_template => 'return (200, "OK", "foo")', result_is_list=>1},
    ],
};

# ABSTRACT: Compare returning enveloped result vs naked/list

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciEnvRes - Compare returning enveloped result vs naked/list

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::PerinciEnvRes (from Perl distribution Bencher-Scenarios-Perinci), released on 2017-01-25.

=head1 SYNOPSIS

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * envres (perl_code)

Code template:

 return [200, "OK", "foo"]



=item * envres_with_resmeta (perl_code)

Code template:

 return [200, "OK", "foo", {}]



=item * str (perl_code)

Code template:

 return "foo"



=item * list (perl_code)

Code template:

 return (200, "OK", "foo")



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PerinciEnvRes >>):

 #table1#
 +---------------------+-----------+-----------+------------+---------+---------+
 | participant         | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +---------------------+-----------+-----------+------------+---------+---------+
 | envres_with_resmeta |   2990000 |       334 |        1   | 1.4e-10 |      20 |
 | envres              |   4300000 |       230 |        1.4 | 3.9e-10 |      36 |
 | list                |  61000000 |        16 |       21   |   5e-11 |      30 |
 | str                 | 200000000 |         5 |       70   | 2.7e-10 |      20 |
 +---------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Perinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Perinci>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Perinci>

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
