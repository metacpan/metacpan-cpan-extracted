# t/benchmarks.pl -- compare times of several different sorting techniques

use Benchmark 'timethese', 'cmpthese';
use Data::Sorting 'sorted_array';

my @text_chars = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9, ' ', ',', '.', '-' );
my @text_100 = map { join '', @text_chars[ map int(rand(@text_chars)), 1 .. int(rand(100)) ] } 1..100;
my @text_1000 = map { join '', @text_chars[ map int(rand(@text_chars)), 1 .. int(rand(100)) ] } 1..1000;

cmpthese timethese 0, {
  ctrl_sort   => sub { sort @text_100 },
  ctrl_cmp    => sub { sort { $a cmp $b } @text_100 },
  ctrl_cmplc  => sub { sort { lc($a) cmp lc($b) } @text_100 },
  sfnc_sort   => sub { sorted_array @text_100 },
  sfnc_packed => sub { sorted_array @text_100, -engine=>'packed' },
  sfnc_precal => sub { sorted_array @text_100, -engine=>'precalc' },
  sfnc_orcish => sub { sorted_array @text_100, -engine=>'orcish' },
  sfnc_locl   => sub { sorted_array @text_100, -compare=>'lc_locale'},
  sfnc_natrl  => sub { sorted_array @text_100, -compare=>'natural'},
};

__END__

                 Rate sfnc_natrl sfnc_locl sfnc_orcish sfnc_precal sfnc_packed sfnc_sort ctrl_cmplc ctrl_sort ctrl_cmp
sfnc_natrl     22.0/s         --      -44%        -51%        -60%        -91%     -100%      -100%     -100%    -100%
sfnc_locl      39.0/s        77%        --        -12%        -29%        -84%      -99%      -100%     -100%    -100%
sfnc_orcish    44.5/s       102%       14%          --        -19%        -82%      -99%      -100%     -100%    -100%
sfnc_precal    55.1/s       150%       41%         24%          --        -78%      -99%      -100%     -100%    -100%
sfnc_packed     251/s      1039%      542%        463%        355%          --      -94%      -100%     -100%    -100%
sfnc_sort      4416/s     19968%    11214%       9820%       7915%       1662%        --      -100%     -100%    -100%
ctrl_cmplc   922421/s   4191487%  2363126%    2071904%    1674120%     367925%    20787%         --      -10%     -12%
ctrl_sort   1026088/s   4662565%  2628721%    2304769%    1862279%     409286%    23135%        11%        --      -2%
ctrl_cmp    1046912/s   4757192%  2682072%    2351546%    1900076%     417594%    23606%        13%        2%       --
