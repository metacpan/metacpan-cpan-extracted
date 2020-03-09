use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use Test::TCP;
use HTTP::Server::PSGI;
use AWS::XRay qw/ capture /;
use Test::More;
use t::Util qw/ reset segments /;

# mock server of IMDSv2
my $token      = "very-secret";
my $app_server = Test::TCP->new(
    listen => 1,
    code   => sub {
        my $sock   = shift;
        my $server = HTTP::Server::PSGI->new(
            listen_sock => $sock,
        );
        $server->run(
            sub {
                my $env    = shift;
                my $method = $env->{REQUEST_METHOD};
                my $path   = $env->{PATH_INFO};
                if ($method eq 'PUT') {
                    if (!$env->{HTTP_X_AWS_EC2_METADATA_TOKEN_TTL_SECONDS}) {
                        return [400, [], ['Bad Request']];
                    }
                    if ($path ne '/api/token') {
                        return [404, [], ['Not Found']];
                    }
                    return [200, [], [$token]];
                }
                if ($method eq 'GET') {
                    if (($env->{HTTP_X_AWS_EC2_METADATA_TOKEN} || '') ne $token) {
                        return [401, [], ['Unauthorized']];
                    }
                    if ($path eq '/meta-data/instance-id') {
                        return [200, [], ['i-1234567890abcdef0']];
                    }
                    if ($path eq '/meta-data/placement/availability-zone') {
                        return [200, [], ['ap-northeast-1a']];
                    }
                    return [404, [], ['Not Found']];
                }
                return [405, [], ['Method Not Allowed']];
            }
        );
    },
    max_wait => 10, # seconds
);
use AWS::XRay::Plugin::EC2;
$AWS::XRay::Plugin::EC2::_base_url = "http://127.0.0.1:" . $app_server->port;

sub myApp {
    capture "remote1", sub { };
}

AWS::XRay->plugins('AWS::XRay::Plugin::EC2');
AWS::XRay->add_capture("main", "myApp");

myApp();

my @seg = segments();

my $root = pop @seg;

is $root->{origin},     'AWS::EC2::Instance';
is_deeply $root->{aws}, {
    ec2 => {
        availability_zone => 'ap-northeast-1a',
        instance_id       => 'i-1234567890abcdef0',
    },
};

done_testing;
