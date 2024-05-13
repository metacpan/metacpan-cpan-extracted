package Bencher::Scenario::Accessors::Set;

use 5.010001;
use strict;
use warnings;

use Bencher::ScenarioUtil::Accessors;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Accessors'; # DIST
our $VERSION = '0.151'; # VERSION

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
                code_template => "state \$o = do { my \$o = ${_}->new; \$o }; \$o->".($spec->{setter_name} // "attr1")."(42)",
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

This document describes version 0.151 of Bencher::Scenario::Accessors::Set (from Perl distribution Bencher-ScenarioBundle-Accessors), released on 2024-05-06.

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

L<Perl::Examples::Accessors::ObjectTinyRW> 0.132

L<Perl::Examples::Accessors::ObjectTinyRWXS> 0.132

L<Perl::Examples::Accessors::SimpleAccessor> 0.132

L<Simple::Accessor> 1.13

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Tiny (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassTiny->new; $o }; $o->attr1(42)



=item * Class::Accessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorArray->new; $o }; $o->attr1(42)



=item * Mojo::Base (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBase->new; $o }; $o->attr1(42)



=item * Object::Tiny::RW::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRWXS->new; $o }; $o->attr1(42)



=item * Class::XSAccessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessor->new; $o }; $o->attr1(42)



=item * Moops (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moops->new; $o }; $o->attr1(42)



=item * Class::InsideOut (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassInsideOut->new; $o }; $o->attr1(42)



=item * Moos (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moos->new; $o }; $o->attr1(42)



=item * no generator (hash-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o }; $o->attr1(42)



=item * Class::Accessor::PackedString (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorPackedString->new; $o }; $o->attr1(42)



=item * Object::Tiny::RW (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectTinyRW->new; $o }; $o->attr1(42)



=item * Simple::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::SimpleAccessor->new; $o }; $o->attr1(42)



=item * Object::Simple (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectSimple->new; $o }; $o->attr1(42)



=item * Mouse (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mouse->new; $o }; $o->attr1(42)



=item * Mojo::Base::XS (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::MojoBaseXS->new; $o }; $o->attr1(42)



=item * Class::Struct (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassStruct->new; $o }; $o->attr1(42)



=item * no generator (array-based) (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o }; $o->attr1(42)



=item * Class::Accessor (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessor->new; $o }; $o->attr1(42)



=item * Moo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moo->new; $o }; $o->attr1(42)



=item * Class::Accessor::PackedString::Set (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassAccessorPackedStringSet->new; $o }; $o->attr1(42)



=item * Class::XSAccessor::Array (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ClassXSAccessorArray->new; $o }; $o->attr1(42)



=item * Moose (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Moose->new; $o }; $o->attr1(42)



=item * Mo (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Mo->new; $o }; $o->attr1(42)



=item * Object::Pad (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::ObjectPad->new; $o }; $o->set_attr1(42)



=item * raw hash access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Hash->new; $o }; $o->{attr1} = 42



=item * raw array access (perl_code)

Code template:

 state $o = do { my $o = Perl::Examples::Accessors::Array->new; $o }; $o->[0] = 42



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::Set

