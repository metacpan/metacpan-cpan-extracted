package Bencher::Scenario::IPCSystemOptions;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => "Measure the overhead of IPC::System::Options's system()".
        "over CORE::system()",
    modules => {
        'IPC::System::Options' => {version=>0.27},
    },
    default_precision => 0.001,
    participants => [
        {
            name => 'core-true',
            code => sub {
                system {"/bin/true"} "/bin/true";
            },
        },
        {
            name => 'iso-true',
            module => 'IPC::System::Options',
            code => sub {
                IPC::System::Options::system({shell=>0}, "/bin/true");
            },
        },
        {
            name => 'core-perl',
            code => sub {
                system {$^X} $^X, "-e1";
            },
        },
        {
            name => 'iso-perl',
            module => 'IPC::System::Options',
            code => sub {
                IPC::System::Options::system({shell=>0}, $^X, "-e1");
            },
        },
    ],
};

1;
# ABSTRACT: Measure the overhead of IPC::System::Options's system()over CORE::system()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::IPCSystemOptions - Measure the overhead of IPC::System::Options's system()over CORE::system()

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::IPCSystemOptions (from Perl distribution Bencher-Scenario-IPCSystemOptions), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m IPCSystemOptions

To run module startup overhead benchmark:

 % bencher --module-startup -m IPCSystemOptions

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Conclusion: Testing on my system (L<IPC::System::Options> 0.24, perl: 5.22.0,
CPU: Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores)) shows the overhead to be
~40μs (0.04ms) so for benchmarking commands that have overhead in the range of
10-100ms we normally don't need to worry about the overhead of
IPC::System::Option (0.04-0.4%) when we are using default precision (~1%).

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<IPC::System::Options> 0.29

=head1 BENCHMARK PARTICIPANTS

=over

=item * core-true (perl_code)



=item * iso-true (perl_code)

L<IPC::System::Options>



=item * core-perl (perl_code)



=item * iso-perl (perl_code)

L<IPC::System::Options>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m IPCSystemOptions >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | iso-perl    |       176 |      5.67 |       1    | 5.5e-06 |     219 |
 | core-perl   |       177 |      5.64 |       1.01 | 5.5e-06 |     178 |
 | iso-true    |       222 |      4.5  |       1.26 | 4.4e-06 |    1821 |
 | core-true   |       231 |      4.32 |       1.31 | 4.2e-06 |    1894 |
 +-------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m IPCSystemOptions --module-startup >>):

 #table2#
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant          | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | IPC::System::Options | 1.25                         | 4.52               | 16.4           |     11.9  |                   6.03 |       1    | 1.2e-05 |     720 |
 | perl -e1 (baseline)  | 0.824                        | 4.05               | 16             |      5.87 |                   0    |       2.03 | 5.8e-06 |     246 |
 +----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-IPCSystemOptions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-IPCSystemOptions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-IPCSystemOptions>

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
