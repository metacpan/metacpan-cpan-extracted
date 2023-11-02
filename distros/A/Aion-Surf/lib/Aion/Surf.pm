package Aion::Surf;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.3";

use List::Util qw/pairmap/;
use LWP::UserAgent qw//;
use HTTP::Cookies qw//;
use Aion::Format::Json qw//;
use Aion::Format::Url qw//;

use Exporter qw/import/;
our @EXPORT = our @EXPORT_OK = grep {
	ref \$Aion::Surf::{$_} eq "GLOB"
		&& *{$Aion::Surf::{$_}}{CODE}
			&& !/^(_|(NaN|import)\z)/n
} keys %Aion::Surf::;


#@category surf

use config TIMEOUT => 10;
use config FROM_IP => undef;
use config AGENT => q{Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15};

our $ua = LWP::UserAgent->new;
$ua->agent(AGENT);
#$ua->env_proxy;
$ua->timeout(TIMEOUT);
$ua->local_address(FROM_IP) if FROM_IP;
$ua->cookie_jar(HTTP::Cookies->new);

# Между вызовами делаем случайный интервал (для граббинга - чтобы не быть заблокированным за автоматические обращения)
our $SLEEP = 0;
our $LAST_REQUEST = Time::HiRes::time();
sub _sleep(;$) {
	Time::HiRes::sleep(rand + .5) if Time::HiRes::time() - $LAST_REQUEST < 2;
	$LAST_REQUEST = Time::HiRes::time();
}

