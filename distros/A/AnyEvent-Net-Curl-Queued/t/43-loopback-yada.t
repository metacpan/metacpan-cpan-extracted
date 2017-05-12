#!perl
use lib qw(inc);
use strict;
use utf8;
use warnings qw(all);

use Encode;
use JSON;
use Test::More;

use_ok('YADA');
use_ok('YADA::Worker');
use_ok('Test::HTTP::AnyEvent::Server');

my $server = Test::HTTP::AnyEvent::Server->new;
isa_ok($server, 'Test::HTTP::AnyEvent::Server');

my $ua_string = Net::Curl::version();
my $q = YADA->new(
    common_opts => {
        encoding    => 'gzip',
        useragent   => $ua_string,
    },
    http_response => 1,
);
isa_ok($q, qw(YADA));

can_ok($q, qw(append wait));

for my $j (1 .. 10) {
    for my $i (1 .. 10) {
        my $url = $server->uri . 'echo/head';
        my $post = qq({"i":$i,"j":$j,"k":"яда"});
        $q->append(sub {
            YADA::Worker->new(
                initial_url => $url,
                opts        => { cookie => q(time=) . time },
                on_init     => sub {
                    my ($self) = @_;

                    $self->setopt(postfields => $post);
                    $self->sign($self->post_content);
                },
                on_finish   => sub {
                    my ($self, $result) = @_;

                    isa_ok($self, qw(YADA::Worker));

                    can_ok($self, qw(
                        data
                        final_url
                        has_error
                        header
                        initial_url
                    ));

                    is($self->final_url, $url, 'initial/final URLs match');
                    is(0 + $result, 0, 'got CURLE_OK');
                    ok(!$self->has_error, "libcurl message: '$result'");

                    like(${$self->data}, qr{\bContent-Type:\s*application/json\b}ix, 'got data: ' . ${$self->data});
                    like(${$self->data}, qr{\bUser-Agent\s*:\s*\Q$ua_string\E\b}sx, 'got User-Agent tag');
                    like(${$self->data}, qr{\bCookie\s*:\s*time=\d+\b}sx, 'got Cookie tag');
                },
            )
        });
    }

    my $json_string = qq({ "word": "ímã", "j": $j, "seed": @{[ rand ]} });
    my $json_hash = { word => "ímã", j => $j, seed => rand };
    for my $post (
        $json_string,
        encode_utf8($json_string) . "\n",           # whitespace padding hack
        encode_json($json_hash),
        decode_utf8(encode_json($json_hash)) . "\n",# whitespace padding hack
        { ref => 1, %$json_hash },
    ) {
        $q->append(sub {
            YADA::Worker->new(
                initial_url => $server->uri . 'echo/body',
                on_init     => sub {
                    my ($self) = @_;

                    $self->setopt(postfields => $post);
                    $self->sign($self->post_content);
                },
                on_finish   => sub {
                    my ($self, $result) = @_;
                    like(${$self->data}, qr/^\s*\{[^\}]+\}\s*$/sx, ${$self->data});
                    my $json = decode_json(${$self->data});
                    is(uc $json->{word}, 'ÍMÃ', 'encoding');
                },
            )
        });
    }

    $q->wait;
}

done_testing(6 + 8 * 100 + 2 * 50);
