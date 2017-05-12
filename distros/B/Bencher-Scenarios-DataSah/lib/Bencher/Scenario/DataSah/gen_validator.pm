package Bencher::Scenario::DataSah::gen_validator;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.07'; # VERSION

my $return_types = ['bool', 'str', 'full'];

our $scenario = {
    summary => 'Benchmark validator generation',
    modules => {
        'Data::Sah' => {version=>'0.84'},
    },
    participants => [
        {
            name => 'gen_validator',
            fcall_template => 'Data::Sah::gen_validator(<schema>, {return_type=> <return_type>})',
        },
    ],
    datasets => [
        {args => {'return_type@' => $return_types, schema => 'str'}},
        {args => {'return_type@' => $return_types, schema => 'str*'}},
        {args => {'return_type@' => $return_types, schema => ['str', len=>8]}},
        {args => {'return_type@' => $return_types, schema => ['str', min_len=>1, max_len=>10]}},
        {args => {'return_type@' => $return_types, schema => 'date'}},
        {args => {'return_type@' => $return_types, schema => ['array', of=>['str', min_len=>1, max_len=>10]]}},
        {args => {'return_type@' => $return_types, schema => ['array', elems=>['int*', 'str*', 'float*', 're*']]}},
    ],
};

1;
# ABSTRACT: Benchmark validator generation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSah::gen_validator - Benchmark validator generation

=head1 VERSION

This document describes version 0.07 of Bencher::Scenario::DataSah::gen_validator (from Perl distribution Bencher-Scenarios-DataSah), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSah::gen_validator

To run module startup overhead benchmark:

 % bencher --module-startup -m DataSah::gen_validator

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah> 0.87

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_validator (perl_code)

Function call template:

 Data::Sah::gen_validator(<schema>, {return_type=> <return_type>})



=back

=head1 BENCHMARK DATASETS

=over

=item * str

=item * str*

=item * ["str","len",8]

=item * ["str","min_len",1,"max_len",10]

=item * date

=item * ["array","of",["str","min_len",1,"max_len",10]]

=item * ["array","elems",["int*","str*","float*","re*"]]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataSah::gen_validator >>):

 #table1#
 +--------------------------------------------------+-----------------+-----------+-----------+------------+-----------+---------+
 | dataset                                          | arg_return_type | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +--------------------------------------------------+-----------------+-----------+-----------+------------+-----------+---------+
 | ["array","elems",["int*","str*","float*","re*"]] | bool            |       200 |     5     |       1    |   0.00014 |      21 |
 | ["array","elems",["int*","str*","float*","re*"]] | str             |       220 |     4.6   |       1    | 2.5e-05   |      20 |
 | ["array","elems",["int*","str*","float*","re*"]] | full            |       220 |     4.5   |       1.1  | 6.1e-06   |      20 |
 | ["array","of",["str","min_len",1,"max_len",10]]  | full            |       300 |     3     |       1    | 7.2e-05   |      21 |
 | ["array","of",["str","min_len",1,"max_len",10]]  | str             |       320 |     3.2   |       1.5  | 2.8e-05   |      20 |
 | ["array","of",["str","min_len",1,"max_len",10]]  | bool            |       400 |     3     |       2    | 3.6e-05   |      21 |
 | ["str","len",8]                                  | str             |       600 |     2     |       3    | 5.3e-05   |      20 |
 | ["str","len",8]                                  | full            |       620 |     1.6   |       3    | 1.1e-05   |      20 |
 | ["str","min_len",1,"max_len",10]                 | bool            |       600 |     2     |       3    | 4.3e-05   |      20 |
 | ["str","min_len",1,"max_len",10]                 | full            |       692 |     1.45  |       3.37 | 9.1e-07   |      20 |
 | ["str","len",8]                                  | bool            |       700 |     1     |       3    |   2e-05   |      20 |
 | str*                                             | full            |       700 |     1     |       4    | 1.8e-05   |      20 |
 | ["str","min_len",1,"max_len",10]                 | str             |       800 |     1     |       4    | 2.4e-05   |      20 |
 | date                                             | full            |       770 |     1.3   |       3.7  | 2.7e-06   |      23 |
 | date                                             | bool            |       800 |     1     |       4    | 2.7e-05   |      20 |
 | str*                                             | str             |       800 |     1     |       4    | 1.3e-05   |      20 |
 | date                                             | str             |       810 |     1.2   |       4    |   5e-06   |      20 |
 | str*                                             | bool            |      1000 |     1     |       5    | 3.7e-05   |      21 |
 | str                                              | full            |      1200 |     0.85  |       5.7  | 2.6e-06   |      21 |
 | str                                              | bool            |      1220 |     0.821 |       5.93 | 4.8e-07   |      20 |
 | str                                              | str             |      1200 |     0.82  |       6    | 4.4e-06   |      23 |
 +--------------------------------------------------+-----------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m DataSah::gen_validator --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Data::Sah           | 0.82                         | 4                  | 16             |      12   |                    5.9 |          1 |   0.00011 |      21 |
 | perl -e1 (baseline) | 1.3                          | 4.8                | 16             |       6.1 |                    0   |          2 | 4.1e-05   |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


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
