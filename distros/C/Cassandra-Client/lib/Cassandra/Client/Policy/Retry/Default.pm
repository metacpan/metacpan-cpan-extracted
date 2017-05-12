package Cassandra::Client::Policy::Retry::Default;
use 5.010;
use strict;
use warnings;

use Cassandra::Client::Policy::Retry qw/
    try_next_host
    retry
    rethrow
/;

sub new {
    my ($class)= @_;
    return bless {}, $class;
}

sub on_read_timeout {
    my ($self, $statement, $consistency_level, $required_responses, $received_responses, $data_retrieved, $nr_retries)= @_;

    return rethrow if $nr_retries;
    return retry if $received_responses >= $required_responses && !$data_retrieved;
    return rethrow;
}

sub on_unavailable {
    my ($self, $statement, $consistency_level, $required_replicas, $alive_replicas, $nr_retries)= @_;

    return rethrow if $nr_retries;
    return try_next_host;
}

sub on_write_timeout {
    my ($self, $statement, $consistency_level, $write_type, $required_acks, $received_acks, $nr_retries)= @_;

    return rethrow if $nr_retries;
    return retry if $write_type eq 'BATCH_LOG';
    return rethrow;
}

sub on_request_error {
    my ($self, $statement, $consistency_level, $error, $nr_retries)= @_;

    return rethrow if $nr_retries;
    return try_next_host;
}

1;
