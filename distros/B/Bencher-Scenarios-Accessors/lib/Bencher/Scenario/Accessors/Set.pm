package Bencher::Scenario::Accessors::Set;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.14'; # VERSION

use Bencher::ScenarioUtil::Accessors;

my $classes = \%Bencher::ScenarioUtil::Accessors::classes;

our $scenario = {
    summary => 'Benchmark attribute write/set',
    modules => {
        # include the generator modules here so we can show their versions in
        # sample benchmark results produced by PWP:Bencher::Scenario
        (map { $_=>0 } grep {defined} map { $classes->{$_}{generator} }
             keys %$classes),
    },
    participants => [
        (map {
            my $spec = $classes->{$_};
            +{
                name => $spec->{generator} || $spec->{name},
                module => $_,
                code_template => "state \$o = do { my \$o = ${_}->new; \$o }; \$o->attr1(42)",
            };
        } grep { !$classes->{$_}{immutable} && ($classes->{$_}{supports_setters} // 1) } keys %$classes),

        # also compare with raw hash & array access
        {
            name => 'raw hash access',
            module => 'Perl::Examples::Accessors::Hash',
            code_template => "state \$o = do { my \$o = Perl::Examples::Accessors::Hash->new; \$o }; \$o->{attr1} = 42",
        },
        {
            name => 'raw array access',
            module => 'Perl::Examples::Accessors::Array',
            code_template => "state \$o = do { my \$o = Perl::Examples::Accessors::Array->new; \$o }; \$o->[0] = 42",
        },
    ],
};

1;
# ABSTRACT: Benchmark attribute write/set

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Accessors::Set - Benchmark attribute write/set

=head1 VERSION

This document describes version 0.14 of Bencher::Scenario::Accessors::Set (from Perl distribution Bencher-Scenarios-Accessors), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::Set

To run module startup overhead benchmark:

 % bencher --module-startup -m Accessors::Set

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Class::Accessor> 0.34

L<Class::Accessor::Array> 0.02

L<Class::InsideOut> 1.13

L<Class::Struct> 0.65

L<Class::Tiny> 1.004

L<Class::XSAccessor> 1.19

L<Class::XSAccessor::Array> 1.19

L<Evo::Class>

L<Mo> 0.40

L<Mojo::Base>

L<Mojo::Base::XS> 0.07

L<Moo> 2.002004

L<Moops> 0.034

L<Moos> 0.30

L<Moose> 2.1805

L<Mouse> v2.4.5

L<Object::Simple> 3.17

L<Object::Tiny> 1.08

L<Object::Tiny::RW> 1.07

L<Object::Tiny::RW::XS> 0.03

L<Object::Tiny::XS> 1.01

L<Perl::Examples::Accessors::Array> 0.12

L<Perl::Examples::Accessors::ClassAccessor> 0.12

L<Perl::Examples::Accessors::ClassAccessorArray> 0.12

L<Perl::Examples::Accessors::ClassInsideOut> 0.12

L<Perl::Examples::Accessors::ClassStruct> 0.12

L<Perl::Examples::Accessors::ClassTiny> 0.12

L<Perl::Examples::Accessors::ClassXSAccessor> 0.12

L<Perl::Examples::Accessors::ClassXSAccessorArray> 0.12

L<Perl::Examples::Accessors::EvoClass> 0.12

L<Perl::Examples::Accessors::Hash> 0.12

L<Perl::Examples::Accessors::Mo> 0.12

L<Perl::Examples::Accessors::MojoBase> 0.12

L<Perl::Examples::Accessors::MojoBaseXS> 0.12

L<Perl::Examples::Accessors::Moo> 0.12

L<Perl::Examples::Accessors::Moops> 0.12

L<Perl::Examples::Accessors::Moos> 0.12

L<Perl::Examples::Accessors::Moose> 0.12

L<Perl::Examples::Accessors::Mouse> 0.12

L<Perl::Examples::Accessors::ObjectSimple> 0.12

L<Perl::Examples::Accessors::ObjectTinyRW> 0.12

L<Perl::Examples::Accessors::ObjectTinyRWXS> 0.12

L<Perl::Examples::Accessors::SimpleAccessor> 0.12

L<Simple::Accessor> 1.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Tiny (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassTiny->new; $o }; $o->attr1(42)



=item * Moo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moo->new; $o }; $o->attr1(42)



=item * Class::XSAccessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessor->new; $o }; $o->attr1(42)



=item * Class::InsideOut (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassInsideOut->new; $o }; $o->attr1(42)



=item * no generator (hash-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o }; $o->attr1(42)



=item * Object::Tiny::RW::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRWXS->new; $o }; $o->attr1(42)



