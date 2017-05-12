use warnings;
use strict;

use FindBin;
use File::Temp qw(tempfile);
use Test::More tests => 10;


use App::TimeClock::Weekly::PrinterInterface;
use App::TimeClock::Weekly::ConsolePrinter;

package Dummy;
sub new { bless { }, shift; }
package main;

sub find_timelog {
    return "$FindBin::Bin/" . shift;
}

BEGIN {
    use_ok('App::TimeClock::Weekly::Report');
}


my $printer = App::TimeClock::Weekly::ConsolePrinter->new();
my $timelog = find_timelog("timelog.empty");

ok(my $report = App::TimeClock::Weekly::Report->new($timelog, $printer));

SKIP: {
    eval { use Test::Exception };
    skip "Test::Exception not installed", 12 if $@;


    dies_ok (sub {App::TimeClock::Weekly::Report->new()}, "No arguments to new()");
    dies_ok (sub {App::TimeClock::Weekly::Report->new($timelog)}, "Missing printer argument to new()");
    dies_ok (sub {App::TimeClock::Weekly::Report->new($timelog, $timelog)}, "Printer is not a reference");
    dies_ok (sub {App::TimeClock::Weekly::Report->new($timelog, \$timelog)}, "Printer is not an object");
    dies_ok (sub {App::TimeClock::Daily::Report->new($timelog, Dummy->new())}, "Printer is not a PrinterInterface");

    dies_ok (sub {App::TimeClock::Weekly::Report->new("./nothing_to_find_here", $printer)}, "Timelog file does not exist");

    SKIP: {
        skip "Running on Windows", 2 if $^O eq 'MSWin32';

        my ($fh, $filename) = tempfile(UNLINK => 1);
        chmod 0220, $filename;

        dies_ok (sub {App::TimeClock::Weekly::Report->new($filename, $printer)}, "Timelog not readable");

        chmod 0664, $filename;

        {
            my $report = App::TimeClock::Weekly::Report->new($filename, $printer);
            unlink $filename;
            dies_ok (sub {$report->execute()}, "Timelog deleted");
        }
    }
}
