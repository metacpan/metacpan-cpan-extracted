package Cassandra::Client::Policy::Retry;
use 5.010;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK= (qw/try_next_host retry rethrow/);

sub try_next_host {
    my $cl= shift;
    return 'retry';
}

sub retry {
    my $cl= shift;
    return 'retry';
}

sub rethrow {
    return 'rethrow';
}

1;
