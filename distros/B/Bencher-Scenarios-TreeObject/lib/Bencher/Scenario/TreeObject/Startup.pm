package Bencher::Scenario::TreeObject::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

use Bencher::ScenarioUtil::TreeObject;

my $classes = \%Bencher::ScenarioUtil::TreeObject::classes;

our $scenario = {
    summary => 'Benchmark startup of various tree classes',
    module_startup => 1,
    participants => [
        map {
            #my $spec = $classes->{$_};
            +{ module=>$_ };
        } keys %$classes,
    ],
};

1;
# ABSTRACT: Benchmark startup of various tree classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TreeObject::Startup - Benchmark startup of various tree classes

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::TreeObject::Startup (from Perl distribution Bencher-Scenarios-TreeObject), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TreeObject::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Tree::ObjectXS::Hash> 0.02

L<Tree::Object::Array> 0.07

L<Tree::ObjectXS::Array> 0.02

L<Tree::Object::Hash::ChildrenAsList> 0.07

L<Tree::Object::Array::Glob> 0.07

L<Tree::Object::Hash> 0.07

L<Tree::Object::InsideOut> 0.07

=head1 BENCHMARK PARTICIPANTS

=over

=item * Tree::ObjectXS::Hash (perl_code)

L<Tree::ObjectXS::Hash>



=item * Tree::Object::Array (perl_code)

L<Tree::Object::Array>



=item * Tree::ObjectXS::Array (perl_code)

L<Tree::ObjectXS::Array>



=item * Tree::Object::Hash::ChildrenAsList (perl_code)

L<Tree::Object::Hash::ChildrenAsList>



=item * Tree::Object::Array::Glob (perl_code)

L<Tree::Object::Array::Glob>



=item * Tree::Object::Hash (perl_code)

L<Tree::Object::Hash>



=item * Tree::Object::InsideOut (perl_code)

L<Tree::Object::InsideOut>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m TreeObject::Startup >>):

 #table1#
 +------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                        | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Tree::Object::InsideOut            | 0.82                         | 4.2                | 16             |        48 |                     17 |       1    |   0.00021 |      20 |
 | Tree::ObjectXS::Array              | 1.63                         | 5.15               | 18.8           |        43 |                     12 |       1.12 |   4e-05   |      20 |
 | Tree::ObjectXS::Hash               | 0.84                         | 4.2                | 16             |        43 |                     12 |       1.1  | 9.8e-05   |      20 |
 | Tree::Object::Array                | 0.84                         | 4.3                | 16             |        40 |                      9 |       1.2  | 6.3e-05   |      21 |
 | Tree::Object::Array::Glob          | 1.6                          | 5                  | 19             |        40 |                      9 |       1.2  | 7.2e-05   |      22 |
 | Tree::Object::Hash                 | 2.4                          | 5.8                | 20             |        40 |                      9 |       1.2  |   0.00013 |      20 |
 | Tree::Object::Hash::ChildrenAsList | 0.84                         | 4.1                | 16             |        39 |                      8 |       1.2  | 4.1e-05   |      20 |
 | perl -e1 (baseline)                | 2                            | 5.4                | 21             |        31 |                      0 |       1.6  | 3.1e-05   |      20 |
 +------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-TreeObject>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-TreeObject>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-TreeObject>

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
