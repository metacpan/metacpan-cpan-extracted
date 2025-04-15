package Acme::CPANModules::OrderedHash;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-04-15'; # DATE
our $DIST = 'Acme-CPANModules-OrderedHash'; # DIST
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => "List of modules that provide ordered hash data type",
    description => <<'MARKDOWN',

When you ask a Perl's hash for the list of keys, the answer comes back
unordered. In fact, Perl explicitly randomizes the order of keys it returns
everytime. The random ordering is a (security) feature, not a bug. However,
sometimes you want to know the order of insertion. These modules provide you
with an ordered hash; most of them implement it by recording the order of
insertion of keys in an additional array.

Other related modules:

<pm:Tie::SortHash> - will automatically sort keys when you call `keys()`,
`values()`, `each()`. But this module does not maintain insertion order.

MARKDOWN
    entries => [

        {
            module => 'Tie::IxHash',
            bench_code => sub {
                my ($op, $numkeys, $numrep) = @_;

                tie my %hash, "Tie::IxHash";
                for (1..$numkeys) { $hash{"key$_"} = $_ }

                if ($op eq 'delete') {
                    for (1..$numkeys) { delete $hash{"key$_"} }
                } elsif ($op eq 'keys') {
                    for (1..$numrep) { my @keys = keys %hash }
                } elsif ($op eq 'iterate') {
                    for (1..$numrep) { while (my ($k,$v) = each %hash) {} }
                }
            },
        },

        {
            module => 'Hash::Ordered',
            bench_code => sub {
                my ($op, $numkeys, $numrep) = @_;

                my $hash = Hash::Ordered->new;
                for (1..$numkeys) { $hash->set("key$_" => $_) }

                if ($op eq 'delete') {
                    for (1..$numkeys) { $hash->delete("key$_") }
                } elsif ($op eq 'keys') {
                    for (1..$numrep) { my @keys = $hash->keys }
                } elsif ($op eq 'iterate') {
                    for (1..$numrep) { my $iter = $hash->iterator; while (my ($k,$v) = $iter->()) {} }
                }
            },
        },

        {
            module => 'Tie::Hash::Indexed',
            description => <<'MARKDOWN',

Provides two interfaces: tied hash and OO.

MARKDOWN
            bench_code => sub {
                my ($op, $numkeys, $numrep) = @_;

                tie my %hash, "Tie::Hash::Indexed";
                for (1..$numkeys) { $hash{"key$_"} = $_ }

                if ($op eq 'delete') {
                    for (1..$numkeys) { delete $hash{"key$_"} }
                } elsif ($op eq 'keys') {
                    for (1..$numrep) { my @keys = keys %hash }
                } elsif ($op eq 'iterate') {
                    for (1..$numrep) { while (my ($k,$v) = each %hash) {} }
                }
            },
        },

        {
            module => 'Tie::LLHash',
            bench_code => sub {
                my ($op, $numkeys, $numrep) = @_;

                tie my %hash, "Tie::LLHash";
                for (1..$numkeys) { (tied %hash)->insert("key$_" => $_) }

                if ($op eq 'delete') {
                    for (1..$numkeys) { delete $hash{"key$_"} }
                } elsif ($op eq 'keys') {
                    for (1..$numrep) { my @keys = keys %hash }
                } elsif ($op eq 'iterate') {
                    for (1..$numrep) { while (my ($k,$v) = each %hash) {} }
                }
            },
        },

        {
            module => 'Tie::StoredOrderHash',
            bench_code => sub {
                my ($op, $numkeys, $numrep) = @_;

                tie my %hash, "Tie::StoredOrderHash";
                for (1..$numkeys) { $hash{"key$_"} = $_ }

                if ($op eq 'delete') {
                    for (1..$numkeys) { delete $hash{"key$_"} }
                } elsif ($op eq 'keys') {
                    for (1..$numrep) { my @keys = keys %hash }
                } elsif ($op eq 'iterate') {
                    for (1..$numrep) { while (my ($k,$v) = each %hash) {} }
                }
            },
        },

        {
            module => 'Array::OrdHash',
            description => <<'MARKDOWN',

Provide something closest to PHP's associative array, where you can refer
elements by key or by numeric index, and insertion order is remembered.

MARKDOWN
            bench_code => sub {
                my ($op, $numkeys, $numrep) = @_;

                my $hash = Array::OrdHash->new;
                for (1..$numkeys) { $hash->{"key$_"} = $_ }

                if ($op eq 'delete') {
                    for (1..$numkeys) { delete $hash->{"key$_"} }
                } elsif ($op eq 'keys') {
                    for (1..$numrep) { my @keys = keys %$hash }
                } elsif ($op eq 'iterate') {
                    for (1..$numrep) { while (my ($k,$v) = each %$hash) {} }
                }
            },
        },

        {
            module => 'List::Unique::DeterministicOrder',
            description => <<'MARKDOWN',

Provide a list, not hash.

MARKDOWN
            bench_tags => ["no_iterate"].
            bench_code => sub {
                my ($op, $numkeys, $numrep) = @_;

                my $hash = List::Unique::DeterministicOrder->new(data=>[]);
                for (1..$numkeys) { $hash->push("key$_") }

                if ($op eq 'delete') {
                    for (1..$numkeys) { $hash->delete("key$_") }
                } elsif ($op eq 'keys') {
                    for (1..$numrep) { my @keys = $hash->keys }
                } elsif ($op eq 'iterate') {
                    for (1..$numrep) { while (my ($k,$v) = each %$hash) {} }
                }
            },
        },

        {
            module => 'Tree::RB::XS',
            description => <<'MARKDOWN',

Multi-purpose tree data structure which can record insertion order and act as an
ordered hash. Use `track_recent => 1, keys_in_recent_order => 1` options. Can
be used as a tied hash, or as an object (faster).

MARKDOWN
            bench_code => sub {
                my ($op, $numkeys, $numrep) = @_;

                my $tree= Tree::RB::XS->new(compare_fn => 'str', track_recent => 1, keys_in_recent_order => 1);
                for (1..$numkeys) { $tree->insert("key$_") }

                if ($op eq 'delete') {
                    for (1..$numkeys) { $tree->delete("key$_") }
                } elsif ($op eq 'keys') {
                    for (1..$numrep) { my @keys= $tree->keys }
                } elsif ($op eq 'iterate') {
                    for (1..$numrep) { my $iter = $tree->iter; while (my $v = $iter->next) {} }
                }
            },
        },
    ],

    bench_datasets => [
        {name=>'insert 1000 pairs', argv => ['insert', 1000]},
        {name=>'insert 1000 pairs + delete', argv => ['delete', 1000]},
        {name=>'insert 1000 pairs + return keys 100 times', argv => ['keys', 1000, 100]},
        {name=>'insert 1000 pairs + iterate 10 times', argv => ['iterate', 1000, 10], exclude_participant_tags => ['no_iterate']},
    ],
};

