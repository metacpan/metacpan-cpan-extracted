use Test::More tests=>24;
use Time::Local;
use Date::PeriodParser;
{
  $Date::PeriodParser::TestTime = $base = 1018674096;
  $Date::PeriodParser::TestTime = $base = 1018674096; # eliminate "used only once" warning
}

sub slt { scalar localtime timelocal @_ }
sub sl { scalar localtime shift }
my ($s, $mn, $h, $d, $m, $y, $wd, $yd, $dst) = localtime($base);


%tests = (
          'a week ago'                =>
             [ slt(0,  0,  0,  $d-7, $m, $y, abs($wd-7)%7, $yd-7, $dst),
               slt(59, 59, 23, $d-7, $m, $y, abs($wd-7)%7, $yd-7, $dst) ],
          'six weeks from now'        =>
             [ slt(0,  0,  0,  24, 4, $y, abs($wd-7)%7, $yd-7, $dst),
               slt(59, 59, 23, 24, 4, $y, abs($wd-7)%7, $yd-7, $dst) ],
          '1 day ago'                =>
             [ slt(0,  0,  0,  $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(59, 59, 23, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'twenty years ago'                =>
             [ slt(0,  0,  0,  $d, $m, $y-20, ($wd-1)%7, $yd-1, $dst),
               slt(59, 59, 23, $d, $m, $y-20, ($wd-1)%7, $yd-1, $dst) ],
          'four days ago'                =>
             [ slt(0,  0,  0,  $d-4, $m, $y, ($wd-4)%7, $yd-4, $dst),
               slt(59, 59, 23, $d-4, $m, $y, ($wd-4)%7, $yd-4, $dst) ],
          'in three days time'        =>
             [ slt(0,  0,  0,  $d+3, $m, $y, ($wd+3)%7, $yd+3, $dst),
               slt(59, 59, 23, $d+3, $m, $y, ($wd+3)%7, $yd+3, $dst) ],
          'in 3 days time'        =>
             [ slt(0,  0,  0,  $d+3, $m, $y, ($wd+3)%7, $yd+3, $dst),
               slt(59, 59, 23, $d+3, $m, $y, ($wd+3)%7, $yd+3, $dst) ],
          'seven days away'        =>
             [ slt(0,  0,  0,  $d+7, $m, $y, ($wd+7)%7, $yd+7, $dst),
               slt(59, 59, 23, $d+7, $m, $y, ($wd+7)%7, $yd+7, $dst) ],
           'one hundred days ago'  =>
             [ slt(0,  0,  0,  2, 0, $y, ($wd+7)%7, $yd+7, $dst),
               slt(59, 59, 23, 2, 0, $y, ($wd+7)%7, $yd+7, $dst) ],
           'two thousand days ago'  =>
             [ slt(0,  0,  0,  20, 9, 96, ($wd+7)%7, $yd+7, $dst),
               slt(59, 59, 23, 20, 9, 96, ($wd+7)%7, $yd+7, $dst) ],
           'in ten months'          =>
             [ slt(0,  0,  0,  $d, 1, $y+1, ($wd+7)%7, $yd+7, $dst),
               slt(59, 59, 23, $d, 1, $y+1, ($wd+7)%7, $yd+7, $dst) ],
           'in a million days'      =>
             [ slt(0,  0,  0,  9, 2, 2840-1900, ($wd+7)%7, $yd+7, $dst),
               slt(59, 59, 23, 9, 2, 2840-1900, ($wd+7)%7, $yd+7, $dst) ],
         );

my($from, $to);
foreach $interval (keys %tests) {
  ($from, $to) = parse_period($interval);
  is(sl($from), $tests{$interval}->[0]);
  is(sl($to), $tests{$interval}->[1]);
}
