package Bencher::Scenario::Accessors::Construction;

our $DATE = '2021-08-03'; # DATE
our $VERSION = '0.150'; # VERSION

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

This document describes version 0.150 of Bencher::Scenario::Accessors::Construction (from Perl distribution Bencher-Scenarios-Accessors), released on 2021-08-03.

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

=item * Class::Accessor::PackedString (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessorPackedString->new



=item * Class::Accessor::Array (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessorArray->new



=item * Mojo::Base (perl_code)

Code template:

 Perl::Examples::Accessors::MojoBase->new



=item * Object::Tiny (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTiny->new



=item * Simple::Accessor (perl_code)

Code template:

 Perl::Examples::Accessors::SimpleAccessor->new



=item * Object::Tiny::RW (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTinyRW->new



=item * Moose (perl_code)

Code template:

 Perl::Examples::Accessors::Moose->new



=item * no generator (scalar-based) (perl_code)

Code template:

 Perl::Examples::Accessors::Scalar->new



=item * Moos (perl_code)

Code template:

 Perl::Examples::Accessors::Moos->new



=item * Object::Pad (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectPad->new



=item * Object::Tiny::XS (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTinyXS->new



=item * Mouse (perl_code)

Code template:

 Perl::Examples::Accessors::Mouse->new



=item * Mo (perl_code)

Code template:

 Perl::Examples::Accessors::Mo->new



=item * Object::Simple (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectSimple->new



=item * Moops (perl_code)

Code template:

 Perl::Examples::Accessors::Moops->new



=item * Class::Struct (perl_code)

Code template:

 Perl::Examples::Accessors::ClassStruct->new



=item * Class::XSAccessor (perl_code)

Code template:

 Perl::Examples::Accessors::ClassXSAccessor->new



=item * Object::Tiny::RW::XS (perl_code)

Code template:

 Perl::Examples::Accessors::ObjectTinyRWXS->new



=item * no generator (array-based) (perl_code)

Code template:

 Perl::Examples::Accessors::Array->new



=item * Moo (perl_code)

Code template:

 Perl::Examples::Accessors::Moo->new



=item * Class::InsideOut (perl_code)

Code template:

 Perl::Examples::Accessors::ClassInsideOut->new



=item * Mojo::Base::XS (perl_code)

Code template:

 Perl::Examples::Accessors::MojoBaseXS->new



=item * Class::Accessor (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessor->new



=item * Class::Tiny (perl_code)

Code template:

 Perl::Examples::Accessors::ClassTiny->new



=item * no generator (hash-based) (perl_code)

Code template:

 Perl::Examples::Accessors::Hash->new



=item * Class::Accessor::PackedString::Set (perl_code)

Code template:

 Perl::Examples::Accessors::ClassAccessorPackedStringSet->new



=item * Class::XSAccessor::Array (perl_code)

Code template:

 Perl::Examples::Accessors::ClassXSAccessorArray->new



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::Construction

Result formatted as table:

 #table1#
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Moos                               |    180000 |   5.5     |                 0.00% |              3937.69% | 6.7e-09 |      20 |
 | Class::InsideOut                   |    444000 |   2.25    |               143.26% |              1559.84% | 8.3e-10 |      20 |
 | Class::Tiny                        |    800000 |   1.2     |               340.11% |               817.44% | 1.7e-09 |      20 |
 | Simple::Accessor                   |   1011600 |   0.98854 |               454.56% |               628.10% | 4.9e-12 |      22 |
 | Moose                              |   1000000 |   0.98    |               461.58% |               618.98% | 3.3e-09 |      20 |
 | Class::Accessor::PackedString      |   1578600 |   0.63348 |               765.37% |               366.58% | 5.7e-12 |      20 |
 | Class::Struct                      |   1600000 |   0.62    |               780.64% |               358.49% | 1.6e-09 |      23 |
 | Mo                                 |   1650400 |   0.60593 |               804.72% |               346.29% | 5.7e-12 |      20 |
 | Object::Pad                        |   1660000 |   0.604   |               807.75% |               344.80% |   2e-10 |      22 |
 | Moops                              |   1700000 |   0.6     |               815.63% |               340.97% | 8.3e-10 |      20 |
 | Moo                                |   1700000 |   0.58    |               846.42% |               326.63% | 8.3e-10 |      20 |
 | Mouse                              |   2100000 |   0.47    |              1068.25% |               245.62% | 8.3e-10 |      20 |
 | Class::Accessor::Array             |   2810000 |   0.3559  |              1440.23% |               162.15% | 2.3e-11 |      20 |
 | no generator (array-based)         |   3250000 |   0.308   |              1681.16% |               126.69% |   1e-10 |      20 |
 | Mojo::Base                         |   3800000 |   0.26    |              1982.75% |                93.86% | 3.1e-10 |      20 |
 | Object::Simple                     |   3868000 |   0.2586  |              2020.26% |                90.43% | 4.9e-12 |      20 |
 | no generator (hash-based)          |   3989000 |   0.2507  |              2087.02% |                84.62% | 5.1e-12 |      20 |
 | Object::Tiny::RW                   |   4086000 |   0.2447  |              2140.11% |                80.25% | 4.8e-12 |      20 |
 | Object::Tiny                       |   4090000 |   0.244   |              2142.72% |                80.04% | 8.8e-11 |      28 |
 | Class::Accessor::PackedString::Set |   4119000 |   0.2428  |              2158.22% |                78.80% |   5e-12 |      20 |
 | no generator (scalar-based)        |   4200000 |   0.24    |              2197.16% |                75.77% | 3.3e-10 |      31 |
 | Class::Accessor                    |   4792000 |   0.2087  |              2526.83% |                53.71% | 4.9e-12 |      20 |
 | Object::Tiny::RW::XS               |   6700000 |   0.15    |              3552.59% |                10.54% | 2.1e-10 |      20 |
 | Object::Tiny::XS                   |   6800000 |   0.15    |              3625.85% |                 8.37% | 2.1e-10 |      20 |
 | Mojo::Base::XS                     |   6800000 |   0.15    |              3627.76% |                 8.31% | 2.6e-10 |      20 |
 | Class::XSAccessor                  |   6840000 |   0.146   |              3649.75% |                 7.68% | 4.6e-11 |      26 |
 | Class::XSAccessor::Array           |   7400000 |   0.14    |              3937.69% |                 0.00% | 1.6e-10 |      20 |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                           Rate   Moos  Class::InsideOut  Class::Tiny  Simple::Accessor  Moose  Class::Accessor::PackedString  Class::Struct    Mo  Object::Pad  Moops   Moo  Mouse  Class::Accessor::Array  no generator (array-based)  Mojo::Base  Object::Simple  no generator (hash-based)  Object::Tiny::RW  Object::Tiny  Class::Accessor::PackedString::Set  no generator (scalar-based)  Class::Accessor  Object::Tiny::RW::XS  Object::Tiny::XS  Mojo::Base::XS  Class::XSAccessor  Class::XSAccessor::Array 
  Moos                                 180000/s     --              -59%         -78%              -82%   -82%                           -88%           -88%  -88%         -89%   -89%  -89%   -91%                    -93%                        -94%        -95%            -95%                       -95%              -95%          -95%                                -95%                         -95%             -96%                  -97%              -97%            -97%               -97%                      -97% 
  Class::InsideOut                     444000/s   144%                --         -46%              -56%   -56%                           -71%           -72%  -73%         -73%   -73%  -74%   -79%                    -84%                        -86%        -88%            -88%                       -88%              -89%          -89%                                -89%                         -89%             -90%                  -93%              -93%            -93%               -93%                      -93% 
  Class::Tiny                          800000/s   358%               87%           --              -17%   -18%                           -47%           -48%  -49%         -49%   -50%  -51%   -60%                    -70%                        -74%        -78%            -78%                       -79%              -79%          -79%                                -79%                         -80%             -82%                  -87%              -87%            -87%               -87%                      -88% 
  Simple::Accessor                    1011600/s   456%              127%          21%                --     0%                           -35%           -37%  -38%         -38%   -39%  -41%   -52%                    -63%                        -68%        -73%            -73%                       -74%              -75%          -75%                                -75%                         -75%             -78%                  -84%              -84%            -84%               -85%                      -85% 
  Moose                               1000000/s   461%              129%          22%                0%     --                           -35%           -36%  -38%         -38%   -38%  -40%   -52%                    -63%                        -68%        -73%            -73%                       -74%              -75%          -75%                                -75%                         -75%             -78%                  -84%              -84%            -84%               -85%                      -85% 
  Class::Accessor::PackedString       1578600/s   768%              255%          89%               56%    54%                             --            -2%   -4%          -4%    -5%   -8%   -25%                    -43%                        -51%        -58%            -59%                       -60%              -61%          -61%                                -61%                         -62%             -67%                  -76%              -76%            -76%               -76%                      -77% 
  Class::Struct                       1600000/s   787%              262%          93%               59%    58%                             2%             --   -2%          -2%    -3%   -6%   -24%                    -42%                        -50%        -58%            -58%                       -59%              -60%          -60%                                -60%                         -61%             -66%                  -75%              -75%            -75%               -76%                      -77% 
  Mo                                  1650400/s   807%              271%          98%               63%    61%                             4%             2%    --           0%     0%   -4%   -22%                    -41%                        -49%        -57%            -57%                       -58%              -59%          -59%                                -59%                         -60%             -65%                  -75%              -75%            -75%               -75%                      -76% 
  Object::Pad                         1660000/s   810%              272%          98%               63%    62%                             4%             2%    0%           --     0%   -3%   -22%                    -41%                        -49%        -56%            -57%                       -58%              -59%          -59%                                -59%                         -60%             -65%                  -75%              -75%            -75%               -75%                      -76% 
  Moops                               1700000/s   816%              275%         100%               64%    63%                             5%             3%    0%           0%     --   -3%   -21%                    -40%                        -48%        -56%            -56%                       -58%              -59%          -59%                                -59%                         -60%             -65%                  -75%              -75%            -75%               -75%                      -76% 
  Moo                                 1700000/s   848%              287%         106%               70%    68%                             9%             6%    4%           4%     3%    --   -18%                    -38%                        -46%        -55%            -55%                       -56%              -57%          -57%                                -58%                         -58%             -64%                  -74%              -74%            -74%               -74%                      -75% 
  Mouse                               2100000/s  1070%              378%         155%              110%   108%                            34%            31%   28%          28%    27%   23%     --                    -24%                        -34%        -44%            -44%                       -46%              -47%          -48%                                -48%                         -48%             -55%                  -68%              -68%            -68%               -68%                      -70% 
  Class::Accessor::Array              2810000/s  1445%              532%         237%              177%   175%                            77%            74%   70%          69%    68%   62%    32%                      --                        -13%        -26%            -27%                       -29%              -31%          -31%                                -31%                         -32%             -41%                  -57%              -57%            -57%               -58%                      -60% 
  no generator (array-based)          3250000/s  1685%              630%         289%              220%   218%                           105%           101%   96%          96%    94%   88%    52%                     15%                          --        -15%            -16%                       -18%              -20%          -20%                                -21%                         -22%             -32%                  -51%              -51%            -51%               -52%                      -54% 
  Mojo::Base                          3800000/s  2015%              765%         361%              280%   276%                           143%           138%  133%         132%   130%  123%    80%                     36%                         18%          --              0%                        -3%               -5%           -6%                                 -6%                          -7%             -19%                  -42%              -42%            -42%               -43%                      -46% 
  Object::Simple                      3868000/s  2026%              770%         364%              282%   278%                           144%           139%  134%         133%   132%  124%    81%                     37%                         19%          0%              --                        -3%               -5%           -5%                                 -6%                          -7%             -19%                  -41%              -41%            -41%               -43%                      -45% 
  no generator (hash-based)           3989000/s  2093%              797%         378%              294%   290%                           152%           147%  141%         140%   139%  131%    87%                     41%                         22%          3%              3%                         --               -2%           -2%                                 -3%                          -4%             -16%                  -40%              -40%            -40%               -41%                      -44% 
  Object::Tiny::RW                    4086000/s  2147%              819%         390%              303%   300%                           158%           153%  147%         146%   145%  137%    92%                     45%                         25%          6%              5%                         2%                --            0%                                  0%                          -1%             -14%                  -38%              -38%            -38%               -40%                      -42% 
  Object::Tiny                        4090000/s  2154%              822%         391%              305%   301%                           159%           154%  148%         147%   145%  137%    92%                     45%                         26%          6%              5%                         2%                0%            --                                  0%                          -1%             -14%                  -38%              -38%            -38%               -40%                      -42% 
  Class::Accessor::PackedString::Set  4119000/s  2165%              826%         394%              307%   303%                           160%           155%  149%         148%   147%  138%    93%                     46%                         26%          7%              6%                         3%                0%            0%                                  --                          -1%             -14%                  -38%              -38%            -38%               -39%                      -42% 
  no generator (scalar-based)         4200000/s  2191%              837%         400%              311%   308%                           163%           158%  152%         151%   150%  141%    95%                     48%                         28%          8%              7%                         4%                1%            1%                                  1%                           --             -13%                  -37%              -37%            -37%               -39%                      -41% 
  Class::Accessor                     4792000/s  2535%              978%         474%              373%   369%                           203%           197%  190%         189%   187%  177%   125%                     70%                         47%         24%             23%                        20%               17%           16%                                 16%                          14%               --                  -28%              -28%            -28%               -30%                      -32% 
  Object::Tiny::RW::XS                6700000/s  3566%             1400%         700%              559%   553%                           322%           313%  303%         302%   300%  286%   213%                    137%                        105%         73%             72%                        67%               63%           62%                                 61%                          60%              39%                    --                0%              0%                -2%                       -6% 
  Object::Tiny::XS                    6800000/s  3566%             1400%         700%              559%   553%                           322%           313%  303%         302%   300%  286%   213%                    137%                        105%         73%             72%                        67%               63%           62%                                 61%                          60%              39%                    0%                --              0%                -2%                       -6% 
  Mojo::Base::XS                      6800000/s  3566%             1400%         700%              559%   553%                           322%           313%  303%         302%   300%  286%   213%                    137%                        105%         73%             72%                        67%               63%           62%                                 61%                          60%              39%                    0%                0%              --                -2%                       -6% 
  Class::XSAccessor                   6840000/s  3667%             1441%         721%              577%   571%                           333%           324%  315%         313%   310%  297%   221%                    143%                        110%         78%             77%                        71%               67%           67%                                 66%                          64%              42%                    2%                2%              2%                 --                       -4% 
  Class::XSAccessor::Array            7400000/s  3828%             1507%         757%              606%   599%                           352%           342%  332%         331%   328%  314%   235%                    154%                        119%         85%             84%                        79%               74%           74%                                 73%                          71%              49%                    7%                7%              7%                 4%                        -- 
 
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

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAUdQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADVlQDWmADalADUAAAAlADUlQDVlQDVlADUlQDVlQDVlADUlADUlADUAAAAlADUlADUlADUlADUlQDVlQDWlADUlADUlADUlADUVgB7jQDKhgDAdACnZQCRAAAAKQA7ZgCTaQCXZgCSMABFYQCMRwBmWAB+TwBxYQCLQgBeAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADUbQCb////3+8+pAAAAGl0Uk5TABFEZiK7Vcwzd4jdme6qjqPVzsfSP+z89vH59HVOdSDf5Nbs9USXpyLnM/ARiGbHaVz37/qjdfn21cfWtO30/Jn5tM/o4OBgMFAgxtrR9XC/pPLNTmvhrVtcQPeP49+XxJ+vz8iJ5++1uEyjjwAAAAFiS0dEAIgFHUgAAAAJcEhZcwAAAEgAAABIAEbJaz4AAAAHdElNRQflCAMJOSHlpGLVAAAvV0lEQVR42u2d+b/0yHXWtbbUWhqcZIYEjPNmFuyYgFnDvoQE5vWwxIFxbAYTMIRF5v//ndo3nVKrJd3bkvr5fj723Fu332qp9KjqVNWpc5IEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADw9qSZ+iFL3eJsQVUAPIu80D9lg/phcDVcDI/VB8BTKY16KUEXlwqCBgeirq6si86bJmOCLvh/pKCzpqnZj3kJQYMjkbddlpRt0/R5NvRdNzRC0Ne+6YacfyCDoMGR4CZHyTrp5pYN1yS5DgUTdDGw7jnv+d8haHAopA1dX6pSSpd1z0OWtxmDqxqCBseCC7oZyq5Ugu65oJu+5EDQ4HAwQV96bnIwQadJkooe+tImel0aggaHorywiSFTLzc5OqbrllsdaZ/LHyFocDBubZ5Wbdl2/V+oqrbta2FG531V8R8haHAw0ozZG1mWJvq/utjfAAcAAAAAAAAAAAAAYAWXtiqx3gTOQtqmye367KsAYCPy7tlXAMCGNLd26GBygENRF/7v6ghcnXKHGmZyNM++QADmU7fD4M375LnkohqGLmmYmLPy2ZcIwHzaJkkrayrrc8nlLS3apmZibtBDgwPBzyQ3ZZLxI5zXTJ9LFqfgrlXSVbcKNjQ4EP01SW5dkvaX5NJz7QqPXfN/tRMl5S9+R/Brvw7AG/EbQmK/8clyQWd927OpX3Jpi94eEsqloP3O+dO/9Juc3/rU47d+81OC9aWf/uWDlYYN87alJ23gvyIkNnx3sZ7T6pZdhA1966WxLAR9lYL21z8+/XXyjWjepjQpD1baZO9ZeuoGXiFofgAuqblycxkJJTA5XCDoyVIIerPSFYJuqkSeTU77RpjQUsaFkHjrfxaCniyFoDcrXSHomi9nND2ruUluN3H3ctmukf9zgaAnSyHozUpXCJpZGhU/m3xlE8OivyRa0HVfteGCHQQ9WQpBb1a6RtBJkZENlo6LaUEX2duUJvnBSrPiPUtP3cCrBD0fWtAAbA0EDU4FBA1OBQQNTgUEDU4FBA1OBQQNTgUEDU4FBA1OBQQNTgUEDU4FBA1OBQQNTgUEDU4FBA1OBQQNDspf/Z7kt71SCBoclA+/knzPK4WgwUGBoMGpgKDBqYCgwamAoMGpeG9Be1mwIGiwNe8saD8LFgQNtuadBe1nwYKgwda8s6D9LFgQNNia9xB0NAsWBA22ZnNBZ4PACX4Wz4IFQYOt2VzQaca49sasmMqCBUGDrXkbk6O6zMqCBUGDrXkTQV9vyawsWJ9+h3fndHRXAJYQCroWElsn6LTnEp2TBet3Gk72+FcAQBMKOhcSWyfoRi42L82CBcBy3sDkSGXHvDgLFgDLeQNBq1xXi7NgAbCcNxD0TVoci7NgAbCcNxB0LyyN5VmwAFjO+/lyzM6CBcAcPvtc8MWXXikc/MGO+Gvfl/xgRqmWLgQNdsvvkiL93UnpQtBgt3xYIF0IGuwWCBoclM8+SH7olULQ4KB8vpl0IWiwAyBocCogaHAqIGhwKiBocCogaHAqIGhwKiBocCogaHAqIGhwKiBocCogaHAqIGhwKiBocCogaHAqIGhwKs4iaGTBAoKTCBpZsIDkJIJGFiwgOYmgkQULSI4k6LT2f0cWLDDiOIJOb8NQuYHNkQULjDmOoLsqTWUcXQGyYAGKwwg65emuigZZsMAkhxF0NiR1ls7MggVBvyyHEfRlKNu2r+dlwfrrJSd/duOC9+e9BN0Iia0QdDMwE7npE2TBAlMcpocW8k15rm9kwQJxDiPoWgq6RhYsMMVhBJ201yTpWmTBApMcR9A83RWbFCILFpjiOIKm0l1FiiHo1+VAgp4PBP26QNDgVEDQ4FRA0OBUQNDgVEDQ4FRA0OBUQNDgVEDQ4FRA0OBUQNDgVEDQ4FRA0OBUQNDgVEDQ4FRA0OBUQNDgVEDQ4FRA0OBUQNDgVEDQ4FRA0OBUQNDgVJxF0EjrBgQnETTSugHJSQSNtG5AchJBI60bkBxZ0EjrBkYcR9DNwCidAqR1A2OOI+hbl2WZTb2JtG6A4jiCVjmAkNYNTHEcQQ9502Qz07ohC9bLcpgsWMnQNh1PFzQnrRt66JflMD100TDRXpHWDUxzGEELkNYN3OEwghaTwQJp3cA0xxE0X87oKqR1A5McRtBJw5N9I60bmOY4gk4KpHUDdzmQoOcDQb8CHz6X+KUQNDgoWrp0KQQNDgYEDU4FBA1OBQQNTgUEDU4FBA1OBQQNTgUEDU4FBA1OBQQNTgUEDU4FBA1OBQQNTgUEDU4FBA1OBQQNTsWBBF3Xsz4WBYJ+BQ4j6Lwfyqxdo2kI+hU4iqDrIc/KVMXeWAYE/QocRdBNJyI9V9n9j8aAoF+Bwwi6WSJoZME6MV8q/NKjCDrraybo/DGTA1mwzswXUktf+KVHEXRyHdq+7R8L7owsWGdGiTQSgYMu3ZGgkyJvLg9OCZEF6xT83qRxcVBBF9J4zgvib/5aHrJgnY0vfzVlXBxS0EV25cmBsktLTAqb0vsosmAdgS+/kBG7PvNLf0WJlC49tKDzsmpF9orb2OjI3KxuyIJ1ELRIP5Clpxc0syBi08G0v5XIgnU4Xl7QirENfWu4yYEsWLvlB2pG90Ov9KSCfiALVn7jH+1DGzqvpA2NLFh75W9MSpcuPaygJfM2VpqqbKouKC7aQk0KkQVrp0DQJGxud+nE1p9fXDGLo20KZMHaLRA0CRM0X7MoA5Mja5SgkQVrr0DQJDmzLZhKo+vQyIL1fP7mB8n3vVIImqYsk6ZvK+IvXNDIgrUDaOlC0HEu+WxnDmTBen8gaMWsVY71y8cQ9GZ8/wHpQtAk1+r+Z+4AQW8GBB2ULjA5uoZ7J604gQVBbwcEHZQuMDkGyYqnAEFvBgQdlCLQzLGBoINSCPrYQNBBKQR9bCDooBSCPjYQdFAKQR8bCDoohaCPDQQdlELQxwaCDkoh6GMDQQelEPSxgaCDUgj62EDQQSkEfWwg6KAUgj42EHRQCkEfGwg6KIWgjw0EHZRC0McGgg5KIehjA0EHpRD0sYGgg1II+iho6f6ILP3glULQircTNLJgrQWCnlX6ToJGFqzVQNCzSt9J0MiCtRoIelbpOwkaWbBWA0HPKt1S0FkQ1B9ZsLYEgp5Vup2g834YSjfiHbJgbQoEPat0M0GnfZ6kTlx/ZMHaGAh6VulmghbBc5sSWbDeCgh6Vum2k8LbbV4WrN9pOGvC470eEPSsUi3oXEhsnaDLlidemZMF6zsi3GOx4DteFwh6VqkWdC0ktnKVI2+5mYwsWG8CBD2rdFuT4yI7ZWTBegMg6FmlmwlaJAziykUWrLcBgp5VuuEqR50kXYssWG8FBD2rdDuToxvKtq+RBeutgKBnlW5oQxd0mgpkwXoUnWT+B14pBD2rFA7++0OL9PtkKQQNQR8MCHpFKQS9PyDoFaUQ9P6AoFeUQtD7A4JeUQpB7w8IekUpBL0/IOgVpRD0/oCgV5RC0PsDgl5RCkHvDwh6RSkEvT8g6BWlEPT+gKBXlELQ+wOCXlEKQe8PCHpFKQS9PyDoFaUQ9P6AoFeUQtD7A4JeUQpB7w8IekUpBL0/IOgVpRD0/oCgV5RC0PsDgl5RCkHvDwh6RSmyYO0PCHpFKbJg7Q8IekUpsmDtDwh6RSmyYO0PCHpF6ZaCrpEF60F+OBn0C4J+qqDrdhja2ilAFqy76KdASxeCfqqg+y5JOxsIGlmwZgBBBw2xI0GLPCrFUCML1gNA0EFD7EjQKbeYs6GYlQULSYMkEHTQEPtKGsTs5W5eFiykdZNA0EFD7CqtW9oMwkpGFqzZQNBBQ+zI5EjqqpRrHMiCNRsIOmiIPQm6VZuByII1Hwg6aIgdCfoyCCscWbAeAYIOGmJHgm4GAbJgPQIEHTTEjgQdBVmw4kDQQUMcQdAEELQCgg4aAoI+NhB00BAQ9LGBoIOGgKCPDQQdNAQEvT8++1zwxd+aUQpBBw0BQT+Tv/09ye95pXTLTpdC0BD0u/J3yDb8uw+0LAQdlELQz2R9y0LQQSkEvTXqOJ/fLMnfe6OWhaCDUgh6a7544/aGoCHod+Wt2xuChqDfFQhaAkGvB4IOSiFoCHo1ELQEgl4PBB2UQtAQ9GogaAkEvR4IOiiFoCHo1UDQEgh6PRB0UApBQ9CrgaAlEPR6IOigFIKGoFcDQUsg6EXsLwsWBC2BoJewwyxYELQEgl7CDrNgQdASCHoJO8yCBUFLIOg4GfnrTrNgQdASCDpKMRC/7jYLFgQtgaAj6LRXwa+7zYIFQUsg6Agq7dVhsmBB0BIIOooICP3MLFg//CD5zC+mz3dD0Kp1zinoLbJgyQjnT8yCFWnv6fPdb9XeEPRTBb1BFiydG+h5WbCm2xuCfiVBSzYR9POyYEHQCghasYWgn5gFC4JWQNCKLQT9xCxYELQCglZsIOhnZsGCoBUQtOLgWbAgaAUErTiMg/8PfiT5+14pBK2AoBWHEfSS9oagIeg3AoIOSiFoCBqC9ko/eKUQtAKChqCXNzAEvRwIOij94JVC0AoIGoJe3sAQ9HIg6KD0g1cKQSsgaAh6eQND0MuBoIPSD14pBK2AoCHo5Q0MQS8Hgg5KP3ilELQCgoaglzcwBL0cCDoo/eCVQtCKHQr6yy8+F6xvbwgagn4jHhL0Ay0LQSsgaAUEDUEvb2AIeg4QdFAKQUPQEPREKQS9Hgg6KIWgIWgI2iv94JVC0AoIGoJe3sAQ9Bwg6KAUgoagIeiJUgh6PbSg9Z6gH90Zgg5KIeh9CLp2woHRgv59smV/n2zDR0qTf0C27HSp31r/cEHp9x4o9aX7jyZLf0SW+o32jx8oXd/sutEeavb1DTyn2d9M0DJ1kAaCDkoh6KMJWqYO0r9B0EEpBH0wQevUQQoIOiiFoA8m6CCOPwQdlELQBxN0kDro03/yXYJ/+v8k/4ws/eeLS7/7L1TxI6X/0iv9gwWl/+qB0j/0Sv9osvRfk6V+o/2bB0rXN7tutIeafX0Dz2n2txJ0kDro0wGAd+F9TA4Ajg2ZOgiAw0KlDgLPJ03X1/GSUKmDDs3maZ2fg8juBBZApA6awfvK5pFvazfP6xynXv1d0Rqqbn4lVPM8cGlF1/fNqtLjcy3p8pyUXr7yuce+jaR5swlBeHNFkt5u6wa3gqqhqOO3QTUw0TxTlxY+jbrvsstoQHiklK43fsFPJS87omHSviR7EKp7TIvhgeHzQtUQ+TaalupB6Nt4jPDm+O95X6+sclxDy0vqoY78gznNE7+00dNI+yv//1Gd80vpeicu+Jl0VVMSF5r1PfnmUdNLVgXxybwaCInlTVmNPxt8W11dZQ1tQ9RwK/txKX0bkRrIKyNuTnSilGzCGgr5G1Exr2JUw63iOdnb69wGJh5G9NLCp5GSa7aPlNL1Tl7wE7m01KO9ZGkxuv6iZU+hIXrSYiDuqWkvWTXSblNdO/4wXfKy/Mr/tsvAJdtUl8u4hq7Nm350EfRt0DWQV0bfnBgLmtGUelyDuHyyYl6FU0PNP5hXOWuEJjQkog1MPIzYpYVPo2lYQZ5kTTX0+aJSut7pC34ilz67dFUVvOlN5e4uSuqEP4VL8MBEH0iZg9wOy0eDFK/z6newTZU3bep9WzHwGdOQ8SEwaEWxrF4P4TBH3wZZQ+TKiJvTY0F5v4aMd6FExaoKW0POZVEMKfs6648w3cC81w8fBn1pckDyngb/QDcMQ9VcGmvjPFJK1xtttGcirrMc2u4iU94XOTfw+fpoyodDWai49EOVZn1X+GOS7ANTf/QU5uxQ12VZu83CfxbP0LeB1aNS3yafcX9lDSr+EG4JyTGxczq3vB3KInFuI6jarYG+smvLVTa6OTMWZP3dexOXPy7WVcga0vwiNZC0F/5fb+4VNLBebNC9vn9r5KXpAcl7Gj1/9etMNKvt5h8ppeuNNdozcQbknAkkvQ0Vu8j01onmTZOiz2resvxRFG3Ghz02B/anMqoPzN1OV5qzVcWeWjLoGuQDS/gYlTS2u7lksj3STHxbWkqrsMyZZMVnHaNONGEqesDMmC1MA5fspr6e3YYyv+XLGtYQXpkuvVz4swxuzhkL7LyHrkF8OhsX2ypYDWnTD0MpFd01/L/SciIb2Cw26F5fPoypS7MDknwa9Y1PH9yxjDfHI6V0vZON9lTUdWb8Si9JWrF+jr1xpZx98+GnGdqPtwsfx7u2kcNqWpkhVfZVqg90ZuHKnM1lo/MfWQ36gTXCOG5Nd8NsG2GuMSmyb0tZRyuk2jRFn4vPXnr2b4a2Nk3YcbMxL3UNVcU/z75e3YY0v9XLqmuIXhlfihLqaHk37txc4o0FTTNRgxoi2J34xV4VTXNpq4z9MReKvogp3cB6k4JsYLvYYHp90TzRS/Mehnwa7AXqm1SKtKl5h8Vb7pFSut7JRnuuoOV11kwvF7MsWveNmKzkXNY/bvpbwW2QQgx/fNhL9Vgk+yrdB9bWxNPmLBsWr8p+TVPzwKrqwr5SfLWybZo2lUMEb85iEP8mY/pu07LN875rKzHo6iZMeQ296UsuqsdO1W1I81u/rKIG2ddcMuLK+FJU2qZp1Ynh1NwcN1y/tmPBpZu4NzVE8AHZKRamrx1OLq2QqLR5maJFA9RpGmlgO6rYXj+j6lWX5j8M/TTSa9vL7rPru64v04dLyXpjjfZEpJFvrlNcphqqeR/KJZCzy7y0YkDjNoiQe8F1pObmqq/y+0BZrzZnm1IupOXZrTMPLG0qVsr0xkuFRL4WCtVvedPWTJHpICxtVsO/FUJgw6tpwrTrq4vzbeKJcgF/FBUI89t0Kvoa5Dw3vDK1FMVGA9a7F6m5OWm42rGg5sXC4hnVYIcIPiCbYmX6mirqfycW3tJWXnkv37JoA9vFhqDXD+uVl0Y+DPn5YehEU9ya7PFSut5Ioz0FaWEq49m/Tj1wFEN97S+XtihKZh7JXjNTEwI+vmlBq77K6QO9VTLe5Yo3hb/PrAb7wNKPrCG+ZqXatmHdt11CZoMtM35SZmNcpO0g7UFhi5smdL9NmJLZUHjmd2B/m3muuTL5UyaXom78tlreAOrmpOH6lR0LbtZo9GpgF2OGCG/FQZm+dji5tXxu2A5DJbXDapxqYLvY4PT6VL380qiHkQptsm/MyqEzRu4jpZGHHG20pyAtTG3ku9dpp7Xsr93Aeo6Od3/iWvkVC3ml3CS5SMNq3FeZepU5K3dsxfvclPaB/fv/ULW1Kk2UbeNwZaM3a8SrXvDgQqir0mtC79uaoWn4E3fN7+BlNfNccWVfXUXNYudLvGfsLrI2LcTNuasYYixIGz5TNhaPvjdRQzmwl8gMEWqg99ZBzHCSMgPhxi5TDlVJzi4h2sBcYHaxwQx0ZL3JHwcP4ytlQsixgD8CJlMzhZ5fGjzkn/zJRKM9T9BqgVcb+Y4YzSpj4c/0+e0JG8RO+5xNudx7OXW9ypyVO7bifWY16AeWpP/xP9lSadt4VGI11BRehqwbxHafaUL/29i3NCPz239ZzTxXXNltqIpEvWniPavlrNPem7NcweZyoiJt8eh7Ex9uCjYa6CEiidQgdMAkepO7iLm3hk42cGq+wVlsiKyvjB4Glxf/Oqlr2XsW5iLmlo7qnWq05+As8NrxWPUpYqKhtt86b+FXzNiEeWimfXpTzu2rAqM8+USsosodW7VJm5ZdEZZK2ya40Iw/rtoKoeRrCBzbhP6a3FVdkGd+245N7PyYsYB/dVVx60SOnGIpKq39ezOGK7NjrvpRa4vnE9lOzA7upRT1EEHWoO6DybBQfV/n7Y6PGlgLzFtsiNVLPAzeY9k3wpoDeUGV0p8l6p1otKfgWZh2PBZzEjXRuAxsws00V5t2Tcw+m2seasNK9FW0Ua5WUeWOrTQ2yqb+ZlwqbJuQm21YVwi8Cd2vs3eh+vjA/HY/640F7HF0/Hc5JnluP6NVjJsweblxYC0evsyW1tXlKs4CMQtJDRF0DY5EvR3SWANrgbmLDXS9o4dhnfjMP7M7UHwlfFxKfzao906jPQfPwjTjsbg8vXbPpyxDqftG1a5qgcnpyu2mXBExyu0qaqaeOa+BKiUpCjWd1EKwC7De15m7yFRVvvntfdYdC2o2geuGq3qn9Mgjd77CmUHBLjpthp79zVo8bI7Z8eYRj5W9JWqIoGuwTelvwpMNzD0R9c2axYZIveOHETjxpXy72ox/+pVxSh1fqlGpW2+80Z6Ib2GaVuGDs92xVTMRx65iD8zuubrON8p6HhvlP/X25sSOrXyf6VIaMZ0khOB/nbkL3bye+e1/1h0LmMjZy9uRO1/Ovcl77q89e8kvA++s/vRnYj+azTF5tyBWJ8TbJLp+ugbhTKB/ls4bRayBHU/E1DoJRq6MeBiBE1+hrXXPh8iUejXQpW5DUI32VHwLU25HSxeX8UauMysx3V/idOXCsCKNcjG0OS5bYsdWvs90KY10ANZffB3SyBwgQJvf8c+Kgb5sbv0176vUvlNm58tbxeCya5Vp2iTpz9V+NH/6Ymxr1NokbyOyBmdrmktU3DF/WckGdj0RrcAi9QYPY+TEx79O1ls7PkS21KmBLnW+LtZozyWwMOV+q3BxCTZy+XLN6CXMeWeou3JuWH1FG+XSinFctpwdW7qUxHEAlkJIY1/nI8zvqc8KJclVk7q/1t80plxt27irGOLDF7mr6VlSTDNpK5ZppJJEp0vV4BjHRqLiZaXu3ngiCoHVTfTKRg/jMnbi018nXWi0D5Eu9V2sbOmoXqrRnm9uSIIF3jQ1Li7uRMNZrnGGPeni6fgbxYzyRA4AjsuWfoze2mqSTV+r4wCsWjv6dR5FMfFZ0dHwK7jKhZxU7vRwVwx326awFywuly8V58Jlzvbz7LNy4jlVgzPSu32gfVmdBvY8EcUt24rDekcPg3vxjZz4Pro+T8aHyN3RtjWksYdMNtpu8Bd4b53jOmMmMK6jvB32lIun15VHjHLvPInjskWurdKIjkIu7FohRL6OJPJZcwmOI3LTam+9YNvGfroemlK8EY7NxA1JNfRGa3Ddm90+0L6sxfCfZR2hJ2LqVRxeWfAwlBef78QX+jx5PkSRJUDiIdONthfcBV7emj8OPDFl0ypHec+u0i6e3pqRb5QrtKOut4pq3vJgbZVGdhRy4ui8U+TXxaogPps7y1a21rRtlSuGs20jV9XtrGxQPaljM/FNmoKs4RNHo9Zb2O0D5csqG1gsAdKeiKbiYEMpeBjGi89x4iN8nlwfInoJkHrIdKPtBrPAK0yopgw8Mb3NTiMl0V8aF88y7nUhG0VbMe4qqnnLg7VVGrXnJh2A7Wepr4sx/qxzwpMpqXN8A9VbLWzGbzvremo+nKRm7LU2Ux2poU48jQbewno7USyHyQYWS4BjT0S3YmdPbvwwbtaLzzjxfUX5PMnJYmwJkHzI0UbbC4W3rZn2f+x5YgabnWbqzTsV4+LpEnpdJK6jrl5F9eeYvntXiFgB1R3FaOJIfF2U0WedE56F39UYVwy+8yVW4d2DW/bDcZvJrYEN9Z5GPW9hc2vyMIMoE0uAoSdiULHZkyMextXx4pNOfBGfJyHo2BIg/ZDjjbYvtJ2c918bF5fRZmcqPXhUp5J6Lp4a3ygPfIhNm5TOWx67pLRLzQqo7ihGE8fAyWOS8LPqhKe4BHUVIp7E5aJcMfRgUjir6tIq8PZ4lM0krldeoFuDHOpdjZqRXrys5tb0y8pd1zKnG2XvAjfPRQAMp+Kph+F68QknPsrniXtY/ZfLaAnwzkMmGm1/1I6d7J2wDDY7lTOK7lQ8F0+NZ5SHPsSyUreTnXrLedeoVkDJ0WD0dXdwP+uc43UvgQ3Ldcnsz6Z3XDG6m+N6Kj7t7fEYm4l7i3Mr2atBuTf7Gv3Ff01N69hby8RKn3BdK51u9NZWbS2KvYqnHobnxZenuqk9n6fQwyq5+5DdY7F77p3ldFqbUPUnHbFnK5drlDOK7S8pmFEul0svhA+x/D5njjn5lrOuUTttkqOB+rrZ2M9653idS2CvcyYWlvtbY76Na9AuXQvnQG+PR9tM2ZAxK7ltnBrMUO9rtPlUNKPTOsZXU7qu6SVA8RU8apso9i4t9jCEXUt68bk+T5SH1Z2H7B+L3WXv3HXOqmSirz++Z2udUdK4oJlRngrHZ3vk2Trq0nPM6PXdzLooORqor5uN/SxxjtePJ3FRHzU9ubfMHezxaG68ikz9SdRgh3pXo9y9uXBapy1/KnwO+XtiXde83TcnAIa6tNjDSOWhM8+LT07ePJ8nysNq+iFTx2J3xoWNwWaqIkyon2aF+IXeWzXOKNH+UsEX3G/XhDhLTc0xQ2qzf9JnozOmq4md4w3iSXh+ebxTcmf/X432eNT18n8Txk1Q4vI1ys0Y2zrKE1G8J8p1rQnGylEADPJhmJ2fwItPecc5Pk8jD6tPVIwEql76WOwOYZ2HmaowE+rPymGQNzjaW5XvuHZGifaXGvaW8P49kCPlNU1g98PYUwxcI1dDnuMl4kl4fnnuoqAbA8cuzMsoetJKtosgclVLeQZyjX7jvKvONojaPxfbK47rmjtWugEwYg/DcW9WvXHhLPgnnlOZ72HV1jYg47he+rjtHuFr73aq8rFi0/GsLNQuq7e3KlvKOKPcqzjrLyJylC/HkUPtGBHXxuyH8ac4vQH4KOQRTyqehO+X53RKbgwco1019DgLYrbRtLi4Drx3VbbOf3P3z/l7Yod0b6x0RvrYw3Ddm4UXX9Tnianc9bCq3YCMo3rjx213hXhzWecxOuoqD0O7hpUZyIwzykS9Yj0+ufG5eMvdvP57KXf9x3NM4ppkXJuvzUbb/f2SBxkf8RzHkyD88mpH6OJCM2+PxyzcaCvZ9waVQ/34XRUvq++JyBvHvj3uWKmLJx6G694sVxZjPk9c5dbDyg/IOKqXOha7Q8SbyzsPM50ur+ZPV++wnnnJZzijqJ1c/oxSGZlKLP9GPIuDS9JxbcxG26b2GnWOdxxPgvbL4zav9HL3YuAobBQ9eb1hz8iG+ui76nsi8vfEDuneWFlPPQzavZmevOpXwnhY+QEZvXpjZ5/3hnnN+ZEhLRot6CsbcFLvvKMZA+87o+hNWt7LJx8zIdAi5r8bYOPa2FPT28WUIs/xEvEkCL+89Jf/46b3eLwYOEkQmkOHXQl6xqz/Ov6u+p6I+j1RU8EqGXtIjR9GzL05JSev+pUwHlZ+QEb3IUfPPu8N2320N2Pk31QLs56pbNR5x+BEzt3ldLOTm7Z52ok5JuvsI37BITaujd1o627JNpDneKl4EpRfXvnL1A9/YW6CDM0x9gaNvqsjT8TMrTYYK20Ad/EwPL+80L3ZcVAMF/ytM7q8uiAgo33IM2fxT8b3pHBisubqR/ZQ60LG6w5P5Ew6o4hOxW5S6zmm+Ieh/y6JE9dG74eltw0ELd7K8Yw0Fk+C8suzezz+Eg8VmsPtGbW8Yu8q6YmYeFNBO1Y6/aV8GK7PU+De7Doosg+nOvq6CfbOVJ4WZEDGrtCN9tX9WfzzCb31HYVVsotRYyFvJPpEToAXONGuxzfOvtxo3CRx4tqYrbpm/axQvZWjGWksngTlw+fs8YiPaL+NcWgOOSl2vEHlHdHvKu2JmLhTwcbEBjBTT+VPEvg8BSESXQfFVLlYuT6D4lWLBmRUjXZvFr8DIt76grovRdACefW8kUYncqgKvcCJdkQ2c0wumsB/l8aNa3PZrgndmOPGIY2NJtF4EtYv71tyj6fIjd+Gtb+9oyOeNygn8q6OPRH1GxFMBfmwaqaewmVu7POknZ5oB0WxN6l9Bu2rRgdk9Bpt39Yz7a2vqPnOSqmldLuNTuSMuYWBE82IbOeY7Ml8OyemDh3XZjX6rZRmQcFtIj2aiOscL6QYvzx6j4dVpP02xsHI9Fkr6w3KGb+rYchQ80llKnjVymHV9Jcp7fOU/s+fJFEHRW7gmM0+r38iwzSqRjuA9TztSVFntmdkn7i/8xwPnOjMMXn0xTmrFX5cm03u2DknJ82CrDEmajSehPDL+ya6x5M1jt+GP/aYjjFw3R69q6OQoRq7cWOrdYdVrtGIz1PyZ3+eRB0UueTtcXfn2NAoIKPbaD8/iPU84Ukh/67jdd/feY4GTnTmmLN3S724NuuRvZ1jKyRSjXo0ifrZ3MqpPZ6sdPw2uMvAz9SMy3VvDly3w3fVDxlayD2e0poKnlmvh1XdX9I+T+xSvnJ8nuxqjPH7DDf75GJXEKYxaLT9W8/3R5H0kZ3naODEYI45Ex3XZhPUK+W9lZkMPyhHk59Erq34OLXHkw6u3wYbe+SMK3BvDpDv6s+1Z60fMjSTXhuNc+hJDWneFqu72nDX54nZfn/eOkHZ+NMMY+vKPW03ICPdaHtDtMoMTwqFF697ChltZBw4MVG/u3PMd4aPm3Zi5B57FPsGajS5xq5teo+Ht4/nt8Ff45F7cwh/V41nre+ImDXWZUK/EWLdNNxiLdxLND5PhXZQ9HyewqBsFzf6OhWQUdgaZKPtBpn8UbXKvDWYaLxuAs/3NhnFnvTnmO+KHDfJkwjibb236hJbN5aZgEUSLeuBr2Zc1r15hmetPzvJSmNXfGveiKqJuPF67s3CmjOTV+PzJJ3t/KBspif3tyJ0QEY1HZ08vvF0qsZZpU/uXykdr5v+qPG9jUc8cueY74J/Is4f/1VaaqHGe5GM6XVjc+RZrI+Vneu5TaXBolCetf6QLoYN1eEIh3/lM0BvsXruzTLvnp68fq19nqjIZ3qMCQ51/uJ/uW02fXzjqRTKW9+0yow1GDJeN03oe7sL/BNxP3bGf3v+XqjxzqoLvW5sjjzXwtu08Fb1ZpxF4GO69qz1h/QqNx/hXYX2GQjceMfuzTrvngnYIeeukchn0o8gPNQZniK8d3zjSahWkX67slW+jVnPxWS8bvrZOL631/0E0AlOxDnjvz1/X/f3D3jSezz2IFQm+3dvVe/uNEqO6dqz1m9O/n0mmZ7jM+AuHY3dm43Pk40EIkdXMvKZ8iMID3WGpwjvHt94CqnrrW9aJdbnTsbrpmo33V24ff5k4scenVN52YI9njATcP2nP8sLJ0SSP+OiGUzE1dSmJleGkPTGkMn0PJ8B14135N5s567GTJR2BR35rEmprYhZR0Wfju+tf3fjORKvO0ZHnqnbAeRJu1Fa6rq93qvIrhurs9B+JmA21P/v/8OG+kc8t/WYLjxrTcwP1TPIYUPGlXR9Blxjf+zebOeuiZm8SruCjpJGbkXMPir6VDxv/YkpkMofTcfrphDqcMKN7MbakAQn4rgAiLTUaXPX7Nd7PCIGR3jk2RxFSGZ6brueiKljb9iewQ4bns9Aqo198myuM3fVATuUXUFGSfO3InTq8PlHRZ+J560fnwLVU/G6KXTqlP2FG5GLWf6JOKHGpefv5R6PjMERLH3ZoX6e57bviei5F5g3ywwbvs+AaXdzNtdxb3bz7pmAHerWiShpfioccyx29lHRZ+J768cg43Wrpqb/hVLHDsONyOmSfyJOqHHd+Xs5zgdHnp2hftpzW7rWjjwROSNDSA8bpM+AczbXC78q/yvy7gUOitrDSu5FBIc6P7rHYuccFX06vrd+9GlR8bon0erYWbgRe6bMO/Yo1Lju/L101g+8IJyhfspzW7vWhp6IEUNIQ/gMeGdz3fCrcf9EE/mMONTZNO6x2B3GLSeY5UlBx+uOIGbIRh37CjcSicGdmhjLy87fi35NjPP+kWd3qI97bhvX2sAT8Z4h5PsMxM/mJtP+ibdSbEVQhzpL71jsDuOWE8zzpCDjdUc+KmbINu/gftbqOOaRmPFYRY/hp4CXnr9X/ZowJrw1OTLF7gjHtdbzRLxrCEmfgY+dDek4OpurmfBPLD5GD3Xyztp59HuaCsWZ50lBxuum0DPk/UVn8I+O6mOPepDlalzkZ2MDdsgYHC4zjyI4rrXuwukMQ0j4DJQ2pOMlvqYW9U9MqUOd9f81pwjto99h3HKSBzwppnOceAeA9uaFFRwdlRdso8eM1TgLL2DHOEHXvKMI1rXWLJzycWO2IeSEdFywpkYe6nRPEUrupbc5GjNynAQHgPZFcHRU/ORFj7mXLi56z4k1fcdD8t2jCL5rrV44VePGHUNIOz11t2SuzxNB5FCnPUU4K73N4bif4yQ8ALQfRkdH1S350WMWGYhhwI4xd44iBK61ulY1bkwbQtrp6RvfvflB4oc61SnCWeltjsd0jpNkfABoN4yOjirui3G6QcSygh+w40Fo19rcnCS+Zwhpp6dftCuOjlCHOv1ThHcf/enwkpbvLdwINXJsIEa1rEAE7JjdahnlWivdNvS4ETOEpHuzdnr6pReZ+tHLIDZoyFOEr0OYtHxfk2Fi5FgvRhuRggjYMQshXMK1VhpCZtwgu0bt3my8QVeFXw23Iuy44Z8ifB2IpOVPpiAywDgjx1oxigxuOrjOwq0j62/ku9YqQ2hq3LA+T8bpac3+VbgVYcaNZlczoXeESFr+bMgMMOqQ7loxylhIZllh4daR9Teyq4jWEJocNxz3Zu30tCr8argVYQaLFxS0F6JlR8NTNAOMUOMaMeqohyvSurj+Ro5rrWsITY4bjs+TcXpaF35Vb0XYzSd+Yc1uHue7EYZo2QXCM4HKAGPUuOaCTdTDxcsKnr+R4xPnGUJTuO7Nyulpk/Cr3rHYXfn8vhs7jDaiDklSGWCsGldcsI16uHRZwfc3UsdBkgcMIdfnSTs9bRB+1VkP2uGRjDcnGqLluRjPBCqqvVXjMrcNa+MWM07Qko1GJj570Cqf5/P0+JXZlBkv2D1PhGh57nXpiwkzwKxXo2fj3j+cRUAnPnvYKn+D8Kuh28LrdM9TIVr2gPVM8DPArFejsXHdWEgPEUl89rhVvnn41f26Lbw58RAt+8DxTHCi2q9X4yVbvfJMJT7j48bHx63yjcOv7tdt4e2Jh2jZB45ngjFFmRhXqjFvymrdyjOd+EyHIk0etoO2C7/q5ufa0U7Ce7H3cCOuZ4Iq4WJcp8amunZDvmqxj058pkKRrrCDVuCF6NRX9nJLz7sPNxJ6JkgxrtkHkROGK3uTFy/2UUG3nXFjsVW+sqmcEJ0vaGwo9h5uJPRMUGJctVYuPIfY1G3x6uQ46LY/brz7UWJ9LJbIz/VCyNMVew83EngmaDGuWSsXC23NsGg49lxrzZAejBvvfJTYjVsa5ud6JYQb1gHCjXiHJNeIUSMW2pp2ye5y6Fqr2GLcWIx3LHb5CYdjYwIOHyPciE2GukKMNqEqnzC09ZK3IuJau8W4sRjvWOziEw4HJxKiZa84yVAXi9GpI20qprsH94OFJ2LEtXaLcWMx3rHYxSccDoyfa+MQ2/wmGepCMQZ1iEDCD4Y1k84BEdfaFePGevy4pUtOOBybINfG7sONCM817QAkLvphMY7ruLXVg/2Y7H795cItjJj1kHFLX4cw18azr+fe5QrPNZsMNVkgRqKOJHvwxrUnojvtW2vEbMSSXKcnIsy1sWu055rvAPSYGOk6HkFYzyZuop32rTRiNmNRrtNTMCPt974wnmsrYustrkN7IkrrOXAO2MCI2Yyn5jp9Jg+k/d4J68+TrKhDeSIq69lzDtjCiNmQJ+Y6fSbz037vhzUe/GvrUJ6IJpOfcQ5Yb8RszrvnOt0D89N+74c1Hvxr69CeiKNzPFsYQmAhZK6NA73NW3iuLaxDeyKOXGu3MITAUohcG4dii7n7wjqUJ+LYtXYLQwg8TizXxqHYYmX18To8T8SvQ9faLQwh8ChpNNcGuMsdT8QnufC/NGSujSNZz09jjifiC25iPBsy18azL+oQzPFEfMEt5mcTybUB7nMsT8RXIZ5rA8Tx43Xu3hPxlaBybYA7IF7nfnlxp8JFeMnisIqxM17XqXARkWRxYDe8rFPhImLJ4sB+eFGnwkW8cLzOI/GSToWLeOF4neBkxJLFAXAwhGstnSwOgANSNcmhPREB0GjXWngighPgxuuEJyI4Op5rLTwRwdHxXWvhiQgOjuda+4LhOsHJ8ON1whMRHJwXj9cJzgZca8G5gGstOBVwrQXnAq614GTAtRYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACA7fn/A6OnTBUicxYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjEtMDgtMDNUMDk6NTc6MzMrMDc6MDANczNRAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIxLTA4LTAzVDA5OjU3OjMzKzA3OjAwfC6L7QAAACF0RVh0cHM6SGlSZXNCb3VuZGluZ0JveAA1MDR4NzIwKzUwKzUw1uIiwwAAABN0RVh0cHM6TGV2ZWwAQWRvYmUtMi4wCjmTdA0AAAAASUVORK5CYII=" />

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