1;
# ABSTRACT: List of modules that provide ordered hash data type

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::OrderedHash - List of modules that provide ordered hash data type

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::OrderedHash (from Perl distribution Acme-CPANModules-OrderedHash), released on 2025-04-15.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module OrderedHash

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module OrderedHash

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

When you ask a Perl's hash for the list of keys, the answer comes back
unordered. In fact, Perl explicitly randomizes the order of keys it returns
everytime. The random ordering is a (security) feature, not a bug. However,
sometimes you want to know the order of insertion. These modules provide you
with an ordered hash; most of them implement it by recording the order of
insertion of keys in an additional array.

Other related modules:

L<Tie::SortHash> - will automatically sort keys when you call C<keys()>,
C<values()>, C<each()>. But this module does not maintain insertion order.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Tie::IxHash>

=item L<Hash::Ordered>

=item L<Tie::Hash::Indexed>

Provides two interfaces: tied hash and OO.


=item L<Tie::LLHash>

=item L<Tie::StoredOrderHash>

=item L<Array::OrdHash>

Provide something closest to PHP's associative array, where you can refer
elements by key or by numeric index, and insertion order is remembered.


=item L<List::Unique::DeterministicOrder>

Provide a list, not hash.


=item L<Tree::RB::XS>

Multi-purpose tree data structure which can record insertion order and act as an
ordered hash. Use C<< track_recent =E<gt> 1, keys_in_recent_order =E<gt> 1 >> options. Can
be used as a tied hash, or as an object (faster).


=back

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Tie::IxHash> 1.23

L<Hash::Ordered> 0.014

L<Tie::Hash::Indexed> 0.08

L<Tie::LLHash> 1.004

L<Tie::StoredOrderHash> 0.22

L<Array::OrdHash> 1.03

L<Tree::RB::XS> 0.19

=head1 BENCHMARK PARTICIPANTS

=over

=item * Tie::IxHash (perl_code)

L<Tie::IxHash>



=item * Hash::Ordered (perl_code)

L<Hash::Ordered>



=item * Tie::Hash::Indexed (perl_code)

L<Tie::Hash::Indexed>



=item * Tie::LLHash (perl_code)

L<Tie::LLHash>



