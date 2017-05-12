use Test::More tests => 41;

BEGIN { require_ok ( 'ASNMTAP::Time' ) };

BEGIN { use_ok ( 'ASNMTAP::Time' ) };
BEGIN { use_ok ( 'ASNMTAP::Time', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Time', qw(:EPOCHTIME) ) };
BEGIN { use_ok ( 'ASNMTAP::Time', qw(:LOCALTIME) ) };
BEGIN { use_ok ( 'ASNMTAP::Time', qw(SEC MIN HOUR DAY WEEK &get_timeslot &get_yearMonthDay &get_yyyymmddhhmmsswday &get_datetimeSignal &get_datetime &get_logfiledate &get_csvfiledate &get_csvfiletime &get_epoch &get_week &get_wday &get_hour &get_min &get_seconds &get_day &get_month &get_year) ) };

TODO: {
  ok ( get_timeslot (), 'ASNMTAP::Time::get_timeslot()' );

  ok ( get_yyyymmddhhmmsswday (), 'ASNMTAP::Time::get_yyyymmddhhmmsswday()' );
  ok ( get_datetimeSignal (), 'ASNMTAP::Time::get_datetimeSignal()' );
  ok ( get_datetime (), 'ASNMTAP::Time::get_datetime()' );

  ok ( get_hour (), 'ASNMTAP::Time::get_hour()' );
  ok ( get_min (), 'ASNMTAP::Time::get_min()' );
  ok ( get_seconds (), 'ASNMTAP::Time::get_seconds()' );

  ok ( get_epoch ( 'now' ), 'ASNMTAP::Time::get_epoch(\'now\')' );
  ok ( get_week ( 'now' ), 'ASNMTAP::Time::get_week(\'now\')' );

  ok ( get_csvfiletime (), 'ASNMTAP::Time::get_csvfiletime()' );

  use Time::Local;
  my $time = time();
  my $timeslot = timelocal ( 0, (localtime($time))[1,2,3,4,5] );
  my ($year, $month, $day, $hour, $min, $seconds, $wday) = ((localtime($time))[5]+1900, (localtime($time))[4]+1, (localtime($time))[3,2,1,0,6]);
  $year    = sprintf ("%04d", $year);
  $month   = sprintf ("%02d", $month);
  $day     = sprintf ("%02d", $day);
  $seconds = sprintf ("%02d", $seconds);
  $min     = sprintf ("%02d", $min);
  $hour    = sprintf ("%02d", $hour);
 
  is ( get_epoch ( 'now' ), $time, 'ASNMTAP::Time::get_epoch(\'now\')' );
  ok ( get_week ( 'now', $time ), 'ASNMTAP::Time::get_week(\'now\', time())' );

  is ( get_wday ( 'now' ), $wday, 'ASNMTAP::Time::get_wday(\'now\')' );
  is ( get_day ( 'now' ), $day, 'ASNMTAP::Time::get_day(\'now\')' );
  is ( get_month ( 'now' ), $month, 'ASNMTAP::Time::get_month(\'now\')' );
  is ( get_year ( 'now' ), $year, 'ASNMTAP::Time::get_year(\'now\')' );

  is ( get_hour ( $time ), $hour, 'ASNMTAP::Time::get_hour(time())' );
  is ( get_min ( $time ), $min, 'ASNMTAP::Time::get_min(time())' );
  is ( get_seconds ( $time ), $seconds, 'ASNMTAP::Time::get_seconds(time())' );

  is ( get_epoch ( 'now', $time ), $time, 'ASNMTAP::Time::get_epoch(\'now\', time())' );
  is ( get_wday ( 'now', $time ), $wday, 'ASNMTAP::Time::get_day(\'now\', time())' );
  is ( get_day ( 'now', $time ), $day, 'ASNMTAP::Time::get_day(\'now\', time())' );
  is ( get_month ( 'now', $time ), $month, 'ASNMTAP::Time::get_month(\'now\')' );
  is ( get_year ( 'now', $time ), $year, 'ASNMTAP::Time::get_year(\'now\')' );

  is ( get_yearMonthDay (), "$year$month$day", 'ASNMTAP::Time::get_yearMonthDay()' );
  is ( get_logfiledate (), "$year$month$day", 'ASNMTAP::Time::get_logfiledate()' );
  is ( get_csvfiledate (), "$year/$month/$day", 'ASNMTAP::Time::get_csvfiledate()' );

  is ( get_yearMonthDay ( $time ), "$year$month$day", 'ASNMTAP::Time::get_yearMonthDay(time())' );

  is ( get_timeslot ( $time ), $timeslot, 'ASNMTAP::Time::get_timeslot(time())' );

  is ( get_epoch (), undef, 'ASNMTAP::Time::get_epoch()' );
  is ( get_week (), undef, 'ASNMTAP::Time::get_week()' );
  is ( get_wday (), undef, 'ASNMTAP::Time::get_wday()' );
  is ( get_day (), undef, 'ASNMTAP::Time::get_day()' );
  is ( get_month (), undef, 'ASNMTAP::Time::get_month()' );
  is ( get_year (), undef, 'ASNMTAP::Time::get_year()' );
}
