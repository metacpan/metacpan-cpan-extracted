package Bencher::Scenario::IODParsingModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);

our $scenario = {
    summary => 'Benchmark IOD/INI parsing modules',
    modules => {
        # minimum versions
        'Config::IOD' => {version=>'0.31'},
        'Config::IOD::Reader' => {version=>'0.31'},
    },
    participants => [
        {
            module => 'Config::IOD::Reader',
            code_template => 'state $iod = Config::IOD::Reader->new; $iod->read_file(<filename>)',
        },
        {
            module => 'Config::IOD',
            code_template => 'state $iod = Config::IOD->new; $iod->read_file(<filename>)',
        },

        {
            module => 'Config::INI::Reader',
            code_template => 'Config::INI::Reader->read_file(<filename>)',
            tags => ['ini'],
        },
        {
            module => 'Config::IniFiles',
            code_template => 'Config::IniFiles->new(-file => <filename>)',
            tags => ['ini'],
        },
        {
            module => 'Config::Simple::Conf',
            code_template => 'Config::Simple::Conf->new(<filename>)',
            tags => ['ini'],
        },
    ],

    datasets => [
    ],
};

my $dir = dist_dir('IOD-Examples')
    or die "Can't find share dir for IOD-Examples";
for my $filename (glob "$dir/examples/extra-bench-*.iod") {
    my $basename = $filename; $basename =~ s!.+/!!;
    push @{ $scenario->{datasets} }, {
        name => $basename,
        args => {filename => $filename},
        ( exclude_participant_tags => ['ini'] ) x ($basename =~ /basic\.iod/ ? 1:0), # these files are not parseable by INI parsers
    };
}

1;
# ABSTRACT: Benchmark IOD/INI parsing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::IODParsingModules - Benchmark IOD/INI parsing modules

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::IODParsingModules (from Perl distribution Bencher-Scenario-IODParsingModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m IODParsingModules

To run module startup overhead benchmark:

 % bencher --module-startup -m IODParsingModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Config::INI::Reader> 0.025

L<Config::IOD> 0.33

L<Config::IOD::Reader> 0.32

L<Config::IniFiles> 2.93

L<Config::Simple::Conf> 2.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * Config::IOD::Reader (perl_code)

Code template:

 state $iod = Config::IOD::Reader->new; $iod->read_file(<filename>)



=item * Config::IOD (perl_code)

Code template:

 state $iod = Config::IOD->new; $iod->read_file(<filename>)



=item * Config::INI::Reader (perl_code) [ini]

Code template:

 Config::INI::Reader->read_file(<filename>)



=item * Config::IniFiles (perl_code) [ini]

Code template:

 Config::IniFiles->new(-file => <filename>)



=item * Config::Simple::Conf (perl_code) [ini]

Code template:

 Config::Simple::Conf->new(<filename>)



=back

=head1 BENCHMARK DATASETS

=over

=item * extra-bench-basic-compat.iod

=item * extra-bench-basic.iod

=item * extra-bench-typical1.iod

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m IODParsingModules >>):

 #table1#
 +----------------------+------------------------------+-----------+-----------+------------+---------+---------+
 | participant          | dataset                      | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +----------------------+------------------------------+-----------+-----------+------------+---------+---------+
 | Config::IniFiles     | extra-bench-basic-compat.iod |       230 |     4.3   |       1    | 4.9e-06 |      20 |
 | Config::INI::Reader  | extra-bench-basic-compat.iod |       840 |     1.2   |       3.6  | 2.2e-06 |      21 |
 | Config::IOD          | extra-bench-basic-compat.iod |      1100 |     0.92  |       4.7  | 1.5e-06 |      20 |
 | Config::IOD          | extra-bench-basic.iod        |      1130 |     0.887 |       4.87 | 4.6e-07 |      22 |
 | Config::IniFiles     | extra-bench-typical1.iod     |      1100 |     0.88  |       4.9  | 1.1e-06 |      20 |
 | Config::IOD::Reader  | extra-bench-basic-compat.iod |      1400 |     0.7   |       6.2  | 9.1e-07 |      20 |
 | Config::IOD::Reader  | extra-bench-basic.iod        |      1400 |     0.7   |       6.2  | 9.1e-07 |      20 |
 | Config::Simple::Conf | extra-bench-basic-compat.iod |      1600 |     0.64  |       6.8  | 1.1e-06 |      21 |
 | Config::INI::Reader  | extra-bench-typical1.iod     |      4200 |     0.24  |      18    | 6.4e-07 |      20 |
 | Config::IOD          | extra-bench-typical1.iod     |      4700 |     0.21  |      20    | 4.3e-07 |      20 |
 | Config::Simple::Conf | extra-bench-typical1.iod     |      6100 |     0.16  |      26    | 4.1e-07 |      28 |
 | Config::IOD::Reader  | extra-bench-typical1.iod     |      7600 |     0.13  |      33    | 2.7e-07 |      20 |
 +----------------------+------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m IODParsingModules --module-startup >>):

 #table2#
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant          | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Config::INI::Reader  | 4.7                          | 8.1                | 28             |      38   |                   31.9 |        1   | 6.5e-05 |      20 |
 | Config::IniFiles     | 1                            | 4.3                | 16             |      38   |                   31.9 |        1   |   9e-05 |      20 |
 | Config::IOD::Reader  | 1.4                          | 4.8                | 19             |      14   |                    7.9 |        2.7 | 7.9e-05 |      20 |
 | Config::IOD          | 5.4                          | 9.1                | 33             |      14   |                    7.9 |        2.8 | 5.3e-05 |      21 |
 | Config::Simple::Conf | 0.82                         | 4                  | 16             |       8.4 |                    2.3 |        4.5 | 5.7e-05 |      21 |
 | perl -e1 (baseline)  | 1.5                          | 4.8                | 19             |       6.1 |                    0   |        6.2 | 3.8e-05 |      21 |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-IODParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-IODParsingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-IODParsingModules>

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