=item * Tie::StoredOrderHash (perl_code)

L<Tie::StoredOrderHash>



=item * Array::OrdHash (perl_code)

L<Array::OrdHash>



=item * Tree::RB::XS (perl_code)

L<Tree::RB::XS>



=back

=head1 BENCHMARK DATASETS

=over

=item * insert 1000 pairs

=item * insert 1000 pairs + delete

=item * insert 1000 pairs + return keys 100 times

=item * insert 1000 pairs + iterate 10 times

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.40.1 >>, CPU: I<< AMD Ryzen 5 7535HS with Radeon Graphics (6 cores) >>, OS: I<< GNU/Linux Ubuntu version 24.10 >>, OS kernel: I<< Linux version 6.11.0-8-generic >>.

Benchmark command (default options):

 % bencher --cpanmodules-module OrderedHash

Result formatted as table (split, part 1 of 4):

 #table1#
 {dataset=>"insert 1000 pairs"}
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant          | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Tie::StoredOrderHash |       539 |     1.85  |                 0.00% |               528.45% | 1.4e-06 |      22 |
 | Tie::LLHash          |       640 |     1.6   |                19.19% |               427.28% | 3.4e-06 |      20 |
 | Array::OrdHash       |       889 |     1.12  |                64.84% |               281.24% | 9.6e-07 |      20 |
 | Tie::IxHash          |      1080 |     0.928 |                99.73% |               214.65% | 6.1e-07 |      20 |
 | Hash::Ordered        |      1460 |     0.684 |               170.98% |               131.92% | 4.1e-07 |      20 |
 | Tie::Hash::Indexed   |      1600 |     0.62  |               196.91% |               111.67% | 9.6e-07 |      20 |
 | Tree::RB::XS         |      3400 |     0.3   |               528.45% |                 0.00% | 5.4e-07 |      21 |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

          Rate   T:S   T:L   A:O   T:I   H:O  TH:I  TR:X 
  T:S    539/s    --  -13%  -39%  -49%  -63%  -66%  -83% 
  T:L    640/s   15%    --  -29%  -42%  -57%  -61%  -81% 
  A:O    889/s   65%   42%    --  -17%  -38%  -44%  -73% 
  T:I   1080/s   99%   72%   20%    --  -26%  -33%  -67% 
  H:O   1460/s  170%  133%   63%   35%    --   -9%  -56% 
  TH:I  1600/s  198%  158%   80%   49%   10%    --  -51% 
  TR:X  3400/s  516%  433%  273%  209%  128%  106%    -- 
 
 Legends:
   A:O: participant=Array::OrdHash
   H:O: participant=Hash::Ordered
   T:I: participant=Tie::IxHash
   T:L: participant=Tie::LLHash
   T:S: participant=Tie::StoredOrderHash
   TH:I: participant=Tie::Hash::Indexed
   TR:X: participant=Tree::RB::XS

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


Result formatted as table (split, part 2 of 4):

 #table2#
 {dataset=>"insert 1000 pairs + delete"}
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant          | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Tie::IxHash          |        31 |    32     |                 0.00% |              5838.76% | 4.8e-05 |      21 |
 | Tie::StoredOrderHash |       310 |     3.3   |               875.00% |               509.10% | 8.6e-06 |      21 |
 | Tie::LLHash          |       376 |     2.66  |              1098.31% |               395.59% | 2.5e-06 |      20 |
 | Array::OrdHash       |       440 |     2.3   |              1289.81% |               327.31% | 6.1e-06 |      20 |
 | Hash::Ordered        |       610 |     1.6   |              1854.01% |               203.93% | 1.9e-06 |      20 |
 | Tie::Hash::Indexed   |      1060 |     0.946 |              3272.21% |                76.11% | 5.7e-07 |      20 |
 | Tree::RB::XS         |      1900 |     0.54  |              5838.76% |                 0.00% | 6.3e-07 |      20 |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

          Rate    T:I   T:S   T:L   A:O   H:O  TH:I  TR:X 
  T:I     31/s     --  -89%  -91%  -92%  -95%  -97%  -98% 
  T:S    310/s   869%    --  -19%  -30%  -51%  -71%  -83% 
  T:L    376/s  1103%   24%    --  -13%  -39%  -64%  -79% 
  A:O    440/s  1291%   43%   15%    --  -30%  -58%  -76% 
  H:O    610/s  1900%  106%   66%   43%    --  -40%  -66% 
  TH:I  1060/s  3282%  248%  181%  143%   69%    --  -42% 
  TR:X  1900/s  5825%  511%  392%  325%  196%   75%    -- 
 
 Legends:
   A:O: participant=Array::OrdHash
   H:O: participant=Hash::Ordered
   T:I: participant=Tie::IxHash
   T:L: participant=Tie::LLHash
   T:S: participant=Tie::StoredOrderHash
   TH:I: participant=Tie::Hash::Indexed
   TR:X: participant=Tree::RB::XS

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


