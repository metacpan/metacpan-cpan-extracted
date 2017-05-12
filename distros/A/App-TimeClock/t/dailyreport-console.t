use strict;
use warnings;
use Test::More tests => 18;

use FindBin;
use File::Temp qw(tempfile);

use App::TimeClock::Daily::Report;
use App::TimeClock::Daily::PrinterInterface;
use App::TimeClock::Daily::ConsolePrinter;

my $printer = App::TimeClock::Daily::ConsolePrinter->new();

sub find_timelog {
    return "$FindBin::Bin/" . shift;
}

sub daily_report {
    my $timelog = shift;
    my ($fh, $filename) = tempfile(UNLINK => 1);

    $printer->_set_output_fh($fh);

    my $report = App::TimeClock::Daily::Report->new(find_timelog($timelog), $printer);
    $report->_set_report_time("2012/03/15", "16:00:00");
    $report->execute();

    seek $fh, 0, 0;
    chomp(my @report = <$fh>);
    close $fh;

    my $size = (-s $filename);

    return ($size, @report);
}

#
#                  =====================================
#                  Daily Report Mon Dec  3 16:52:44 2012
#                  =====================================
# 
# * Thu 2012/03/15 (08:07:06 - 16:15:14) *
# +--------------------------------------------------------------+-------+
# | Total Daily Hours                                            |  8.14 |
# +--------------------------------------------------------------+-------+
# | Afternoon                                                    |  3.05 |
# +--------------------------------------------------------------+-------+
# | FirstCheckIn                                                 |  4.07 |
# +--------------------------------------------------------------+-------+
# | Lunch                                                        |  1.02 |
# +--------------------------------------------------------------+-------+
# 
# TOTAL = 8.14 hours
# PERIOD = 1 days
# AVERAGE = 8.14 hours/day
{
    my ($size, @report) = daily_report("timelog.1day");

    is($#report, 18, "Number of lines in report");
    is($size, 926, "Size of report");
    is($report[ 7], "| Total Daily Hours                                            |  8.14 |", "Total Daily Hours");
    is($report[ 9], "| Afternoon                                                    |  3.05 |", "Afternoon project");
    is($report[11], "| FirstCheckIn                                                 |  4.07 |", "FirstCheckIn project");
    is($report[13], "| Lunch                                                        |  1.02 |", "Lunch");
    is($report[16], "TOTAL = 8.14 hours", "Total hours worked");
    is($report[17], "PERIOD = 1 days", "Period worked");
    is($report[18], "AVERAGE = 8.14 hours/day");
}

{
    my ($size, @report) = daily_report("timelog.dos");
    is($report[ 9], "| Afternoon                                                    |  3.05 |", "Afternoon project");
}

{
    my ($size, @report) = daily_report("timelog.2days");
    is($report[-2], "PERIOD = 2 days", "Period worked");
}

{
    my ($size, @report) = daily_report("timelog.empty");
    is($report[-3], "TOTAL = 0.00 hours", "Total hours worked");
    is($report[-2], "PERIOD = 0 days", "Period worked");

}

{
    my ($size, @report) = daily_report("timelog.open");
    is($report[-6], "| Support (NOT checked out)                                    |  3.50 |", "Support hours");
    # TODO: Test that header prints correct report time
}

{
    my ($size, @report) = daily_report("timelog.pastmidnight");
    is($report[-6], "| ThisWillBeALongDay                                           | 18.00 |", "Long hours");
    is($report[-3], "TOTAL = 26.14 hours", "Total hours worked");
}

{
    my ($size, @report) = daily_report("timelog.issue13");
    is($size, 1872, "Size of report");
    is($report[9], "| cam                                                          |  8.00 |", "Eight hours");
}
