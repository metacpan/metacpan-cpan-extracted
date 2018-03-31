use strict;
use warnings;
use Test::More;
use AnyEvent::Connector;

subtest "no no_proxy", sub {
    my $c = AnyEvent::Connector->new(
        proxy => "http://hoge.com",
    );
    is $c->proxy_for("localhost", 80), "http://hoge.com";
    is $c->proxy_for("127.0.0.1", 5000), "http://hoge.com";
    is $c->proxy_for("foo.example.com", 22), "http://hoge.com";
    is $c->proxy_for("buzz.example.com", 22), "http://hoge.com";
    is $c->proxy_for("bar.quux.net",443), "http://hoge.com";
};

subtest "no_proxy domain", sub {
    my $c = AnyEvent::Connector->new(
        proxy => "http://hoge.com",
        no_proxy => "example.com",
    );
    is $c->proxy_for("localhost", 80), "http://hoge.com";
    is $c->proxy_for("127.0.0.1", 5000), "http://hoge.com";
    is $c->proxy_for("foo.example.com", 22), undef;
    is $c->proxy_for("buzz.example.com", 22), undef;
    is $c->proxy_for("bar.quux.net",443), "http://hoge.com";
};

subtest "no_proxy host", sub {
    my $c = AnyEvent::Connector->new(
        proxy => "http://hoge.com",
        no_proxy => "buzz.example.com",
    );
    is $c->proxy_for("localhost", 80), "http://hoge.com";
    is $c->proxy_for("127.0.0.1", 5000), "http://hoge.com";
    is $c->proxy_for("foo.example.com", 22), "http://hoge.com";
    is $c->proxy_for("buzz.example.com", 22), undef;
    is $c->proxy_for("bar.quux.net",443), "http://hoge.com";
};

subtest "no_proxy list", sub {
    my $c = AnyEvent::Connector->new(
        proxy => "http://hoge.com",
        no_proxy => ["example.com", "localhost"],
    );
    is $c->proxy_for("localhost", 80), undef;
    is $c->proxy_for("127.0.0.1", 5000), "http://hoge.com";
    is $c->proxy_for("foo.example.com", 22), undef;
    is $c->proxy_for("buzz.example.com", 22), undef;
    is $c->proxy_for("bar.quux.net",443), "http://hoge.com";
};

subtest "no_proxy IPv4 address", sub {
    my $c = AnyEvent::Connector->new(
        proxy => "http://hoge.com",
        no_proxy => "127.0.0.1",
    );
    is $c->proxy_for("localhost", 80), "http://hoge.com";
    is $c->proxy_for("127.0.0.1", 5000), undef;
    is $c->proxy_for("foo.example.com", 22), "http://hoge.com";
    is $c->proxy_for("buzz.example.com", 22), "http://hoge.com";
    is $c->proxy_for("bar.quux.net",443), "http://hoge.com";
};

subtest "no_proxy empty string", sub {
    my $c = AnyEvent::Connector->new(
        proxy => "http://hoge.com",
        no_proxy => "",
    );
    is $c->proxy_for("localhost", 80), "http://hoge.com";
    is $c->proxy_for("127.0.0.1", 5000), "http://hoge.com";
    is $c->proxy_for("foo.example.com", 22), "http://hoge.com";
    is $c->proxy_for("buzz.example.com", 22), "http://hoge.com";
    is $c->proxy_for("bar.quux.net",443), "http://hoge.com";
};

subtest "no_proxy empty arrayref", sub {
    my $c = AnyEvent::Connector->new(
        proxy => "http://hoge.com",
        no_proxy => [],
    );
    is $c->proxy_for("localhost", 80), "http://hoge.com";
    is $c->proxy_for("127.0.0.1", 5000), "http://hoge.com";
    is $c->proxy_for("foo.example.com", 22), "http://hoge.com";
    is $c->proxy_for("buzz.example.com", 22), "http://hoge.com";
    is $c->proxy_for("bar.quux.net",443), "http://hoge.com";
};

subtest "no_proxy environment should be ignored if env_proxy option is not specified", sub {
    local $ENV{no_proxy} = "foo.com";
    my $c = AnyEvent::Connector->new(
        proxy => "http://bar.net:8080"
    );
    is $c->proxy_for("www.foo.com", 80), "http://bar.net:8080";
    is $c->proxy_for("foo.com", 80), "http://bar.net:8080";
    is $c->proxy_for("hoge.com", 5000), "http://bar.net:8080";
};

done_testing;