Result formatted as table (split, part 3 of 4):

 #table3#
 {dataset=>"insert 1000 pairs + iterate 10 times"}
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant          | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Tie::StoredOrderHash |      71   |     14    |                 0.00% |               508.52% |   2e-05 |      20 |
 | Tie::LLHash          |      75.4 |     13.3  |                 5.52% |               476.69% | 1.2e-05 |      24 |
 | Array::OrdHash       |      87.2 |     11.5  |                22.04% |               398.65% |   1e-05 |      20 |
 | Tie::IxHash          |     107   |      9.36 |                49.51% |               307.02% | 2.5e-06 |      20 |
 | Tie::Hash::Indexed   |     171   |      5.85 |               139.18% |               154.42% |   5e-06 |      21 |
 | Hash::Ordered        |     250   |      4    |               250.17% |                73.78% | 6.1e-06 |      20 |
 | Tree::RB::XS         |     435   |      2.3  |               508.52% |                 0.00% | 8.2e-07 |      20 |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

          Rate   T:S   T:L   A:O   T:I  TH:I   H:O  TR:X 
  T:S     71/s    --   -4%  -17%  -33%  -58%  -71%  -83% 
  T:L   75.4/s    5%    --  -13%  -29%  -56%  -69%  -82% 
  A:O   87.2/s   21%   15%    --  -18%  -49%  -65%  -80% 
  T:I    107/s   49%   42%   22%    --  -37%  -57%  -75% 
  TH:I   171/s  139%  127%   96%   60%    --  -31%  -60% 
  H:O    250/s  250%  232%  187%  134%   46%    --  -42% 
  TR:X   435/s  508%  478%  400%  306%  154%   73%    -- 
 
 Legends:
   A:O: participant=Array::OrdHash
   H:O: participant=Hash::Ordered
   T:I: participant=Tie::IxHash
   T:L: participant=Tie::LLHash
   T:S: participant=Tie::StoredOrderHash
   TH:I: participant=Tie::Hash::Indexed
   TR:X: participant=Tree::RB::XS

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


Result formatted as table (split, part 4 of 4):

 #table4#
 {dataset=>"insert 1000 pairs + return keys 100 times"}
 +----------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant          | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +----------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Tie::StoredOrderHash |      17   |     58    |                 0.00% |              1439.14% | 6.1e-05   |      20 |
 | Tie::LLHash          |      20   |     50    |                16.39% |              1222.37% | 7.3e-05   |      20 |
 | Array::OrdHash       |      25   |     40    |                44.54% |               964.81% |   0.00011 |      21 |
 | Tie::IxHash          |      26.8 |     37.3  |                54.99% |               893.08% | 3.3e-05   |      20 |
 | Tie::Hash::Indexed   |      44   |     23    |               154.54% |               504.67% | 2.7e-05   |      20 |
 | Hash::Ordered        |     135   |      7.43 |               678.48% |                97.71% | 7.1e-06   |      20 |
 | Tree::RB::XS         |     270   |      3.8  |              1439.14% |                 0.00% | 4.3e-06   |      20 |
 +----------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

          Rate    T:S    T:L   A:O   T:I  TH:I   H:O  TR:X 
  T:S     17/s     --   -13%  -31%  -35%  -60%  -87%  -93% 
  T:L     20/s    15%     --  -19%  -25%  -54%  -85%  -92% 
  A:O     25/s    44%    25%    --   -6%  -42%  -81%  -90% 
  T:I   26.8/s    55%    34%    7%    --  -38%  -80%  -89% 
  TH:I    44/s   152%   117%   73%   62%    --  -67%  -83% 
  H:O    135/s   680%   572%  438%  402%  209%    --  -48% 
  TR:X   270/s  1426%  1215%  952%  881%  505%   95%    -- 
 
 Legends:
   A:O: participant=Array::OrdHash
   H:O: participant=Hash::Ordered
   T:I: participant=Tie::IxHash
   T:L: participant=Tie::LLHash
   T:S: participant=Tie::StoredOrderHash
   TH:I: participant=Tie::Hash::Indexed
   TR:X: participant=Tree::RB::XS

