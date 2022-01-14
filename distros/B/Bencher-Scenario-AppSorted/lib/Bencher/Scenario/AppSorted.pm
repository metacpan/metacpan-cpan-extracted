package Bencher::Scenario::AppSorted;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-31'; # DATE
our $DIST = 'Bencher-Scenario-AppSorted'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Slurper 'write_text';
use File::Temp qw(tempdir);

my $dir = tempdir();
write_text("$dir/100k-sorted"            , join("", map {sprintf "%06d\n", $_} 1..100_000));
write_text("$dir/100k-unsorted-middle"   , join("", map {sprintf "%06d\n", $_} 1..50_000, 50_002, 50_001, 50_003..100_000));
write_text("$dir/100k-unsorted-beginning", join("", map {sprintf "%06d\n", $_} 2,1, 3..100_000));

our $scenario = {
    summary => 'Benchmark sorted vs is-sorted',
    participants => [
        {name=>"sorted"   , module=>'App::sorted', cmdline_template=>'sorted <filename>; true'},
        {name=>"is-sorted", module=>'File::IsSorted', cmdline_template=>'is-sorted check <filename>; true'},
    ],
    precision => 7,
    datasets => [
        {name=>'100k-sorted', args=>{filename=>"$dir/100k-sorted"}},
        {name=>'100k-unsorted-middle', args=>{filename=>"$dir/100k-unsorted-middle"}},
        {name=>'100k-unsorted-beginning', args=>{filename=>"$dir/100k-unsorted-beginning"}},
    ],
};

1;
# ABSTRACT: Benchmark sorted vs is-sorted

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::AppSorted - Benchmark sorted vs is-sorted

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::AppSorted (from Perl distribution Bencher-Scenario-AppSorted), released on 2021-07-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m AppSorted

To run module startup overhead benchmark:

 % bencher --module-startup -m AppSorted

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<App::sorted> 0.002

L<File::IsSorted> 0.0.6

=head1 BENCHMARK PARTICIPANTS

=over

=item * sorted (command)

Command line:

 #TEMPLATE: sorted <filename>; true



=item * is-sorted (command)

Command line:

 #TEMPLATE: is-sorted check <filename>; true



=back

=head1 BENCHMARK DATASETS

=over

=item * 100k-sorted

=item * 100k-unsorted-middle

=item * 100k-unsorted-beginning

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m AppSorted

Result formatted as table:

 #table1#
 | participant | dataset                 | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |-------------+-------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------|
 | sorted      | 100k-sorted             |       8.1 |       120 |                 0.00% |                96.99% | 0.0011  |       7 |
 | sorted      | 100k-unsorted-middle    |      10   |        98 |                27.06% |                55.04% | 0.00018 |       7 |
 | sorted      | 100k-unsorted-beginning |      13   |        75 |                64.21% |                19.97% | 0.00029 |       8 |
 | is-sorted   | 100k-sorted             |      13   |        75 |                65.08% |                19.33% | 0.00031 |       7 |
 | is-sorted   | 100k-unsorted-middle    |      14   |        70 |                77.62% |                10.91% | 0.00016 |       8 |
 | is-sorted   | 100k-unsorted-beginning |      16   |        63 |                96.99% |                 0.00% | 0.00023 |       7 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                      Rate  sorted 100k-sorted  sorted 100k-unsorted-middle  sorted 100k-unsorted-beginning  is-sorted 100k-sorted  is-sorted 100k-unsorted-middle  is-sorted 100k-unsorted-beginning 
  sorted 100k-sorted                 8.1/s                  --                         -18%                            -37%                   -37%                            -41%                               -47% 
  sorted 100k-unsorted-middle         10/s                 22%                           --                            -23%                   -23%                            -28%                               -35% 
  sorted 100k-unsorted-beginning      13/s                 60%                          30%                              --                     0%                             -6%                               -16% 
  is-sorted 100k-sorted               13/s                 60%                          30%                              0%                     --                             -6%                               -16% 
  is-sorted 100k-unsorted-middle      14/s                 71%                          39%                              7%                     7%                              --                                -9% 
  is-sorted 100k-unsorted-beginning   16/s                 90%                          55%                             19%                    19%                             11%                                 -- 
 
 Legends:
   is-sorted 100k-sorted: dataset=100k-sorted participant=is-sorted
   is-sorted 100k-unsorted-beginning: dataset=100k-unsorted-beginning participant=is-sorted
   is-sorted 100k-unsorted-middle: dataset=100k-unsorted-middle participant=is-sorted
   sorted 100k-sorted: dataset=100k-sorted participant=sorted
   sorted 100k-unsorted-beginning: dataset=100k-unsorted-beginning participant=sorted
   sorted 100k-unsorted-middle: dataset=100k-unsorted-middle participant=sorted

