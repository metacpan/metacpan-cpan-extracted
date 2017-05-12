use strict;
use warnings;

use Test::More;
use Test::Warn;

BEGIN {
    use_ok('BusyBird::Log', "bblog");
}

{
    local $BusyBird::Log::Logger = undef;
    warning_is { bblog('error', 'log is suppressed') } undef, 'Log is suppressed.';
}


my $log = "";

$BusyBird::Log::Logger = sub {
    my ($level, $msg) = @_;
    $log .= "$level: $msg\n";
};

bblog("notice", "log test");
is($log, "notice: log test\n", "log OK");

{
    my @logs = ();
    local $BusyBird::Log::Logger = sub {
        my ($level, $msg) = @_;
        push(@logs, [$level, $msg]);
    };
    bblog("warn", "warning test");
    is($log, "notice: log test\n", '$log is not changed.');
    is_deeply(@logs, ['warn', 'warning test'], 'logged to @logs');
}

bblog('info', 'end log');
is($log, "notice: log test\ninfo: end log\n", "Logger is restored.");

done_testing();