Result formatted as table:

 #table1#
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Simple::Accessor                   |    718000 |    1390   |                 0.00% |              2838.97% | 4.5e-10 |      20 |
 | Class::Accessor::PackedString::Set |   1430000 |     699   |                99.12% |              1375.97% | 3.3e-10 |      20 |
 | Class::Accessor::PackedString      |   1950000 |     514   |               170.83% |               985.18% | 2.9e-10 |      21 |
 | Class::Accessor                    |   2080000 |     480.8 |               189.62% |               914.78% |   4e-11 |      22 |
 | Class::InsideOut                   |   2680000 |     372   |               273.84% |               686.16% | 1.3e-10 |      22 |
 | Object::Pad                        |   3830000 |     261   |               432.63% |               451.78% | 1.4e-10 |      20 |
 | Moose                              |   4040000 |     248   |               462.21% |               422.76% | 5.6e-11 |      24 |
 | Object::Tiny::RW                   |   4100000 |     250   |               465.92% |               419.33% | 4.8e-10 |      20 |
 | Class::Struct                      |   4430000 |     226   |               516.87% |               376.43% | 7.8e-11 |      20 |
 | Class::Accessor::Array             |   4640000 |     216   |               545.38% |               355.39% | 6.2e-11 |      22 |
 | Mojo::Base                         |   4910000 |     204   |               584.01% |               329.67% | 1.1e-10 |      21 |
 | Object::Simple                     |   5150000 |     194   |               616.89% |               309.96% | 9.1e-11 |      20 |
 | no generator (hash-based)          |   5280000 |     189   |               635.52% |               299.57% | 1.1e-10 |      20 |
 | Class::Tiny                        |   5360000 |     186   |               646.95% |               293.47% | 8.7e-11 |      21 |
 | Mo                                 |   5370000 |     186   |               647.38% |               293.23% | 1.4e-10 |      24 |
 | no generator (array-based)         |   5980000 |     167   |               732.60% |               252.99% | 1.1e-10 |      20 |
 | Mouse                              |   9210000 |     109   |              1181.81% |               129.28% | 3.6e-11 |      21 |
 | Object::Tiny::RW::XS               |  11000000 |      94   |              1375.12% |                99.24% | 1.9e-10 |      20 |
 | Moos                               |  10700000 |      93.8 |              1384.43% |                97.99% |   8e-11 |      20 |
 | Moops                              |  11100000 |      90.4 |              1439.42% |                90.91% | 4.9e-11 |      20 |
 | Class::XSAccessor                  |  11000000 |      88   |              1473.83% |                86.74% |   9e-11 |      20 |
 | Mojo::Base::XS                     |  11300000 |      88.4 |              1474.96% |                86.61% | 7.8e-11 |      20 |
 | Moo                                |  11000000 |      88   |              1485.57% |                85.36% |   1e-10 |      24 |
 | Class::XSAccessor::Array           |  13000000 |      75   |              1763.55% |                57.71% | 1.3e-10 |      20 |
 | raw hash access                    |  17000000 |      60   |              2229.43% |                26.17% | 7.4e-11 |      21 |
 | raw array access                   |  21000000 |      47   |              2838.97% |                 0.00% | 1.5e-10 |      20 |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                            Rate  Simple::Accessor  Class::Accessor::PackedString::Set  Class::Accessor::PackedString  Class::Accessor  Class::InsideOut  Object::Pad  Object::Tiny::RW  Moose  Class::Struct  Class::Accessor::Array  Mojo::Base  Object::Simple  no generator (hash-based)  Class::Tiny    Mo  no generator (array-based)  Mouse  Object::Tiny::RW::XS  Moos  Moops  Mojo::Base::XS  Class::XSAccessor   Moo  Class::XSAccessor::Array  raw hash access  raw array access 
  Simple::Accessor                      718000/s                --                                -49%                           -63%             -65%              -73%         -81%              -82%   -82%           -83%                    -84%        -85%            -86%                       -86%         -86%  -86%                        -87%   -92%                  -93%  -93%   -93%            -93%               -93%  -93%                      -94%             -95%              -96% 
  Class::Accessor::PackedString::Set   1430000/s               98%                                  --                           -26%             -31%              -46%         -62%              -64%   -64%           -67%                    -69%        -70%            -72%                       -72%         -73%  -73%                        -76%   -84%                  -86%  -86%   -87%            -87%               -87%  -87%                      -89%             -91%              -93% 
  Class::Accessor::PackedString        1950000/s              170%                                 35%                             --              -6%              -27%         -49%              -51%   -51%           -56%                    -57%        -60%            -62%                       -63%         -63%  -63%                        -67%   -78%                  -81%  -81%   -82%            -82%               -82%  -82%                      -85%             -88%              -90% 
  Class::Accessor                      2080000/s              189%                                 45%                             6%               --              -22%         -45%              -48%   -48%           -52%                    -55%        -57%            -59%                       -60%         -61%  -61%                        -65%   -77%                  -80%  -80%   -81%            -81%               -81%  -81%                      -84%             -87%              -90% 
  Class::InsideOut                     2680000/s              273%                                 87%                            38%              29%                --         -29%              -32%   -33%           -39%                    -41%        -45%            -47%                       -49%         -50%  -50%                        -55%   -70%                  -74%  -74%   -75%            -76%               -76%  -76%                      -79%             -83%              -87% 
  Object::Pad                          3830000/s              432%                                167%                            96%              84%               42%           --               -4%    -4%           -13%                    -17%        -21%            -25%                       -27%         -28%  -28%                        -36%   -58%                  -63%  -64%   -65%            -66%               -66%  -66%                      -71%             -77%              -81% 
  Object::Tiny::RW                     4100000/s              455%                                179%                           105%              92%               48%           4%                --     0%            -9%                    -13%        -18%            -22%                       -24%         -25%  -25%                        -33%   -56%                  -62%  -62%   -63%            -64%               -64%  -64%                      -70%             -76%              -81% 
  Moose                                4040000/s              460%                                181%                           107%              93%               50%           5%                0%     --            -8%                    -12%        -17%            -21%                       -23%         -25%  -25%                        -32%   -56%                  -62%  -62%   -63%            -64%               -64%  -64%                      -69%             -75%              -81% 
  Class::Struct                        4430000/s              515%                                209%                           127%             112%               64%          15%               10%     9%             --                     -4%         -9%            -14%                       -16%         -17%  -17%                        -26%   -51%                  -58%  -58%   -60%            -60%               -61%  -61%                      -66%             -73%              -79% 
  Class::Accessor::Array               4640000/s              543%                                223%                           137%             122%               72%          20%               15%    14%             4%                      --         -5%            -10%                       -12%         -13%  -13%                        -22%   -49%                  -56%  -56%   -58%            -59%               -59%  -59%                      -65%             -72%              -78% 
  Mojo::Base                           4910000/s              581%                                242%                           151%             135%               82%          27%               22%    21%            10%                      5%          --             -4%                        -7%          -8%   -8%                        -18%   -46%                  -53%  -54%   -55%            -56%               -56%  -56%                      -63%             -70%              -76% 
  Object::Simple                       5150000/s              616%                                260%                           164%             147%               91%          34%               28%    27%            16%                     11%          5%              --                        -2%          -4%   -4%                        -13%   -43%                  -51%  -51%   -53%            -54%               -54%  -54%                      -61%             -69%              -75% 
  no generator (hash-based)            5280000/s              635%                                269%                           171%             154%               96%          38%               32%    31%            19%                     14%          7%              2%                         --          -1%   -1%                        -11%   -42%                  -50%  -50%   -52%            -53%               -53%  -53%                      -60%             -68%              -75% 
  Class::Tiny                          5360000/s              647%                                275%                           176%             158%              100%          40%               34%    33%            21%                     16%          9%              4%                         1%           --    0%                        -10%   -41%                  -49%  -49%   -51%            -52%               -52%  -52%                      -59%             -67%              -74% 
  Mo                                   5370000/s              647%                                275%                           176%             158%              100%          40%               34%    33%            21%                     16%          9%              4%                         1%           0%    --                        -10%   -41%                  -49%  -49%   -51%            -52%               -52%  -52%                      -59%             -67%              -74% 
  no generator (array-based)           5980000/s              732%                                318%                           207%             187%              122%          56%               49%    48%            35%                     29%         22%             16%                        13%          11%   11%                          --   -34%                  -43%  -43%   -45%            -47%               -47%  -47%                      -55%             -64%              -71% 
  Mouse                                9210000/s             1175%                                541%                           371%             341%              241%         139%              129%   127%           107%                     98%         87%             77%                        73%          70%   70%                         53%     --                  -13%  -13%   -17%            -18%               -19%  -19%                      -31%             -44%              -56% 
  Object::Tiny::RW::XS                11000000/s             1378%                                643%                           446%             411%              295%         177%              165%   163%           140%                    129%        117%            106%                       101%          97%   97%                         77%    15%                    --    0%    -3%             -5%                -6%   -6%                      -20%             -36%              -50% 
  Moos                                10700000/s             1381%                                645%                           447%             412%              296%         178%              166%   164%           140%                    130%        117%            106%                       101%          98%   98%                         78%    16%                    0%    --    -3%             -5%                -6%   -6%                      -20%             -36%              -49% 
  Moops                               11100000/s             1437%                                673%                           468%             431%              311%         188%              176%   174%           150%                    138%        125%            114%                       109%         105%  105%                         84%    20%                    3%    3%     --             -2%                -2%   -2%                      -17%             -33%              -48% 
  Mojo::Base::XS                      11300000/s             1472%                                690%                           481%             443%              320%         195%              182%   180%           155%                    144%        130%            119%                       113%         110%  110%                         88%    23%                    6%    6%     2%              --                 0%    0%                      -15%             -32%              -46% 
  Class::XSAccessor                   11000000/s             1479%                                694%                           484%             446%              322%         196%              184%   181%           156%                    145%        131%            120%                       114%         111%  111%                         89%    23%                    6%    6%     2%              0%                 --    0%                      -14%             -31%              -46% 
  Moo                                 11000000/s             1479%                                694%                           484%             446%              322%         196%              184%   181%           156%                    145%        131%            120%                       114%         111%  111%                         89%    23%                    6%    6%     2%              0%                 0%    --                      -14%             -31%              -46% 
  Class::XSAccessor::Array            13000000/s             1753%                                832%                           585%             541%              396%         248%              233%   230%           201%                    188%        172%            158%                       152%         148%  148%                        122%    45%                   25%   25%    20%             17%                17%   17%                        --             -19%              -37% 
  raw hash access                     17000000/s             2216%                               1065%                           756%             701%              520%         334%              316%   313%           276%                    260%        240%            223%                       215%         210%  210%                        178%    81%                   56%   56%    50%             47%                46%   46%                       25%               --              -21% 
  raw array access                    21000000/s             2857%                               1387%                           993%             922%              691%         455%              431%   427%           380%                    359%        334%            312%                       302%         295%  295%                        255%   131%                  100%   99%    92%             88%                87%   87%                       59%              27%                -- 
 
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
   Object::Tiny::RW: participant=Object::Tiny::RW
   Object::Tiny::RW::XS: participant=Object::Tiny::RW::XS
   Simple::Accessor: participant=Simple::Accessor
   no generator (array-based): participant=no generator (array-based)
   no generator (hash-based): participant=no generator (hash-based)
   raw array access: participant=raw array access
   raw hash access: participant=raw hash access

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
