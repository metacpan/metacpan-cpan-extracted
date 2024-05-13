package Bencher::Scenario::Accessors::Construction;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Accessors'; # DIST
our $VERSION = '0.151'; # VERSION

use Bencher::ScenarioUtil::Accessors;

my $classes = \%Bencher::ScenarioUtil::Accessors::classes;

our $scenario = {
    summary => 'Benchmark object construction',
    modules => {
        # force minimum version
        'Perl::Examples::Accessors' => {version=>0.05},

        # include the generator modules here so we can show their versions in
        # sample benchmark results produced by PWP:Bencher::Scenario
        (map { $_=>0 } grep {defined} map { $classes->{$_}{generator} }
             keys %$classes),
    },
    participants => [
        map {
            my $spec = $classes->{$_};
            +{
                name => $spec->{generator} || $spec->{name},
                module => $_,
                code_template => "${_}->new",
            };
        } keys %$classes,
    ],
    include_result_size => 1,
};

1;
# ABSTRACT: Benchmark object construction

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Accessors::Construction - Benchmark object construction

=head1 VERSION

This document describes version 0.151 of Bencher::Scenario::Accessors::Construction (from Perl distribution Bencher-ScenarioBundle-Accessors), released on 2024-05-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Accessors::Construction

To run module startup overhead benchmark:

 % bencher --module-startup -m Accessors::Construction

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

L<Class::Struct> 0.68

L<Class::Tiny> 1.008

L<Class::XSAccessor> 1.19

L<Class::XSAccessor::Array> 1.19

L<Mo> 0.40

L<Mojo::Base>

L<Mojo::Base::XS> 0.07

L<Moo> 2.005005

L<Moops> 0.038

L<Moos> 0.30

L<Moose> 2.2206

L<Mouse> v2.5.10

L<Object::Pad> 0.806

L<Object::Simple> 3.19

L<Object::Tiny> 1.09

L<Object::Tiny::RW> 1.07

L<Object::Tiny::RW::XS> 0.04

L<Object::Tiny::XS> 1.01

L<Perl::Examples::Accessors> 0.132

L<Perl::Examples::Accessors::Array> 0.132

L<Perl::Examples::Accessors::ClassAccessor> 0.132

L<Perl::Examples::Accessors::ClassAccessorArray> 0.132

L<Perl::Examples::Accessors::ClassAccessorPackedString> 0.132

L<Perl::Examples::Accessors::ClassAccessorPackedStringSet> 0.132

L<Perl::Examples::Accessors::ClassInsideOut> 0.132

L<Perl::Examples::Accessors::ClassStruct> 0.132

L<Perl::Examples::Accessors::ClassTiny> 0.132

L<Perl::Examples::Accessors::ClassXSAccessor> 0.132

L<Perl::Examples::Accessors::ClassXSAccessorArray> 0.132

L<Perl::Examples::Accessors::Hash> 0.132

L<Perl::Examples::Accessors::Mo> 0.132

L<Perl::Examples::Accessors::MojoBase> 0.132

L<Perl::Examples::Accessors::MojoBaseXS> 0.132

L<Perl::Examples::Accessors::Moo> 0.132

L<Perl::Examples::Accessors::Moops> 0.132

L<Perl::Examples::Accessors::Moos> 0.132

L<Perl::Examples::Accessors::Moose> 0.132

L<Perl::Examples::Accessors::Mouse> 0.132

L<Perl::Examples::Accessors::ObjectPad> 0.132

L<Perl::Examples::Accessors::ObjectSimple> 0.132

L<Perl::Examples::Accessors::ObjectTiny> 0.132

L<Perl::Examples::Accessors::ObjectTinyRW> 0.132

L<Perl::Examples::Accessors::ObjectTinyRWXS> 0.132

L<Perl::Examples::Accessors::ObjectTinyXS> 0.132

L<Perl::Examples::Accessors::Scalar> 0.132

L<Perl::Examples::Accessors::SimpleAccessor> 0.132

L<Simple::Accessor> 1.13

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Tiny (perl_code)

