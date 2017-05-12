# Copyright (c) 2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# test get_localtime

use strict;
use Date::Gregorian;

$| = 1;

my $P_DISABLE = 'WITHOUT_DATE_GREGORIAN_LOCALTIME_TESTS';
if (exists($ENV{$P_DISABLE}) && $ENV{$P_DISABLE}) {
    print "1..0 # SKIP disabled via environment parameter\n";
    exit 0;
}

print "1..7\n";

my $success = 1;
my $overall_success = 1;

sub test {
    my ($n, $ok) = @_;
    $overall_success &&= $ok;
    print !$ok && 'not ', "ok $n\n";
}

sub fmt_time {
    my ($S, $M, $H, $d, $m, $y, $wd, $yd, $is) = @_;
    return
	sprintf '%04d%02d%02d%02d%02d%02d %d',
	    1900+$y, 1+$m, $d, $H, $M, $S, $is;
}

sub check_conversion {
    my ($nr, $date) = @_;
    my ($y, $m, $d) = $date->get_ymd;
    my $time = $date->get_localtime;
    my $ds = sprintf '%04d%02d%02d', $y, $m, $d;
    my $ts = 'undef';
    my $gs = 'undef';
    my $cdate = 'X';
    my $ctime = 'X';
    my $ok = defined $time;
    if ($ok) {
	$ts = fmt_time(localtime $time);
	$gs = fmt_time(gmtime $time);
	$cdate = $ds eq substr($ts, 0, 8)? '1': '0';
	$ctime = '000000' eq substr($ts, 8, 6)? '1': '0';
	$ok = '1' eq $cdate && '1' eq $ctime;
    }
    print "# $nr: $ds | $time $gs $ts $cdate $ctime\n";
    $success &&= $ok;
}

my $now = time;
print
    "# now: $now ", fmt_time(gmtime $now), " ",
    fmt_time(localtime $now), "\n";

my $date = Date::Gregorian->new->set_ymd(2006, 12, 1);
test 1, $date;

my $limit = $date->new->set_ymd(2008, 1, 31);
test 2, $limit;

my $iterator = $date->iterate_days_upto($limit, '<=');
test 3, $iterator;

my $count = 0;
while ($iterator->()) {
    ++$count;
    check_conversion($count, $date);
}
test 4, $success;
test 5, 31+365+31 == $count;

my $xxl = '999999';
$date->set_ymd(0+$xxl, 12, 31);
my $result = eval {
    $date->get_localtime;
};
test 6, !$@;
if (defined $result) {
    my $ts = fmt_time(localtime $result);
    print "# ${xxl}1231 | $result $ts\n";
    test 7, "${xxl}1231000000" eq substr($ts, 0, 10 + length($xxl));
}
else {
    print "ok 7 # SKIP xxl timestamps not implemented\n";
}

if (!$overall_success) {
    warn <<"EOT";

-------------------------------------------------------------------
NOTICE: You can disable the tests for localtime compatibility by
setting $P_DISABLE=1 in the environment.
Date::Gregorian can safely be installed and used without this test
as long as such compatibility is not relied upon (which would be
hard to establish anyway).
-------------------------------------------------------------------

EOT
}

__END__
