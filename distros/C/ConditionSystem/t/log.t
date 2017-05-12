use strict;
use warnings FATAL => 'all';
use Test::More;

{
    package MalformedLogEntry;
    use Moose;
    extends 'Throwable::Error';
}

{
    package MyApp;
    use ConditionSystem;

    sub parse_log_entry {
        my $entry = shift or die "Must specify entry";
        if($entry =~ /(\d+-\d+-\d+) (\d+:\d+:\d+) (\w+) (.*)/) {
            return ($1, $2, $3, $4);
        }
        else {
            restart_case {
                MalformedLogEntry->new($entry),
            }
            bind_continue(use_value => sub { return shift }),
            bind_continue(log => sub {
                warn "*** Invalid entry: $entry";
                return undef;
            });
        }
    };
}

use ConditionSystem;

my @logs = with_handlers {
    (
        [ MyApp::parse_log_entry('2010-01-01 10:09:5 WARN Test') ],
        [ MyApp::parse_log_entry('Oh no bad data') ],
        [ MyApp::parse_log_entry('2010-10-12 12:11:03 INFO Notice it still carries on!') ]
    );
}
handle(MalformedLogEntry => restart(use_value => 'hungry hungry hippos'));

is_deeply(\@logs, [
    [ '2010-01-01', '10:09:5', 'WARN', 'Test' ],
    [ 'hungry hungry hippos' ],
    [ '2010-10-12', '12:11:03', 'INFO', 'Notice it still carries on!']
]);

done_testing;

