
package MyLog;

$MyLog::mylog = bless {}, 'MyLog';

sub new {
    return $mylog;
}

sub can {
    0;
}

sub info {
    shift;
    push @{ $MyLog::mylog->{info} }, "@_";
}

sub error {
    shift;
    push @{ $MyLog::mylog->{error} }, "@_";
}

sub debug {
    shift;
    push @{ $MyLog::mylog->{debug} }, "@_";
}


package TestApp;

use strict;
use warnings;

use Catalyst qw/ MemoryUsage /;

__PACKAGE__->config(
    'Plugin::MemoryUsage' => {
        report => 1,
        action_milestones => 1,
    },
);

__PACKAGE__->setup;

sub log {
    return MyLog->new;
}


1;