The above result presented as chart:

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAMNQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFgAfEQAYAAAAAAAAAAAAAAAAAAAAJQA1JQA1AAAAhgDAlQDVjQDKlADUAAAAlADUlADUAAAAlADUlADUlADUlADUlQDVlADUZQCRdACnSABnigDFlADVVgB7lQDWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJwA5lADU////j2kvMQAAAD10Uk5TABFEZiK7Vcwzd4jdme6qjnXVzsfV0v728ez5/v369uzr377W99oiRBEzp4jH1WnwTnV1PyBgcFCbz4Iwj6UkzFIAAAABYktHRACIBR1IAAAACXBIWXMAAABIAAAASABGyWs+AAAAB3RJTUUH5QcfEiMElmF/LgAAGDZJREFUeNrtnYmW48hxRbEQBIiFHntsz0i2JUu2Fu+rvMP6/78SMrGQVVMVKGYGQQR07zlSV7On8/A1LsFMJBCRJAAAAAAAAAAAAAAAAAAAAAAAAAAAAPAZaTb9kKX3L2cBQwG8ivw0/5T10w/9vcOn/rHxAF5Ksdj7kdCnc4nQYIiqvAyn6Lyus0Hok/tlFDqr62r4MS8QGiyRN22WFE1dd3nWd23b117oS1e3fe7+gwyhwRJuylEMJ+n6mvWXJLn0p0HoUz+cnvPO/TlCgynGOXR1LotR3eH03Gd5kw04qxEabOGErvuiLSahOyd03RUOhAZzDEKfOzflGIROkyT1Z+hzk8zXpREaTFGch4XhYK+bcrSD142bdaRdPv6I0GCMa5OnZVM0bfcHZdk0XeWn0XlXlu5HhAZjpNkw38iyNJl/nV9+uwEOAAAAAAAAAAAAAAAAcDimB47S6tVvBECB8SnQ9Nr35Sl2LIAXMz8F2pZper2++t0ARDI9BZq6pzNO9avfDUA0/v7I4f8qbi+DI+CFPvfFeC/wyDd/6Pmjb8EEf/wJf/LlEaYD/moZ1YSu3eP7dTe/9u2ffuf4/keRfP9d7Agj8e9Ed5wf6wyjNs6f/f/H/PnX/2Ucf3GIhxnmKcf4PN0k9I+UxlaalddKBea0xil0hlEb5ye//ZifPjbMN8cRulpWhh6ElkHoHTM+NNdckqRt5tcQWgahd8wodNWVd4tChJZB6P2TZncHG6FlENoYWkKflATKlDbltcbJdYZRG+cvEVpGS2jYhp8htAxC2wKhV0BoWyD0CghtC4ReAaFtgdArILQtEHoFhLYFQq+A0LZA6BUQ2hYIvQJC2wKhV0BoWyD0CghtC4ReAaFtgdArILQtEHoFhLYFQq+A0LZA6BUQ2hYIvQJC2wKhV0BoWyD0CghtC4ReAaFtgdArILQtEHoFhLYFQq+A0LZA6BUQ2hYIfc8H1Y0Q2hYIfcfYBavuB5ZSawhtC4RemLtgXdssy9Srj8I2IPTC1AUrKd7UDURoWyD0HWN96D6v72rNIrQtEPqOSeimbvvlLI3QtkDoO7zQpzpNksutC9Z3tUOpujM8m3ih/fH++XGE9tx1wfo+c9D72wjxQvvj3R5H6MzNNk7qXbBgG5hy3DH1KaxcA/v5NYS2BULfkU0bK0XTcB3aKAj9Q07P6IIF24DQKyC0LRB6BYS2BUKvgNC2QOgVENoWCL0CQtsCoVdAaFsg9AoIbQuEXgGhbYHQKyC0LRB6BYS2BUKvgNC2QOgVENoWCL0CQtsCoVdAaFsg9AoIbQuEXgGhbYHQKyC0LRB6BYS2BUKvgNC2QOgVENoWCL0CQtsCoVdAaFsg9AoIbQuEXgGhbYHQKyC0LRB6BYS2BUKvgNC2QOh7lpp2S61GhDYGQt9xmlPUS1c3hDYGQi/Mbd1cWV2EtgpCL8xt3ZK0uyK0VRD6jqnHyrVmymEWhL5jFDovmUPbBaHvGNu6Nac3Qv+4cOTho8JX+KuffsxfPzhOvND+eP/iOELX5TDjaOq5jxtn6G1QOrNyhr5n7IJVI/QLQOgnkHEd+mUg9BNA6NeB0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0BuB0NuA0M9gauuWnW4vIfQ2IPQTGNu65V3fF+n8GkJvA0KrM7V1S7s8Sct2fhWhtwGh1Znauo19KZYC0Qi9DQj9BJaC58n1Ov+E0NuA0E9gFrpomtsc+vvMcQodc6/88lef8OvHxvmbz8Z58P3sR2h/vNtDCZ3lTT2/9u13tSMLHXOv/O0nB/63D5r4mUC/ffD97Edof7x/fiihk+S8/HTUKQdCixxoyuHXgxlCfxGE3jFjn8K+SpK2mV9DaBmE3jHjebnti6ar5tcQWgah988pu1sCIrQMQhsDoWUQ2hgILYPQxkBoGYQ2BkLLILQxEFoGoY2B0DIIbQyElkFoYyC0DEIbA6FlENoYCC2D0MZAaBmENgZCyyC0MRBaBqGNgdAyCG0MhJZBaGMgtAxCGwOhZRDaGAgtg9DGQGgZhDYGQssgtDEQWgahX01VPfSfI7QMQr+WvOuLrHnAaYSWQeiXUvV5VqR1l375byC0DEK/lLpNsiJJyq8XE0VoGYR+KXWN0CMILWJF6KyrBqHzz6Yck+fV70EXLIQWsSJ0cumbrunyj/9w7IJVNX3fUKzxiyD0Szllp7w+p/lHHSamLlhJ1yYp5XS/CkK/kFN2aV0DjXPz0Rx66YKVunP1fIpGaBmEfiGDsk3huH48h/b1odPM/zSfwxFaBqFfSpVLf7o0ojgdv/EmQotYEXoi/7hL2yR0WvdLEyy6YK1wPKFtdcHKr27K0X3s5yh0VRZ3W+NH7VOI0J9hqk9h1tVlUd8mFO/+1Kdo3vwpUw6Z4wntsTLlqOvk3CZpIywKz73/iM6vIbQMQr+UQeiqSJJCmHLUvWd+DaFlEPql5M0p6U9Jw70cCC1iReikKJK6a8qv/wWElkHo13POv347NEKvgNAvJcsf/RsILYPQL+XywGRjBKFlEPq1tPWbi3LrILQMQr+UrH97UW4dhJZBaGMgtAxCGwOhZRDaGAgtg9DGQGgZhDYGQssgtDEQWgahjYHQMghtDISWQWhjILQMQhsDoWUQ2hgILYPQxkBoGYQ2BkLLILQxEFoGoY2B0DIIbQyElkFoYyC0DEIbA6FlENoYCC2D0MZAaBmENgZCyyD0nsne/Zog9BoIvWNO/dtfHQgtg9C7ZW7rNv86gtAyCL1bprZuy68jCC2D0Dtm7oKVIfSXQegdg9AIPXFgoX/sW3U+XIZ37yD0Z/jj/YvjCs0ZWuR4QnsOfIZGaBGE3jEIjdATCG0NhBY5htAfgdAyCG0MhJZBaGMgtAxCGwOhZRDaGAgtg9DGQGgZhDYGQssgtDEQWgahjYHQMghtDISWQWhjILQMQhsDoWUQ2hgILYPQxkBoGYQ2BkLLILQxEFoGoY2B0DIIbQyElkFoYyC0DEIbA6FlENoYCC2D0MZAaBmENgZCyyC0MRBaBqGNgdAyCG0MhJZBaGMgtAxCGwOhZRB6z0zt3Kr09hJCyyD0jhnbuZ3Kvm+X1xBaBqF3y9zOrbimp6aeX0VoGYTeLVM7t1NfJcmlnF9FaBmE3jG+0Pnt/zwILYPQO8ZrnI9Cz+vCb7/PHKdXv7eZX/7qE3792DgI/Rn+eLfHEfoyCj0b/O13tSOLGFaVv1MSEaE/wx/vnx9H6J1PORB6k3EONOU4uZNz3syvIbQMQu+Y8bxc1OP/RhBaBqF3zCh01ZVNuewVIrQMQu+fNLtbAiK0DEIbA6FlENoYCC2D0MZAaBmENgZCyyC0MRBaBqGNgdAyCG0MhJZBaGMgtAxCGwOhZRDaGAgtg9DGQGgZhDYGQssgtDEQWgahjYHQMghtDISWQWhjILQMQhsDoWUQ2hgILYPQxkBoGYQ2BkLLILQxEFoGoY2B0DIIbQyElkFoYyC0DEIbA6FlENoYCC2D0AbYcxcshN5knCMJfW76/kqxxi+C0Hsn7S5JWlJO94sg9N65uFrn527+LULLIPTeqV1HN1pSfBWE3juV61PY9nOJaISWQejd03ZFWTirPXTBkjme0AfqgjVR1ee7KcfO+hQi9LPHOVCfQk/qTsb5blsjI/Qm4xxoypH25yTdb/N6hN5knAMJneR90bXL7xBaBqH3zymrbr9BaBmENgZCyyC0MRBaBqGNgdAyCG0MhJZBaGMgtAxCGwOhZRDaGAgtg9DGQGgZhDYGQssgtDEQWgahjYHQMghtDISWQWhjILQMQhsDoWUQ2hgILYPQxkBoGYQ2BkLLILQxEFoGoY2B0DIIbQyElkFoYyC0DEIbA6FlENoYCC2D0MZAaBmENgZCyyC0MRBaBqGNgdAyCG2A6q4atJbQWR0/huPvlUT8B6VxfqIk9GfjPCq00jhHErpq+r5Qb+uG0GHjIHQ0TZ2k5VJPV0vof/ynn33MPz82DkJvMs6RhHb9gupi/p2W0P/y2YH/18fGQehNxjmS0N0lSa7qZ2iEDhsHoaPJuqZr1OfQCB02DkLHkpbX7Hw3h+7h95JXe6hG7lojV/185e7fvoHfS17toRq+NXLa76bTJkAUvjVy3cUPBLAL8r5suip+nDt204dWl4PGOhynTHu+0RxzAnPQWLBK3bz6HRALNGmU7uRQ4qx0at1ZLLVcIJNfiy6NGeDU+r+el30bNc70duqi3EWsKZdSLLVcsELb5PVd9/CHGdZepTsV1s05K+MPWV1e2j5/faw5l1IstVywwslt0lQRF7aHtVfWDWN0Z3cJ5hz7ftzbuUSeWjVizbmUYmnlgjUyv4vaFsEDuLXX9TocsaoqiiruguLwt3t3zONnv9Gx5lxKsbRygYCfHab+7JNFfBsOR+k0nArLsjk7rQNGOI1Tg3PXl2nj3kjdx1xEdrn+PTrWlCsi1pTLx0oUcsHnuH/XaXbYDv/aSV5cg8aY1151OXwv+y/5oLdTDr6kpyY7lXXtvpbr5vG3s7ylMVdwrHe5YmK5XFOsJCoXrHBxX8XT7DAty3PeBUw2/cbFtPZKm4v78dIFfqem6fDXa3dz7Mm9naYKOpX5WFOu34TGep8rJtaQa46VROSCNdKuaJfZYdp2Zciix00yl7VX7k5nRRG6eLq2yclbc72mdTkME7Sc87HmXKGxfpArItaQa46VROSCFfJvOn/KCJ8deoZzz23tVYSvd6rET8L9zt5pOKkOp+s85HrAGGtvuZZYwblAJj31v3GzuqjZ4TTJvC0pq9Dv0nHNVBd+2jKcH+vk2pTN4zrOsfaWa4kVmAvWaN1Rz4ajHjo79Iv3aZIZvvYamddMaZcPCgxjuTNY0O1XS6zQXOM1Cf1cS6ywXLDGqZ9mdcGT3mHxPk8yg5eUE8uayX0ZF1E7e0us0FxllTwlV1QskMjLpk6XyWr411+aLpPM4LWXo1qWgn6yGvr1rhcrUcnlPhh3uYJnLbBCXZ7PZTlPVvsmeIFybeP3Y6ZZ5rJmCj/sirEShVzT5Dk+F6zhrhmlw6ljXGuHfp+eUrd4j5lk+tnqNMu8rZl2EStm8nwfK1HIBQJ50ab+Bhn/3HjErC4t+q5yi/eYSaabrc6zzNuaaQ+xkphc97GSqFywQlvWwzrJ30/gZokRX4NtfXIzzC6PmjwPs9Vllhmh4RNiRU2e72PFLXFB5DzOK/39BOeIR8bzrusSf9hjdgjOmS9mtizigjXcV6wkeROLyfMTOXfZuS3LqmjyvAte76RVeb6473d/iS10duif3HCz1fhZ5p5iubeT6cSCdYq+ac/D92DQFdr5TNO6LWX/RVqGX2KbntxwBVTjZ5n7iTV9UHViwUdU/hxxf5zzwNvd53oAJ3cWdCehYdETfMCmJzfc93vQLHOnsaYPanAsWCV1t1Fe/OWn89mV6M+7wLXOUg/A/+CLU4dPD+cnN9z3e8jpcKex5g9qaCxY5+KeIRrmc1VRDiuUrm+Cr0mMTw6dz6n7IQ0VaHx8enlyI3S2urdYU675gxozCYdPqIreffUN/7zugmp28S+GTw79sxveHz89DNxanh6QWZ7cCDiPjbn2FWvONX9QOT0/gaZNL8ORz7pzH774n5luPxv9iZgezo9PRzy5MebaV6w5F49YPQ9/L3A+rHKuXV13Tdyxf1sP4PHzTzV/BS8PyAQ/uTHn2lWsJRePWD0Nf7CS1l3tzQd/osqtRNcDcFsMedMX1e1BktAnN+Zcu4q1PCDDI1ZP4DZ5dof/PJVHDx1Np8xB3QxzhOGs+h/LgySPP7nxLldcLJ0yB3Os9PaADI9YqTNNnscKPe01SUO/mPXKHAzvwb+Jor09SPLwkxvvckXFii5z8C7W7QEZHrHSZp5k+utQyXk4j2VhUzq9MgfufUwnw/Cnwn+QKyZWdJmD07tYt1w8YqWIO3ctk2f/VXoOr4OlVubAM15DCJxdaubSKXMwf1CjYsEK480wy+Q57+vgHTTNMgcefzEh64Nml5q5lMoczB/UmFiwRu0O1W3ynGTXa/BNvYplDhK/QV2762xhO2h6ubTKHEwfr7hYsEJa9m55c5s8RxBd5mAcZdy48DtxaXetwzRUzBVd5mDCf1AjY8EabZ35yVzs5NkRX+YguW1cjDtx59DtBsVc8WUOxnfkP6iRseBTbv+krT9/RU6eleoBKGxc6OfSiKVQSB1Ebr3L0vH+hojJs1I9AJX9mCfkii1z4HPFF1IHkbveZfEND6LrAWjsxzwvV1SsKZdGPRKQuOtyENPwQKUegMp+zBNzxcSac8XuMILIm95lWfiDzzr1AFT2Y56YKybWsh8T+UEFiXe9y4K/mpXqAWQq+zG7y5W92Y+J+qCCiM6Su9KqB5D/p8J+zP5yjbE0csEKGkvusbRgVD2AkdRtTUfvx+wu1xJLIRcI6PQum0sLjkNGGeR34mL3Y7RazenlusWKygWfo3hT7620YEw9gOlt+Z24iI0LvWt+mrmiY8EKOjf1Os7ZrbRgVD2Auw3G8I0LvWt+urkiY8EaOjf1OtyTTLceTeH3JbzZYAyuz6x3zU83V2QsWEHppt7U1V8bDpVGacG3G4xRuaKv+T0hF88JPhG1m3pd4VdfYCWutKBWwXGle7Cfk4tadc9D66beQRp3FnR1q2IOl1rBcZ17sJ+Ui2JIz0Pppt5kKk6YD4c/4nBpFRxXugd7h7ngc+LvVb6rRHs++7sy8zLiHK+1EXfQXCCjcK/yUonWP0B06c7nJrwbhNYG41FzwQoavcvmSrTjA0Rt3wRfYtPbYDxqLvgcjUsJbyrRRqOzEaeQ623h4J3kAhmVSwmKlWi1NuI0cmkWDlbbYAQRlSW3ZiVapY04jVyqhYO1NhhBRmXJrVWJVnEjTiOXWuFgzQ1GWCFuya1biVZpIy4+l27hYNVc8BWCl9xalWhHdDbiFHKpFQ5+Ui4QiFlya1WinYnfiPPXNmJ7sqkVDtbLBV8mdMmtVIlWayPu5M9947WNqJ5sqU6BXd0NRniEoLOGViVatY24slqubcT0ZPO5FArsam4wwgaoVaLV24hLl2sbsbk0Cuyq5YItUKlEq7vB6K4lzNc2InNpxFLLBU9l+t5UqUSr2epy6hDvCLq28TaXQiylzqTwZG7fnNGVaDU3GB3uWkLwtY13uRRiqWwwwrO5Fe6MqEQ7filrtrqc31DwbRLvcwVNnn0u1c6k8HRu1TrDK9FOX8pKG4wL/ibR0GsJerm0NhhhA94U7gytRDt/KSttMN4o4nqbKOX6L6UNRng+bwt3hlSivd+P0dpgXAjeiFPN9d9aG4zwbN4X7nz86/TtfoxGF6Id5vqfncSCNeILd77bj4nr1rPbXDuJBQI6hTt/sB8T061nx7leHgsEFAt3anY8JBcEoVK4U7czILkgHJXCnaqdAckFEag061HtDEguCEepWY9SZ0C9WFl6yFwgo9SsR6szoGqsA+aCNXSa9Wh1BlSOdbxcIOALd6p0tdHpDKiZ6399rGPlApmpcKdGVxuNzoDKuabF3IFywQpT4c7IrjZKnQHVc/3fGOtAuWCFuXBncFcbzc6A+rnCm/XsNBd8jq/WshTuDKz2o9cZ8Dm5QosY7TAXyIzVWpbCnYE3Get1BnxOrtB7p/eXC2Smai1JXA8Qpc6A5IJYlmotEVdo1ToDkguiia7WotgZkFygQ1xTG73OgGqcz8fMBevENeuJ7gyoxViQdLy24UsmHiQXPEpMUxuFzoBq+KqN47UNXzLxKLngYcIfv9foDKiGK0j6Rr2D5ILtiOx4qMu11aiwu79csAlvNxj30H3BFSSNv7axv1ywBe82GHdBPV3TiLm2scdc8Hx0NuKUcU+uRjYi3mUueD4aG3H6DGu4yEbE+8wFz0dhI+4Z76qObUS8z1ywDXEbcU8gdg2nssEIJomcrO4F3Q1GsEvkZHU3aG4wgmkOcolWcYMR4PUobjACvB6dDUaAvaCxwQiwGxQ2GAF2RPwGI8CeiN9gBNgR3CQKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB75nch9YV/FcYCUgAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMS0wNy0zMVQxODozNTowNCswNzowMH0nwJgAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjEtMDctMzFUMTg6MzU6MDQrMDc6MDAMengkAAAAIXRFWHRwczpIaVJlc0JvdW5kaW5nQm94ADUwNHg3MjArNTArNTDW4iLDAAAAE3RFWHRwczpMZXZlbABBZG9iZS0yLjAKOZN0DQAAAABJRU5ErkJggg==" />

=end html


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m AppSorted --module-startup

Result formatted as table:

 #table2#
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------|
 | File::IsSorted      |        32 |                28 |                 0.00% |               693.00% | 0.00012 |       7 |
 | App::sorted         |         9 |                 5 |               242.68% |               131.41% | 0.00032 |       7 |
 | perl -e1 (baseline) |         4 |                 0 |               693.00% |                 0.00% | 0.00016 |       9 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate   F:I   A:s  perl -e1 (baseline) 
  F:I                   31.2/s    --  -71%                 -87% 
  A:s                  111.1/s  255%    --                 -55% 
  perl -e1 (baseline)  250.0/s  700%  125%                   -- 
 
 Legends:
   A:s: mod_overhead_time=5 participant=App::sorted
   F:I: mod_overhead_time=28 participant=File::IsSorted
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 CONTRIBUTOR

=for stopwords perlancar (on netbook-dell-xps13)

perlancar (on netbook-dell-xps13) <perlancar@gmail.com>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-AppSorted>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-AppSorted>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-AppSorted>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
