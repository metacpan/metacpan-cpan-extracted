use strict;
use warnings;
use Test::More tests => 3;

use FindBin;
use File::Temp qw(tempfile);

use App::TimeClock::Weekly::Report;
use App::TimeClock::Weekly::PrinterInterface;
use App::TimeClock::Weekly::ConsolePrinter;

my $printer = App::TimeClock::Weekly::ConsolePrinter->new();

sub find_timelog {
    return "$FindBin::Bin/" . shift;
}

sub weekly_report {
    my $timelog = shift;
    my ($fh, $filename) = tempfile(UNLINK => 1);

    $printer->_set_output_fh($fh);

    my $report = App::TimeClock::Weekly::Report->new(find_timelog($timelog), $printer);
    $report->_set_report_time("2012/03/15", "16:00:00");
    $report->execute();

    seek $fh, 0, 0;
    chomp(my @report = <$fh>);
    close $fh;

    my $size = (-s $filename);

    return ($size, @report);
}

#
#                  ======================================
#                  Weekly Report Wed Aug 13 08:33:34 2014
#                  ======================================
#
# +------+------+------+------+------+------+------+-------+
# | Mo19 | Tu20 | We21 | Th22 | Fr23 | Sa24 | Su25 | TOTAL |
# +------+------+------+------+------+------+------+-------+
# | 7.50 |      |      |      |      |      |      |  7.50 | Monday
# +------+------+------+------+------+------+------+-------+
# |      | 7.50 |      |      |      |      |      |  7.50 | Tuesday
# +------+------+------+------+------+------+------+-------+
# |      |      | 7.50 |      |      |      |      |  7.50 | Wedensday
# +------+------+------+------+------+------+------+-------+
# |      |      |      | 7.50 |      |      |      |  7.50 | Thursdag
# +------+------+------+------+------+------+------+-------+
# |      |      |      |      | 7.50 |      |      |  7.50 | Friday
# +------+------+------+------+------+------+------+-------+
# | 7.50 | 7.50 | 7.50 | 7.50 | 7.50 | 7.50 | 7.50 | 37.50 |
# +------+------+------+------+------+------+------+-------+
#

{
    my ($size, @report) = weekly_report("timelog.1week");

    is($#report, 5, "Number of lines in report");
    is($size, 212, "Size of report");
    is($report[5], "Weekly reporting is *not* implemented yet!");
}
