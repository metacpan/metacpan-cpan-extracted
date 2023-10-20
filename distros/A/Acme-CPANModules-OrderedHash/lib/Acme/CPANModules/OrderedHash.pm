package Acme::CPANModules::OrderedHash;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-06'; # DATE
our $DIST = 'Acme-CPANModules-OrderedHash'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => "List of modules that provide ordered hash data type",
    description => <<'_',

When you ask a Perl's hash for the list of keys, the answer comes back
unordered. In fact, Perl explicitly randomizes the order of keys it returns
everytime. The random ordering is a (security) feature, not a bug. However,
sometimes you want to know the order of insertion. These modules provide you
with an ordered hash; most of them implement it by recording the order of
insertion of keys in an additional array.

Other related modules:

<pm:Tie::SortHash> - will automatically sort keys when you call `keys()`,
`values()`, `each()`. But this module does not maintain insertion order.

_
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
            description => <<'_',

Provide something closest to PHP's associative array, where you can refer
elements by key or by numeric index, and insertion order is remembered.

_
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
            bench_tags => ['no_iterate'],
            bench_code => sub {
                my ($op, $numkeys, $numrep) = @_;

                my $hash = List::Unique::DeterministicOrder->new(data=>[]);
                for (1..$numkeys) { $hash->push("key$_") }

                if ($op eq 'delete') {
                    for (1..$numkeys) { $hash->delete("key$_") }
                } elsif ($op eq 'keys') {
                    for (1..$numrep) { my @keys = $hash->keys }
                } elsif ($op eq 'iterate') {
                    die "Not implemented";
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

This document describes version 0.003 of Acme::CPANModules::OrderedHash (from Perl distribution Acme-CPANModules-OrderedHash), released on 2023-10-06.

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

Author: L<CHORNY|https://metacpan.org/author/CHORNY>

=item L<Hash::Ordered>

Author: L<DAGOLDEN|https://metacpan.org/author/DAGOLDEN>

=item L<Tie::Hash::Indexed>

Author: L<MHX|https://metacpan.org/author/MHX>

Provides two interfaces: tied hash and OO.


=item L<Tie::LLHash>

Author: L<XAERXESS|https://metacpan.org/author/XAERXESS>

=item L<Tie::StoredOrderHash>

Author: L<TFM|https://metacpan.org/author/TFM>

=item L<Array::OrdHash>

Author: L<WOWASURIN|https://metacpan.org/author/WOWASURIN>

Provide something closest to PHP's associative array, where you can refer
elements by key or by numeric index, and insertion order is remembered.


=item L<List::Unique::DeterministicOrder>

Author: L<SLAFFAN|https://metacpan.org/author/SLAFFAN>

Provide a list, not hash.


=back

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Tie::IxHash> 1.23

L<Hash::Ordered> 0.014

L<Tie::Hash::Indexed> 0.08

L<Tie::LLHash> 1.004

L<Tie::StoredOrderHash> 0.22

L<Array::OrdHash> 1.03

L<List::Unique::DeterministicOrder> 0.004

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



=item * List::Unique::DeterministicOrder (perl_code) [no_iterate]

L<List::Unique::DeterministicOrder>



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

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark command (default options):

 % bencher --cpanmodules-module OrderedHash

Result formatted as table (split, part 1 of 4):

 #table1#
 {dataset=>"insert 1000 pairs"}
 +----------------------------------+------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                      | p_tags     | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------+------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Tie::StoredOrderHash             |            |       360 |     2.78  |                 0.00% |               197.99% | 1.1e-06 |      20 |
 | Tie::LLHash                      |            |       380 |     2.6   |                 6.60% |               179.55% | 1.3e-05 |      20 |
 | Array::OrdHash                   |            |       540 |     1.9   |                49.87% |                98.83% | 3.2e-06 |      20 |
 | Tie::Hash::Indexed               |            |       700 |     2     |                81.84% |                63.87% | 7.2e-05 |      22 |
 | Tie::IxHash                      |            |       676 |     1.48  |                87.57% |                58.87% | 9.9e-07 |      20 |
 | Hash::Ordered                    |            |       884 |     1.13  |               145.25% |                21.50% | 1.1e-06 |      21 |
 | List::Unique::DeterministicOrder | no_iterate |      1070 |     0.931 |               197.99% |                 0.00% |   8e-07 |      21 |
 +----------------------------------+------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                     Rate  T:S   T:L   TH:I   A:O   T:I   H:O   LU:D no_iterate 
  T:S               360/s    --   -6%   -28%  -31%  -46%  -59%             -66% 
  T:L               380/s    6%    --   -23%  -26%  -43%  -56%             -64% 
  TH:I              700/s   38%   30%     --   -5%  -26%  -43%             -53% 
  A:O               540/s   46%   36%     5%    --  -22%  -40%             -51% 
  T:I               676/s   87%   75%    35%   28%    --  -23%             -37% 
  H:O               884/s  146%  130%    76%   68%   30%    --             -17% 
  LU:D no_iterate  1070/s  198%  179%   114%  104%   58%   21%               -- 
 
 Legends:
   A:O : p_tags= participant=Array::OrdHash
   H:O : p_tags= participant=Hash::Ordered
   LU:D no_iterate: p_tags=no_iterate participant=List::Unique::DeterministicOrder
   T:I : p_tags= participant=Tie::IxHash
   T:L : p_tags= participant=Tie::LLHash
   T:S : p_tags= participant=Tie::StoredOrderHash
   TH:I : p_tags= participant=Tie::Hash::Indexed

The above result presented as chart:

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAALpQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlADVlQDVlADUlADUlADUAAAAAAAAlQDVlQDWlADVlQDVlADVlQDVlADUlADUlADUMQBHQgBfQQBeJAA0PgBZFgAfAAAADQATGwAmGwAmGQAkGgAmFQAfCAALFAAcBgAIAAAAlADURQBj////AKSsQwAAADp0Uk5TABFEZiK7Vcwzd4jdme6qo9XOx3Xs/Pbx+f637DPfROTwaXVO9XqnIhHW6/v64PjV+/L4+fj59vD17/FMXs4AAAABYktHRACIBR1IAAAACXBIWXMAAABIAAAASABGyWs+AAAAB3RJTUUH5woGFzgSVQG+oQAAFNtJREFUeNrt3Q+f27Z9gHEABAX+VZPMi7NkadJ2a9Zu69b97bi9/9c1ghRPp7PlBAJh/gA938/nDDu2CTh6jkdSOlEpAAAAAAAAAAAAAAAAAAAAAClps45Gv/6v5uhlAQEq+/JTM63j9LphOx29QiBAfa33I0HbkyNoZKRx7byLrrrO+KDtMvqgTdc1829XNUEjJ1U/GFX3XTdWc9DjMEydD7odu2Gq/B8wBI2c+EOOet5Jd+e53VapdrKTsdO8e65G//sEjaysx9DNydWXdiczmao3M181QSMvPuhuqod6C3qcg+7G2iNoZGcO+jT6Qw4ftFZK+z30qVfbZWmCRlbq03xiONe7HHIMc9j9fNCh51NE/zNF0MjMua+06+t+GCvjXN+Pjb/KUY3Ojf6Ig6CRF23m4w1jtPLj8pPLf759AhwAAAAAAAAAAAAQxtyOjb4dgaxs38O5jtZN/gU2LyOQle17OLexPmvbd9cRyMr2PZyXcfnOoda9jEButlc3LuP2w/UXQF5ugq7WkPU2Xv7Mr75YfPkVsJsv16r+KmXQ7Rqy3cbLn3n3119779/t4Js9NrLaZ0Es66BlvV+i+puvUgZ955Dj3Y6T1vttqtvxXeNY1kHL2rOtxU3Q1u+Uq/5lTDBp+Q8RywqRNmhVd7cf+09a/kPEskIkDroZXe/0ddx/0vIfIpYVYveg39DG3Iy7T1r+Q8SyQqQOOvmk1X6bMjZ+Gyzr4GVlHzTwGkGjKASNohA0ikLQKApBoygEjaIQNA7x7Xf3/G3Udgkah/j+f+/5ddR2CRqHIGgUhaBRFIJGUQgaRSFoFIWgURSCRlEIGkUhaBSFoFEUgkZRCBpFIWgUhaBRFIJGUQgaRSFoFIWgURSCRlEIGkUhaBSFoFEUgkZRCBpFIWgUJZ+gL/eSafTHxzSTIjfZBG2X27lZN03DR8ZEkyI7mQRtT2694eZZ2777cEwyKTKUSdBV7dZbIjdKte6DMc2kyFAmQd+5aX3Cm9cjT3kFXa0B67fjNukXxtvxzo3Izf5B2yWq90mCbteA7dvx8mfe/dB5O95bF7nZP2izRPU1hxw4Ql6HHNbvjKv+gzHVpMhOXkGruvv4R6JJkZ3Mgm5G1zv94ZhoUmQnm6AvtDEfHZNOinzkFrS8SSEKQaMoBI2iEDSKQtAoCkGjKASNohA0ikLQKApBoygEjaIQNIpC0CgKQaMoBI2iEDSKQtAoCkGjKASNohA0ikLQKApBoygEjaIQNIpC0CgKQaMoBI2iEDSKQtAoCkGjKASNohA0ikLQKApBoygEjaIQNIqSXdCN/viYdFJkI7OgT/00neeErZumQV3HpJMiI3kFrcdWaedvtnnWtn81ppwUOckr6NbfBfk0Kjs18y/cy5h0UuQkr6A73y43r8d9eQXd+D3yMJlqDVlvY9JJkZO8glbDWLt6ato1ZLuN26Q/1l71Wf8PQpT9g66WqL5JtLNsuhOHHLgvrz209neqr/zJ4LxTrvqXMemkyElmQU8npZfLdW8+Uk6KnOQVtKqmevRPpDSj652+jkknRUYyC1pZ0yyjNuZmTDop8pFb0PImhSgEjeP95rd3/C54UwSN4/3dvQi/D94UQeN43xG0nEkRj6AFTYp4BC1oUsQjaEGTIh5BC5oU8Qha0KSIR9CCJkU8ghY0KeIRtKBJEY+gBU2KeAQtaFLEI2hBkyIeQQuaFPEIWtCkiEfQgiZFPIIWNCniEbSgSRGPoAVNingELWhSxCNoQZMiHkELmhTxCFrQpIhH0IImRTyCFjQp4hG0oEkRj6AFTYp4BC1oUsQjaEGTIh5BC5oU8Qha0KSIR9CCJkU8ghY0KeI9c9DN5baxjb4dk06KtJ436KafpnpO2Lpp8rd328akkyK15w2675R2c8H1WdvlBpyXMemkSO15g56MUl2t7NQo1bqXMe2kSO15gx5bpc4DN68vzPMGbcZ+7LWq1pD1NqadFKk9bdDanc1pPoZu15DtNm6T/lh7VYqpkZDooKslqm+SBF318w/NZDnkKIvooFdp2ur8+Z+ejPU75bnubUw6KZJ72qAbf1WjG5Wqu9uPlJMiuacNej4bdP04R92Mrnf6OiadFKk9b9DKGrOM+s2YdFIk9sRBy5sU8Qha0KSIR9CCJkU8ghY0KeIRtKBJEY+gBU2KeAQtaFLEI2hBkyIeQQuaFPEIWtCkiEfQgiZFPIIWNCniEbSgSRGPoAVNingELWhSxCNoQZMiHkELmhTxCFrQpIhH0IImRTyCFjQp4hG0oEkRj6AFTYp4BC1oUsQjaEGTIh5BC5oU8Qha0KSIR9CCJkU8ghY0KeIRtKBJEY+gBU2KeMUG3TQHTIrDFRp0NU616SOaJuhMlRl0M1Wm1t2og/9mxKSQoMygu0GZWilngv9mxKSQoNCgO4J+UmUGbcZmDrrikOP5lBm0aqd+7MdfeB/YRt+Oj04KAQoNWtmqO31y/2ymhVHWTdPg/8ZljJgUxyszaLsePFf2/h/RZtbOByX1Wdve33TzMj48KSQoMWhr2sHneup/7qTQnZT1d5Rt3cv46KSQocSgq9r1y23vzz9zUtieleLm9WUpMej59O4XnQ7q0d+vfg1Zb+Pjk0KCMoO++NQxtFqefvHXQ5QP2W7jNumPyz7+F14nycXff3/P745e2l5EB10tUX3zyGs5zv5vjp88htbLbz/VIcfv7z5Evz16aXsRHfTqoSdWOld3bvjkH6p6/6P1O+X5p9v4+KQZIOgQgoLuOnUalO4/eVJ4Xnuvu9uPhyfNAEGHkBV0U899fvKQ4/JEYjO63unr+PCkGSDoEIKCrnqr5kOIn70OvdDG3IyPTpoBgg4hKGhV16obexf+F2MmlY+gQ0gK2jtVj7/YjqBzVWbQJvr6MUFnqsyg24iDjYcnzQBBhxAUtBo6/+qkx79hhaBzVWbQlxc7T8F/MWbSDAgN+qdf3/MPwdsqM+h4BJ3psgha0KTJEXQIghaPoEMQtHgEHYKgxSPoEAQtHkGHIGjxCDoEQYtH0CEIWjyCDkHQ4hF0CIIWj6BDELR4BB2CoMUj6BAELR5BhyBo8Qg6BEGLR9AhCFo8gg5B0OIRdAiCFo+gQxC0eAQdgqDFI+gQBC0eQYcgaPEIOgRBi0fQIQhaPIIOQdDiEXQIghaPoEMQtHgEHYKgxSPoEAQtHkGHyC5o3axjo2/HpJMeiqBDZBa0Pk+Ts0pZN03+joXbmHTSgxF0iMyCHpzW57NS9VnbvruOSSc9GEGHyCtoPc0HHLZT1o+texmTTno0gg6RV9BmUo3R3LyeoO/KK+jTVPf92KhqDVlvY9JJj0bQIfIKupvm4+VuVO0ast3GbdIfay/6foeyEHSI/YOulqi+SXXI4Q+kDYccBH1HXnvoZg26sX6nXPVqG5NOejSCDpFX0KpvlRrmgOvu9iPppAcj6BCZBd2Mzp8ULqPT1zHppAcj6BCZBa305dbJb8ekkx6LoEPkFrS8SZMj6BAELR5BhyBo8Qg6BEGLR9AhCFo8gg5B0OIRdAiCFo+gQxC0eAQdgqDFI+gQBC0eQYcgaPEIOgRBi0fQIQhaPIIOQdDiEXQIghaPoEMQtHgEHYKgxSPoEAQtHkGHIGjxCDoEQYtH0CEIWjyCDkHQ4hF0CIIWj6BDELR4e5bzh+/v+PbQZRG0oEmT+yzlfCdzWQRdIIIOQdDiEXQIghaPoEMQtHgEHYKgxSPoEAQtHkGHIGjxCDoEQYtH0CEIWjyCDkHQ4hF0CIIWj6BDZBt0o2/HzzLpIQg6RGZBd9OsVsq6aRrUdUw66cEIOkRmQZ8HY0yjVH3Wtu+uY9JJD0bQITIL+nJjejvNUbfuZUw76cEIOkRmQU9V1xmluHk9Qd+RW9B9N0yVqtaQ9TamnfRgBB0ir6BtN7fbjqpdQ7bbuE36Q+eZiBkEIugQ+wdtlqi+Trez1JO5d8jxhfHs49uWiKBD7B+0XaJ6nyRo488J5zNB63fKVa+28YJDjp9D0I9K05bxVzUGp1Td3X6knPRoBB0ir6BVN9V9P0fdjK53+jomnfRgBB0is6D9Ac0y6jdj0kmPRdAhcgta3qTJEXQIghaPoEMQtHgEHYKgxSPoEAQtHkGHIGjxCDoEQYtH0CEIWjyCDkHQ4hF0CIIWj6BDELR4BB2CoMUj6BAELR5BhyBo8Qg6BEGLR9AhCFo8gg5B0OIRdAiCFo+gQxC0eAQdgqDFI+gQBC0eQYcgaPEIOgRBi0fQIQhaPIIOQdDiEXQIghaPoEMQtHgEHYKgxSPoEAQtHkGHIGjxCDoEQYtH0CEIWjyCDkHQ4hF0CIIWj6BDELR4BB2CoMUj6BAELR5Bh8gw6Gb98XIzt0Zff4egfw5BPypdW109/2DdNA2vxtSTHomgQ2QXtJl80PVZ2767joknPRRBh8gtaD2e6+V230q17mVMPOmxCDpEbkGfO3/IYSa1/LCNiSc9FkGHyCzoyi3H0NUast7GbdIvjGeTTH0Ygg6xf9B2iep9kqBtb5eg2zVku42X3373Q+eZiBkEIugQ+wdtlqi+ThJ05+Yjjr6zHHIQ9B15HXL4TxYftPU75apX25h00qMRdIi8gvaW69B1d/uRetIjEXSITINuRtc7fR1TT3okgg6RX9ArbczN+FkmPQZBh8g1aDmTJkfQIQhaPIIOQdDiEXQIgk7jD9/f8W3wpgg6BEGnkVs5QpdF0FLkVo7QZRG0FLmVI3RZBC1FbuUIXRZBS5FbOUKXRdBS5FaO0GURtBS5lSN0WQQtRW7lCF0WQcf46df3/BS8rdzKEbosgo5x/yH6ffC2citH6LIIOgZBi1sWQccgaHHLIugYBC1uWQQdg6DFLYugYxC0uGURdAyCFrcsgo5B0OKWRdAxCFrcsgg6BkGLWxZBxyBoccsi6BgELW5ZBB2DoMUti6BjELS4ZRF0DIIWtyyCjkHQ4pZF0DEIWtyyCDoGQYtbFkHHIGhxyyLoGAQtblkEHYOgxS2LoGMQtLhlEXQMgha3rCcIervxcaNvxx0mJWhxyyo+6GqcpnpO2LppGtR13GVSgha3rNKD1mOltJsLrs/a9t113GVSgha3rNKDXm7r3dXKTo1SrXsZ95mUoMUtq/SgF+ezSnPzeoIWt6wnCLrue62qNWS9jduk77/wvvzqMX/8v3v+GLytf7y3qX/acVn/XPyy/hS8qT/dXda/BG9r9eUS1b8mu8pRzcfM7Rqy3cbL73319eL9u8f8+d9e+ffXv/hz8Lb+4/Wm/vPVL/5rx2X9d/HL+kvwpv5yd1n/E7yt1fu1ql8lClqp03TvkAPIy3w+uARs/U656l9GIEvGX9UY5oDr7vYDyNIw1f04R92Mrnf6OgJ5ssYso34zAsjIMMRv43mWhQs7jKPMI/KTP3vY5Z9YVTZ+K8KXNavcNDz9sWgzDuY0nvbYlK53PhSq612WdZ5cP3X7PdISl+U/M7r+ZJyL3lTe9Nj6H/fZ2LDXxcTt5bJTtcO/0NXz5sy4S4VSl9X6zfjdUjXtsm/K167P0Njls2OPRc2PtR7svM+J/1Tr1s+yJv64yp5PEpfl6bEe1NQ0dd3sdDyUKzvvbUznpnGHnc78KI377Ov9F3Xdn+bHKf7hdu22trjt6G48W3nLWplxtMq5eW1qryP87Cz7G3+Ve5pcd+qi/j9s+y7d73MFwPgvnP5zo52iT5u2r8E27pE+9f3loqmoZV1o67r5cMP646EdNpehdX/jv342Ztmrusd3Oq/2XesVAP34qU69Ps4vR+P9OfZf+vIPmyJOWW09Dq//fsSy7I7LWrTzqeV6mDb0VSv0ilVql/2Nb/Cif/iY42bf5Q8Wqr5+eAe2lmzr6fK4mLh94fwZezlYjdsVDvOn6OuLG48vazs/2GVZy9Lc6TSa5SXzqqvrpzwnvO5vfINd468hPfpk+pt9VzN19aPH4/7AxR+e6m7qlqNxv6d/MBzdLv+e+TNWj+thUPQlGLtd3IhYlno5P9hrWctr1fren5GbZz16frO/GcZhGOtHDxLe7ru6Ry+tXg5curEd6/mR8Ufj9vEvx+fJLc1p/0TIvF07jNEP93ZxI2JZ6np+sMuyKqN7rd3Qt/7//A4XX/JlrxdTq3MXdxz3et+lH9x3vRy49OuzPMZX8/gD1Dn3korp5xPfOn739XJx48FlvTk/iF+Wtv6Tw85fEavRavXkr/C57G8iTuA+2Nbj+65XBy7mMtZR17SrUQ/XQ5/LiW+sKu6A/u35QfSyhuXM8tz5B+DZn1B52d/Eff283dbju9TXBy71Hs/eNpNWw7Q8C7rjk94u6prLB+cHEZaXbdjlU8N/A3X/6BfGklz2NxL2XYvtwMXu8cyyvxo2f02POxD/gIl74mif84NXL9tYLpU049Q/7engjbj9zf7b2g5cdnnyrO7OY1uNTu/1QpU97HF+8PplG7pfvgaR8ypyf7P7trYDl12+fA7L1ZZmp1eX7CT2/MAOb162Ue34EGJ3exy4bNr1WoKwxzv2/MA1b162UfPdBpLteBB0fSseSaLPD7S+fdlGw8mgZHseBO14Lrij2POD8/D0L9t4VoPIfVfs+cFyceSZX7aBwvj3HXrml22gKKeTf7vwZ3/ZBrJXub7TqqmdWa/UiTw/AH6hzp1OzimzXL7mbeCQu+WZxe2iBlfqkDN/+rc84cQ7ziJ/p3Fyev3+ON4THLnTtjf+icHlBaenXd7wADjO4G/fZ0ar6r6q9nnrFOA4dry8gp8nBpGvrp/cafupWp4YPHpJwKNOvavMcHlV3voK/o4rz8jVef2WhOryYsHT8v2HRy8KeNT2fpfn7VuGeQU/cqb79fiiubxFGM8LIlOXcqtLyb2o74YEAr28y/vl/UkcQSNr27u8N8ubIEW+7SpwtGZ7l/eh16riGwaRrXq96Ly9i6Meh4ffkhg43va+mdteud3zJnTA57aV3Ea+yzsgw3YTIn8Nes83lwQ+p+utdy9vGeXfo4AnupGtlxusXN7Fke9/Rdaut971N23SA+8liry93HpXu7GeHr5zEyDDq1vvVi1v74XsRd96FxAl9ta7gCgxt94F5Hn41ruARNxhEAAAAAAAAAAAAAAAAAAAAAAA7OH/AfkO3DO55y17AAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIzLTEwLTA2VDE2OjU2OjE4KzA3OjAwICMN/gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMy0xMC0wNlQxNjo1NjoxOCswNzowMFF+tUIAAAAhdEVYdHBzOkhpUmVzQm91bmRpbmdCb3gANTA0eDcyMCs1MCs1MNbiIsMAAAATdEVYdHBzOkxldmVsAEFkb2JlLTIuMAo5k3QNAAAAAElFTkSuQmCC" />

=end html


Result formatted as table (split, part 2 of 4):

 #table2#
 {dataset=>"insert 1000 pairs + delete"}
 +----------------------------------+------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                      | p_tags     | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------+------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Tie::IxHash                      |            |        17 |     58.8  |                 0.00% |              3799.19% | 4.1e-05 |      20 |
 | Tie::StoredOrderHash             |            |       200 |      5    |              1070.77% |               233.04% | 1.1e-05 |      20 |
 | Tie::LLHash                      |            |       220 |      4.6  |              1191.67% |               201.87% | 1.4e-05 |      21 |
 | Array::OrdHash                   |            |       279 |      3.59 |              1537.64% |               138.10% | 2.8e-06 |      21 |
 | Hash::Ordered                    |            |       370 |      2.7  |              2087.76% |                78.23% | 4.9e-06 |      20 |
 | List::Unique::DeterministicOrder | no_iterate |       604 |      1.66 |              3450.01% |                 9.84% | 5.1e-07 |      20 |
 | Tie::Hash::Indexed               |            |       663 |      1.51 |              3799.19% |                 0.00% |   6e-07 |      20 |
 +----------------------------------+------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate   T:I   T:S   T:L   A:O   H:O   LU:D no_iterate  TH:I  
  T:I               17/s     --  -91%  -92%  -93%  -95%             -97%   -97% 
  T:S              200/s  1076%    --   -8%  -28%  -46%             -66%   -69% 
  T:L              220/s  1178%    8%    --  -21%  -41%             -63%   -67% 
  A:O              279/s  1537%   39%   28%    --  -24%             -53%   -57% 
  H:O              370/s  2077%   85%   70%   32%    --             -38%   -44% 
  LU:D no_iterate  604/s  3442%  201%  177%  116%   62%               --    -9% 
  TH:I             663/s  3794%  231%  204%  137%   78%               9%     -- 
 
 Legends:
   A:O : p_tags= participant=Array::OrdHash
   H:O : p_tags= participant=Hash::Ordered
   LU:D no_iterate: p_tags=no_iterate participant=List::Unique::DeterministicOrder
   T:I : p_tags= participant=Tie::IxHash
   T:L : p_tags= participant=Tie::LLHash
   T:S : p_tags= participant=Tie::StoredOrderHash
   TH:I : p_tags= participant=Tie::Hash::Indexed

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
 | Tie::LLHash          |      45   |      22   |                 0.00% |               206.84% | 4.1e-05 |      21 |
 | Tie::StoredOrderHash |      46   |      21.7 |                 2.02% |               200.75% | 9.4e-06 |      20 |
 | Array::OrdHash       |      51.4 |      19.5 |                13.93% |               169.32% | 1.4e-05 |      21 |
 | Tie::IxHash          |      65.1 |      15.4 |                44.41% |               112.47% | 9.4e-06 |      20 |
 | Tie::Hash::Indexed   |      97.5 |      10.3 |               116.20% |                41.93% | 9.3e-06 |      20 |
 | Hash::Ordered        |     140   |       7.2 |               206.84% |                 0.00% | 6.4e-05 |      20 |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

          Rate   T:L   T:S   A:O   T:I  TH:I   H:O 
  T:L     45/s    --   -1%  -11%  -29%  -53%  -67% 
  T:S     46/s    1%    --  -10%  -29%  -52%  -66% 
  A:O   51.4/s   12%   11%    --  -21%  -47%  -63% 
  T:I   65.1/s   42%   40%   26%    --  -33%  -53% 
  TH:I  97.5/s  113%  110%   89%   49%    --  -30% 
  H:O    140/s  205%  201%  170%  113%   43%    -- 
 
 Legends:
   A:O: participant=Array::OrdHash
   H:O: participant=Hash::Ordered
   T:I: participant=Tie::IxHash
   T:L: participant=Tie::LLHash
   T:S: participant=Tie::StoredOrderHash
   TH:I: participant=Tie::Hash::Indexed

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


Result formatted as table (split, part 4 of 4):

 #table4#
 {dataset=>"insert 1000 pairs + return keys 100 times"}
 +----------------------------------+------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                      | p_tags     | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +----------------------------------+------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Tie::StoredOrderHash             |            |      10.7 |     93.2  |                 0.00% |               845.55% | 5.8e-05   |      20 |
 | Tie::LLHash                      |            |      12   |     86    |                 8.76% |               769.40% |   0.00011 |      20 |
 | Array::OrdHash                   |            |      14   |     70    |                32.35% |               614.46% |   0.0001  |      20 |
 | Tie::IxHash                      |            |      16.2 |     61.8  |                50.70% |               527.45% | 5.4e-05   |      20 |
 | Tie::Hash::Indexed               |            |      24   |     41    |               124.79% |               320.64% |   0.0001  |      20 |
 | Hash::Ordered                    |            |      78.3 |     12.8  |               629.18% |                29.67% | 4.2e-06   |      20 |
 | List::Unique::DeterministicOrder | no_iterate |     101   |      9.85 |               845.55% |                 0.00% | 2.2e-06   |      22 |
 +----------------------------------+------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                     Rate  T:S   T:L   A:O   T:I   TH:I   H:O   LU:D no_iterate 
  T:S              10.7/s    --   -7%  -24%  -33%   -56%  -86%             -89% 
  T:L                12/s    8%    --  -18%  -28%   -52%  -85%             -88% 
  A:O                14/s   33%   22%    --  -11%   -41%  -81%             -85% 
  T:I              16.2/s   50%   39%   13%    --   -33%  -79%             -84% 
  TH:I               24/s  127%  109%   70%   50%     --  -68%             -75% 
  H:O              78.3/s  628%  571%  446%  382%   220%    --             -23% 
  LU:D no_iterate   101/s  846%  773%  610%  527%   316%   29%               -- 
 
 Legends:
   A:O : p_tags= participant=Array::OrdHash
   H:O : p_tags= participant=Hash::Ordered
   LU:D no_iterate: p_tags=no_iterate participant=List::Unique::DeterministicOrder
   T:I : p_tags= participant=Tie::IxHash
   T:L : p_tags= participant=Tie::LLHash
   T:S : p_tags= participant=Tie::StoredOrderHash
   TH:I : p_tags= participant=Tie::Hash::Indexed

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher --cpanmodules-module OrderedHash --module-startup

Result formatted as table:

 #table5#
 +----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                      | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | List::Unique::DeterministicOrder |      16.2 |               8.5 |                 0.00% |               110.26% | 7.7e-06 |      20 |
 | Hash::Ordered                    |      15.9 |               8.2 |                 1.50% |               107.15% |   6e-06 |      20 |
 | Tie::Hash::Indexed               |      15.5 |               7.8 |                 4.57% |               101.06% | 4.9e-06 |      22 |
 | Array::OrdHash                   |      15   |               7.3 |                 7.86% |                94.94% | 1.1e-05 |      20 |
 | Tie::IxHash                      |      14.9 |               7.2 |                 8.49% |                93.81% |   9e-06 |      20 |
 | Tie::LLHash                      |      13.6 |               5.9 |                18.93% |                76.79% | 7.4e-06 |      20 |
 | Tie::StoredOrderHash             |      10.7 |               3   |                51.34% |                38.93% | 5.9e-06 |      20 |
 | perl -e1 (baseline)              |       7.7 |               0   |               110.26% |                 0.00% | 3.4e-05 |      20 |
 +----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  LU:D   H:O  TH:I  A:O  T:I   T:L   T:S  perl -e1 (baseline) 
  LU:D                  61.7/s    --   -1%   -4%  -7%  -8%  -16%  -33%                 -52% 
  H:O                   62.9/s    1%    --   -2%  -5%  -6%  -14%  -32%                 -51% 
  TH:I                  64.5/s    4%    2%    --  -3%  -3%  -12%  -30%                 -50% 
  A:O                   66.7/s    7%    6%    3%   --   0%   -9%  -28%                 -48% 
  T:I                   67.1/s    8%    6%    4%   0%   --   -8%  -28%                 -48% 
  T:L                   73.5/s   19%   16%   13%  10%   9%    --  -21%                 -43% 
  T:S                   93.5/s   51%   48%   44%  40%  39%   27%    --                 -28% 
  perl -e1 (baseline)  129.9/s  110%  106%  101%  94%  93%   76%   38%                   -- 
 
 Legends:
   A:O: mod_overhead_time=7.3 participant=Array::OrdHash
   H:O: mod_overhead_time=8.2 participant=Hash::Ordered
   LU:D: mod_overhead_time=8.5 participant=List::Unique::DeterministicOrder
   T:I: mod_overhead_time=7.2 participant=Tie::IxHash
   T:L: mod_overhead_time=5.9 participant=Tie::LLHash
   T:S: mod_overhead_time=3 participant=Tie::StoredOrderHash
   TH:I: mod_overhead_time=7.8 participant=Tie::Hash::Indexed
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

L<Hash::Ordered> has strong performance in iterating and returning keys, while
L<List::Unique::DeterministicOrder> is strong in insertion and deletion (or
L<Tie::Hash::Indexed> if you're looking for actual hash type).

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-OrderedHash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