=item * Mouse (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mouse->new; $o }; $o->attr1(42)



=item * Object::Simple (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectSimple->new; $o }; $o->attr1(42)



=item * Moos (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moos->new; $o }; $o->attr1(42)



=item * Mo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mo->new; $o }; $o->attr1(42)



=item * Mojo::Base (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBase->new; $o }; $o->attr1(42)



=item * no generator (array-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o }; $o->attr1(42)



=item * Simple::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::SimpleAccessor->new; $o }; $o->attr1(42)



=item * Class::Struct (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassStruct->new; $o }; $o->attr1(42)



=item * Object::Tiny::RW (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRW->new; $o }; $o->attr1(42)



=item * Class::Accessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorArray->new; $o }; $o->attr1(42)



=item * Class::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessor->new; $o }; $o->attr1(42)



=item * Moops (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moops->new; $o }; $o->attr1(42)



=item * Mojo::Base::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBaseXS->new; $o }; $o->attr1(42)



=item * Moose (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moose->new; $o }; $o->attr1(42)



=item * Class::XSAccessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessorArray->new; $o }; $o->attr1(42)



=item * Evo::Class (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::EvoClass->new; $o }; $o->attr1(42)



=item * raw hash access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o }; $o->{attr1} = 42



=item * raw array access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o }; $o->[0] = 42



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Accessors::Set >>):

 #table1#
 +----------------------------+-----------+-----------+------------+---------+---------+
 | participant                | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------+-----------+-----------+------------+---------+---------+
 | Simple::Accessor           |    264000 |    3.79   |       1    | 1.4e-09 |      30 |
 | Class::Accessor            |   1700000 |    0.57   |       6.6  | 8.1e-10 |      21 |
 | Class::InsideOut           |   2550000 |    0.392  |       9.65 | 2.1e-10 |      20 |
 | Evo::Class                 |   3900000 |    0.26   |      15    | 4.2e-10 |      20 |
 | Class::Struct              |   4330000 |    0.231  |      16.4  | 8.7e-11 |      29 |
 | Moose                      |   4337000 |    0.2306 |      16.42 |   1e-11 |      20 |
 | Object::Tiny::RW           |   4400000 |    0.23   |      17    | 4.2e-10 |      20 |
 | Mo                         |   4480000 |    0.223  |      16.9  |   1e-10 |      20 |
 | Class::Accessor::Array     |   4561000 |    0.2193 |      17.27 | 1.1e-11 |      24 |
 | Mojo::Base                 |   5030000 |    0.199  |      19    |   1e-10 |      20 |
 | Class::Tiny                |   5100000 |    0.2    |      19    | 4.4e-10 |      21 |
 | Object::Simple             |   5241000 |    0.1908 |      19.84 | 1.2e-11 |      20 |
 | no generator (hash-based)  |   5860000 |    0.171  |      22.2  | 9.8e-11 |      26 |
 | no generator (array-based) |   6399000 |    0.1563 |      24.23 | 9.8e-12 |      20 |
 | Mouse                      |   9180000 |    0.109  |      34.7  | 1.1e-11 |      26 |
 | Moops                      |   9500000 |    0.11   |      36    | 2.1e-10 |      20 |
 | Mojo::Base::XS             |   9500000 |    0.1    |      36    | 2.6e-10 |      20 |
 | Class::XSAccessor          |   9550000 |    0.105  |      36.2  | 1.1e-11 |      20 |
 | Moos                       |  10000000 |    0.098  |      39    | 1.6e-10 |      20 |
 | Object::Tiny::RW::XS       |  11000000 |    0.095  |      40    |   2e-10 |      21 |
 | Class::XSAccessor::Array   |  11000000 |    0.094  |      40    | 1.5e-10 |      22 |
 | Moo                        |  12000000 |    0.082  |      46    | 2.1e-10 |      21 |
 | raw array access           |  10000000 |    0.07   |      50    | 4.2e-09 |      20 |
 | raw hash access            |  15000000 |    0.067  |      56    | 1.6e-10 |      20 |
 +----------------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Accessors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Accessors>

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
