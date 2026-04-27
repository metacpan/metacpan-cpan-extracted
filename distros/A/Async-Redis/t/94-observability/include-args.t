use strict;
use warnings;
use Test2::V0;
use Async::Redis::Telemetry;

subtest 'include_args default is 0' => sub {
    my $t = Async::Redis::Telemetry->new;
    is $t->{include_args}, 0, 'default off';
};

subtest 'include_args=0 produces command-name-only span data' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_span(
        0, 1, 'HSET', 'key', 'f', 'v'
    );
    is $formatted, 'HSET', 'command name only';
};

subtest 'include_args=1 produces full command' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_span(
        1, 0, 'HSET', 'key', 'f', 'v'
    );
    like $formatted, qr/HSET.*key/, 'args included';
};

subtest 'credential redaction still applies when include_args=1' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_span(
        1, 1, 'AUTH', 'secretpassword'
    );
    unlike $formatted, qr/secretpassword/, 'password redacted';
};

done_testing;