sub surf(@) {
	my $method = $_[0] =~ /^(\w+)\z/ ? shift: "GET";
	my $url = shift;
	my $headers;
	my $data = ref $_[0]? shift: undef;
	$headers = $data, undef $data if $method =~ /^(GET|HEAD)\z/n;

	my %set = @_;

	if(exists $set{sleep}) {
		my $sleep = delete $set{sleep};
	} else {
		_sleep if $SLEEP;
	}

	my $query = delete $set{query};
	if(defined $query) {
		$url = join "", $url, $url =~ /\?/ ? "&": "?",
			Aion::Format::Url::to_url_params $query;
	}

	my $request = HTTP::Request->new($method => $url);

	my $validate_data = sub {
		die "surf: data has already been provided!" if defined $data;
		die "surf: sended data in $method!" if $method =~ /^(HEAD|GET)\z/;
	};

	# Устанавливаем данные
	my $json = delete $set{json};
	$json = $data, undef $data if not defined $json and ref $data eq "HASH";
	if(defined $json) {
		$validate_data->();

		$request->header('Content-Type' => 'application/json; charset=utf-8');
		$data = Aion::Format::Json::to_json $json;
		utf8::encode($data) if utf8::is_utf8($data);
		$request->content($data);
	}

	my $form = delete $set{form};
	$form = $data, undef $data if not defined $form and ref $data eq "ARRAY";
	if(defined $form) {
		$validate_data->();
		$data = 1;

		$request->header('Content-Type' => 'application/x-www-form-urlencoded');
		$request->content(Aion::Format::Url::to_url_params $form);
	}

	if($headers = delete($set{headers}) // $headers) {
		if(ref $headers eq 'HASH') {
			$request->header($_, $headers->{$_}) for sort keys %$headers;
		} else {
			for my ($key, $val) (@$headers) {
				$request->header($key, $val);
			}
		}
	}

	if(my $cookie_href = delete $set{cookies}) {
		my $jar = $ua->cookie_jar;
		my $url_href = Aion::Format::Url::parse_url $url;
		my $domain = $url_href->{domain};
		$domain = "localhost.local" if $domain eq "localhost";

		$cookie_href = {@$cookie_href} if ref $cookie_href eq "ARRAY";

		for my $key (sort keys %$cookie_href) {

			my $av;
			my $val = $cookie_href->{$key};
			$av = $val, $val = shift @$av, $av = {@$av} if ref $val;

			$jar->set_cookie(
				delete($a->{version}),
				Aion::Format::Url::to_url_param $key
					=> Aion::Format::Url::to_url_param $val,
				delete($av->{path}) // "/",
				delete($av->{domain}) // $domain,
				delete($av->{port}),
				delete($av->{path_spec}),
				delete($av->{secure}),
				delete($av->{maxage}),
				delete($av->{discard}),
				$av
			);
		}
	}

	my $response_set = delete $set{response};

	die "Unknown keys: " . join ", ", keys %set if keys %set;

	my $response = $ua->request($request);
	$$response_set = $response if ref $response_set;

	return $response->is_success if $method eq "HEAD";

	my $content = $response->decoded_content;
	eval { $content = Aion::Format::Json::from_json($content) } if $content =~ m!^\{!;

	$content
}

sub head (;$) { my $x = @_ == 0? $_: shift;	surf HEAD   => ref $x? @{$x}: $x }
sub get  (;$) { my $x = @_ == 0? $_: shift; surf GET    => ref $x? @{$x}: $x }
sub post (@)  { my $x = @_ == 0? $_: \@_;   surf POST   => ref $x? @{$x}: $x }
sub put  (@)  { my $x = @_ == 0? $_: \@_;   surf PUT    => ref $x? @{$x}: $x }
sub patch(@)  { my $x = @_ == 0? $_: \@_;   surf PATCH  => ref $x? @{$x}: $x }
sub del  (;$) { my $x = @_ == 0? $_: shift; surf DELETE => ref $x? @{$x}: $x }


use config TELEGRAM_BOT_TOKEN => undef;

# Отправляет сообщение телеграм
sub chat_message($$) {
	my ($chat_id, $message) = @_;

	my $ok = post "https://api.telegram.org/bot${\ TELEGRAM_BOT_TOKEN}/sendMessage", response => \my $response, json => {
		chat_id => $chat_id,
		text => $message,
		disable_web_page_preview => 1,
		parse_mode => 'Html',
	};

	die $ok->{description} if !$ok->{ok};

	$ok
}


use config TELEGRAM_BOT_CHAT_ID => undef;
use config TELEGRAM_BOT_TECH_ID => undef;

# Отправляет сообщение в телеграм-бот
sub bot_message(;$) { chat_message TELEGRAM_BOT_CHAT_ID, @_ == 0? $_: $_[0] }
# Отправляет сообщение в технический телеграм канал
sub tech_message(;$) { chat_message TELEGRAM_BOT_TECH_ID, @_ == 0? $_: $_[0] }


# Получает последние сообщения отправленные боту
sub bot_update() {
	my @updates;

	for(my $offset = 0;;) {

		my $ok = post "https://api.telegram.org/bot${\ TELEGRAM_BOT_TOKEN}/getUpdates", json => {
			offset => $offset,
		};

		die $ok->{description} if !$ok->{ok};

		my $result = $ok->{result};
		return \@updates if !@$result;

		push @updates, map $_->{message}, grep $_->{message}, @$result;

		$offset = $result->[$#$result]{update_id} + 1;
	}
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Surf - surfing by internet

=head1 VERSION

0.0.3

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Aion::Surf contains a minimal set of functions for surfing the Internet. The purpose of the module is to make surfing as easy as possible, without specifying many additional settings.

=head1 SUBROUTINES

=head2 surf ([$method], $url, [$data], %params)

Send request by LWP::UserAgent and adapt response.

C<@params> maybe:

=over

=item * C<query> - add query params to C<$url>.

=item * C<json> - body request set in json format. Add header C<Content-Type: application/json; charset=utf-8>.

=item * C<form> - body request set in url params format. Add header C<Content-Type: application/x-www-form-urlencoded>.

=item * C<headers> - add headers. If C<header> is array ref, then add in the order specified. If C<header> is hash ref, then add in the alphabet order.

=item * C<cookies> - add cookies. Same as: C<< cookies =E<gt> {go =E<gt> "xyz", session =E<gt> ["abcd", path =E<gt> "/page"]} >>.

=item * C<response> - returns response (as HTTP::Response) by this reference.

=back

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

=head2 head (;$url)

Check resurce in internet. Returns C<1> if exists resurce in internet, otherwice returns C<"">.

=head2 get (;$url)

Get content from resurce in internet.

=head2 post (;$url, [$headers_href], %params)

Add content resurce in internet.

=head2 put (;$url, [$headers_href], %params)

Create or update resurce in internet.

=head2 patch (;$url, [$headers_href], %params)

Set attributes on resurce in internet.

=head2 del (;$url)

Delete resurce in internet.

=head2 chat_message ($chat_id, $message)

Sends a message to a telegram chat.

	# mock
	use Aion::Format::Json;
	*LWP::UserAgent::request = sub {
	    my ($ua, $request) = @_;
	    HTTP::Response->new(200, "OK", undef, to_json {ok => 1});
	};
	
	chat_message "ABCD", "hi!"  # --> {ok => 1}

=head2 bot_message (;$message)

Sends a message to a telegram bot.

	bot_message "hi!" # --> {ok => 1}

=head2 tech_message (;$message)

Sends a message to a technical telegram channel.

	tech_message "hi!" # --> {ok => 1}

=head2 bot_update ()

Receives the latest messages sent to the bot.

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

=head1 SEE ALSO

=over

=item * LWP::Simple

=item * LWP::Simple::Post

=item * HTTP::Request::Common

=item * WWW::Mechanize

=item * LLL<https://habr.com/ru/articles/63432/>

=back

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
