
use strict;
use warnings;

use Test::More import => ['!pass'];
use HTTP::Date qw(str2time);

use constant ONE_YEAR => 365 * 24 * 60 * 60;

my $test_root;
BEGIN {
    use Path::Class qw();
    $test_root = '' . Path::Class::dir('t', 'test-app', 'static');
}

{
    use Dancer;

    # Settings must be loaded before plugin
    setting(plugins => {
        CDN => {
            root    => $test_root,
            base    => '/CDN/',
            plugins => [ 'CSS' ],
        }
    });

    eval "use Dancer::Plugin::CDN";
    die "$@" if $@;

    get '/status' => sub {
        return "OK";
    };

    get '/' => sub {
        return cdn_url( 'css/style.css' );
    };

    get '/page2' => sub {
        return cdn_url( 'css/style2.css' );
    };

}

use Dancer::Test;

route_exists [GET => '/status'], 'home page route';

response_status_is [GET => '/status'], 200;
response_content_is [GET => '/status'], 'OK';

my $resp = dancer_response(GET => '/');
is $resp->{status}, 200, 'GET / => status 200';
like $resp->{content}, qr{^/CDN/css/style[.][0-9A-F]{12}[.]css},
    'css/style.css rewritten to /CDN/css/style.<HASH>.css';
chomp(my $url = $resp->{content});

$resp = dancer_response(GET => $url);
is $resp->{status}, 200, "GET $url => status 200";
like $resp->{content}, qr/h1 \{ color: red; \}/, 'css/style.css content';

ok $resp->header('Expires'), 'Expires header';
ok $resp->header('Last-Modified'), 'Last-Modified header';
ok $resp->header('Cache-Control'), 'Cache-Control header';
my $lifetime = str2time( $resp->header('Expires') ) - time();
ok $lifetime > ONE_YEAR, 'future expiry';

$resp = dancer_response(GET => '/page2');
is $resp->{status}, 200, "GET /page2 => status 200";
like $resp->{content}, qr{^/CDN/css/style2[.][0-9A-F]{12}[.]css},
    'css/style.css rewritten to /CDN/css/style2.<HASH>.css';
chomp($url = $resp->{content});

$resp = dancer_response(GET => $url);
is $resp->{status}, 200, "GET $url => status 200";
like $resp->{content}, qr{images/logo[.][0-9A-F]{12}[.]png},
    'css/style2.css content';

$url =~ s/[.][0-9A-F]{12}[.]/.FFFFFFFFFFFF./;
$resp = dancer_response(GET => $url);
is $resp->{status}, 404, "GET $url => status 404";

done_testing;

