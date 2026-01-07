# t/94-observability/redaction.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis::Telemetry;

subtest 'AUTH password redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'AUTH', 'supersecret'
    );
    is($formatted, 'AUTH [REDACTED]', 'single password redacted');
};

subtest 'AUTH user password redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'AUTH', 'myuser', 'mysecretpass'
    );
    is($formatted, 'AUTH myuser [REDACTED]', 'ACL password redacted, username visible');
};

subtest 'CONFIG SET requirepass redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'CONFIG', 'SET', 'requirepass', 'newpassword'
    );
    is($formatted, 'CONFIG SET requirepass [REDACTED]', 'password config redacted');
};

subtest 'CONFIG SET masterauth redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'CONFIG', 'SET', 'masterauth', 'replicapass'
    );
    is($formatted, 'CONFIG SET masterauth [REDACTED]', 'masterauth redacted');
};

subtest 'CONFIG SET non-password not redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'CONFIG', 'SET', 'maxmemory', '100mb'
    );
    is($formatted, 'CONFIG SET maxmemory 100mb', 'non-password config visible');
};

subtest 'CONFIG GET not redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'CONFIG', 'GET', 'maxmemory'
    );
    is($formatted, 'CONFIG GET maxmemory', 'CONFIG GET visible');
};

subtest 'MIGRATE AUTH redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'MIGRATE', 'host', '6379', 'key', '0', '5000', 'AUTH', 'password'
    );
    like($formatted, qr/AUTH \[REDACTED\]/, 'MIGRATE AUTH password redacted');
};

subtest 'MIGRATE AUTH2 redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'MIGRATE', 'host', '6379', 'key', '0', '5000', 'AUTH2', 'user', 'pass'
    );
    like($formatted, qr/AUTH2 user \[REDACTED\]/, 'MIGRATE AUTH2 password redacted');
};

subtest 'regular commands not redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'GET', 'mykey'
    );
    is($formatted, 'GET mykey', 'GET visible');

    $formatted = Async::Redis::Telemetry::format_command_for_log(
        'SET', 'mykey', 'myvalue'
    );
    is($formatted, 'SET mykey myvalue', 'SET visible');

    $formatted = Async::Redis::Telemetry::format_command_for_log(
        'HSET', 'hash', 'field', 'value'
    );
    is($formatted, 'HSET hash field value', 'HSET visible');
};

subtest 'HELLO AUTH redacted' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'HELLO', '3', 'AUTH', 'user', 'pass'
    );
    like($formatted, qr/AUTH user \[REDACTED\]/, 'HELLO AUTH redacted');
};

subtest 'case insensitive' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log(
        'auth', 'password'
    );
    is($formatted, 'AUTH [REDACTED]', 'lowercase auth redacted');

    $formatted = Async::Redis::Telemetry::format_command_for_log(
        'Auth', 'Password'
    );
    is($formatted, 'AUTH [REDACTED]', 'mixed case auth redacted');
};

subtest 'empty command' => sub {
    my $formatted = Async::Redis::Telemetry::format_command_for_log();
    is($formatted, '', 'empty command returns empty string');
};

done_testing;
