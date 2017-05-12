use strict;
use warnings;
use Test::More 0.89;
use Test::Fatal;
use MIME::Base64;

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

{
    package Mock::Data::Riak::Async::HTTP;

    use Moose;
    use namespace::autoclean;

    extends 'Data::Riak::Async::HTTP';

    sub _send_via_anyevent_http {
        my ($self, $http_request, $cb, $error_cb) = @_;
        $error_cb->($http_request);
    }

    __PACKAGE__->meta->make_immutable;
}

use Data::Riak::Async;

my $username = 'foo';
my $password = 'bar';

my $t = Mock::Data::Riak::Async::HTTP->new({
    host          => 'some-host.example.com',
    port          => 8098,
    request_class => Data::Riak::HTTP::Request::BasicAuth::,
    request_class_args => {
        basic_auth_username => $username,
        basic_auth_password => $password,
    },
});
isa_ok $t, 'Data::Riak::Async::HTTP';

my $d = Data::Riak::Async->new({ transport => $t });
isa_ok $d, 'Data::Riak::Async';

my $cv = AE::cv;
$d->ping({
    cb       => sub { $cv->send(@_) },
    error_cb => sub { $cv->croak(@_) },
});

my $r = exception { $cv->recv };
isa_ok $r, 'HTTP::Request';

is $r->header('Authorization'),
    'Basic ' . encode_base64("${username}:${password}"),
    'Request got the basic auth headers we expected';

done_testing;
