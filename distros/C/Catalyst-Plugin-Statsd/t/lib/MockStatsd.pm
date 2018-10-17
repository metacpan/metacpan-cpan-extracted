package MockStatsd;

use Moo;
extends 'Net::Statsd::Tiny';

our @Data;

sub _record {
    my ($self, $suffix, $metric, $value) = @_;

    if ($metric =~ /^catalyst\./) {
        push @Data, "$metric:$value$suffix";
    }
}

sub flush {
}

1;
