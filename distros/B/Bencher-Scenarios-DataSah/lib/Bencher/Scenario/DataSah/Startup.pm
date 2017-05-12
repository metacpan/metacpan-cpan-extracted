package Bencher::Scenario::DataSah::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.07'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of loading Data::Sah and generating validators',
    participants => [
        { name => 'perl'               , perl_cmdline => ["-e1"] },
        { name => 'load_dsah'          , perl_cmdline => ["-MData::Sah", "-e", 1] },
        { name => 'load_dsah+get_plc'  , perl_cmdline => ["-MData::Sah", "-e", '$sah = Data::Sah->new; $plc = $sah->get_compiler("perl")'] },
        { name => 'genval_bool_int'    , perl_cmdline => ["-MData::Sah=gen_validator", "-e", 'gen_validator("int")'] },
        { name => 'genval_str_int'     , perl_cmdline => ["-MData::Sah=gen_validator", "-e", 'gen_validator("int",{return_type=>"str"})'] },
        { name => 'genval_str_date'    , perl_cmdline => ["-MData::Sah=gen_validator", "-e", 'gen_validator("date",{return_type=>"str"})'] },
        { name => 'genval_str_5typical', perl_cmdline => ["-MData::Sah=gen_validator", "-e", 'for ("int", "str*", [int=>min=>1, max=>10], [str, min_len=>4], [any=>of=>["str",["array",of=>"str"]]]) { gen_validator("int",{return_type=>"str"}) }'] },
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of loading Data::Sah and generating validators

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSah::Startup - Benchmark startup overhead of loading Data::Sah and generating validators

=head1 VERSION

This document describes version 0.07 of Bencher::Scenario::DataSah::Startup (from Perl distribution Bencher-Scenarios-DataSah), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSah::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * perl (command)



=item * load_dsah (command)



=item * load_dsah+get_plc (command)



=item * genval_bool_int (command)



=item * genval_str_int (command)



=item * genval_str_date (command)



=item * genval_str_5typical (command)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSah::Startup >>):

 #table1#
 +---------------------+-----------+-----------+------------+-----------+---------+
 | participant         | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------------------+-----------+-----------+------------+-----------+---------+
 | genval_str_5typical |        18 |      57   |        1   | 9.2e-05   |      20 |
 | genval_str_date     |        18 |      55   |        1   | 7.8e-05   |      20 |
 | genval_str_int      |        19 |      53   |        1.1 | 6.2e-05   |      20 |
 | genval_bool_int     |        19 |      53   |        1.1 |   0.00012 |      20 |
 | load_dsah+get_plc   |        35 |      29   |        2   |   3e-05   |      20 |
 | load_dsah           |        88 |      11   |        5   | 5.1e-05   |      20 |
 | perl                |       200 |       5.1 |       11   |   2e-05   |      20 |
 +---------------------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DataSah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSah>

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
