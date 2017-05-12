#!perl
use lib qw(inc);
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use_ok('AnyEvent::Net::Curl::Queued');
use_ok('Test::HTTP::AnyEvent::Server');

use lib qw(t);
use_ok(q(Retrier));

my $server = Test::HTTP::AnyEvent::Server->new;
isa_ok($server, 'Test::HTTP::AnyEvent::Server');

my $q = AnyEvent::Net::Curl::Queued->new;
isa_ok($q, 'AnyEvent::Net::Curl::Queued');

can_ok($q, qw(append prepend cv));

my $n = 10;
for my $i (1 .. $n) {
    my $url = $server->uri . 'echo/head';
    $q->append(sub {
        Retrier->new(
            attr1       => rand,
            attr2       => $i,
            attr3       => URI->new($url),
            attr4       => 'B',
            initial_url => $url,
            on_init     => sub {
                my ($self) = @_;
                my $query = "i=$i";
                $self->sign($query);
                $self->setopt(CURLOPT_POSTFIELDS => $query);
            },
            on_finish   => sub {
                my ($self, $result) = @_;

                isa_ok($self, qw(Retrier));

                can_ok($self, qw(
                    attr1
                    attr2
                    attr3
                    clone
                    data
                    final_url
                    has_error
                    header
                    initial_url
                ));

                ok($self->attr1 >= 0, 'custom attribute 1 is >= 0');
                ok($self->attr1 < 1, 'custom attribute 1 is < 1');

                ok($self->attr2 == $i, 'custom attribute 2 ok');

                ok(ref($self->attr3) =~ m{^URI\b}x, 'custom attribute 3 ok');

                ok(
                    (($self->retry == 5) and ($self->attr4 =~ /A/x))
                        or
                    (($self->retry < 5) and ($self->attr4 =~ /B/x)),
                    'custom attribute 4 ok (not cloned!)'
                );

                ok($self->final_url eq $url, 'initial/final URLs match');
                ok($result == 0, 'got CURLE_OK');
                ok($self->has_error, "forced error");

                like(${$self->data}, qr{^POST\s+/echo/head\s+HTTP/1\.[01]}ix, 'got data: ' . ${$self->data});
            },
            retry       => 5,
        )
    });
}
$q->cv->wait;

done_testing 556;