Code template:

 Perl::Examples::Accessors::ClassTiny->new



=item * Class::Accessor::Array (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessorArray->new



=item * no generator (scalar-based) (perl_code)

Code template:

 Perl::Examples::Accessors::Scalar->new



=item * Mojo::Base (perl_code)

Code template:

 Perl::Examples::Accessors::MojoBase->new



=item * Object::Tiny::RW::XS (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTinyRWXS->new



=item * Class::XSAccessor (perl_code)

Code template:

 Perl::Examples::Accessors::ClassXSAccessor->new



=item * Moops (perl_code)

Code template:

 Perl::Examples::Accessors::Moops->new



=item * Class::InsideOut (perl_code)

Code template:

 Perl::Examples::Accessors::ClassInsideOut->new



=item * Moos (perl_code)

Code template:

 Perl::Examples::Accessors::Moos->new



=item * no generator (hash-based) (perl_code)

Code template:

 Perl::Examples::Accessors::Hash->new



=item * Class::Accessor::PackedString (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessorPackedString->new



=item * Object::Tiny::RW (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTinyRW->new



=item * Simple::Accessor (perl_code)

Code template:

 Perl::Examples::Accessors::SimpleAccessor->new



=item * Object::Tiny::XS (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTinyXS->new



=item * Object::Simple (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectSimple->new



=item * Mouse (perl_code)

Code template:

 Perl::Examples::Accessors::Mouse->new



=item * Mojo::Base::XS (perl_code)

Code template:

 Perl::Examples::Accessors::MojoBaseXS->new



=item * Class::Struct (perl_code)

Code template:

 Perl::Examples::Accessors::ClassStruct->new



=item * no generator (array-based) (perl_code)

Code template:

 Perl::Examples::Accessors::Array->new



=item * Class::Accessor (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessor->new



=item * Moo (perl_code)

Code template:

 Perl::Examples::Accessors::Moo->new



=item * Class::Accessor::PackedString::Set (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessorPackedStringSet->new



=item * Class::XSAccessor::Array (perl_code)

Code template:

 Perl::Examples::Accessors::ClassXSAccessorArray->new



=item * Moose (perl_code)

Code template:

 Perl::Examples::Accessors::Moose->new



=item * Mo (perl_code)

Code template:

 Perl::Examples::Accessors::Mo->new



=item * Object::Tiny (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTiny->new



=item * Object::Pad (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectPad->new



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::Construction

Result formatted as table:

 #table1#
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Moos                               |    144000 |    6.94   |                 0.00% |              4396.84% | 2.9e-09 |      20 |
 | Class::InsideOut                   |    370000 |    2.7    |               156.94% |              1650.13% |   3e-09 |      20 |
 | Class::Tiny                        |    699000 |    1.43   |               385.20% |               826.80% | 5.8e-10 |      20 |
 | Simple::Accessor                   |    818000 |    1.22   |               467.67% |               692.15% | 6.5e-10 |      20 |
 | Moose                              |    842000 |    1.19   |               483.98% |               670.03% | 9.5e-10 |      20 |
 | Class::Accessor::PackedString      |   1290000 |    0.776  |               794.00% |               403.00% | 2.4e-10 |      21 |
 | Mo                                 |   1440000 |    0.696  |               897.14% |               350.97% | 1.2e-10 |      20 |
 | Class::Struct                      |   1460000 |    0.683  |               916.14% |               342.54% | 1.7e-10 |      20 |
 | Moo                                |   1540000 |    0.65   |               967.53% |               321.24% | 6.7e-11 |      20 |
 | Moops                              |   1540000 |    0.648  |               971.26% |               319.77% | 1.6e-10 |      20 |
 | Mouse                              |   2000000 |    0.5    |              1286.77% |               224.27% | 6.3e-10 |      20 |
 | Object::Pad                        |   2040000 |    0.49   |              1314.94% |               217.81% | 9.1e-11 |      21 |
 | Class::Accessor::Array             |   2400000 |    0.416  |              1568.34% |               169.54% | 8.1e-11 |      23 |
 | no generator (array-based)         |   2820000 |    0.355  |              1854.28% |               130.10% | 6.4e-11 |      20 |
 | Class::Accessor::PackedString::Set |   3280000 |    0.304  |              2179.37% |                97.28% | 8.6e-11 |      22 |
 | no generator (scalar-based)        |   3360000 |    0.298  |              2228.26% |                93.14% | 1.2e-10 |      25 |
 | Mojo::Base                         |   3360000 |    0.298  |              2231.33% |                92.89% |   1e-10 |      21 |
 | Object::Simple                     |   3380000 |    0.296  |              2241.97% |                92.01% | 4.2e-11 |      20 |
 | Object::Tiny::RW                   |   3410000 |    0.293  |              2268.71% |                89.84% | 3.1e-11 |      20 |
 | Object::Tiny                       |   3423000 |    0.2922 |              2274.98% |                89.34% | 2.3e-11 |      20 |
 | no generator (hash-based)          |   3450000 |    0.29   |              2294.83% |                87.77% | 6.6e-11 |      20 |
 | Class::Accessor                    |   4240000 |    0.236  |              2841.29% |                52.89% | 6.3e-11 |      22 |
 | Object::Tiny::RW::XS               |   5800000 |    0.17   |              3916.96% |                11.95% |   2e-10 |      20 |
 | Object::Tiny::XS                   |   5970000 |    0.167  |              4043.81% |                 8.52% | 2.6e-11 |      20 |
 | Class::XSAccessor                  |   6000000 |    0.167  |              4062.56% |                 8.03% | 5.7e-11 |      21 |
 | Mojo::Base::XS                     |   6010000 |    0.166  |              4069.72% |                 7.85% | 4.2e-11 |      23 |
 | Class::XSAccessor::Array           |   6500000 |    0.15   |              4396.84% |                 0.00% |   2e-10 |      20 |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                           Rate   Moos  Class::InsideOut  Class::Tiny  Simple::Accessor  Moose  Class::Accessor::PackedString    Mo  Class::Struct   Moo  Moops  Mouse  Object::Pad  Class::Accessor::Array  no generator (array-based)  Class::Accessor::PackedString::Set  no generator (scalar-based)  Mojo::Base  Object::Simple  Object::Tiny::RW  Object::Tiny  no generator (hash-based)  Class::Accessor  Object::Tiny::RW::XS  Object::Tiny::XS  Class::XSAccessor  Mojo::Base::XS  Class::XSAccessor::Array 
  Moos                                 144000/s     --              -61%         -79%              -82%   -82%                           -88%  -89%           -90%  -90%   -90%   -92%         -92%                    -94%                        -94%                                -95%                         -95%        -95%            -95%              -95%          -95%                       -95%             -96%                  -97%              -97%               -97%            -97%                      -97% 
  Class::InsideOut                     370000/s   157%                --         -47%              -54%   -55%                           -71%  -74%           -74%  -75%   -76%   -81%         -81%                    -84%                        -86%                                -88%                         -88%        -88%            -89%              -89%          -89%                       -89%             -91%                  -93%              -93%               -93%            -93%                      -94% 
  Class::Tiny                          699000/s   385%               88%           --              -14%   -16%                           -45%  -51%           -52%  -54%   -54%   -65%         -65%                    -70%                        -75%                                -78%                         -79%        -79%            -79%              -79%          -79%                       -79%             -83%                  -88%              -88%               -88%            -88%                      -89% 
  Simple::Accessor                     818000/s   468%              121%          17%                --    -2%                           -36%  -42%           -44%  -46%   -46%   -59%         -59%                    -65%                        -70%                                -75%                         -75%        -75%            -75%              -75%          -76%                       -76%             -80%                  -86%              -86%               -86%            -86%                      -87% 
  Moose                                842000/s   483%              126%          20%                2%     --                           -34%  -41%           -42%  -45%   -45%   -57%         -58%                    -65%                        -70%                                -74%                         -74%        -74%            -75%              -75%          -75%                       -75%             -80%                  -85%              -85%               -85%            -86%                      -87% 
  Class::Accessor::PackedString       1290000/s   794%              247%          84%               57%    53%                             --  -10%           -11%  -16%   -16%   -35%         -36%                    -46%                        -54%                                -60%                         -61%        -61%            -61%              -62%          -62%                       -62%             -69%                  -78%              -78%               -78%            -78%                      -80% 
  Mo                                  1440000/s   897%              287%         105%               75%    70%                            11%    --            -1%   -6%    -6%   -28%         -29%                    -40%                        -48%                                -56%                         -57%        -57%            -57%              -57%          -58%                       -58%             -66%                  -75%              -76%               -76%            -76%                      -78% 
  Class::Struct                       1460000/s   916%              295%         109%               78%    74%                            13%    1%             --   -4%    -5%   -26%         -28%                    -39%                        -48%                                -55%                         -56%        -56%            -56%              -57%          -57%                       -57%             -65%                  -75%              -75%               -75%            -75%                      -78% 
  Moo                                 1540000/s   967%              315%         119%               87%    83%                            19%    7%             5%    --     0%   -23%         -24%                    -36%                        -45%                                -53%                         -54%        -54%            -54%              -54%          -55%                       -55%             -63%                  -73%              -74%               -74%            -74%                      -76% 
  Moops                               1540000/s   970%              316%         120%               88%    83%                            19%    7%             5%    0%     --   -22%         -24%                    -35%                        -45%                                -53%                         -54%        -54%            -54%              -54%          -54%                       -55%             -63%                  -73%              -74%               -74%            -74%                      -76% 
  Mouse                               2000000/s  1288%              440%         186%              144%   138%                            55%   39%            36%   30%    29%     --          -2%                    -16%                        -29%                                -39%                         -40%        -40%            -40%              -41%          -41%                       -42%             -52%                  -65%              -66%               -66%            -66%                      -70% 
  Object::Pad                         2040000/s  1316%              451%         191%              148%   142%                            58%   42%            39%   32%    32%     2%           --                    -15%                        -27%                                -37%                         -39%        -39%            -39%              -40%          -40%                       -40%             -51%                  -65%              -65%               -65%            -66%                      -69% 
  Class::Accessor::Array              2400000/s  1568%              549%         243%              193%   186%                            86%   67%            64%   56%    55%    20%          17%                      --                        -14%                                -26%                         -28%        -28%            -28%              -29%          -29%                       -30%             -43%                  -59%              -59%               -59%            -60%                      -63% 
  no generator (array-based)          2820000/s  1854%              660%         302%              243%   235%                           118%   96%            92%   83%    82%    40%          38%                     17%                          --                                -14%                         -16%        -16%            -16%              -17%          -17%                       -18%             -33%                  -52%              -52%               -52%            -53%                      -57% 
  Class::Accessor::PackedString::Set  3280000/s  2182%              788%         370%              301%   291%                           155%  128%           124%  113%   113%    64%          61%                     36%                         16%                                  --                          -1%         -1%             -2%               -3%           -3%                        -4%             -22%                  -44%              -45%               -45%            -45%                      -50% 
  no generator (scalar-based)         3360000/s  2228%              806%         379%              309%   299%                           160%  133%           129%  118%   117%    67%          64%                     39%                         19%                                  2%                           --          0%              0%               -1%           -1%                        -2%             -20%                  -42%              -43%               -43%            -44%                      -49% 
  Mojo::Base                          3360000/s  2228%              806%         379%              309%   299%                           160%  133%           129%  118%   117%    67%          64%                     39%                         19%                                  2%                           0%          --              0%               -1%           -1%                        -2%             -20%                  -42%              -43%               -43%            -44%                      -49% 
  Object::Simple                      3380000/s  2244%              812%         383%              312%   302%                           162%  135%           130%  119%   118%    68%          65%                     40%                         19%                                  2%                           0%          0%              --               -1%           -1%                        -2%             -20%                  -42%              -43%               -43%            -43%                      -49% 
  Object::Tiny::RW                    3410000/s  2268%              821%         388%              316%   306%                           164%  137%           133%  121%   121%    70%          67%                     41%                         21%                                  3%                           1%          1%              1%                --            0%                        -1%             -19%                  -41%              -43%               -43%            -43%                      -48% 
  Object::Tiny                        3423000/s  2275%              824%         389%              317%   307%                           165%  138%           133%  122%   121%    71%          67%                     42%                         21%                                  4%                           1%          1%              1%                0%            --                         0%             -19%                  -41%              -42%               -42%            -43%                      -48% 
  no generator (hash-based)           3450000/s  2293%              831%         393%              320%   310%                           167%  140%           135%  124%   123%    72%          68%                     43%                         22%                                  4%                           2%          2%              2%                1%            0%                         --             -18%                  -41%              -42%               -42%            -42%                      -48% 
  Class::Accessor                     4240000/s  2840%             1044%         505%              416%   404%                           228%  194%           189%  175%   174%   111%         107%                     76%                         50%                                 28%                          26%         26%             25%               24%           23%                        22%               --                  -27%              -29%               -29%            -29%                      -36% 
  Object::Tiny::RW::XS                5800000/s  3982%             1488%         741%              617%   599%                           356%  309%           301%  282%   281%   194%         188%                    144%                        108%                                 78%                          75%         75%             74%               72%           71%                        70%              38%                    --               -1%                -1%             -2%                      -11% 
  Object::Tiny::XS                    5970000/s  4055%             1516%         756%              630%   612%                           364%  316%           308%  289%   288%   199%         193%                    149%                        112%                                 82%                          78%         78%             77%               75%           74%                        73%              41%                    1%                --                 0%              0%                      -10% 
  Class::XSAccessor                   6000000/s  4055%             1516%         756%              630%   612%                           364%  316%           308%  289%   288%   199%         193%                    149%                        112%                                 82%                          78%         78%             77%               75%           74%                        73%              41%                    1%                0%                 --              0%                      -10% 
  Mojo::Base::XS                      6010000/s  4080%             1526%         761%              634%   616%                           367%  319%           311%  291%   290%   201%         195%                    150%                        113%                                 83%                          79%         79%             78%               76%           76%                        74%              42%                    2%                0%                 0%              --                       -9% 
  Class::XSAccessor::Array            6500000/s  4526%             1700%         853%              713%   693%                           417%  363%           355%  333%   332%   233%         226%                    177%                        136%                                102%                          98%         98%             97%               95%           94%                        93%              57%                   13%               11%                11%             10%                        -- 
 
 Legends:
   Class::Accessor: participant=Class::Accessor
   Class::Accessor::Array: participant=Class::Accessor::Array
   Class::Accessor::PackedString: participant=Class::Accessor::PackedString
   Class::Accessor::PackedString::Set: participant=Class::Accessor::PackedString::Set
   Class::InsideOut: participant=Class::InsideOut
   Class::Struct: participant=Class::Struct
   Class::Tiny: participant=Class::Tiny
   Class::XSAccessor: participant=Class::XSAccessor
   Class::XSAccessor::Array: participant=Class::XSAccessor::Array
   Mo: participant=Mo
   Mojo::Base: participant=Mojo::Base
   Mojo::Base::XS: participant=Mojo::Base::XS
   Moo: participant=Moo
   Moops: participant=Moops
   Moos: participant=Moos
   Moose: participant=Moose
   Mouse: participant=Mouse
   Object::Pad: participant=Object::Pad
   Object::Simple: participant=Object::Simple
   Object::Tiny: participant=Object::Tiny
   Object::Tiny::RW: participant=Object::Tiny::RW
   Object::Tiny::RW::XS: participant=Object::Tiny::RW::XS
   Object::Tiny::XS: participant=Object::Tiny::XS
   Simple::Accessor: participant=Simple::Accessor
   no generator (array-based): participant=no generator (array-based)
   no generator (hash-based): participant=no generator (hash-based)
   no generator (scalar-based): participant=no generator (scalar-based)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Accessors>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Accessors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
