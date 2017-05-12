package Bencher::Scenario::Accessors::Get;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.14'; # VERSION

use Bencher::ScenarioUtil::Accessors;

my $classes = \%Bencher::ScenarioUtil::Accessors::classes;

our $scenario = {
    summary => 'Benchmark attribute read/get',
    modules => {
        # include the generator modules here so we can show their versions in
        # sample benchmark results produced by PWP:Bencher::Scenario
        (map { $_=>0 } grep {defined} map { $classes->{$_}{generator} }
             keys %$classes),
    },
    participants => [
        (map {
            my $spec = $classes->{$_};
            my $supports_setters = $spec->{supports_setters} // 1;
            +{
                name => $spec->{generator} || $spec->{name},
                module => $_,
                code_template => $supports_setters ?
                    "state \$o = do { my \$o = ${_}->new; \$o->attr1(42); \$o }; \$o->attr1" :
                    "state \$o = do { my \$o = ${_}->new(attr1 => 42); \$o }; \$o->attr1",
            };
        } grep { !$classes->{$_}{immutable} } keys %$classes),

        # also compare with raw hash & array access
        {
            name => 'raw hash access',
            module => 'Perl::Examples::Accessors::Hash',
            code_template => "state \$o = do { my \$o = Perl::Examples::Accessors::Hash->new; \$o->attr1(42); \$o }; \$o->{attr1}",
        },
        {
            name => 'raw array access',
            module => 'Perl::Examples::Accessors::Array',
            code_template => "state \$o = do { my \$o = Perl::Examples::Accessors::Array->new; \$o->attr1(42); \$o }; \$o->[0]",
        },
    ],
    result => 42,
};

1;
# ABSTRACT: Benchmark attribute read/get

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Accessors::Get - Benchmark attribute read/get

=head1 VERSION

This document describes version 0.14 of Bencher::Scenario::Accessors::Get (from Perl distribution Bencher-Scenarios-Accessors), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::Get

To run module startup overhead benchmark:

 % bencher --module-startup -m Accessors::Get

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

L<Perl::Examples::Accessors::ObjectTiny> 0.12

L<Perl::Examples::Accessors::ObjectTinyRW> 0.12

L<Perl::Examples::Accessors::ObjectTinyRWXS> 0.12

L<Perl::Examples::Accessors::ObjectTinyXS> 0.12

L<Perl::Examples::Accessors::SimpleAccessor> 0.12

L<Simple::Accessor> 1.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Tiny (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassTiny->new; $o->attr1(42); $o }; $o->attr1



=item * Moo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moo->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyXS->new(attr1 => 42); $o }; $o->attr1



=item * Object::Tiny (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTiny->new(attr1 => 42); $o }; $o->attr1



=item * Class::XSAccessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessor->new; $o->attr1(42); $o }; $o->attr1



=item * Class::InsideOut (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassInsideOut->new; $o->attr1(42); $o }; $o->attr1



=item * no generator (hash-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny::RW::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRWXS->new; $o->attr1(42); $o }; $o->attr1



=item * Mouse (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mouse->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Simple (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectSimple->new; $o->attr1(42); $o }; $o->attr1



=item * Moos (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moos->new; $o->attr1(42); $o }; $o->attr1



=item * Mo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mo->new; $o->attr1(42); $o }; $o->attr1



=item * Mojo::Base (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBase->new; $o->attr1(42); $o }; $o->attr1



=item * no generator (array-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o->attr1(42); $o }; $o->attr1



=item * Simple::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::SimpleAccessor->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Struct (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassStruct->new; $o->attr1(42); $o }; $o->attr1



=item * Object::Tiny::RW (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRW->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Accessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorArray->new; $o->attr1(42); $o }; $o->attr1



=item * Class::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessor->new; $o->attr1(42); $o }; $o->attr1



=item * Moops (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moops->new; $o->attr1(42); $o }; $o->attr1



=item * Mojo::Base::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBaseXS->new; $o->attr1(42); $o }; $o->attr1



=item * Moose (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moose->new; $o->attr1(42); $o }; $o->attr1



=item * Class::XSAccessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessorArray->new; $o->attr1(42); $o }; $o->attr1



=item * Evo::Class (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::EvoClass->new; $o->attr1(42); $o }; $o->attr1



=item * raw hash access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o->attr1(42); $o }; $o->{attr1}



=item * raw array access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o->attr1(42); $o }; $o->[0]



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Accessors::Get >>):

 #table1#
 +----------------------------+-----------+-----------+------------+---------+---------+
 | participant                | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +----------------------------+-----------+-----------+------------+---------+---------+
 | Class::Accessor            |   2011000 |     497.3 |      1     | 1.2e-11 |      22 |
 | Simple::Accessor           |   2834000 |     352.8 |      1.409 | 1.1e-11 |      20 |
 | Class::InsideOut           |   3250000 |     308   |      1.61  |   3e-10 |      21 |
 | Class::Struct              |   4320000 |     231   |      2.15  |   1e-10 |      20 |
 | Mojo::Base                 |   4900000 |     210   |      2.4   | 3.1e-10 |      20 |
 | Mo                         |   5000000 |     200   |      2.5   | 4.2e-10 |      20 |
 | Object::Tiny::RW           |   5588000 |     179   |      2.779 | 1.1e-11 |      20 |
 | no generator (array-based) |   5588000 |     178.9 |      2.779 | 1.1e-11 |      20 |
 | Object::Simple             |   5800000 |     170   |      2.9   | 3.1e-10 |      20 |
 | Evo::Class                 |   5846000 |     171   |      2.907 | 1.2e-11 |      20 |
 | no generator (hash-based)  |   6010000 |     166   |      2.99  |   1e-10 |      20 |
 | Class::Accessor::Array     |   6400000 |     160   |      3.2   | 3.1e-10 |      20 |
 | Moose                      |   6600000 |     150   |      3.3   | 4.2e-10 |      20 |
 | Class::Tiny                |   6800000 |     150   |      3.4   | 2.9e-10 |      20 |
 | Object::Tiny               |   8800000 |     110   |      4.4   | 1.9e-10 |      23 |
 | Mouse                      |  10000000 |      99   |      5     | 1.4e-10 |      20 |
 | Object::Tiny::XS           |  11400000 |      87.9 |      5.66  | 5.3e-11 |      20 |
 | Mojo::Base::XS             |  12000000 |      87   |      5.7   | 3.4e-10 |      20 |
 | Moos                       |  12000000 |      81   |      6.1   | 1.6e-10 |      20 |
 | Moops                      |  13000000 |      78   |      6.3   | 1.6e-10 |      20 |
 | Object::Tiny::RW::XS       |  13000000 |      77   |      6.4   | 2.4e-10 |      24 |
 | Class::XSAccessor          |  13000000 |      75   |      6.6   | 1.5e-10 |      21 |
 | Moo                        |  14500000 |      69.1 |      7.2   | 4.6e-11 |      21 |
 | Class::XSAccessor::Array   |  19000000 |      53   |      9.3   | 6.3e-11 |      20 |
 | raw hash access            |  32000000 |      32   |     16     | 2.1e-10 |      20 |
 | raw array access           |  49500000 |      20.2 |     24.6   |   1e-11 |      20 |
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
