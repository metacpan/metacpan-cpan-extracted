use strict;
use warnings;
use Test::More 0.89;
use Test::Fatal;
use MIME::Base64;

{
    package FakeUserAgent;

    use Moose;
    use namespace::autoclean;

    extends 'LWP::UserAgent';

    sub request {
        my ($self, $http_request) = @_;
        die $http_request;
    }
}

{
    package Data::Riak::HTTP::Request::BasicAuth;

    use Moose;
    use MIME::Base64;
    use namespace::autoclean;

    extends 'Data::Riak::HTTP::Request';

    has [map { "basic_auth_$_" } qw(username password)] => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    sub _build_headers {
        my ($self) = @_;

        return {
            Authorization => 'Basic ' . encode_base64(
                join q[:] => map {
                    $self->${\"basic_auth_$_"}
                } qw(username password),
            ),
        };
    }

    __PACKAGE__->meta->make_immutable;
}

use Data::Riak;

my $username = 'foo';
my $password = 'bar';

my $t = Data::Riak::HTTP->new({
    host          => 'some-host.example.com',
    port          => 8098,
    user_agent    => FakeUserAgent->new,
    request_class => Data::Riak::HTTP::Request::BasicAuth::,
    request_class_args => {
        basic_auth_username => $username,
        basic_auth_password => $password,
    },
});
isa_ok $t, 'Data::Riak::HTTP';

my $d = Data::Riak->new({ transport => $t });
isa_ok $d, 'Data::Riak';

my $r = exception { $d->ping };
isa_ok $r, 'HTTP::Request';

is $r->header('Authorization'),
    'Basic ' . encode_base64("${username}:${password}"),
    'Request got the basic auth headers we expected';

done_testing;
