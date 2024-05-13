package Bencher::Scenario::Accessors::GeneratorStartup;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Accessors'; # DIST
our $VERSION = '0.151'; # VERSION

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

This document describes version 0.151 of Bencher::Scenario::Accessors::GeneratorStartup (from Perl distribution Bencher-ScenarioBundle-Accessors), released on 2024-05-06.

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

L<Simple::Accessor> 1.13

=head1 BENCHMARK PARTICIPANTS

=over

=item * Class::Tiny (perl_code)

L<Class::Tiny>



=item * Class::Accessor::Array (perl_code)

L<Class::Accessor::Array>



=item *  (perl_code)



=item * Mojo::Base (perl_code)

L<Mojo::Base>



=item * Object::Tiny::RW::XS (perl_code)

L<Object::Tiny::RW::XS>



=item * Class::XSAccessor (perl_code)

L<Class::XSAccessor>



=item * Moops (perl_code)

L<Moops>



=item * Class::InsideOut (perl_code)

L<Class::InsideOut>



=item * Moos (perl_code)

L<Moos>



=item *  (perl_code)



=item * Class::Accessor::PackedString (perl_code)

L<Class::Accessor::PackedString>



=item * Object::Tiny::RW (perl_code)

L<Object::Tiny::RW>



=item * Simple::Accessor (perl_code)

L<Simple::Accessor>



=item * Object::Tiny::XS (perl_code)

L<Object::Tiny::XS>



=item * Object::Simple (perl_code)

L<Object::Simple>



=item * Mouse (perl_code)

L<Mouse>



=item * Mojo::Base::XS (perl_code)

L<Mojo::Base::XS>



=item * Class::Struct (perl_code)

L<Class::Struct>



=item *  (perl_code)



=item * Class::Accessor (perl_code)

L<Class::Accessor>



=item * Moo (perl_code)

L<Moo>



=item * Class::Accessor::PackedString::Set (perl_code)

L<Class::Accessor::PackedString::Set>



=item * Class::XSAccessor::Array (perl_code)

L<Class::XSAccessor::Array>



=item * Moose (perl_code)

L<Moose>



=item * Mo (perl_code)

L<Mo>



=item * Object::Tiny (perl_code)

L<Object::Tiny>



=item * Object::Pad (perl_code)

L<Object::Pad>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Accessors::GeneratorStartup

