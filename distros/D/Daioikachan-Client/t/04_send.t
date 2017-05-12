
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Mock::Guard qw/mock_guard/;

use Daioikachan::Client;

subtest '_send' => sub {
    my $endpoint = 'http://daioikachan_endpoint.example.com';
    my $headers = [ 'x-test-daioikachan-header' => 'foo' ];

    my $instance = Daioikachan::Client->new({
            endpoint => $endpoint,
            headers  => $headers,
        });

    my $message = 'foo';

    my $got = {};
    my $guard = mock_guard('Furl::HTTP', {
            post => sub {
                (my $self, $got->{uri}, $got->{headers}, $got->{params}) = @_;

                return;
            },
        });

    subtest 'when arguments has a channel' => sub {
        my $channel = '#foo';

        $instance->_send({
                channel => $channel,
                message => $message,
                type    => 'notice',
            });

        is $got->{params}->{channel}, $channel, 'should send to channel';
    };

    subtest 'when arguments does not have a channel' => sub {
        $instance->_send({
                message => $message,
                type    => 'notice',
            });

        is $got->{params}->{channel}, $instance->{default_channel}, 'should send to default channel';
    };

    subtest 'when arguments has a message' => sub {
        $instance->_send({
                message => $message,
                type    => 'notice',
            });

        is $got->{params}->{message}, $message, 'message should send to channel';
    };

    subtest 'endpoint' => sub {
        $instance->_send({
                message => $message,
                type    => 'notice',
            });

        like $got->{uri}, qr/$endpoint/, 'message should send to endpoint';
    };

    subtest 'send type' => sub {
        my $type = 'notice';
        $instance->_send({
                message => $message,
                type    => $type,
            });

        like $got->{uri}, qr/$endpoint$type/, 'message should send to endpoint with send type';
    };

    subtest 'headers' => sub {
        $instance->_send({
                message => $message,
                type    => 'notice',
            });

        is_deeply $got->{headers}, $headers, 'message should send to endpoint with headers';
    };
};

done_testing;
