use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-surf!aion!surf/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Surf - surfing by internet
# 
# # VERSION
# 
# 0.0.3
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
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

::is scalar do {get "http://example/ex"}, "get", 'get "http://example/ex"             # => get';
::is scalar do {surf "http://example/ex"}, "get", 'surf "http://example/ex"            # => get';

::is scalar do {head "http://example/ex"}, scalar do{1}, 'head "http://example/ex"            # -> 1';
::is scalar do {head "http://example/not-found"}, scalar do{""}, 'head "http://example/not-found"     # -> ""';

::is scalar do {surf HEAD => "http://example/ex"}, scalar do{1}, 'surf HEAD => "http://example/ex"    # -> 1';
::is scalar do {surf HEAD => "http://example/not-found"}, scalar do{""}, 'surf HEAD => "http://example/not-found"  # -> ""';

::is_deeply scalar do {[map { surf $_ => "http://example/ex" } qw/GET HEAD POST PUT PATCH DELETE/]}, scalar do {[qw/get 1 post put patch delete/]}, '[map { surf $_ => "http://example/ex" } qw/GET HEAD POST PUT PATCH DELETE/] # --> [qw/get 1 post put patch delete/]';

::is_deeply scalar do {patch "http://example/json"}, scalar do {{a => 10}}, 'patch "http://example/json" # --> {a => 10}';

::is_deeply scalar do {[map patch, qw! http://example/ex http://example/json !]}, scalar do {["patch", {a => 10}]}, '[map patch, qw! http://example/ex http://example/json !]  # --> ["patch", {a => 10}]';

::is scalar do {get ["http://example/ex", headers => {Accept => "*/*"}]}, "get", 'get ["http://example/ex", headers => {Accept => "*/*"}]  # => get';
::is scalar do {surf "http://example/ex", headers => [Accept => "*/*"]}, "get", 'surf "http://example/ex", headers => [Accept => "*/*"]   # => get';

# 
# # DESCRIPTION
# 
# Aion::Surf contains a minimal set of functions for surfing the Internet. The purpose of the module is to make surfing as easy as possible, without specifying many additional settings.
# 
# # SUBROUTINES
# 
# ## surf (\[$method], $url, \[$data], %params)
# 
# Send request by LWP::UserAgent and adapt response.
# 
# `@params` maybe:
# 
# * `query` - add query params to `$url`.
# * `json` - body request set in json format. Add header `Content-Type: application/json; charset=utf-8`.
# * `form` - body request set in url params format. Add header `Content-Type: application/x-www-form-urlencoded`.
# * `headers` - add headers. If `header` is array ref, then add in the order specified. If `header` is hash ref, then add in the alphabet order.
# * `cookies` - add cookies. Same as: `cookies => {go => "xyz", session => ["abcd", path => "/page"]}`.
# * `response` - returns response (as HTTP::Response) by this reference.
# 
done_testing; }; subtest 'surf (\[$method], $url, \[$data], %params)' => sub { 
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

::is scalar do {$request->as_string}, scalar do{$req}, '    $request->as_string # -> $req';
::is scalar do {$ua->cookie_jar->as_string}, scalar do{$req_cookies}, '    $ua->cookie_jar->as_string  # -> $req_cookies';

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
::is scalar do {$res}, scalar do{3.14}, '$res           # -> 3.14';
::is scalar do {ref $response}, "HTTP::Response", 'ref $response  # => HTTP::Response';

# 
# ## head (;$url)
# 
# Check resurce in internet. Returns `1` if exists resurce in internet, otherwice returns `""`.
# 
# ## get (;$url)
# 
# Get content from resurce in internet.
# 
# ## post (;$url, \[$headers_href], %params)
# 
# Add content resurce in internet.
# 
# ## put (;$url, \[$headers_href], %params)
# 
# Create or update resurce in internet.
# 
# ## patch (;$url, \[$headers_href], %params)
# 
# Set attributes on resurce in internet.
# 
# ## del (;$url)
# 
# Delete resurce in internet.
# 
# ## chat_message ($chat_id, $message)
# 
# Sends a message to a telegram chat.
# 
done_testing; }; subtest 'chat_message ($chat_id, $message)' => sub { 
# mock
use Aion::Format::Json;
*LWP::UserAgent::request = sub {
    my ($ua, $request) = @_;
    HTTP::Response->new(200, "OK", undef, to_json {ok => 1});
};

::is_deeply scalar do {chat_message "ABCD", "hi!"}, scalar do {{ok => 1}}, 'chat_message "ABCD", "hi!"  # --> {ok => 1}';

# 
# ## bot_message (;$message)
# 
# Sends a message to a telegram bot.
# 
done_testing; }; subtest 'bot_message (;$message)' => sub { 
::is_deeply scalar do {bot_message "hi!"}, scalar do {{ok => 1}}, 'bot_message "hi!" # --> {ok => 1}';

# 
# ## tech_message (;$message)
# 
# Sends a message to a technical telegram channel.
# 
done_testing; }; subtest 'tech_message (;$message)' => sub { 
::is_deeply scalar do {tech_message "hi!"}, scalar do {{ok => 1}}, 'tech_message "hi!" # --> {ok => 1}';

# 
# ## bot_update ()
# 
# Receives the latest messages sent to the bot.
# 
done_testing; }; subtest 'bot_update ()' => sub { 
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

::is_deeply scalar do {bot_update}, scalar do {["hi!"]}, 'bot_update  # --> ["hi!"]';


# mock
*LWP::UserAgent::request = sub {
    HTTP::Response->new(200, "OK", undef, to_json {
        ok => 0,
        description => "nooo!"
    })
};

::like scalar do {eval { bot_update }; $@}, qr!nooo\!!, 'eval { bot_update }; $@  # ~> nooo!';

# 
# # SEE ALSO
# 
# * LWP::Simple
# * LWP::Simple::Post
# * HTTP::Request::Common
# * WWW::Mechanize
# * [An article about sending an HTTP request to a server](https://habr.com/ru/articles/63432/)
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