Result formatted as table:

 #table1#
 +------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                        | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Moose                              |    140    |            132    |                 0.00% |              1757.20% |   0.00015 |      20 |
 | Mojo::Base                         |    113    |            105    |                20.95% |              1435.54% | 3.5e-05   |      20 |
 | Moops                              |     59    |             51    |               131.64% |               701.77% | 3.2e-05   |      20 |
 | Mouse                              |     26.6  |             18.6  |               415.00% |               260.62% | 2.5e-05   |      20 |
 | Moos                               |     20    |             12    |               595.88% |               166.89% | 2.2e-05   |      20 |
 | Object::Pad                        |     19.6  |             11.6  |               596.93% |               166.48% | 1.9e-05   |      20 |
 | Moo                                |     18    |             10    |               654.42% |               146.18% | 2.6e-05   |      20 |
 | Class::InsideOut                   |     17.7  |              9.7  |               671.85% |               140.62% | 1.7e-05   |      20 |
 | Object::Tiny::XS                   |     17    |              9    |               704.23% |               130.93% | 1.1e-05   |      20 |
 | Object::Simple                     |     16    |              8    |               732.29% |               123.14% | 7.5e-05   |      25 |
 | Class::Struct                      |     14.6  |              6.6  |               835.18% |                98.59% | 1.3e-05   |      21 |
 | Class::XSAccessor::Array           |     14.4  |              6.4  |               850.01% |                95.49% | 1.2e-05   |      20 |
 | Class::Tiny                        |     14    |              6    |               850.03% |                95.49% | 1.5e-05   |      21 |
 | Object::Tiny::RW::XS               |     14.2  |              6.2  |               860.08% |                93.44% | 7.3e-06   |      21 |
 | Class::XSAccessor                  |     14    |              6    |               873.11% |                90.85% | 2.5e-05   |      20 |
 | Class::Accessor                    |     14    |              6    |               874.92% |                90.50% | 1.5e-05   |      21 |
 | Mojo::Base::XS                     |     10.9  |              2.9  |              1155.66% |                47.91% | 8.5e-06   |      20 |
 | Simple::Accessor                   |     11    |              3    |              1155.96% |                47.87% | 8.3e-05   |      20 |
 | Class::Accessor::PackedString      |      9.35 |              1.35 |              1361.77% |                27.05% | 6.9e-06   |      20 |
 | Mo                                 |      9.3  |              1.3  |              1369.24% |                26.41% | 1.2e-05   |      20 |
 | perl -e1 (baseline)                |      8    |              0    |              1517.77% |                14.80% |   0.00017 |      21 |
 | Object::Tiny::RW                   |      7.73 |             -0.27 |              1669.41% |                 4.96% | 5.9e-06   |      20 |
 | Object::Tiny                       |      7.68 |             -0.32 |              1680.29% |                 4.32% | 3.7e-06   |      20 |
 | Class::Accessor::PackedString::Set |      7.47 |             -0.53 |              1730.04% |                 1.48% | 6.1e-06   |      21 |
 | Class::Accessor::Array             |      7.36 |             -0.64 |              1757.20% |                 0.00% | 6.8e-06   |      20 |
 +------------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                         Rate  Moose  Mojo::Base  Moops  Mouse  Moos  Object::Pad   Moo  Class::InsideOut  Object::Tiny::XS  Object::Simple  Class::Struct  Class::XSAccessor::Array  Object::Tiny::RW::XS  Class::Tiny  Class::XSAccessor  Class::Accessor  Simple::Accessor  Mojo::Base::XS  Class::Accessor::PackedString    Mo  perl -e1 (baseline)  Object::Tiny::RW  Object::Tiny  Class::Accessor::PackedString::Set  Class::Accessor::Array 
  Moose                                 7.1/s     --        -19%   -57%   -81%  -85%         -86%  -87%              -87%              -87%            -88%           -89%                      -89%                  -89%         -90%               -90%             -90%              -92%            -92%                           -93%  -93%                 -94%              -94%          -94%                                -94%                    -94% 
  Mojo::Base                            8.8/s    23%          --   -47%   -76%  -82%         -82%  -84%              -84%              -84%            -85%           -87%                      -87%                  -87%         -87%               -87%             -87%              -90%            -90%                           -91%  -91%                 -92%              -93%          -93%                                -93%                    -93% 
  Moops                                16.9/s   137%         91%     --   -54%  -66%         -66%  -69%              -70%              -71%            -72%           -75%                      -75%                  -75%         -76%               -76%             -76%              -81%            -81%                           -84%  -84%                 -86%              -86%          -86%                                -87%                    -87% 
  Mouse                                37.6/s   426%        324%   121%     --  -24%         -26%  -32%              -33%              -36%            -39%           -45%                      -45%                  -46%         -47%               -47%             -47%              -58%            -59%                           -64%  -65%                 -69%              -70%          -71%                                -71%                    -72% 
  Moos                                 50.0/s   600%        465%   195%    33%    --          -1%   -9%              -11%              -15%            -19%           -27%                      -28%                  -29%         -30%               -30%             -30%              -44%            -45%                           -53%  -53%                 -60%              -61%          -61%                                -62%                    -63% 
  Object::Pad                          51.0/s   614%        476%   201%    35%    2%           --   -8%               -9%              -13%            -18%           -25%                      -26%                  -27%         -28%               -28%             -28%              -43%            -44%                           -52%  -52%                 -59%              -60%          -60%                                -61%                    -62% 
  Moo                                  55.6/s   677%        527%   227%    47%   11%           8%    --               -1%               -5%            -11%           -18%                      -19%                  -21%         -22%               -22%             -22%              -38%            -39%                           -48%  -48%                 -55%              -57%          -57%                                -58%                    -59% 
  Class::InsideOut                     56.5/s   690%        538%   233%    50%   12%          10%    1%                --               -3%             -9%           -17%                      -18%                  -19%         -20%               -20%             -20%              -37%            -38%                           -47%  -47%                 -54%              -56%          -56%                                -57%                    -58% 
  Object::Tiny::XS                     58.8/s   723%        564%   247%    56%   17%          15%    5%                4%                --             -5%           -14%                      -15%                  -16%         -17%               -17%             -17%              -35%            -35%                           -45%  -45%                 -52%              -54%          -54%                                -56%                    -56% 
  Object::Simple                       62.5/s   775%        606%   268%    66%   25%          22%   12%               10%                6%              --            -8%                       -9%                  -11%         -12%               -12%             -12%              -31%            -31%                           -41%  -41%                 -50%              -51%          -52%                                -53%                    -54% 
  Class::Struct                        68.5/s   858%        673%   304%    82%   36%          34%   23%               21%               16%              9%             --                       -1%                   -2%          -4%                -4%              -4%              -24%            -25%                           -35%  -36%                 -45%              -47%          -47%                                -48%                    -49% 
  Class::XSAccessor::Array             69.4/s   872%        684%   309%    84%   38%          36%   25%               22%               18%             11%             1%                        --                   -1%          -2%                -2%              -2%              -23%            -24%                           -35%  -35%                 -44%              -46%          -46%                                -48%                    -48% 
  Object::Tiny::RW::XS                 70.4/s   885%        695%   315%    87%   40%          38%   26%               24%               19%             12%             2%                        1%                    --          -1%                -1%              -1%              -22%            -23%                           -34%  -34%                 -43%              -45%          -45%                                -47%                    -48% 
  Class::Tiny                          71.4/s   900%        707%   321%    90%   42%          40%   28%               26%               21%             14%             4%                        2%                    1%           --                 0%               0%              -21%            -22%                           -33%  -33%                 -42%              -44%          -45%                                -46%                    -47% 
  Class::XSAccessor                    71.4/s   900%        707%   321%    90%   42%          40%   28%               26%               21%             14%             4%                        2%                    1%           0%                 --               0%              -21%            -22%                           -33%  -33%                 -42%              -44%          -45%                                -46%                    -47% 
  Class::Accessor                      71.4/s   900%        707%   321%    90%   42%          40%   28%               26%               21%             14%             4%                        2%                    1%           0%                 0%               --              -21%            -22%                           -33%  -33%                 -42%              -44%          -45%                                -46%                    -47% 
  Simple::Accessor                     90.9/s  1172%        927%   436%   141%   81%          78%   63%               60%               54%             45%            32%                       30%                   29%          27%                27%              27%                --              0%                           -15%  -15%                 -27%              -29%          -30%                                -32%                    -33% 
  Mojo::Base::XS                       91.7/s  1184%        936%   441%   144%   83%          79%   65%               62%               55%             46%            33%                       32%                   30%          28%                28%              28%                0%              --                           -14%  -14%                 -26%              -29%          -29%                                -31%                    -32% 
  Class::Accessor::PackedString       107.0/s  1397%       1108%   531%   184%  113%         109%   92%               89%               81%             71%            56%                       54%                   51%          49%                49%              49%               17%             16%                             --    0%                 -14%              -17%          -17%                                -20%                    -21% 
  Mo                                  107.5/s  1405%       1115%   534%   186%  115%         110%   93%               90%               82%             72%            56%                       54%                   52%          50%                50%              50%               18%             17%                             0%    --                 -13%              -16%          -17%                                -19%                    -20% 
  perl -e1 (baseline)                 125.0/s  1650%       1312%   637%   232%  150%         145%  125%              121%              112%            100%            82%                       80%                   77%          75%                75%              75%               37%             36%                            16%   16%                   --               -3%           -4%                                 -6%                     -7% 
  Object::Tiny::RW                    129.4/s  1711%       1361%   663%   244%  158%         153%  132%              128%              119%            106%            88%                       86%                   83%          81%                81%              81%               42%             41%                            20%   20%                   3%                --            0%                                 -3%                     -4% 
  Object::Tiny                        130.2/s  1722%       1371%   668%   246%  160%         155%  134%              130%              121%            108%            90%                       87%                   84%          82%                82%              82%               43%             41%                            21%   21%                   4%                0%            --                                 -2%                     -4% 
  Class::Accessor::PackedString::Set  133.9/s  1774%       1412%   689%   256%  167%         162%  140%              136%              127%            114%            95%                       92%                   90%          87%                87%              87%               47%             45%                            25%   24%                   7%                3%            2%                                  --                     -1% 
  Class::Accessor::Array              135.9/s  1802%       1435%   701%   261%  171%         166%  144%              140%              130%            117%            98%                       95%                   92%          90%                90%              90%               49%             48%                            27%   26%                   8%                5%            4%                                  1%                      -- 
 
 Legends:
   Class::Accessor: mod_overhead_time=6 participant=Class::Accessor
   Class::Accessor::Array: mod_overhead_time=-0.64 participant=Class::Accessor::Array
   Class::Accessor::PackedString: mod_overhead_time=1.35 participant=Class::Accessor::PackedString
   Class::Accessor::PackedString::Set: mod_overhead_time=-0.53 participant=Class::Accessor::PackedString::Set
   Class::InsideOut: mod_overhead_time=9.7 participant=Class::InsideOut
   Class::Struct: mod_overhead_time=6.6 participant=Class::Struct
   Class::Tiny: mod_overhead_time=6 participant=Class::Tiny
   Class::XSAccessor: mod_overhead_time=6 participant=Class::XSAccessor
   Class::XSAccessor::Array: mod_overhead_time=6.4 participant=Class::XSAccessor::Array
   Mo: mod_overhead_time=1.3 participant=Mo
   Mojo::Base: mod_overhead_time=105 participant=Mojo::Base
   Mojo::Base::XS: mod_overhead_time=2.9 participant=Mojo::Base::XS
   Moo: mod_overhead_time=10 participant=Moo
   Moops: mod_overhead_time=51 participant=Moops
   Moos: mod_overhead_time=12 participant=Moos
   Moose: mod_overhead_time=132 participant=Moose
   Mouse: mod_overhead_time=18.6 participant=Mouse
   Object::Pad: mod_overhead_time=11.6 participant=Object::Pad
   Object::Simple: mod_overhead_time=8 participant=Object::Simple
   Object::Tiny: mod_overhead_time=-0.32 participant=Object::Tiny
   Object::Tiny::RW: mod_overhead_time=-0.27 participant=Object::Tiny::RW
   Object::Tiny::RW::XS: mod_overhead_time=6.2 participant=Object::Tiny::RW::XS
   Object::Tiny::XS: mod_overhead_time=9 participant=Object::Tiny::XS
   Simple::Accessor: mod_overhead_time=3 participant=Simple::Accessor
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

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
