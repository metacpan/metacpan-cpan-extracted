#!perl
use lib qw(inc);
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use_ok('AnyEvent::Net::Curl::Queued');
use_ok('AnyEvent::Net::Curl::Queued::Easy');
use_ok('Test::HTTP::AnyEvent::Server');

my $server = Test::HTTP::AnyEvent::Server->new;
isa_ok($server, 'Test::HTTP::AnyEvent::Server');

my $q = AnyEvent::Net::Curl::Queued->new;
isa_ok($q, 'AnyEvent::Net::Curl::Queued');

can_ok($q, qw(append prepend cv));

my $n = 50;
for my $i (1 .. $n) {
    my $url = $server->uri . 'echo/body';
    my $post = "i=$i";
    $q->append(sub {
        AnyEvent::Net::Curl::Queued::Easy->new(
            http_response => 1,
            initial_url => $url,
            on_init     => sub {
                my ($self) = @_;

                $self->sign($post);
                $self->setopt({ postfields => $post });
            },
            on_finish   => sub {
                my ($self, $result) = @_;

                isa_ok($self, qw(AnyEvent::Net::Curl::Queued::Easy));
                isa_ok($self->response, qw(HTTP::Response));
                ok($self->response->code == 200, 'HTTP 200');

                can_ok($self, qw(
                    data
                    final_url
                    has_error
                    header
                    initial_url
                ));

                ok($self->final_url eq $url, 'initial/final URLs match');
                ok($result == 0, 'got CURLE_OK');
                ok(!$self->has_error, "libcurl message: '$result'");
                ok(ref($self->response) eq 'HTTP::Response', 'returns ' . ref($self->response));

                is($self->response->content, $post, 'got data: ' . $self->response->content);
            },
            use_stats   => 1,
        )
    });
}
$q->cv->wait;

done_testing(6 + 9 * $n);
