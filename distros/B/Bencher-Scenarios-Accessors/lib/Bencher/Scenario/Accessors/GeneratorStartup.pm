package Bencher::Scenario::Accessors::GeneratorStartup;

our $DATE = '2021-08-03'; # DATE
our $VERSION = '0.150'; # VERSION

use Bencher::ScenarioUtil::Accessors;

my $classes = \%Bencher::ScenarioUtil::Accessors::classes;

our $scenario = {
    summary => 'Benchmark startup of various accessor generators',
    module_startup => 1,
    modules => {
    },
    participants => [
        map {
            my $spec = $classes->{$_};
            +{ (module=>$spec->{generator}) x !!$spec->{generator} };
        } keys %$classes,
    ],
};

1;
# ABSTRACT: Benchmark startup of various accessor generators

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Accessors::GeneratorStartup - Benchmark startup of various accessor generators

=head1 VERSION

This document describes version 0.150 of Bencher::Scenario::Accessors::GeneratorStartup (from Perl distribution Bencher-Scenarios-Accessors), released on 2021-08-03.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::GeneratorStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Class::Accessor> 0.51

L<Class::Accessor::Array> 0.032

L<Class::Accessor::PackedString> 0.001

L<Class::Accessor::PackedString::Set> 0.001

L<Class::InsideOut> 1.14

L<Class::Struct> 0.66

L<Class::Tiny> 1.008

L<Class::XSAccessor> 1.19

L<Class::XSAccessor::Array> 1.19

L<Mo> 0.40

L<Mojo::Base>

L<Mojo::Base::XS> 0.07

L<Moo> 2.004004

L<Moops> 0.038

L<Moos> 0.30

L<Moose> 2.2015

L<Mouse> v2.5.10

L<Object::Pad> 0.46

L<Object::Simple> 3.19

L<Object::Tiny> 1.09

L<Object::Tiny::RW> 1.07

L<Object::Tiny::RW::XS> 0.04

L<Object::Tiny::XS> 1.01

L<Simple::Accessor> 1.13

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Accessor::PackedString (perl_code)

L<Class::Accessor::PackedString>



=item * Class::Accessor::Array (perl_code)

L<Class::Accessor::Array>



=item * Mojo::Base (perl_code)

L<Mojo::Base>



=item * Object::Tiny (perl_code)

L<Object::Tiny>



=item * Simple::Accessor (perl_code)

L<Simple::Accessor>



=item * Object::Tiny::RW (perl_code)

L<Object::Tiny::RW>



=item * Moose (perl_code)

L<Moose>



=item *  (perl_code)



=item * Moos (perl_code)

L<Moos>



=item * Object::Pad (perl_code)

L<Object::Pad>



=item * Object::Tiny::XS (perl_code)

L<Object::Tiny::XS>



=item * Mouse (perl_code)

L<Mouse>



=item * Mo (perl_code)

L<Mo>



=item * Object::Simple (perl_code)

L<Object::Simple>



=item * Moops (perl_code)

L<Moops>



=item * Class::Struct (perl_code)

L<Class::Struct>



=item * Class::XSAccessor (perl_code)

L<Class::XSAccessor>



=item * Object::Tiny::RW::XS (perl_code)

L<Object::Tiny::RW::XS>



=item *  (perl_code)



=item * Moo (perl_code)

L<Moo>



=item * Class::InsideOut (perl_code)

L<Class::InsideOut>



=item * Mojo::Base::XS (perl_code)

L<Mojo::Base::XS>



=item * Class::Accessor (perl_code)

L<Class::Accessor>



=item * Class::Tiny (perl_code)

L<Class::Tiny>



=item *  (perl_code)



=item * Class::Accessor::PackedString::Set (perl_code)

L<Class::Accessor::PackedString::Set>



=item * Class::XSAccessor::Array (perl_code)

L<Class::XSAccessor::Array>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::GeneratorStartup

