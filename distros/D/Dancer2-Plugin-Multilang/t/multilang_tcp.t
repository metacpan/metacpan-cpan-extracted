use strict;
use warnings;

use Test::More;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Data::Dumper;

use t::testapp::lib::Site;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        #Enter with a language-equipped URL
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        $ua->default_header('Accept-Language' => "en");
        my $res = $ua->get("http://127.0.0.1:$port/it/");
        is($res->content, 'it', "Explicit language in URL returns right language [home]");
        $res  = $ua->get("http://127.0.0.1:$port/it/page");
        is($res->content, 'page-it', "Explicit language in URL returns right language [page]");
        $res  = $ua->get("http://127.0.0.1:$port/second");
        ok($res->is_success && $res->previous, "Redirect from /.. to /it/..");
        is($res->content, 'second-it', "Language configured by previous navigation preserved");

        #Enter with no language, but an header
        $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        $ua->default_header('Accept-Language' => "en");
        $res = $ua->get("http://127.0.0.1:$port/page");
        ok($res->is_success && $res->previous, "Redirect from /.. to /en/..");
        is($res->content, 'page-en', "Header language correctly read to return page");

        #No language and no header, default is used
        $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        $res = $ua->get("http://127.0.0.1:$port/page");
        ok($res->is_success && $res->previous, "Redirect from /.. to /it/..");
        is($res->content, 'page-it', "Default language correctly used when no header/URL is given [home]");
        $res  = $ua->get("http://127.0.0.1:$port/second");
        ok($res->is_success && $res->previous, "Redirect from /.. to /it/..");
        is($res->content, 'second-it', "Default language correctly used when no header/URL is given [page]");

        #Language switch
        $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        $ua->default_header('Accept-Language' => "en");
        $res = $ua->get("http://127.0.0.1:$port");
        $res = $ua->get("http://127.0.0.1:$port/it/page");
        is($res->content, 'page-it', "Language changed from en to it by language in URL");
        $res = $ua->get("http://127.0.0.1:$port/second");
        ok($res->is_success && $res->previous, "Redirect from /.. to /it/..");
        is($res->content, 'second-it', "Language change mantained in further navigations");

        #no_lang_prefix
        $ua = LWP::UserAgent->new;
        $ua->cookie_jar({file => "cookies.txt"});
        $ua->default_header('Accept-Language' => "en");
        $res = $ua->get("http://127.0.0.1:$port");
        $res = $ua->get("http://127.0.0.1:$port/free");
        ok($res->is_success && ! $res->previous, "no_lang_prefix served without redirection");
    },
    server => sub {
        my $port = shift;
        use Dancer2;
        if($Dancer2::VERSION < 0.14)
        {
            Dancer2->runner->server->port($port);
        }
        else
        {
            Dancer2->runner->{'port'} = $port;
        }
        start;
    },
);
done_testing;
