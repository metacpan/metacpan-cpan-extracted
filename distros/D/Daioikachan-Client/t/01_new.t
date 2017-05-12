
use strict;
use warnings;

use Test::More;
use Test::Exception;

use Daioikachan::Client;

subtest 'new' => sub {
    my $class = 'Daioikachan::Client';

    my $endpoint = 'http://daioikachan_endpoint.example.com';

    subtest 'valid params' => sub {
        subtest 'when params has a endpoint' => sub {
            my $instance = $class->new({ endpoint => $endpoint });

            is ref $instance, $class, "should be $class\'s instance";
            is $instance->{endpoint}, $endpoint, 'should be equal endpoint';
            is ref $instance->{ua}, 'Furl::HTTP', 'should have a user agent of Furl::HTTP';
        };

        subtest 'when params has a default_channel' => sub {
            my $default_channel = '#default';
            my $instance = $class->new({
                    endpoint => $endpoint,
                    default_channel => $default_channel,
                });

            is $instance->{default_channel}, $default_channel, 'should be equal default_channel';
        };

        subtest 'when params has a header for ua' => sub {
            my $headers = [ 'x-test-daioikachan-header' => 'foo' ];
            my $instance = $class->new({
                    endpoint => $endpoint,
                    headers => $headers,
                });

            is $instance->{headers}, $headers, 'should be equal headers';
        };

        subtest 'when params has a ua_options' => sub {
            my $user_agent = 'test-daioikachan-agent';
            my $instance = $class->new({
                    endpoint => $endpoint,
                    ua_options => {
                        agent => $user_agent,
                    },
                });

            my %headers = @{$instance->{ua}->{headers}};

            is $headers{"User-Agent"}, $user_agent, 'should be equal user-agent';
        };
    };

    subtest 'invalid params' => sub {
        subtest 'when params does not have a endpoint' => sub {
            throws_ok {
                $class->new;
            } qr/Undefined endpoint/, 'throws undefined endpoint error';
        };
    };
};

done_testing;
