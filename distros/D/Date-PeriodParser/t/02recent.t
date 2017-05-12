use Time::Local;
use Date::PeriodParser;

# /(the day (before|after) )?(yesterday|today|tomorrow)/ ||
#        /^this (morning|afternoon|evening|lunchtime)/   ||
#        /^((at)? lunchtime) (yesterday|today|tomorrow)?/ ||
#        /^in the (morning|afternoon|evening)/ ||
#        /^(last |to)night/ ||
#        /^(yesterday|tomorrow) (morning|afternoon|evening)$/ ||
BEGIN {
# Set the base time we use for tests (Fri Apr 12 22:01:36 2002)
$Date::PeriodParser::TestTime = $base = 
    timelocal( '36', '1', '22', '12', '3', '102' );
my ($s, $mn, $h, $d, $m, $y, $wd, $yd, $dst) = localtime($base);

sub slt { scalar localtime timelocal @_ }
  
%tests = (
          'yesterday'                => 
             [ slt(0,  0,  0,  $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(59, 59, 23, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'today'                    =>
             [ slt(0,  0,  0,  $d, $m, $y, $wd, $yd, $dst),
               slt(59, 59, 23, $d, $m, $y, $wd, $yd, $dst) ],
          'tomorrow'                 =>
             [ slt(0,  0,  0,  $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(59, 59, 23, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'the day before yesterday' =>
             [ slt(0,  0,  0,  $d-2, $m, $y, ($wd-2)%7, $yd-2, $dst),
               slt(59, 59, 23, $d-2, $m, $y, ($wd-2)%7, $yd-2, $dst) ],
          'the day before today'     =>
             [ slt(0,  0,  0,  $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(59, 59, 23, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'the day before tomorrow'  =>
             [ slt(0,  0,  0,  $d, $m, $y, $wd, $yd, $dst),
               slt(59, 59, 23, $d, $m, $y, $wd, $yd, $dst) ],
          'the day after yesterday'  =>
             [ slt(0,  0,  0,  $d, $m, $y, $wd, $yd, $dst),
               slt(59, 59, 23, $d, $m, $y, $wd, $yd, $dst) ],
          'the day after today'      =>
             [ slt(0,  0,  0,  $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(59, 59, 23, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'the day after tomorrow'   =>
             [ slt(0,  0,  0,  $d+2, $m, $y, ($wd+2)%7, $yd+2, $dst),
               slt(59, 59, 23, $d+2, $m, $y, ($wd+2)%7, $yd+2, $dst) ],
          'this morning'             => 
             [ slt(0,  0,  0,  $d, $m, $y, ($wd)%7, $yd, $dst),
               slt(0,  0,  12, $d, $m, $y, ($wd)%7, $yd, $dst) ],
          'yesterday morning'        => 
             [ slt(0,  0,  0,  $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(0,  0,  12, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'tomorrow morning'         => 
             [ slt(0,  0,  0,  $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(0,  0,  12, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'this afternoon'           => 
             [ slt(0, 30,  13, $d, $m, $y, ($wd)%7, $yd, $dst),
               slt(0,  0,  18, $d, $m, $y, ($wd)%7, $yd, $dst) ],
          'yesterday afternoon'      => 
             [ slt(0, 30,  13, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(0,  0,  18, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'tomorrow afternoon'       => 
             [ slt(0, 30,  13, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(0,  0,  18, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'this evening'             => 
             [ slt(0,  0,  18, $d, $m, $y, ($wd)%7, $yd, $dst),
               slt(59, 59, 23, $d, $m, $y, ($wd)%7, $yd, $dst) ],
          'yesterday evening'        => 
             [ slt(0,  0,  18, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(59, 59, 23, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'tomorrow evening'         => 
             [ slt(0,  0,  18, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(59, 59, 23, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'at lunchtime'             => 
             [ slt(0,  0,  12, $d, $m, $y, ($wd)%7, $yd, $dst),
               slt(0,  30, 13, $d, $m, $y, ($wd)%7, $yd, $dst) ],
          'at lunchtime yesterday'   => 
             [ slt(0,  0,  12, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(0,  30, 13, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'at lunchtime the day before yesterday' => 
             [ slt(0,  0,  12, $d-2, $m, $y, ($wd-2)%7, $yd-2, $dst),
               slt(0,  30, 13, $d-2, $m, $y, ($wd-2)%7, $yd-2, $dst) ],
          'at lunchtime the day after yesterday' => 
             [ slt(0,  0,  12, $d, $m, $y, ($wd)%7, $yd, $dst),
               slt(0,  30, 13, $d, $m, $y, ($wd)%7, $yd, $dst) ],
          'at lunchtime today'       => 
             [ slt(0,  0,  12, $d, $m, $y, ($wd)%7, $yd, $dst),
               slt(0,  30, 13, $d, $m, $y, ($wd)%7, $yd, $dst) ],
          'at lunchtime the day before today' => 
             [ slt(0,  0,  12, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(0,  30, 13, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'at lunchtime the day after today' => 
             [ slt(0,  0,  12, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(0,  30, 13, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'at lunchtime tomorrow'    => 
             [ slt(0,  0,  12, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(0,  30, 13, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'at lunchtime the day before tomorrow' => 
             [ slt(0,  0,  12, $d, $m, $y, ($wd)%7, $yd, $dst),
               slt(0,  30, 13, $d, $m, $y, ($wd)%7, $yd, $dst) ],
          'at lunchtime the day after tomorrow' => 
             [ slt(0,  0,  12, $d+2, $m, $y, ($wd+2)%7, $yd+2, $dst),
               slt(0,  30, 13, $d+2, $m, $y, ($wd+2)%7, $yd+2, $dst) ],
          'in the morning'           => 
             [ slt(0,  0,  0,  $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(0,  0,  12, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'in the afternoon'         => 
             [ slt(0, 30,  13, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(0,  0,  18, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'in the evening'           => 
             [ slt(0,  0,  18, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(59, 59, 23, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'last night'               => 
             [ slt(0,  0,  21, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(59, 59, 05, $d, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'tonight'                  => 
             [ slt(0,  0,  21, $d, $m, $y, ($wd)%7, $yd, $dst),
               slt(59, 59, 05, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst) ],
          'tomorrow night'           => 
             [ slt(0,  0,  21, $d+1, $m, $y, ($wd+1)%7, $yd+1, $dst),
               slt(59, 59, 05, $d+2, $m, $y, ($wd+2)%7, $yd+2, $dst) ],
         );
  $num_tests = 2*int keys %tests;
}
use Test::More tests=>$num_tests;
use Time::Local;

my($from, $to);
for my $phrase (keys %tests) {
  SKIP: {
          unless (int @{$tests{$phrase}}) {
            skip "missing tests for '$phrase'",2;
          }
          ($from, $to) = parse_period($phrase);
          is((scalar localtime $from),
             $tests{$phrase}->[0],
             "$phrase 'from' ok");
          is((scalar localtime $to),
             $tests{$phrase}->[1],
             "$phrase 'to' ok");
  }
}