Result formatted as table:

 #table1#
 +------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                        | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Moose                              |       110 |               105 |                 0.00% |              2205.82% |   0.001   |      20 |
 | Mojo::Base                         |        90 |                85 |                33.47% |              1627.64% |   0.0014  |      20 |
 | Moops                              |        49 |                44 |               134.20% |               884.57% |   0.00029 |      20 |
 | Mouse                              |        21 |                16 |               435.12% |               330.90% |   0.00012 |      20 |
 | Moos                               |        20 |                15 |               621.73% |               219.48% |   0.0002  |      20 |
 | Class::InsideOut                   |        20 |                15 |               641.35% |               211.03% |   0.00017 |      20 |
 | Object::Pad                        |        10 |                 5 |               675.19% |               197.45% |   0.00026 |      20 |
 | Moo                                |        10 |                 5 |               698.91% |               188.62% |   0.00022 |      20 |
 | Class::Struct                      |        10 |                 5 |               790.59% |               158.91% |   0.00019 |      21 |
 | Class::XSAccessor                  |        10 |                 5 |               866.05% |               138.69% |   0.00019 |      22 |
 | Object::Simple                     |        10 |                 5 |               869.19% |               137.91% |   0.0002  |      21 |
 | Class::Accessor                    |        10 |                 5 |               873.51% |               136.86% |   0.00033 |      20 |
 | Object::Tiny::XS                   |        10 |                 5 |               887.20% |               133.57% |   0.00023 |      20 |
 | Object::Tiny::RW::XS               |        11 |                 6 |               903.19% |               129.85% | 6.9e-05   |      22 |
 | Class::XSAccessor::Array           |        10 |                 5 |               912.80% |               127.67% |   0.00024 |      20 |
 | Class::Tiny                        |        10 |                 5 |               929.62% |               123.95% |   0.00023 |      20 |
 | Mojo::Base::XS                     |         9 |                 4 |              1191.30% |                78.57% |   0.00018 |      21 |
 | Simple::Accessor                   |         8 |                 3 |              1351.97% |                58.81% |   0.00016 |      20 |
 | Mo                                 |         7 |                 2 |              1454.79% |                48.30% |   0.00025 |      20 |
 | Object::Tiny                       |         7 |                 2 |              1570.40% |                38.04% |   0.00011 |      20 |
 | Class::Accessor::PackedString      |         7 |                 2 |              1582.05% |                37.08% |   0.00014 |      20 |
 | Class::Accessor::PackedString::Set |         6 |                 1 |              1871.76% |                16.94% |   0.00012 |      22 |
 | Class::Accessor::Array             |         6 |                 1 |              1960.62% |                11.90% |   0.00019 |      21 |
 | Object::Tiny::RW                   |         5 |                 0 |              2159.08% |                 2.07% | 6.3e-05   |      20 |
 | perl -e1 (baseline)                |         5 |                 0 |              2205.82% |                 0.00% |   0.00017 |      21 |
 +------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                         Rate  Moose  Mojo::Base  Moops  Mouse  Moos  Class::InsideOut  Object::Tiny::RW::XS  Object::Pad   Moo  Class::Struct  Class::XSAccessor  Object::Simple  Class::Accessor  Object::Tiny::XS  Class::XSAccessor::Array  Class::Tiny  Mojo::Base::XS  Simple::Accessor    Mo  Object::Tiny  Class::Accessor::PackedString  Class::Accessor::PackedString::Set  Class::Accessor::Array  Object::Tiny::RW  perl -e1 (baseline) 
  Moose                                 9.1/s     --        -18%   -55%   -80%  -81%              -81%                  -90%         -90%  -90%           -90%               -90%            -90%             -90%              -90%                      -90%         -90%            -91%              -92%  -93%          -93%                           -93%                                -94%                    -94%              -95%                 -95% 
  Mojo::Base                           11.1/s    22%          --   -45%   -76%  -77%              -77%                  -87%         -88%  -88%           -88%               -88%            -88%             -88%              -88%                      -88%         -88%            -90%              -91%  -92%          -92%                           -92%                                -93%                    -93%              -94%                 -94% 
  Moops                                20.4/s   124%         83%     --   -57%  -59%              -59%                  -77%         -79%  -79%           -79%               -79%            -79%             -79%              -79%                      -79%         -79%            -81%              -83%  -85%          -85%                           -85%                                -87%                    -87%              -89%                 -89% 
  Mouse                                47.6/s   423%        328%   133%     --   -4%               -4%                  -47%         -52%  -52%           -52%               -52%            -52%             -52%              -52%                      -52%         -52%            -57%              -61%  -66%          -66%                           -66%                                -71%                    -71%              -76%                 -76% 
  Moos                                 50.0/s   450%        350%   145%     5%    --                0%                  -44%         -50%  -50%           -50%               -50%            -50%             -50%              -50%                      -50%         -50%            -55%              -60%  -65%          -65%                           -65%                                -70%                    -70%              -75%                 -75% 
  Class::InsideOut                     50.0/s   450%        350%   145%     5%    0%                --                  -44%         -50%  -50%           -50%               -50%            -50%             -50%              -50%                      -50%         -50%            -55%              -60%  -65%          -65%                           -65%                                -70%                    -70%              -75%                 -75% 
  Object::Tiny::RW::XS                 90.9/s   900%        718%   345%    90%   81%               81%                    --          -9%   -9%            -9%                -9%             -9%              -9%               -9%                       -9%          -9%            -18%              -27%  -36%          -36%                           -36%                                -45%                    -45%              -54%                 -54% 
  Object::Pad                         100.0/s  1000%        800%   390%   110%  100%              100%                   10%           --    0%             0%                 0%              0%               0%                0%                        0%           0%             -9%              -19%  -30%          -30%                           -30%                                -40%                    -40%              -50%                 -50% 
  Moo                                 100.0/s  1000%        800%   390%   110%  100%              100%                   10%           0%    --             0%                 0%              0%               0%                0%                        0%           0%             -9%              -19%  -30%          -30%                           -30%                                -40%                    -40%              -50%                 -50% 
  Class::Struct                       100.0/s  1000%        800%   390%   110%  100%              100%                   10%           0%    0%             --                 0%              0%               0%                0%                        0%           0%             -9%              -19%  -30%          -30%                           -30%                                -40%                    -40%              -50%                 -50% 
  Class::XSAccessor                   100.0/s  1000%        800%   390%   110%  100%              100%                   10%           0%    0%             0%                 --              0%               0%                0%                        0%           0%             -9%              -19%  -30%          -30%                           -30%                                -40%                    -40%              -50%                 -50% 
  Object::Simple                      100.0/s  1000%        800%   390%   110%  100%              100%                   10%           0%    0%             0%                 0%              --               0%                0%                        0%           0%             -9%              -19%  -30%          -30%                           -30%                                -40%                    -40%              -50%                 -50% 
  Class::Accessor                     100.0/s  1000%        800%   390%   110%  100%              100%                   10%           0%    0%             0%                 0%              0%               --                0%                        0%           0%             -9%              -19%  -30%          -30%                           -30%                                -40%                    -40%              -50%                 -50% 
  Object::Tiny::XS                    100.0/s  1000%        800%   390%   110%  100%              100%                   10%           0%    0%             0%                 0%              0%               0%                --                        0%           0%             -9%              -19%  -30%          -30%                           -30%                                -40%                    -40%              -50%                 -50% 
  Class::XSAccessor::Array            100.0/s  1000%        800%   390%   110%  100%              100%                   10%           0%    0%             0%                 0%              0%               0%                0%                        --           0%             -9%              -19%  -30%          -30%                           -30%                                -40%                    -40%              -50%                 -50% 
  Class::Tiny                         100.0/s  1000%        800%   390%   110%  100%              100%                   10%           0%    0%             0%                 0%              0%               0%                0%                        0%           --             -9%              -19%  -30%          -30%                           -30%                                -40%                    -40%              -50%                 -50% 
  Mojo::Base::XS                      111.1/s  1122%        900%   444%   133%  122%              122%                   22%          11%   11%            11%                11%             11%              11%               11%                       11%          11%              --              -11%  -22%          -22%                           -22%                                -33%                    -33%              -44%                 -44% 
  Simple::Accessor                    125.0/s  1275%       1025%   512%   162%  150%              150%                   37%          25%   25%            25%                25%             25%              25%               25%                       25%          25%             12%                --  -12%          -12%                           -12%                                -25%                    -25%              -37%                 -37% 
  Mo                                  142.9/s  1471%       1185%   600%   200%  185%              185%                   57%          42%   42%            42%                42%             42%              42%               42%                       42%          42%             28%               14%    --            0%                             0%                                -14%                    -14%              -28%                 -28% 
  Object::Tiny                        142.9/s  1471%       1185%   600%   200%  185%              185%                   57%          42%   42%            42%                42%             42%              42%               42%                       42%          42%             28%               14%    0%            --                             0%                                -14%                    -14%              -28%                 -28% 
  Class::Accessor::PackedString       142.9/s  1471%       1185%   600%   200%  185%              185%                   57%          42%   42%            42%                42%             42%              42%               42%                       42%          42%             28%               14%    0%            0%                             --                                -14%                    -14%              -28%                 -28% 
  Class::Accessor::PackedString::Set  166.7/s  1733%       1400%   716%   250%  233%              233%                   83%          66%   66%            66%                66%             66%              66%               66%                       66%          66%             50%               33%   16%           16%                            16%                                  --                      0%              -16%                 -16% 
  Class::Accessor::Array              166.7/s  1733%       1400%   716%   250%  233%              233%                   83%          66%   66%            66%                66%             66%              66%               66%                       66%          66%             50%               33%   16%           16%                            16%                                  0%                      --              -16%                 -16% 
  Object::Tiny::RW                    200.0/s  2100%       1700%   880%   320%  300%              300%                  120%         100%  100%           100%               100%            100%             100%              100%                      100%         100%             80%               60%   39%           39%                            39%                                 19%                     19%                --                   0% 
  perl -e1 (baseline)                 200.0/s  2100%       1700%   880%   320%  300%              300%                  120%         100%  100%           100%               100%            100%             100%              100%                      100%         100%             80%               60%   39%           39%                            39%                                 19%                     19%                0%                   -- 
 
 Legends:
   Class::Accessor: mod_overhead_time=5 participant=Class::Accessor
   Class::Accessor::Array: mod_overhead_time=1 participant=Class::Accessor::Array
   Class::Accessor::PackedString: mod_overhead_time=2 participant=Class::Accessor::PackedString
   Class::Accessor::PackedString::Set: mod_overhead_time=1 participant=Class::Accessor::PackedString::Set
   Class::InsideOut: mod_overhead_time=15 participant=Class::InsideOut
   Class::Struct: mod_overhead_time=5 participant=Class::Struct
   Class::Tiny: mod_overhead_time=5 participant=Class::Tiny
   Class::XSAccessor: mod_overhead_time=5 participant=Class::XSAccessor
   Class::XSAccessor::Array: mod_overhead_time=5 participant=Class::XSAccessor::Array
   Mo: mod_overhead_time=2 participant=Mo
   Mojo::Base: mod_overhead_time=85 participant=Mojo::Base
   Mojo::Base::XS: mod_overhead_time=4 participant=Mojo::Base::XS
   Moo: mod_overhead_time=5 participant=Moo
   Moops: mod_overhead_time=44 participant=Moops
   Moos: mod_overhead_time=15 participant=Moos
   Moose: mod_overhead_time=105 participant=Moose
   Mouse: mod_overhead_time=16 participant=Mouse
   Object::Pad: mod_overhead_time=5 participant=Object::Pad
   Object::Simple: mod_overhead_time=5 participant=Object::Simple
   Object::Tiny: mod_overhead_time=2 participant=Object::Tiny
   Object::Tiny::RW: mod_overhead_time=0 participant=Object::Tiny::RW
   Object::Tiny::RW::XS: mod_overhead_time=6 participant=Object::Tiny::RW::XS
   Object::Tiny::XS: mod_overhead_time=5 participant=Object::Tiny::XS
   Simple::Accessor: mod_overhead_time=3 participant=Simple::Accessor
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


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

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
