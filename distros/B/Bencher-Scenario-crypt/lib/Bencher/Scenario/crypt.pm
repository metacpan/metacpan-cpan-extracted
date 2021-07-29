package Bencher::Scenario::crypt;

our $DATE = '2021-07-24'; # DATE
our $VERSION = '0.020'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various algorithms of crypt()',
    on_failure => 'skip',
    participants => [
        {
            name => 'crypt',
            code_template => 'state $i = 0; my $c = crypt(++$i, <salt>); die "crypt fails/unsupported" unless $c; $c',
        }
    ],
    datasets => [
        {name=>'des', args=>{salt=>'aa'}},
        {name=>'md5-crypt', args=>{salt=>'$1$12345678$'}},

        {name=>'bcrypt-8', args=>{salt=>'$2b$8$1234567890123456789012$'}},
        {name=>'bcrypt-10', args=>{salt=>'$2b$10$1234567890123456789012$'}},
        {name=>'bcrypt-12', args=>{salt=>'$2b$12$1234567890123456789012$'}},
        {name=>'bcrypt-14', args=>{salt=>'$2b$14$1234567890123456789012$'}},

        {name=>'ssha256-5k', args=>{salt=>'$5$rounds=5000$1234567890123456$'}},
        {name=>'ssha256-50k', args=>{salt=>'$5$rounds=50000$1234567890123456$'}},
        {name=>'ssha256-500k', args=>{salt=>'$5$rounds=500000$1234567890123456$'}},

        {name=>'ssha512-5k', args=>{salt=>'$6$rounds=5000$1234567890123456$'}},
        {name=>'ssha512-50k', args=>{salt=>'$6$rounds=50000$1234567890123456$'}},
        {name=>'ssha512-500k', args=>{salt=>'$6$rounds=500000$1234567890123456$'}},
    ],
};

1;
# ABSTRACT: Benchmark various algorithms of crypt()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::crypt - Benchmark various algorithms of crypt()

=head1 VERSION

This document describes version 0.020 of Bencher::Scenario::crypt (from Perl distribution Bencher-Scenario-crypt), released on 2021-07-24.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m crypt

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * crypt (perl_code)

Code template:

 state $i = 0; my $c = crypt(++$i, <salt>); die "crypt fails/unsupported" unless $c; $c



=back

=head1 BENCHMARK DATASETS

=over

=item * des

=item * md5-crypt

=item * bcrypt-8

=item * bcrypt-10

=item * bcrypt-12

=item * bcrypt-14

=item * ssha256-5k

=item * ssha256-50k

=item * ssha256-500k

=item * ssha512-5k

=item * ssha512-50k

