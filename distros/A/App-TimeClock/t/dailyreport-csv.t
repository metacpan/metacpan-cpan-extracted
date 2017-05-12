use strict;
use warnings;
use Test::More tests => 6;

use FindBin;
use File::Temp qw(tempfile);
use POSIX qw(strftime);

use App::TimeClock::Daily::Report;
use App::TimeClock::Daily::PrinterInterface;
use App::TimeClock::Daily::CsvPrinter;

my $printer = App::TimeClock::Daily::CsvPrinter->new();

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

{
    my ($size, @report) = daily_report("timelog.1day");
    my $day = strftime("%a", 0, 0, 0, 15, 2, 112);
    is($#report, 0, "Number of lines in report");
    is($size, 47+length($day), "Size of report");
    is($report[0], '"'.$day.'","2012/03/15","08:07:06","16:15:14",8.135278', "First line");
}

{
    my ($size, @report) = daily_report("timelog.2days");
    my $day1 = strftime("%a", 0, 0, 0, 15, 2, 112);
    my $day2 = strftime("%a", 0, 0, 0, 16, 2, 112);
    is($#report, 1, "Number of lines in report");
    is($size, 94+length($day1)+length($day2), "Size of report");
    is($report[1], '"'.$day2.'","2012/03/16","08:00:00","16:00:00",8.000000', "Last line");
}
