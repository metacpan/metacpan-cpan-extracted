use strict;
use warnings;
use Test::More;
use AnyEvent::Connector;

foreach my $e (qw{http_proxy HTTP_PROXY no_proxy NO_PROXY ftp_proxy FTP_PROXY}) {
    delete $ENV{$e};
}

subtest "env_proxy no no_proxy", sub {
    local $ENV{http_proxy} = "http://foobar.ne.jp:8080";
    my $c = AnyEvent::Connector->new(
        env_proxy => "http"
    );
    is $c->proxy_for("www.foobar.net", 80), "http://foobar.ne.jp:8080";
};

subtest "env_proxy with no_proxy ENV", sub {
    local $ENV{http_proxy} = "http://foobar.ne.jp:8080";
    local $ENV{no_proxy} = "www.foobar.net";
    my $c = AnyEvent::Connector->new(
        env_proxy => "http"
    );
    is $c->proxy_for("www.foobar.net", 80), undef;
    is $c->proxy_for("backend.foobar.net", 8080), "http://foobar.ne.jp:8080";
};

subtest "env_proxy with proxy override", sub {
    local $ENV{http_proxy} = "http://foobar.ne.jp:8080";
    local $ENV{no_proxy} = "www.foobar.net";
    my $c = AnyEvent::Connector->new(
        env_proxy => "http",
        proxy => "http://alt.proxy.com:5000"
    );
    is $c->proxy_for("www.foobar.net", 80), undef;
    is $c->proxy_for("backend.foobar.net", 8080), "http://alt.proxy.com:5000";

    $c = AnyEvent::Connector->new(
        env_proxy => "http",
        proxy => "",
    );
    is $c->proxy_for("www.foobar.net", 80), undef;
    is $c->proxy_for("backend.foobar.net", 8080), undef;
};

subtest "env_proxy with no_proxy override", sub {
    local $ENV{http_proxy} = "http://foobar.ne.jp:8080";
    local $ENV{no_proxy} = "www.foobar.net";
    my $c = AnyEvent::Connector->new(
        env_proxy => "http",
        no_proxy => "backend.foobar.net",
    );
    is $c->proxy_for("www.foobar.net", 80), "http://foobar.ne.jp:8080";
    is $c->proxy_for("backend.foobar.net", 8080), undef;

    $c = AnyEvent::Connector->new(
        env_proxy => "http",
        no_proxy => ""
    );
    is $c->proxy_for("www.foobar.net", 80), "http://foobar.ne.jp:8080";
    is $c->proxy_for("backend.foobar.net", 8080), "http://foobar.ne.jp:8080";
};

subtest "env_proxy with no matching protocol", sub {
    local $ENV{http_proxy} = "http://foobar.ne.jp:8080";
    local $ENV{no_proxy} = "www.foobar.net";
    my $c = AnyEvent::Connector->new(
        env_proxy => "ftp",
    );
    is $c->proxy_for("www.foobar.net", 80), undef;
    is $c->proxy_for("backend.foobar.net", 8080), undef;
};

done_testing;
