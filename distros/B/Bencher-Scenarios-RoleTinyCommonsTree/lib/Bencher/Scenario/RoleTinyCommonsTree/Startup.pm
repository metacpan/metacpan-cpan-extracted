package Bencher::Scenario::RoleTinyCommonsTree::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of some modules in '.
        'Role-TinyCommons-Tree distribution',
    module_startup => 1,
    modules => {
        'Code::Includable::Tree::NodeMethods'  => {version=>0.11},
        'Role::TinyCommons::Tree::NodeMethods' => {version=>0.11},
    },
    participants => [
        {module=>'Scalar::Util'},

        {module=>'Code::Includable::Tree::FromStruct'},
        {module=>'Code::Includable::Tree::NodeMethods'},

        {module=>'Role::TinyCommons::Tree::FromStruct'},
        {module=>'Role::TinyCommons::Tree::Node'},
        {module=>'Role::TinyCommons::Tree::NodeMethods'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of some modules in Role-TinyCommons-Tree distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RoleTinyCommonsTree::Startup - Benchmark startup overhead of some modules in Role-TinyCommons-Tree distribution

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::RoleTinyCommonsTree::Startup (from Perl distribution Bencher-Scenarios-RoleTinyCommonsTree), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RoleTinyCommonsTree::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Code::Includable::Tree::FromStruct> 0.11

L<Code::Includable::Tree::NodeMethods> 0.11

L<Role::TinyCommons::Tree::FromStruct> 0.11

L<Role::TinyCommons::Tree::Node> 0.11

L<Role::TinyCommons::Tree::NodeMethods> 0.11

L<Scalar::Util> 1.45

=head1 BENCHMARK PARTICIPANTS

=over

=item * Scalar::Util (perl_code)

L<Scalar::Util>



=item * Code::Includable::Tree::FromStruct (perl_code)

L<Code::Includable::Tree::FromStruct>



=item * Code::Includable::Tree::NodeMethods (perl_code)

L<Code::Includable::Tree::NodeMethods>



=item * Role::TinyCommons::Tree::FromStruct (perl_code)

L<Role::TinyCommons::Tree::FromStruct>



=item * Role::TinyCommons::Tree::Node (perl_code)

L<Role::TinyCommons::Tree::Node>



=item * Role::TinyCommons::Tree::NodeMethods (perl_code)

L<Role::TinyCommons::Tree::NodeMethods>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RoleTinyCommonsTree::Startup >>):

 #table1#
 +--------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                          | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +--------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Role::TinyCommons::Tree::FromStruct  | 1.2                          | 4.5                | 16             |      13   |                    8.2 |        1   | 5.7e-05 |      20 |
 | Role::TinyCommons::Tree::NodeMethods | 0.82                         | 4.1                | 16             |      12   |                    7.2 |        1.1 | 4.1e-05 |      20 |
 | Code::Includable::Tree::NodeMethods  | 1.7                          | 5                  | 19             |       9.6 |                    4.8 |        1.4 | 4.2e-05 |      20 |
 | Role::TinyCommons::Tree::Node        | 1.6                          | 5.1                | 19             |       9.4 |                    4.6 |        1.4 | 6.9e-05 |      20 |
 | Scalar::Util                         | 0.86                         | 4.1                | 16             |       8.6 |                    3.8 |        1.5 | 3.2e-05 |      20 |
 | Code::Includable::Tree::FromStruct   | 1.2                          | 4.7                | 18             |       5.3 |                    0.5 |        2.5 | 1.2e-05 |      20 |
 | perl -e1 (baseline)                  | 1                            | 4.4                | 18             |       4.8 |                    0   |        2.8 | 1.1e-05 |      20 |
 +--------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-RoleTinyCommonsTree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-RoleTinyCommonsTree>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-RoleTinyCommonsTree>

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