=item * ssha512-500k

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark with default options (C<< bencher -m crypt >>):

 #table1#
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset      | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | ssha512-500k |      4.98 |  201      |                 0.00% |           7096982.72% | 5.2e-05 |      20 |
 | ssha256-500k |      6.49 |  154      |                30.25% |           5448770.36% | 4.5e-05 |      20 |
 | ssha512-50k  |     49.9  |   20      |               901.89% |            708270.75% | 6.2e-06 |      20 |
 | ssha256-50k  |     64.9  |   15.4    |              1202.92% |            544607.52% | 5.1e-06 |      20 |
 | ssha512-5k   |    496    |    2.01   |              9859.12% |             71162.17% | 6.9e-07 |      20 |
 | ssha256-5k   |    645    |    1.55   |             12835.62% |             54764.65% | 1.3e-06 |      21 |
 | md5-crypt    |   8970    |    0.111  |            179853.46% |              3843.84% | 5.3e-08 |      20 |
 | des          | 350000    |    0.0028 |           7096982.72% |                 0.00% | 3.6e-09 |      27 |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                    Rate  ssha512-500k  ssha256-500k  ssha512-50k  ssha256-50k  ssha512-5k  ssha256-5k  md5-crypt   des 
  ssha512-500k    4.98/s            --          -23%         -90%         -92%        -99%        -99%       -99%  -99% 
  ssha256-500k    6.49/s           30%            --         -87%         -90%        -98%        -98%       -99%  -99% 
  ssha512-50k     49.9/s          905%          670%           --         -23%        -89%        -92%       -99%  -99% 
  ssha256-50k     64.9/s         1205%          900%          29%           --        -86%        -89%       -99%  -99% 
  ssha512-5k       496/s         9900%         7561%         895%         666%          --        -22%       -94%  -99% 
  ssha256-5k       645/s        12867%         9835%        1190%         893%         29%          --       -92%  -99% 
  md5-crypt       8970/s       180981%       138638%       17918%       13773%       1710%       1296%         --  -97% 
  des           350000/s      7178471%      5499900%      714185%      549900%      71685%      55257%      3864%    -- 
 
 Legends:
   des: dataset=des
   md5-crypt: dataset=md5-crypt
   ssha256-500k: dataset=ssha256-500k
   ssha256-50k: dataset=ssha256-50k
   ssha256-5k: dataset=ssha256-5k
   ssha512-500k: dataset=ssha512-500k
   ssha512-50k: dataset=ssha512-50k
   ssha512-5k: dataset=ssha512-5k

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAJJmlDQ1BpY2MAAEiJlZVnUJNZF8fv8zzphUASQodQQ5EqJYCUEFoo0quoQOidUEVsiLgCK4qINEWQRQEXXJUia0UUC4uCAhZ0gywCyrpxFVFBWXDfGZ33HT+8/5l7z2/+c+bec8/5cAEgiINlwct7YlK6wNvJjhkYFMwE3yiMn5bC8fR0A9/VuxEArcR7ut/P+a4IEZFp/OW4uLxy+SmCdACg7GXWzEpPWeGjy0wPj//CZ1dYsFzgMt9Y4eh/eexLzr8s+pLj681dfhUKABwp+hsO/4b/c++KVDiC9NioyGymT3JUelaYIJKZttIJHpfL9BQkR8UmRH5T8P+V/B2lR2anr0RucsomQWx0TDrzfw41MjA0BF9n8cbrS48hRv9/z2dFX73kegDYcwAg+7564ZUAdO4CQPrRV09tua+UfAA67vAzBJn/eqiVDQ0IgALoQAYoAlWgCXSBETADlsAWOAAX4AF8QRDYAPggBiQCAcgCuWAHKABFYB84CKpALWgATaAVnAad4Dy4Aq6D2+AuGAaPgRBMgpdABN6BBQiCsBAZokEykBKkDulARhAbsoYcIDfIGwqCQqFoKAnKgHKhnVARVApVQXVQE/QLdA66At2EBqGH0Dg0A/0NfYQRmATTYQVYA9aH2TAHdoV94fVwNJwK58D58F64Aq6HT8Id8BX4NjwMC+GX8BwCECLCQJQRXYSNcBEPJBiJQgTIVqQQKUfqkVakG+lD7iFCZBb5gMKgaCgmShdliXJG+aH4qFTUVlQxqgp1AtWB6kXdQ42jRKjPaDJaHq2DtkDz0IHoaHQWugBdjm5Et6OvoYfRk+h3GAyGgWFhzDDOmCBMHGYzphhzGNOGuYwZxExg5rBYrAxWB2uF9cCGYdOxBdhK7EnsJewQdhL7HkfEKeGMcI64YFwSLg9XjmvGXcQN4aZwC3hxvDreAu+Bj8BvwpfgG/Dd+Dv4SfwCQYLAIlgRfAlxhB2ECkIr4RphjPCGSCSqEM2JXsRY4nZiBfEU8QZxnPiBRCVpk7ikEFIGaS/pOOky6SHpDZlM1iDbkoPJ6eS95CbyVfJT8nsxmpieGE8sQmybWLVYh9iQ2CsKnqJO4VA2UHIo5ZQzlDuUWXG8uIY4VzxMfKt4tfg58VHxOQmahKGEh0SiRLFEs8RNiWkqlqpBdaBGUPOpx6hXqRM0hKZK49L4tJ20Bto12iQdQ2fRefQ4ehH9Z/oAXSRJlTSW9JfMlqyWvCApZCAMDQaPkcAoYZxmjDA+SilIcaQipfZItUoNSc1Ly0nbSkdKF0q3SQ9Lf5RhyjjIxMvsl+mUeSKLktWW9ZLNkj0ie012Vo4uZynHlyuUOy33SB6W15b3lt8sf0y+X35OQVHBSSFFoVLhqsKsIkPRVjFOsUzxouKMEk3JWilWqUzpktILpiSTw0xgVjB7mSJleWVn5QzlOuUB5QUVloqfSp5Km8oTVYIqWzVKtUy1R1WkpqTmrpar1qL2SB2vzlaPUT+k3qc+r8HSCNDYrdGpMc2SZvFYOawW1pgmWdNGM1WzXvO+FkaLrRWvdVjrrjasbaIdo12tfUcH1jHVidU5rDO4Cr3KfFXSqvpVo7okXY5upm6L7rgeQ89NL0+vU++Vvpp+sP5+/T79zwYmBgkGDQaPDamGLoZ5ht2GfxtpG/GNqo3uryavdly9bXXX6tfGOsaRxkeMH5jQTNxNdpv0mHwyNTMVmLaazpipmYWa1ZiNsulsT3Yx+4Y52tzOfJv5efMPFqYW6RanLf6y1LWMt2y2nF7DWhO5pmHNhJWKVZhVnZXQmmkdan3UWmijbBNmU2/zzFbVNsK20XaKo8WJ45zkvLIzsBPYtdvNcy24W7iX7RF7J/tC+wEHqoOfQ5XDU0cVx2jHFkeRk4nTZqfLzmhnV+f9zqM8BR6f18QTuZi5bHHpdSW5+rhWuT5z03YTuHW7w+4u7gfcx9aqr01a2+kBPHgeBzyeeLI8Uz1/9cJ4eXpVez33NvTO9e7zofls9Gn2eedr51vi+9hP0y/Dr8ef4h/i3+Q/H2AfUBogDNQP3BJ4O0g2KDaoKxgb7B/cGDy3zmHdwXWTISYhBSEj61nrs9ff3CC7IWHDhY2UjWEbz4SiQwNCm0MXwzzC6sPmwnnhNeEiPpd/iP8ywjaiLGIm0iqyNHIqyiqqNGo62ir6QPRMjE1MecxsLDe2KvZ1nHNcbdx8vEf88filhICEtkRcYmjiuSRqUnxSb7JicnbyYIpOSkGKMNUi9WCqSOAqaEyD0tandaXTlz/F/gzNjF0Z45nWmdWZ77P8s85kS2QnZfdv0t60Z9NUjmPOT5tRm/mbe3KVc3fkjm/hbKnbCm0N39qzTXVb/rbJ7U7bT+wg7Ijf8VueQV5p3tudATu78xXyt+dP7HLa1VIgViAoGN1tubv2B9QPsT8M7Fm9p3LP58KIwltFBkXlRYvF/OJbPxr+WPHj0t6ovQMlpiVH9mH2Je0b2W+z/0SpRGlO6cQB9wMdZcyywrK3BzcevFluXF57iHAo45Cwwq2iq1Ktcl/lYlVM1XC1XXVbjXzNnpr5wxGHh47YHmmtVagtqv14NPbogzqnuo56jfryY5hjmceeN/g39P3E/qmpUbaxqPHT8aTjwhPeJ3qbzJqamuWbS1rgloyWmZMhJ+/+bP9zV6tua10bo63oFDiVcerFL6G/jJx2Pd1zhn2m9az62Zp2WnthB9SxqUPUGdMp7ArqGjzncq6n27K7/Ve9X4+fVz5ffUHyQslFwsX8i0uXci7NXU65PHsl+spEz8aex1cDr97v9eoduOZ67cZ1x+tX+zh9l25Y3Th/0+LmuVvsW523TW939Jv0t/9m8lv7gOlAxx2zO113ze92D64ZvDhkM3Tlnv296/d5928Prx0eHPEbeTAaMip8EPFg+mHCw9ePMh8tPN4+hh4rfCL+pPyp/NP637V+bxOaCi+M24/3P/N59niCP/Hyj7Q/Fifzn5Ofl08pTTVNG02fn3Gcufti3YvJlykvF2YL/pT4s+aV5quzf9n+1S8KFE2+Frxe+rv4jcyb42+N3/bMec49fZf4bmG+8L3M+xMf2B/6PgZ8nFrIWsQuVnzS+tT92fXz2FLi0tI/QiyQvpNzTVQAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAMBQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAQFgAfAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGgAmHwAtAAAAAAAAdACnlADUgwC7lQDVAAAAAAAAAAAAAAAAAAAAlADUlQDVlQDVlADUlADUYACJewCwVgB7OABQlQDWlADUZwCUAAAAAAAAAAAAAAAAAAAAAAAAAAAAJwA5lADU////2eYkxAAAADx0Uk5TABFEZiK7Vcwzd4jdme6qqdXKx87V0j/v/Pbs+fH7+/R11ce+p+Tt8E5cRPXs1t9pynXPdRHlWyBrp3CPglsI1wAAAAFiS0dEAIgFHUgAAAAJcEhZcwAAAEgAAABIAEbJaz4AAAAHdElNRQflBxgVJxqQmql1AAAU70lEQVR42u3dC3vjuHWAYQAkRQog1W3SdJo0bTdtdrdN7/cb2v//swKApCwPRyMT5EjQ0fc+HdNORxhZ+5k8oi5WCgAAAAAAAAAAAAAAAAAAAMAdaTN9YvTF/2pylgIepKrPnxo/feIvIq79uvWAh2re4v1C0PWhJWg8ka49hl10Za2JQddpm4I21nbh/9EQNJ5J5XqjGmftUIWgh773NgV9HGzvK3Wx2waeQRw5mrCTtqfQ7lGpo69D0LWPu+dBETSezDhDd4e2mdoNu2dvKmeCWDVB46nEoK1v+mYOeohB26GJCBrPJgR9GOLIEYPWSum0hz44NZ2XJmg8leYQ7hiGeNPI0YewXZw6dLiPmD4laDyXk6t06xrXD5VpW+eGLo3R1dC28VOCxnPRJswbxmgVt+mT+X9/9wA4AAAAAAAAAAAA8HCmfvdlp7++BUpWDd43WlkfNErVrY9Pqbm6BYoWnwam216demNMp1Rz0rWz17dA0dKTv2yjmip9mV4qdGyvboEncDopP79QWaUP17ZA8RrntPIuvSq5GsPV17bTRf7gu+QPfwac/fyPvujnH7rwL1JRv/jjHYI2lbO1Da0eB3Ucw62vbaeLfPqTX0affpXvTzdcdrclfv3LzUv88tcFfB9l3BR/9n9f9OcfuvBfpKL897vsow/jLKG9+eDI8aufbT8ubL/a25cw2+/m2u3vVSflpvjN/3/RX65YYnvQNt4Uxpt4nzDc86vjTrhy6tp2QtBnBH1WRNDpvSJ6N27acMvYr/8ZEfQZQZ8VEbTqfRNfyGnDxoWou6F1rb6+HRH0GUGflRG0qo252MQXc351mxD0GUGfFRJ0jh2CrrZfi+1L1Ntr/OyZMK98U/zVSwcNcX5L0JCEoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQ5RSgp5+/Xqn1Ye2EUFjqYygq8H7Rqu69b4PX97ajggaS0UErYdK6bZXzUnXzqqb2xFBY6mIoI0PH2xT+06pY6tubScEjaUigk5Op9R1+HBrOyFoLJUSdOOcrsZgb26ni3z6wUb1o29ClGRT0FUqap+zHJWzxzHY+tZ2usiP35lI5/6TkGhT0F0qaqeR4+AZObBZESOHbVTa9cadb+XUre2EoLFURNAmnr7onWriqbkP/BkRNJaKCFr1vnFDp7qhdW2YiW9tRwSNpTKCVrUxcaPHzc1tQtBYKiToHASNJYKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqilBJ0V7//Un99GxE0lsoIunPeu05ZHzRK1a33vbq+HRE0lsoIeuiV7p069caYTqnmpGtnr29HBI2lIoI2PkwSte+aKn0ZPlPq2F7dTggaS0UErY2KVde+stbEz9KXV7cTgsZSEUFHddsr72zvK1WN4epr2+kSBI2lQoLW1ltV29DqcVDHMdz62na6zE8/NVH36JsQJdkUtE1F7XGWoz13qb1h5EC2MvbQLp2MM/E+YbjnV8edcOXUte2EoLFURNCHsFeO4lmMvlWqsV//MyJoLBURdHpAxfuwbZwLUXdD61p9fTsiaCwVEfRZbUza6hvbhKCxVFbQqxA0lggaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQpZSgu3rcaPWhbUTQWCoj6M557zpVt9734ctb2xFBY6mMoIde6d6p5qRrZ9XN7YigsVRE0MaHSaL2f+07pY5t+Ozr2wlBY6mIoLVRseq/8WkT/++r2wlBY6mIoKO67asxWH1rO12CoLFUSNDaequOY7D1re10mZ9+aqLu0TchSrIpaJuK2uMsRxu7vDVqMHLgpjL20C6djKvjzrdyN7cTgsZSEUEfvIlUE0/NfeDPiKCxVETQ1ieqG1rXhvt8t7YjgsZSEUGfaWM+tE0IGktlBb0KQWOJoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDlPsF3e39THyCxtK9gq4G3xi3a9MEjaU7Bd35yjTaDvr2X/0wgsbSnYK2vTKNUq25/Vc/jKCxdK+gLUHjHu4UtBm6EHTFyIFv7F53Co/eDW6o9rzqBI2lu522qyt72HP/TND4kjsFXY/Dc1Xf/qsfRtBYukvQtTn28X0KDo47hfi27hJ01bQuvcnSiTuF+Lbu9cDKeHeQkQPf2N0e+j7FPfTAyIFv627noW3b2La//Tc/jqCxdL9HCg+90o4ZGt/W/YLuGqUaRg58W3cKunK18rXitB2+sXvdKWwaZQfXfuBvfhhBY+meL8E6VLs+9k3QWLrXWY5dn5Y0Imgs3Sno467DxoigsXSvkaO342+d2BFBY+leI4effuvEjggaS7wvB0QhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQpZig3z9vqdNf30YEjaVSgq7j85ZsfP5SE75ovY8vEL+2HRE0lsoIuj60MehTfMOwTqnmpGtnr29HBI2lMoKumhR0M76upfZdeknAte2EoLFURtDxCdNxpcpaM30ePlzbTggaS2UF7WzvK1WN4epr2+kiP36XXgSz75tO48ltCrpLRe0WdG1DnMdBHcdw62vb6SKffrDRnu//iKe3KegqFbXfHjrS3jByIFtJI0d6r4Nwz6+OO+HKqWvbCUFjqaig41mMvlWqsV//MyJoLJUUtLK+cfHXJ3dD61p9fTsiaCyVEvSont65Q9/YJgSNpbKCXoWgsUTQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKMUEbdLHTqsPbSOCxlIpQdc+fmi97z+wHRE0lsoIuj60MejmpGtnb29HBI2lMoKumhh07Tulju3N7YSgsVRG0GGE9uOf+OHWdkLQWCop6GoMVt/aThf58TsT6dx/EhJtCrpLRe0W9HEMtr61nS7y6Qcb1bn/JCTaFHSVimLkQDlKGjnquPOt3M3thKCxVFLQqrEf+zMiaCwVFXQ3tK7Vt7cjgsZSKUGPtDEf2iYEjaWygl6FoLFE0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQ5RCg+7017cRQWOpqKCtDxql6tb7Xl3fjggaS0UFfeqNMZ1SzUnXzl7fjggaS0UF3VRpU/sQ9bG9up0QNJaKCtpX1hqljFfpw7XthKCxVFbQzva+UtUYrr62nf42QWOppKBrG1o9Duo4hltf205//dMPNqqz/z0ItCnoKhW172k77c0HR44fvzORzv2XINGmoLtU1G5Bm3ifMNzzq+NOuHLq2nbCyIGlkkYOE89i9K1Sjf36nxFBY6mkoJX1jXMh6m5oXauvb0cEjaWigla1MWmrb2wTgsZSWUGvQtBYImiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaJTjd3/7d1/y9yuWIGiU43dfrvEfVixB0CgHQUOU1wu602+f7xC03X6Nti/RVZuXqLoCvo8dlvjH7UH/0zMFXbfe9+evdgi62X6dti9htodgTQHfxw5L/PP2oH/zTEE3J127839+gj4j6LNnCrr24ch6bOcvCfqMoM+eKWjj5w8JQZ8R9NkzBV2NQc/3Cwn6bIeg/+Vfv+jfVizx77/9ohUrvFjQxzHoevryJw98C/cK+rOR4z++B76F/7xT0HXcOVfuTv8a8K01dvwDiNANrWv19nWAMmiz/e48ClVvXwIoxnGHc6gvq0uD+OGxSxRxJQpZItBD029c4nXpIdz8x9NjlyjgSnQnXcASIzMMW4eOqulf7x5W1/ihUken1On44CUefSW09SGARy9xXqpuN57A6lvbbD1OPB/X62MowVk15N7B3G2Jx16Jw9CmSz52iaRyvqkvHgTOuzLu9XbPYccWH2isvDHDIe7hHrvE9w+9EofpMdfHLqHiuavhYE6DVqeMsSX9DFRtOFAcBnPo23b7ax2eSnq0MRyc1GmwdnA5/xE2LhGGzvMSmVciLLHD96Fc1bXe2wcvUdVtGy8Y7hLWg1mdowtHBusOpm1V411/yPmheE7j0KnSCwRqf6h9FSbAYdUd6x2WGIfOeYn/ylhhWmLLlZjYZjjqarCPXcKZg4+Tb3wapfWrxwYb5vd4p7Ty4/hcvczZv2noPA7xJutPysZXCqy7+bYvMQ+d8xIZV2JaYsv3MdE+/lBUw2OXaKwaz9f58G1lDOLhJ9t3XdN0XXwibjW8yt3CeejUadd2aJVePyxsX2IeOucl1q8wL5F/JbrzYb2KY4v2GUvUm5eI6ngh24cb1qjMu4TVqRl027qQcch68O41er4cOk04OqpDODCZNTfg5eSbuUQyD53zEutXmJfIvBLxsu+eD2OGtUvod69VzloiqUwVvofwMxlGjTCC55y0610VBp0q/odJu5vXePj8/dAZ9rF27YHp/eSbtcRkHjp3WCJrBR3+ad2mO06H8H2cTLX+7ES8+zaedc5eIl6TeEOaoa99epQw60U39ViyCV0fs34gntLnQ6cyp9O6Dj6ffDOWmJ2Hzh2WyFkh7kzT1NI14XvSJ5/xUMQ8G2xYQqWHQeIaQ59e+px3Dnl8tUffhB/yF3pI5fOhM3uFDUss59b1S9Sbl9DTSzIPLnyS9chenLzCsKqsa4+ZS6TvIPRXp5/LOL/EFPMeJdTT+ZHtb9XzVD4fOrNXUJlLfHFuXeeLc+tKNkbT1Pkvkpgmr9ba9rDlEG/byjpt3fSd2fTtZO2i+3izVs3LnHsebRo6362QN/mWMrfa6dk/h7x4LiavOCBU63+iZuPMot34Ddm0g8i7O6fb9lBtetT9iZwP8/lD53yYz598Yzob59bxML9pbk1LhJ38uCeLJ8v06nOW3cXklYYuv7ajdC1UvCuXVgk/lOlru+WhEN0P7WtMz5eH+cyh8+Iwnzu2pqP8prl1OsxvmVunJfowdMUGuyHuZNdVNN6a8+R1GM8bZ12LKB1dqmZ8QKV7mYdCNrk4zE/WD51vh/ncFaaj/Ia5dT7Mb5hb5yVUOocevg1n3MqHQaZb8zx52fjUjXU/WhfXIvxopsn34n4ubjkf5jcMneeHrrJXOB/l8+fWaT+4YW49vO1KdfwW6rCTXXllplvzbfI6rJu86strcTiMky875o9Kc+t8mN8yt46H+czTrXGJ+SifN7emOwHTYT53blVvS8RP05l0u3rHON+auZNXfErcdC3GW7N3L3TeeKs0t54P8xuGzukw/985p1vPE2M6yufMrdOdgPkwnzW3TjfIPCmo6cHO9S6HppzJy52vRdat+drms1OPPD31NjGmo3zG3DrfCXh7Ptv6uXVe6jwpZNV4/pbijZH5QHf4Obq8FljhbW7NOj2l1ObTU+rd3JqO8uvn1vOdgPNhfuXcOv7jLmZ0OSms/hkfl5huzf/JeqA7PSUu/wHO15Um3/PcmnN66t3cmnd6anQxt6aj/Oq59XwnYPwqb8fWt4fD/LDDxiWybs1pifSUuE3X4iW9negc59aM01Ofza0bDvMXc2vmf8Pz2Jr9fLbxyWjO7bJExq15uUR8ynP+tXhJFyc6x7l1/WF+MbdmHebHpS4mxuwXI493AlafYNHp59rEmUnrtnfHPZbIONkX1frtKXHZT8x7TRdj6/Q8z/WH+cXcmmM5t2YukX0noA3T0pAeJ63Dj3Y11OtLXC6x/mRfuPKNH7oXfUrcdhdja+bZqcLm1uyxNdyJcCb9vrCTjefM/Pr94g5LxG/E1mHP/JpPidvu8nSriLk1f2w9xYuZoY7vdGGcznmEefsS1TAMafx7qafE7ejdiU4Jc2vm2KrimBDvyYYU48tG8955ZesSumsPx/QrFwb9Ok+J200aOvcYW4uaW/8363XQ8R0L05Pna29CV49ZQvXx9dfp6XRb37LuFV3MrY863VrK3Dq+Y+H45Hmbl9IOS4w/k+nnIffFKK9sHjoferq1iLn1/I6FaXLKfOR/+xJR2sOnJ+/zJNEPWgyd6090zktsPd2qSphb46RwfsfCvHcP32GJWXpFseZJomvsObduOd1axtw6TgrzOxZmPXl+hyXepD38i70X6EZ7zq2bTreWMLdevj1y5jsW7rDEJX7FxGo7zq35KxQyt86TwoZ3LNxhiUu8wmqVeIzeYeicl8icfAuaW6dJYcs7Fu6wBDKNx+gdhs55iazJt7S5NU0Kj18Cq03H6B2GTjlz6w6Twku9w3JR5mP0DkOnmLl1h0mBYeMR0hmu+RidP7duXCIpbG7dYVJg2Li7i19Hl/tmJTsscYG5FRvMQ+eWw/z2JWZlLIEnNg+dG47ROywxK2MJPLPzr6PLP0bvsMRZGUvgye3wyOzr/EY7lI25FaIwt0IY5lYAAAAAAAAAACDN7wH5gVDYQU6sXgAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyMS0wNy0yNFQyMTozOToyNiswNzowMLSqDyQAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjEtMDctMjRUMjE6Mzk6MjYrMDc6MDDF97eYAAAAIXRFWHRwczpIaVJlc0JvdW5kaW5nQm94ADUwNHg3MjArNTArNTDW4iLDAAAAE3RFWHRwczpMZXZlbABBZG9iZS0yLjAKOZN0DQAAAABJRU5ErkJggg==" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-crypt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-crypt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-crypt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
