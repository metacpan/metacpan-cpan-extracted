package Bencher::Scenario::ArchiveTarModules::ListMemUsage;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Bencher::ScenarioUtil::ArchiveTarModules;

my $modules  = \%Bencher::ScenarioUtil::ArchiveTarModules::Modules;
my $datasets = \@Bencher::ScenarioUtil::ArchiveTarModules::Datasets;

our $scenario = {
    summary => 'Benchmark memory usage for listing files of an archive',
    modules => {
    },
    participants => [
        (map {
            my $spec = $modules->{$_};
            +{
                name => $_,
                module => $_,
                description => $spec->{description},
                code_template => $spec->{code_template_list_files},
            };
        } keys %$modules),

        {
            name => 'perl (baseline)',
            code_template => '1',
        },
    ],
    datasets => $datasets,
    with_process_size => 1,
    precision => 6,
};

1;
# ABSTRACT: Benchmark memory usage for listing files of an archive

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArchiveTarModules::ListMemUsage - Benchmark memory usage for listing files of an archive

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ArchiveTarModules::ListMemUsage (from Perl distribution Bencher-Scenarios-ArchiveTarModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArchiveTarModules::ListMemUsage

To run module startup overhead benchmark:

 % bencher --module-startup -m ArchiveTarModules::ListMemUsage

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Archive::Tar> 2.04

L<Archive::Tar::Wrapper> 0.23

=head1 BENCHMARK PARTICIPANTS

=over

=item * Archive::Tar::Wrapper (perl_code)

Code template:

             my $filename = <filename>;
             my $obj = Archive::Tar::Wrapper->new;
             my @res;
             $obj->list_reset;
             while (my $entry = $obj->list_next) {
                 my ($tar_path, $phys_path) = @$entry;
                 push @res, {
                     name => $tar_path,
                     size => (-s $phys_path),
                 };
             }
             return @res;




=item * Archive::Tar (perl_code)

Code template:

             my $filename = <filename>;
             my $obj = Archive::Tar->new;
             my @files = $obj->read($filename);
             my @res;
             for my $file (@files) {
                 push @res, {
                     name => $file->name,
                     size => $file->size,
                 };
             }
             return @res;




=item * perl (baseline) (perl_code)

Code template:

 1



=back

=head1 BENCHMARK DATASETS

=over

=item * archive.tar.gz

Sample archive with 10 files, ~10MB each

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ArchiveTarModules::ListMemUsage >>):

 #table1#
 +-----------------------+------------------------------+--------------------+----------------+-------------+------------+------------+----------+---------+
 | participant           | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | rate (/s)   | time (ms)  | vs_slowest |  errors  | samples |
 +-----------------------+------------------------------+--------------------+----------------+-------------+------------+------------+----------+---------+
 | Archive::Tar          | 79                           | 83                 | 120            |         1.5 | 660        |          1 |   0.0019 |       6 |
 | Archive::Tar::Wrapper | 9.9                          | 14                 | 41             |      1400   |   0.74     |        890 |   2e-06  |       6 |
 | perl (baseline)       | 0.8                          | 4                  | 20             | 700000000   |   0.000001 |  500000000 | 1.9e-10  |      11 |
 +-----------------------+------------------------------+--------------------+----------------+-------------+------------+------------+----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ArchiveTarModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ArchiveTarModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ArchiveTarModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
