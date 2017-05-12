use strict;
use warnings;
use AnyEvent::WebService::ImKayac;
use Test::More;
use Test::TCP;
use JSON;
use Digest::SHA qw/sha1_hex/;
use Test::Requires qw/Plack::Loader Plack::Request/;

my $tests = [
    # internal error
    {
        response => sub {
            return [500, [], [] ];
        },
        client => sub {
            my $cv = shift;
            AnyEvent::WebService::ImKayac->new(
                user => "hoge",
                type => "none",
            )->send(
                message => "m",
                cb => sub {
                    my ($hdr, $json, $reason) = @_;
                    ok ! $json;
                    is $reason, "Internal Server Error";
                    $cv->send;
                }
            );
        },
    },
    # invalid json
    {
        response => sub {
            [200, [" Content-Type" => "application/json" ], [] ]
        },
        client   => sub {
            my $cv = shift;
            AnyEvent::WebService::ImKayac->new(
                user => "hoge",
                type => "none",
            )->send(
                message => "m",
                cb => sub {
                    my ($hdr, $json, $reason) = @_;
                    ok ! $json;
                    like $reason, qr/^parse error:/;
                    $cv->send;
                }
            );
        },
    },
    # success when none type
    {
        response => sub {
            [200, [" Content-Type" => "application/json" ], [ encode_json({ result => "posted" }) ] ]
        },
        client   => sub {
            my $cv = shift;
            AnyEvent::WebService::ImKayac->new(
                user => "hoge",
                type => "none",
            )->send(
                message => "m",
                cb => sub {
                    my ($hdr, $json, $reason) = @_;
                    is $json->{result}, "posted";
                    is $reason, "OK";
                    $cv->send;
                },
            );
        },
    },
    #password type
    {
        response => sub {
            my $req = shift;
            is $req->param('password'), 'dameleon';
            [200, [" Content-Type" => "application/json" ], [ encode_json({ result => "posted" }) ] ]
        },
        client   => sub {
            my $cv = shift;
            AnyEvent::WebService::ImKayac->new(
                user     => "hoge",
                type     => "password",
                password => "dameleon",
            )->send(
                message => "m",
                cb => sub {
                    my ($hdr, $json, $reason) = @_;
                    is $json->{result}, "posted";
                    is $reason, "OK";
                    $cv->send;
                },
            );
        },
    },
    #secret type
    {
        response => sub {
            my $req = shift;
            is $req->param('sig'), sha1_hex( "m" . "dameleon" );
            [200, [" Content-Type" => "application/json" ], [ encode_json({ result => "posted" }) ] ]
        },
        client   => sub {
            my $cv = shift;
            AnyEvent::WebService::ImKayac->new(
                user       => "hoge",
                type       => "secret",
                secret_key => "dameleon",
            )->send(
                message => "m",
                cb => sub {
                    my ($hdr, $json, $reason) = @_;
                    is $json->{result}, "posted";
                    is $reason, "OK";
                    $cv->send;
                },
            );
        },
    },
];

for my $test ( @$tests ) {
    test_tcp (
        client => sub {
            my $port = shift;
            local $AnyEvent::WebService::ImKayac::URL = "http://127.0.0.1:$port";
            my $client = $test->{client};
            my $cv = AE::cv;
            $client->($cv);
            $cv->recv;
        },
        server => sub {
            my $port = shift;
            my $app = sub {
                my $req = Plack::Request->new(shift);
                $test->{response}->($req);
            };
            Plack::Loader->auto(
                host => "127.0.0.1",
                port => $port,
            )->run($app);
        },
    );
}

done_testing;