The above result presented as chart:

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAADMUExURf///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJQA1JQA1JUA1ZUA1QAAAAAAAJQA1JQA1JQA1JYA15UA1pgA2pUA1ZQA1JQA1JQA1JUA1gAAADEARxYAHzkAUkIAXz4AWSQANEEAXg0AExsAJhsAJhoAJgYACA8AFhkAJBQAHAgACxUAHwAAAAAAAJQA1EUAY////2X7OMoAAABAdFJOUwARRDOIu8x3ImbdqplV7nDO1cfSP/r27PH59HVEM/XsvtoRIscwdSCn3/qjXOHr1fL7+OD68vj5+e/z+PXw9lvaVSXcAAAAAWJLR0QAiAUdSAAAAAlwSFlzAAAASAAAAEgARslrPgAAAAd0SU1FB+kEDwgLByP/S6wAABGgSURBVHja7dwNm6vGeYDhYZhBgBBNYsdxbaeOm48mTdK0aZuPNm0m/f8/qgxCWu25VucsYngHvTz3dWXZ4z15LcGzaGC1NgYAAAAAAAAAAAAAAAAAAADAugo7fWKLV/+8zP3AgPcrr/XaMH0S7O1fcD73QwTez1/rfTtoGwgaz6OsDrVpnLMx3eIQt2PQ1rk6fr1ojwSN59G0nfWt68JpCLrtuuDGoA/98I+a4etHx5IDz2RYcvjhss+5IeiDMYdQDEHX8SR96IfeK9bQeCrjGro8VW5aQw8pB9u01tpTKOu2JGg8lSFoF3znXwXteh+VrhpWHO15NQ08A29PfT0tOYrhIjCUQ9Cn1oz3pYdLQ4LGU/Gnpo03M2LQnTFdG0/SRT9cELpq/AssOfBMju3fVa1vu76xVVW1fTmuOpq+qvrzjwgJGs+ksLWxtjA2rivs9afehbVLpgIAAAAAAAAAAAAA3qXpQ/DxDWI+xN+zmDbAcyr6g6nbzhh/LOrh82kDPKfx/ejOmzqUxhyqaZP7UQEPGv+7KMfuHLYN0yb3owIe56u2MPH96UPJ0+b6te99f/QDYG2fjal99vnioO2hd+dlhg3T5vq18MMvoh+l8cWXiQaNvkz1sM7+fsPTdrHjvhpTC18nOEefwr0lR5LxVy7p291t2rsxaX+lJO20He24pcWNvxo0FFyHOv73UqZNsvEf/Mv2c1wI+kFLi7Pxtkb8nc5qeJbeXTapxr+2o+NC0A9aXFwXfNsOUZd91VbFZZNs/Cs7Oi4E/aDlxdXTL3JOv9D5+vc6CXoT03a049IWt/J4m/S/tVKn/Y3qZsPTdrTjnipo4FMIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWjI++auHy8dTdCQ9w9/u+fbpaMJGvK+JWhoQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1Vthx02YbgS2NcGHhT+BBcwvHQaMtB950pjq0xx85aWxp/LOr+kG48NNpw0DYUw1k61MY38Y91GE7WhyrZeKi04aDruL44DVWHxrly6NuY84c046HShoOO6mqoOrTuGJpmWHy8CvonLsq477BBqwTdjKktD7pw8SqwdsPS49CPq43boOPK2trcOxDbskrQ5Zja8rscVbzHcVaEr4NhyYFP2fKSo+3GjY3XhHX4fLg8NOO6I9F4aLThoE/hvKaw8fZG501cTvuXNTNB4w0bDnr8eUoI8RPftqUp+6qtimTjodKGg35Rn6/9ileXgASNNzxF0DnG4zkRNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQZctBl20IvjSm8CG46ybZeGi05aD7zhTH1hh/LOr+cNkkGw+NNhy0DcVwlg51HYaz9KGaNsnGQ6UNB13H9cUpFDaYWPe0STYeKm046KiunGmGVcdQ8rRJOh7qbDrowsWrwHGZYcO0eRn/Exfl3HnYnlWCbsbUlt/lqOI9DnNvydHZKPcOxLasEnQ5prY46LYbN3Woh++Rdtpcv8qSA2/Y8JLjFKZT8LCONt5dNqnGQ6UNB+3CaDjh91VbFZdNqvFQacNBvyjOS+Xi1YqZoPGGpwg6x3g8J4KGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqLKBoMty1fHYlexBN33wtnqgaYLGG3IHXYfDyReuX2k89iZ30K4z1htT2XXGY2+yB+0IGgnlDtr25RB00xfrjMfe5A7aHELbt32z1njsTPagTd24073zc+3jRxcG3hQ+BDd7PPYld9D1efHc1G997VSNQR87a21p/LGo+8O88dibvEEX9hBjtaf2rYvCxp+D9uOCpA7lsECp5ozH/uQNuvRV66Pj24sOOwYdGudKY0P8B2HOeOxP7iVH+dHLwSno1h1D07SGoPEpuYOevLmGnoKu3XD6PvTjauM26O/Gc3vm/YeNWSVoN6b2vqBPLurf/sGKvfZahK+D4QyNT8l9hrbBVd613Z2vxqBtXJXU4fMwnMXHdceM8dib3EG7zpw6U7QfuSi08fZG503ljPFu3njsTfagnSmHav3Hlhwu+LYtTdlXbVXMG4+9yR10M5Q6rCXaj745qbbjlwt7+7cIGm/IHbTx3ri+rd7zVx8Zj53JHnR0aua/2Y6g8ZbcQdsH3mc3Yzz2JnfQhwcWGzPGY29yB2268d1J839hhaDxltxB23C20njsTe6gNzsez4mgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoJHXP35z108fGEfQyOubuwX+7WcPjCNo5EXQMuMhhKBlxkMIQcuMhxCClhkPIQQtMx5CCFpmPIQQtMx4CCFomfEQQtAy4yGEoGXGQwhBy4yHEIKWGQ8hBC0zHkIIWmY8hBC0zHgIIWiZ8RBC0DLjIYSgZcZDCEHLjIcQgpYZDyEELTMeQghaZjyEELTMeAghaJnxEELQMuMhhKBlxkMIQcuMhxCClhkPIQQtMx5CCFpmPIQQtMx4CCFomfEQQtAy4yGEoGXGQwhBy4yHEIKWGQ8hBC0zHkIIWmY8hBC0zHgIIWiZ8RBC0DLjIYSgZcZDCEHLjIeQXQVd+/ix8CG46ybheGzAjoKuT9UYtD8WdX+4bJKNxybsKOjGj0HXoTTmUE2bdOOxCTsK2hgbg7Zh/DBtUo7HBuwv6KaNn4Vpk3I8NmB/QY/LDBumzcv473yUbMcij2cI2o2pseTAOzxD0Gepgq5DHdcd0ybleGzA/oI2lTPGu8sm4XhswA6DLvuqrYrLJuF4bMCugp4U1t5sko9HTnsMOsd4CCFomfEQQtAy4yGEoGXGQwhBy4yHEIKWGQ8hBC0zHkIIWmY8hBC0zHgIIWiZ8RBC0DLjIYSgZcZDCEHLjIcQgpYZDyEELTMeQghaZjyEELTMeAghaJnxEELQMuMhhKBlxkMIQcuMhxCClhkPIQQtMx5CCFpmPIQQtMx4CCFomfEQQtAy4yGEoGXGQwhBy4yHEIKWGQ8hBC0zHkIIWmY8hBC0zHgIIWiZ8RBC0DLjIYSgZcZDCEHLjIcQgpYZDyEELTMeQghaZjyEELTMeAghaJnxEELQMuMhhKBlxkMIQcuMhxCClhkPIQQtMx5CCFpmPIQQtMx4CCFomfEQQtAy4yGEoGXGQwhBy4yHEIKWGQ8hBC0zHkIIWmY8hBC0zHgIIWiZ8RBC0DLjIYSgZcZDCEHLjIeQHQbtwsCbwofgVhiPrHYY9LGz1pbGH4u6P6Qfj6x2GLRv4sc6lMYcqvTjkdUOgw6Nc6WxYfh0/JB4PLLaY9CtO4amaQ1BK7S/oGtXDGuNflxt3Ab9nY/S/DuQzTME7cbUkp5Ci/B1MJyhFXqGoM9SFWfjNWEdPg+1MeO6I+145LXDoOPtjc6byhnjX25EE7QO+wvauODbtjRlX7VVkX48stph0Ka2Nm6K8yb5eOS0x6BzjIcQgpYZDyEELTMed/38F3f90/xpBC0zHnf98n6Cv5g/jaBlxuMugl4FQedC0Ksg6FwIehUEnQtBr4KgcyHoVRB0LgS9CoLOhaBXQdC5EPQqCDoXgl4FQedC0Ksg6FwIehUEnQtBr4KgcyHoVRB0LgS9CoLOhaBXQdC5EPQqCDoXgl4FQedC0Ksg6FwIehUEnQtBr4KgcyHoVRB0LgS9CoLOhaBXQdDv98tf3fXINIJeA0G/36/uR/PANIJeBUG/H0ETdGb/fPe4PLJIIGiCzuz+cSHoB3ccQedE0AStCkETtCoETdCqEDRBq0LQBJ3Xj7+969cPjCNogs5L7LgQ9IM7jqBnIWiC3vT4uQiaoDOP/83P7vrp/GkETdCZx3/kuHwzfxpBE3Tm8QRN0LMQNEFvaccR9CwETdCZxxM0Qc9C0AS9pR1H0LMQNEFnHk/QBD0LQRP0lnYcQc9C0ASdeTxBE/QsBE3QW9pxBD0LQRN05vEETdCzEDRBb2nHEfQsBE3QmccTNEHPQtAEvaUdR9CzEDRBz1T4EFzC8QRN0LOkDtofi7o/pBtP0AQ9S+Kg61Aac6jSjSdogp4lcdA2XD4kGk/QBD1L4qCb1rwO+rffj37wsH/5v7t+N3/a7+5P+9cHHty/3Z32+wem/f7+g0u74/59wzvuPx6YNvlsTC1x0ONq4yboL78Y/ehh//mHG3/80+2f/jx/2p9v//9/+uPtn/7rgQf3368e3O0f/vLAtL/cnfaHtDvufza84/73gWmTr8bUvvpr0qA/XHIAT60O9bTuADSonDHeLZ+DfShyP4BPKfuqrTb/KLERbvvnvsLa9EPrru83+9TrpqmTDuy6rU5L/lR3+mJu+86e+lPuh/Gm4hiqNhxTvijZkPKckG7aCk+1ahIOexrF+LP0ZPux8Al7KSo/nLNsWy0f9cL7LU5L+1TLoxuOaNJv3aeR+jZgl/AujGvHb7QyyYqo7s4nrDokOXFNq4NE09I+VVO4YRVZ7DPoeESsq0KqZXSRcD1+WQS6fvnDcv2xNkVXx2kJXo/KUCaclvSpnjVtv8+gjQshVM66pU8/ngHjIU50hKPL2W/5uebU9nFE0TapvuWGtUbCaQmf6tVwYLu0V5nbNr4ExwJLOxa47Jp4OgPGQ9wmu/K/PqSFR7n0/e33axMSHOcynJJMq5M+1aKZDqoZL1h96MrlT/UpnAM8F3jWHhaMm86A58/ju1yHf8HCE/VwWA7TyX7pacsNj8XfXG5VxyXT/HmXdW2RYFpcuiR7qnHpHKrLQT0M16tD0ksO6/O4DdC4cZ8u+InNB2fAeOXftNWjJ67iMD6S4bAU/flk7xJcaN5evdmHT6rxZe18/Vb7yy8PPT7tsrMSPdVTW9nhO+TyPN14A2YXi44PAnR91/V+wQn1gzNgHZzvH7/4P4bq8jppw/AyUrs+xevmtLYfXzkePMrTumpYNRcudK6vF007uyxdlj/V4/mXmY6XxYtLen9y0z58CW46t/hS5HIGjIfYhSXrDVf562Et2+GS1SdZB05Xbwvus11e1g79oY+PabhYWHLX7oOly+Kneujjd1ZxXTp2+wk6uh6KxYvdyXQGjHOLReesU2+6l06mS9YEpqu3R8fdvKy157Nq/DHhkm/cD5YuS57qeIUfF/N2+LaoptPKLlYbLy6311L9aOBy/2pxf+UQnhuPcqrvtUm16JR187J2+YH3whtDN0uXZU91usK3oTnGmcP/Uh3UZ3K9gZr4DLjckMtwounSfa9N7OI75JcHdEzyE+qbpcuip3q9wj+GLj7DZtkrx9NKFuDFsjPgC98N1zenviq2d1iu66okN8Nuli6PP9WbpdDlu6JL+h6n55EqwIvlZ8Cz8zVlorc1pHV5WUvzE+okS5fbK/yEP6V9RqkCTO1wrmWTD+5yZZnmxS3N0uXmFlO7wZMAbNhky2dJX9YSLV1eTs3Nlnfdfm35bWJpX9ZSvbnueoW/s1t1T2I/bxJLtHRZ4QofyCr1FT6Q1Vav8AEAAAC86f8BTUbNaf3iLqsAAAAhdEVYdHBzOkhpUmVzQm91bmRpbmdCb3gANTA0eDcyMCs1MCs1MNbiIsMAAAAVdEVYdHBzOkxldmVsAFBTLUFkb2JlLTIuMI2GcXgAAAAASUVORK5CYII=" />

