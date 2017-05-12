use warnings;
use strict;

use FindBin;
use File::Temp qw(tempfile);
use Test::More tests => 15;
use Time::Local;

use App::TimeClock::Daily::PrinterInterface;
use App::TimeClock::Daily::ConsolePrinter;

package Dummy;
sub new { bless { }, shift; }
package main;

sub find_timelog {
    return "$FindBin::Bin/" . shift;
}

BEGIN {
    use_ok('App::TimeClock::Daily::Report');
}

my $printer = App::TimeClock::Daily::ConsolePrinter->new();
my $timelog = find_timelog("timelog.empty");

ok(my $report = App::TimeClock::Daily::Report->new($timelog, $printer), "Report can be created");

# private get/set report_time methods
is($report->_get_report_time(), time, "Report time is current time by default");
$report->_set_report_time("2010/01/31", "12:30:00");
is($report->_get_report_time(), timelocal(00,30,12, 31,00,2010), "Report time is set");

SKIP: {
    eval { use Test::Exception };
    skip "Test::Exception not installed", 12 if $@;

    dies_ok (sub {App::TimeClock::Daily::Report->new()}, "No arguments to new()");
    dies_ok (sub {App::TimeClock::Daily::Report->new($timelog)}, "Missing printer argument to new()");
    dies_ok (sub {App::TimeClock::Daily::Report->new($timelog, $timelog)}, "Printer is not a reference");
    dies_ok (sub {App::TimeClock::Daily::Report->new($timelog, \$timelog)}, "Printer is not an object");
    dies_ok (sub {App::TimeClock::Daily::Report->new($timelog, Dummy->new())}, "Printer is not a PrinterInterface");

    dies_ok (sub {App::TimeClock::Daily::Report->new("./nothing_to_find_here", $printer)}, "Timelog file does not exist");

    SKIP: {
        skip "Running on Windows", 2 if $^O eq 'MSWin32';

        my ($fh, $filename) = tempfile(UNLINK => 1);
        chmod 0220, $filename;

        dies_ok (sub {App::TimeClock::Daily::Report->new($filename, $printer)}, "Timelog not readable");

        chmod 0664, $filename;

        {
            my $report = App::TimeClock::Daily::Report->new($filename, $printer);
            unlink $filename;
            dies_ok (sub {$report->execute()}, "Timelog deleted");
        }
    }
	
    my ($fh, $filename) = tempfile(UNLINK => 1);

    # private _read_lines
    dies_ok (sub {$report->_read_lines($fh)}, "Prematurely end of file");

    open my $file, '<', find_timelog("timelog.bad3");
    dies_ok (sub {$report->_read_lines($file)}, "Excepected check in");
    close $file;

    open $file, '<', find_timelog("timelog.bad4");
    dies_ok (sub {$report->_read_lines($file)}, "Excepected check out");
    close $file;
}
