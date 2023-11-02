# NAME

Aion::Surf - surfing by internet

# VERSION

0.0.3

# SYNOPSIS

```perl
use Aion::Surf;
use common::sense;

# mock
*LWP::UserAgent::request = sub {
    my ($ua, $request) = @_;
    my $response = HTTP::Response->new(200, "OK");

    given ($request->method . " " . $request->uri) {
        $response->content("get")    when $_ eq "GET http://example/ex";
        $response->content("head")   when $_ eq "HEAD http://example/ex";
        $response->content("post")   when $_ eq "POST http://example/ex";
        $response->content("put")    when $_ eq "PUT http://example/ex";
        $response->content("patch")  when $_ eq "PATCH http://example/ex";
        $response->content("delete") when $_ eq "DELETE http://example/ex";

        $response->content('{"a":10}')  when $_ eq "PATCH http://example/json";
        default {
            $response = HTTP::Response->new(404, "Not Found");
            $response->content("nf");
        }
    }

    $response
};

get "http://example/ex"             # => get
surf "http://example/ex"            # => get

head "http://example/ex"            # -> 1
head "http://example/not-found"     # -> ""

surf HEAD => "http://example/ex"    # -> 1
surf HEAD => "http://example/not-found"  # -> ""

[map { surf $_ => "http://example/ex" } qw/GET HEAD POST PUT PATCH DELETE/] # --> [qw/get 1 post put patch delete/]

patch "http://example/json" # --> {a => 10}

[map patch, qw! http://example/ex http://example/json !]  # --> ["patch", {a => 10}]

get ["http://example/ex", headers => {Accept => "*/*"}]  # => get
surf "http://example/ex", headers => [Accept => "*/*"]   # => get
```

# DESCRIPTION

Aion::Surf contains a minimal set of functions for surfing the Internet. The purpose of the module is to make surfing as easy as possible, without specifying many additional settings.

# SUBROUTINES

## surf (\[$method], $url, \[$data], %params)

Send request by LWP::UserAgent and adapt response.

`@params` maybe:

* `query` - add query params to `$url`.
* `json` - body request set in json format. Add header `Content-Type: application/json; charset=utf-8`.
* `form` - body request set in url params format. Add header `Content-Type: application/x-www-form-urlencoded`.
* `headers` - add headers. If `header` is array ref, then add in the order specified. If `header` is hash ref, then add in the alphabet order.
* `cookies` - add cookies. Same as: `cookies => {go => "xyz", session => ["abcd", path => "/page"]}`.
* `response` - returns response (as HTTP::Response) by this reference.

```perl
my $req = "MAYBE_ANY_METHOD https://ya.ru/page?z=30&x=10&y=%1F9E8
Accept: */*,image/*
Content-Type: application/x-www-form-urlencoded

x&y=2
";

my $req_cookies = 'Set-Cookie3: go=""; path="/"; domain=ya.ru; version=0
Set-Cookie3: session=%1F9E8; path="/page"; domain=ya.ru; version=0
';

# mock
*LWP::UserAgent::request = sub {
    my ($ua, $request) = @_;

    $request->as_string # -> $req
    $ua->cookie_jar->as_string  # -> $req_cookies

    my $response = HTTP::Response->new(200, "OK");
    $response->content(3.14);
    $response
};

my $res = surf MAYBE_ANY_METHOD => "https://ya.ru/page?z=30", [x => 1, y => 2, z => undef],
    headers => [
        'Accept' => '*/*,image/*',
    ],
    query => [x => 10, y => "🧨"],
    response => \my $response,
    cookies => {
        go => "",
        session => ["🧨", path => "/page"],
    },
;
$res           # -> 3.14
ref $response  # => HTTP::Response
```

## head (;$url)

Check resurce in internet. Returns `1` if exists resurce in internet, otherwice returns `""`.

## get (;$url)

Get content from resurce in internet.

## post (;$url, \[$headers_href], %params)

Add content resurce in internet.

## put (;$url, \[$headers_href], %params)

Create or update resurce in internet.

## patch (;$url, \[$headers_href], %params)

Set attributes on resurce in internet.

## del (;$url)

Delete resurce in internet.

## chat_message ($chat_id, $message)

Sends a message to a telegram chat.

```perl
# mock
use Aion::Format::Json;
*LWP::UserAgent::request = sub {
    my ($ua, $request) = @_;
    HTTP::Response->new(200, "OK", undef, to_json {ok => 1});
};

chat_message "ABCD", "hi!"  # --> {ok => 1}
```

## bot_message (;$message)

Sends a message to a telegram bot.

```perl
bot_message "hi!" # --> {ok => 1}
```

## tech_message (;$message)

Sends a message to a technical telegram channel.

```perl
tech_message "hi!" # --> {ok => 1}
```

## bot_update ()

Receives the latest messages sent to the bot.

```perl
# mock
*LWP::UserAgent::request = sub {
    my ($ua, $request) = @_;

    my $offset = from_json($request->content)->{offset};
    if($offset) {
        return HTTP::Response->new(200, "OK", undef, to_json {
            ok => 1,
            result => [],
        });
    }

    HTTP::Response->new(200, "OK", undef, to_json {
        ok => 1,
        result => [{
            message => "hi!",
            update_id => 0,
        }],
    });
};

bot_update  # --> ["hi!"]


# mock
*LWP::UserAgent::request = sub {
    HTTP::Response->new(200, "OK", undef, to_json {
        ok => 0,
        description => "nooo!"
    })
};

eval { bot_update }; $@  # ~> nooo!
```

# SEE ALSO

* LWP::Simple
* LWP::Simple::Post
* HTTP::Request::Common
* WWW::Mechanize
* [An article about sending an HTTP request to a server](https://habr.com/ru/articles/63432/)

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
