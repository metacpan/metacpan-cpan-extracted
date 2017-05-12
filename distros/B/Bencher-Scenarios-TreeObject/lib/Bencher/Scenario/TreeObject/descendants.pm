package Bencher::Scenario::TreeObject::descendants;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::TreeObject;
use Tree::Create::Size;

my $classes = \%Bencher::ScenarioUtil::TreeObject::classes;

our $scenario = {
    summary => 'Benchmark descendants()',
    participants => [
        map {
            my $spec = $classes->{$_};
            +{
                module => $_,
                code_template => "state \$tree = Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => '".($spec->{use_my_class} ? "My::$_":$_)."'); my \@res = \$tree->descendants; scalar(\@res)",
            }
        } sort keys %$classes,
    ],
    datasets => \@Bencher::ScenarioUtil::TreeObject::trees_datasets,
};

1;
# ABSTRACT: Benchmark descendants()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TreeObject::descendants - Benchmark descendants()

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::TreeObject::descendants (from Perl distribution Bencher-Scenarios-TreeObject), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TreeObject::descendants

To run module startup overhead benchmark:

 % bencher --module-startup -m TreeObject::descendants

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

 state $tree = Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'My::Tree::Object::Array'); my @res = $tree->descendants; scalar(@res)



=item * Tree::Object::Array::Glob (perl_code)

Code template:

 state $tree = Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'My::Tree::Object::Array::Glob'); my @res = $tree->descendants; scalar(@res)



=item * Tree::Object::Hash (perl_code)

Code template:

 state $tree = Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'Tree::Object::Hash'); my @res = $tree->descendants; scalar(@res)



=item * Tree::Object::Hash::ChildrenAsList (perl_code)

Code template:

 state $tree = Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'Tree::Object::Hash::ChildrenAsList'); my @res = $tree->descendants; scalar(@res)



=item * Tree::Object::InsideOut (perl_code)

Code template:

 state $tree = Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'Tree::Object::InsideOut'); my @res = $tree->descendants; scalar(@res)



=item * Tree::ObjectXS::Array (perl_code)

Code template:

 state $tree = Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'My::Tree::ObjectXS::Array'); my @res = $tree->descendants; scalar(@res)



=item * Tree::ObjectXS::Hash (perl_code)

Code template:

 state $tree = Tree::Create::Size::create_tree(height => <height>, num_children => <num_children>, class => 'Tree::ObjectXS::Hash'); my @res = $tree->descendants; scalar(@res)



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

Benchmark with C<< bencher -m TreeObject::descendants --include-datasets 'small1 (31 nodes)' >>:

 #table1#
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------+-----------+-----------+------------+---------+---------+
 | Tree::Object::Array::Glob          |   20000   |   50      |    1       | 5.3e-08 |      20 |
 | Tree::Object::InsideOut            |   22284.3 |   44.8746 |    1.11045 | 1.1e-11 |      20 |
 | Tree::Object::Hash                 |   23100   |   43.3    |    1.15    | 1.3e-08 |      20 |
 | Tree::Object::Array                |   24900   |   40.1    |    1.24    |   4e-08 |      20 |
 | Tree::Object::Hash::ChildrenAsList |   28000   |   36      |    1.4     | 5.3e-08 |      20 |
 | Tree::ObjectXS::Hash               |   30239   |   33.069  |    1.5069  | 9.1e-11 |      21 |
 | Tree::ObjectXS::Array              |   30800   |   32.5    |    1.53    | 1.2e-08 |      26 |
 +------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark with C<< bencher -m TreeObject::descendants --include-datasets 'medium1 (19531 nodes)' >>:

 #table2#
 +------------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                        | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +------------------------------------+-----------+-----------+------------+-----------+---------+
 | Tree::Object::InsideOut            |        30 |        33 |        1   | 6.3e-05   |      20 |
 | Tree::Object::Array::Glob          |        36 |        28 |        1.2 | 5.3e-05   |      20 |
 | Tree::Object::Hash                 |        37 |        27 |        1.2 |   0.00012 |      20 |
 | Tree::Object::Hash::ChildrenAsList |        41 |        24 |        1.4 |   6e-05   |      20 |
 | Tree::Object::Array                |        42 |        24 |        1.4 | 9.8e-05   |      20 |
 | Tree::ObjectXS::Hash               |        47 |        21 |        1.5 | 5.7e-05   |      20 |
 | Tree::ObjectXS::Array              |        48 |        21 |        1.6 |   0.00017 |      20 |
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
