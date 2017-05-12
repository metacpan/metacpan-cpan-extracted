package Bencher::Scenario::TreeObject::Build;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::TreeObject;
use Tree::Create::Size;

my $classes = \%Bencher::ScenarioUtil::TreeObject::classes;

our $scenario = {
    summary => 'Benchmark tree building using Tree::Create::Size',
    include_result_size => 1,
    participants => [
        map {
            my $spec = $classes->{$_};
            +{
                module => $_,
                code_template => "Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => '".($spec->{use_my_class} ? "My::$_":$_)."')",
            }
        } sort keys %$classes,
    ],
    datasets => \@Bencher::ScenarioUtil::TreeObject::trees_datasets,
};

1;
# ABSTRACT: Benchmark tree building using Tree::Create::Size

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TreeObject::Build - Benchmark tree building using Tree::Create::Size

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::TreeObject::Build (from Perl distribution Bencher-Scenarios-TreeObject), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TreeObject::Build

To run module startup overhead benchmark:

 % bencher --module-startup -m TreeObject::Build

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Tree::Object::Array> 0.07

L<Tree::Object::Array::Glob> 0.07

L<Tree::Object::Hash> 0.07

L<Tree::Object::Hash::ChildrenAsList> 0.07

L<Tree::Object::InsideOut> 0.07

L<Tree::ObjectXS::Array> 0.02

L<Tree::ObjectXS::Hash> 0.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Tree::Object::Array (perl_code)

Code template:

 Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'My::Tree::Object::Array')



=item * Tree::Object::Array::Glob (perl_code)

Code template:

 Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'My::Tree::Object::Array::Glob')



=item * Tree::Object::Hash (perl_code)

Code template:

 Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'Tree::Object::Hash')



=item * Tree::Object::Hash::ChildrenAsList (perl_code)

Code template:

 Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'Tree::Object::Hash::ChildrenAsList')



=item * Tree::Object::InsideOut (perl_code)

Code template:

 Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'Tree::Object::InsideOut')



=item * Tree::ObjectXS::Array (perl_code)

Code template:

 Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'My::Tree::ObjectXS::Array')



=item * Tree::ObjectXS::Hash (perl_code)

Code template:

 Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'Tree::ObjectXS::Hash')



=back

=head1 BENCHMARK DATASETS

=over

=item * tiny1 (3 nodes)

A tree with height=1 and 2 children per non-leaf nodes, nodes=1 + 2 = 3

=item * small1 (31 nodes)

A tree with height=4 and 2 children per non-leaf nodes, nodes=1 + 2 + 4 + 8 + 16 = 31

=item * small2 (364 nodes)

A tree with height=5 and 3 children per non-leaf nodes, nodes=1 + 3 + 9 + 27 + 81 + 243 = 364

=item * small3 (1365 nodes)

A tree with height=5 and 4 children per non-leaf nodes, nodes=1 + 4 + 16 + 64 + 256 + 1024 = 1365

=item * medium1 (19531 nodes)

A tree with height=6 and 5 children per non-leaf nodes, nodes=1 + 5 + 25 + 125 + 625 + 3125 + 15625 = 19531

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m TreeObject::Build --include-datasets 'small1 (31 nodes)' >>:

 #table1#
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | Tree::Object::InsideOut            |      8400 |       120 |        1   | 6.9e-07 |      20 |
 | Tree::Object::Hash::ChildrenAsList |     14000 |        73 |        1.6 | 2.1e-07 |      20 |
 | Tree::Object::Hash                 |     14000 |        72 |        1.6 | 2.1e-07 |      20 |
 | Tree::Object::Array::Glob          |     15000 |        66 |        1.8 | 1.3e-07 |      21 |
 | Tree::Object::Array                |     17000 |        58 |        2.1 | 1.1e-07 |      20 |
 | Tree::ObjectXS::Hash               |     20000 |        50 |        2.4 | 6.7e-08 |      20 |
 | Tree::ObjectXS::Array              |     21000 |        48 |        2.5 | 6.2e-08 |      23 |
 +------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark with C<< bencher -m TreeObject::Build --include-datasets 'medium1 (19531 nodes)' >>:

 #table2#
 +------------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                        | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +------------------------------------+-----------+-----------+------------+-----------+---------+
 | Tree::Object::InsideOut            |      14   |      71   |       1    |   0.00021 |      20 |
 | Tree::Object::Hash::ChildrenAsList |      25.4 |      39.4 |       1.79 | 3.5e-05   |      20 |
 | Tree::Object::Hash                 |      25   |      39   |       1.8  |   6e-05   |      21 |
 | Tree::Object::Array::Glob          |      28   |      35   |       2    |   4e-05   |      20 |
 | Tree::Object::Array                |      34   |      29   |       2.4  | 3.2e-05   |      20 |
 | Tree::ObjectXS::Hash               |      39   |      26   |       2.7  | 3.8e-05   |      20 |
 | Tree::ObjectXS::Array              |      40   |      25   |       2.8  | 3.2e-05   |      21 |
 +------------------------------------+-----------+-----------+------------+-----------+---------+


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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
