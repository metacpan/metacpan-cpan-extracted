
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Mock::Guard qw/mock_guard/;

use Daioikachan::Client;

subtest 'privmsg' => sub {
    my $instance = Daioikachan::Client->new({
            endpoint => 'http://daioikachan_endpoint.example.com',
        });

    subtest 'when arguments is not valid' => sub {
        subtest 'arguments does not have a message' => sub {
            throws_ok {
                $instance->notice;
            } qr/Undefined message/, 'throws undefined message error;'
        };
    };

    subtest 'when arguments is valid' => sub {
        my $message = 'foo';
        my $channel = '#channel';

        my $got;

        my $guard = mock_guard($instance, {
                _send => sub {
                    (my $self, $got) = @_;

                    return;
                },
            });

        $instance->privmsg({
                message => $message,
                channel => $channel,
            });

        is $got->{message}, $message, 'should be equal message';
        is $got->{channel}, $channel, 'should be equal channel';
        is $got->{type}, 'privmsg', 'should be equal "privmsg"';
    };
};

done_testing;
