use strict;
use warnings;
use Test::More;## tests => 6;

use FindBin;
use File::Temp qw(tempfile);

use App::TimeClock::Daily::Report;
use App::TimeClock::Daily::PrinterInterface;
use App::TimeClock::Daily::HtmlPrinter;

my $printer = App::TimeClock::Daily::HtmlPrinter->new();

sub find_timelog {
    return "$FindBin::Bin/" . shift;
}

sub daily_report {
    my $timelog = shift;
    my ($fh, $filename) = tempfile;#(UNLINK => 1);

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
    my ($size, @report) = daily_report("timelog.open");
    is($#report, 24, "Number of lines in report");
    is($size, 1496, "Size of report");
    is($report[21], "<tr><td>Support (NOT checked out)                                   </td><td class='N'> 3.50</td></tr>",
       "Dangling project");
}

{
    my ($size, @report) = daily_report("timelog.1day");
    is($#report, 24, "Number of lines in report");
    is($size, 1496, "Size of report");
    is($report[18], "<tr><th>Total Daily Hours</th><th class='N'> 8.14</th></tr>", "Total hours");
    is($report[19], "<tr><td>Afternoon                                                   </td><td class='N'> 3.05</td></tr>",
       "Afternoon hours");
}

{
    my ($size, @report) = daily_report("timelog.2days");
    is($#report, 28, "Number of lines in report");
    is($size, 1732, "Size of report");
    is($report[0], '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
       "First line");
    is($report[28], '</body></html>', "Last line");
}

done_testing();
