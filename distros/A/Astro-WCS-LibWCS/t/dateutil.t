#! /usr/bin/perl -w
use strict;

use Astro::WCS::LibWCS qw( :functions );

my $ntests = 13;
print "1..$ntests\n";

my $date = 1999.0302; # March 2, 1999
my $time = 6.00000000; # 6 am
my $jd = 2451239.75;
my $epoch = 1999.16506849315;
my $fd = '1999-03-02T06:00:00.000';
my $ts = 1551506400;
my ($iyr, $imon, $iday, $ihr, $imin, $sec) =
    (1999, 3, 2, 6, 0, 0);

#
# dt2jd()
#
print( dt2jd($date,$time) == $jd ? ok() : not_ok() );

#
# jd2dt()
#
my ($date_tmp,$time_tmp);
jd2dt($jd,$date_tmp,$time_tmp);
print( ($date_tmp == $date && $time_tmp == $time) ? ok() : not_ok() );

#
# jd2ep()
#
print( equal(jd2ep($jd),$epoch,1e-12) ? ok() : not_ok() );

#
# ep2fd()
#
print( ep2fd($epoch) eq $fd ? ok() : not_ok() );

#
# ep2ts()
#
print( equal(ep2ts($epoch),$ts,1e-2) ? ok() : not_ok() );

#
# ep2jd()
#
print( equal(ep2jd($epoch),$jd,1e-5) ? ok() : not_ok() );

#
# jd2fd()
#
print( jd2fd($jd) eq $fd ? ok() : not_ok() );

#
# jd2ts()
#
print( equal(jd2ts($jd),$ts,1e-3) ? ok() : not_ok() );

#
# ts2jd()
#
print( equal(ts2jd($ts),$jd,1e-2) ? ok() : not_ok() );

#
# dt2ep()
#
print( equal(dt2ep($date,$time),$epoch,1e-12) ? ok() : not_ok() );

#
# ep2dt()
#
$date_tmp = $time_tmp = 0;
ep2dt($epoch,$date_tmp,$time_tmp);
print( $date_tmp == $date && equal($time_tmp,$time,1e-9) ? ok() : not_ok() );

#
# fd2jd()
#
print( fd2jd($fd) == $jd ? ok() : not_ok() );

#
# dt2fd
#
print ( dt2fd($date,$time) eq $fd ? ok() : not_ok() );

#
# dt2i
#

sub ok {
    return "ok\n";
}

sub not_ok {
    return "not ok\n";
}

sub equal {
    my ($n1, $n2, $range) = @_;

    return 1 if (abs($n1-$n2) < $range);

    return 0;
}
