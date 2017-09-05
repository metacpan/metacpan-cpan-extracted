package Anego::CLI::Status;
use strict;
use warnings;
use utf8;

use Anego::Config;
use Anego::Logger;
use Anego::Task::GitLog;

sub run {
    my $config = Anego::Config->load;

    my $logs = Anego::Task::GitLog->fetch;
    errorf("No change log\n") if @{ $logs } == 0;

    printf <<'__EOF__', $config->rdbms, $config->database, $config->schema_class, $config->schema_path;

RDBMS:        %s
Database:     %s
Schema class: %s (%s)

Hash     Commit message
--------------------------------------------------
__EOF__

    for my $log (@{ $logs }) {
        printf "%7s  %s\n", $log->{hash}, $log->{message};
    }
}

1;
