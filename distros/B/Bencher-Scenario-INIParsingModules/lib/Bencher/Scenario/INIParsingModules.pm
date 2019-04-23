package Bencher::Scenario::INIParsingModules;

our $DATE = '2019-04-23'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);

our $scenario = {
    summary => 'Benchmark INI parsing modules',
    modules => {
        # minimum versions
        #'Foo' => {version=>'0.31'},
    },
    participants => [
        {
            module => 'Config::IOD::INI::Reader',
            code_template => 'state $iod = Config::IOD::INI::Reader->new; $iod->read_file(<filename>)',
        },
        {
            module => 'Config::INI::Reader',
            code_template => 'Config::INI::Reader->read_file(<filename>)',
        },
        {
            module => 'Config::IniFiles',
            code_template => 'Config::IniFiles->new(-file => <filename>)',
        },
        {
            module => 'Config::Simple::Conf',
            code_template => 'Config::Simple::Conf->new(<filename>)',
        },
    ],

    datasets => [
    ],
};

my $dir = dist_dir('INI-Examples')
    or die "Can't find share dir for INI-Examples";
for my $filename (glob "$dir/examples/*bench*.ini") {
    my $basename = $filename; $basename =~ s!.+/!!;
    push @{ $scenario->{datasets} }, {
        name => $basename,
        args => {filename => $filename},
    };
}

1;
# ABSTRACT: Benchmark INI parsing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::INIParsingModules - Benchmark INI parsing modules

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::INIParsingModules (from Perl distribution Bencher-Scenario-INIParsingModules), released on 2019-04-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m INIParsingModules

To run module startup overhead benchmark:

 % bencher --module-startup -m INIParsingModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Config::INI::Reader> 0.025

L<Config::IOD::INI::Reader> 0.342

L<Config::IniFiles> 2.94

L<Config::Simple::Conf> 2.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * Config::IOD::INI::Reader (perl_code)

Code template:

 state $iod = Config::IOD::INI::Reader->new; $iod->read_file(<filename>)



=item * Config::INI::Reader (perl_code)

Code template:

 Config::INI::Reader->read_file(<filename>)



=item * Config::IniFiles (perl_code)

Code template:

 Config::IniFiles->new(-file => <filename>)



=item * Config::Simple::Conf (perl_code)

Code template:

 Config::Simple::Conf->new(<filename>)



=back

=head1 BENCHMARK DATASETS

=over

=item * extra-bench-basic-compat.ini

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m INIParsingModules >>):

 #table1#
 +--------------------------+-----------+-----------+------------+---------+---------+
 | participant              | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +--------------------------+-----------+-----------+------------+---------+---------+
 | Config::IniFiles         |       170 |      5.9  |        1   | 2.2e-05 |      20 |
 | Config::INI::Reader      |       560 |      1.8  |        3.3 | 3.4e-06 |      20 |
 | Config::Simple::Conf     |      1200 |      0.81 |        7.3 | 5.6e-06 |      20 |
 | Config::IOD::INI::Reader |      1300 |      0.75 |        7.9 | 4.7e-06 |      20 |
 +--------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m INIParsingModules --module-startup >>):

 #table2#
 +--------------------------+-----------+------------------------+------------+-----------+---------+
 | participant              | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +--------------------------+-----------+------------------------+------------+-----------+---------+
 | Config::IniFiles         |      43   |                   36   |        1   |   0.00018 |      20 |
 | Config::INI::Reader      |      42   |                   35   |        1   |   6e-05   |      20 |
 | Config::IOD::INI::Reader |      16   |                    9   |        2.8 |   0.00012 |      20 |
 | Config::Simple::Conf     |       8.6 |                    1.6 |        5   | 4.1e-05   |      20 |
 | perl -e1 (baseline)      |       7   |                    0   |        7   | 8.5e-05   |      21 |
 +--------------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-INIParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-INIParsingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-INIParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