=end html


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher --cpanmodules-module OrderedHash --module-startup

Result formatted as table:

 #table5#
 +----------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Hash::Ordered        |        14 |                 6 |                 0.00% |                80.85% |   0.00011 |      20 |
 | Tie::Hash::Indexed   |        13 |                 5 |                 3.99% |                73.91% | 9.5e-05   |      21 |
 | Array::OrdHash       |        13 |                 5 |                 9.26% |                65.51% | 9.4e-05   |      20 |
 | Tree::RB::XS         |        12 |                 4 |                 9.34% |                65.39% | 9.6e-05   |      20 |
 | Tie::LLHash          |        12 |                 4 |                12.48% |                60.77% | 8.7e-05   |      20 |
 | Tie::IxHash          |        12 |                 4 |                13.93% |                58.73% | 3.8e-05   |      20 |
 | Tie::StoredOrderHash |        10 |                 2 |                39.06% |                30.05% |   0.0001  |      20 |
 | perl -e1 (baseline)  |         8 |                 0 |                80.85% |                 0.00% | 7.8e-05   |      21 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  H:O  TH:I  A:O  TR:X   T:L   T:I   T:S  perl -e1 (baseline) 
  H:O                   71.4/s   --   -7%  -7%  -14%  -14%  -14%  -28%                 -42% 
  TH:I                  76.9/s   7%    --   0%   -7%   -7%   -7%  -23%                 -38% 
  A:O                   76.9/s   7%    0%   --   -7%   -7%   -7%  -23%                 -38% 
  TR:X                  83.3/s  16%    8%   8%    --    0%    0%  -16%                 -33% 
  T:L                   83.3/s  16%    8%   8%    0%    --    0%  -16%                 -33% 
  T:I                   83.3/s  16%    8%   8%    0%    0%    --  -16%                 -33% 
  T:S                  100.0/s  39%   30%  30%   19%   19%   19%    --                 -19% 
  perl -e1 (baseline)  125.0/s  75%   62%  62%   50%   50%   50%   25%                   -- 
 
 Legends:
   A:O: mod_overhead_time=5 participant=Array::OrdHash
   H:O: mod_overhead_time=6 participant=Hash::Ordered
   T:I: mod_overhead_time=4 participant=Tie::IxHash
   T:L: mod_overhead_time=4 participant=Tie::LLHash
   T:S: mod_overhead_time=2 participant=Tie::StoredOrderHash
   TH:I: mod_overhead_time=5 participant=Tie::Hash::Indexed
   TR:X: mod_overhead_time=4 participant=Tree::RB::XS
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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PkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUCJ27TukDRIHQueuUPkAUrxO6qvb8NkLnGyCKVwndT642bbjTCJ1vgCheJHTnrmNd2in4AQidb4AoXiS0bQpTF0VrQh+A0PkGiOJVQluEfpsAUbxIaDNVs9D9VIY+AKHzDRDFq3YKr26YhqkP/n2EzjdAFC+btut6OwaPzwidc4AoXjZC1wsf/qyrv/7qQeh8A0TxIqH7yS588KNubOvnrysInW+AKF43y/E9+noVefu6gtD5BojiVSN08zs/NPXXXz0InW+AKF7VQ9fN91qO7wj9xXi6nX8GoQUECKFbDPryonlo135/p/BDoT8vT4DgAzE3EFpAgBDMYtDnlx36/p2/TMuhKkAUL2o5rvZ3fojQugJE8SKhy7pfOpoPf4jQugJE8apzOdzKxz9EaFUBouAtWLnrlD5AFAidu07pA0SB0LnrlD5AFK8Q2jjzuz30RyB0vgGieNV7Ctf5jT74yB9C5xsgipcIXZpr4yftxoG3YL1BgCheInRVt8Ny5PvCW7DeIEAUL2o5qvA3X60gdL4BomCWI3ed0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIAqFz1yl9gCgQOned0geIIoXQXe1vy9o5e1+G0PkGiOLHC92N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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n OrderedHash

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries OrderedHash | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=OrderedHash -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::OrderedHash -E'say $_->{module} for @{ $Acme::CPANModules::OrderedHash::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module contains benchmark instructions. You can run a
benchmark for some/all the modules listed in this Acme::CPANModules module using
the L<bencher> CLI (from L<Bencher> distribution):

    % bencher --cpanmodules-module OrderedHash

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-OrderedHash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-OrderedHash>.

=head1 SEE ALSO

L<Acme::CPANModules::HashUtilities>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Michael Conrad

Michael Conrad <mike@nrdvana.net>

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-OrderedHash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
