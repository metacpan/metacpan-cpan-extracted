use strict;
use warnings;
use t::TestMe;
use Dancer::Test;
use Test::More import => ["!pass"], tests => 2;
use Test::Cucumber::Tiny;

my $cucumber = Test::Cucumber::Tiny->new(
    scenarios => [
        {
            Scenario => "Load the page has <tag> tag only",
            Given => "route of <route>",
            When  => "get response",
            Then  =>  "response has tag <tag> and url is <minifered_url>",
            Examples => [
                {
                    route => "/js_tags",
                    tag   => "script",
                    minifered_url => "http://localhost/static/minified.js",
                },
                {
                    route => "/css_tags",
                    tag   => "link",
                    minifered_url => "http://localhost/static/minified.css",
                },
            ],
        },
    ],
);

$cucumber->Given(
    qr/route of (.+)/, sub {
        my $c = shift;
        diag shift;
        $c->{route} = $1;
    }
);

$cucumber->When(
    qr/get response/, sub {
        my $c = shift;
        diag shift;
        $c->{response} = dancer_response(GET => $c->{route});
    }
);

$cucumber->Then(
    qr/response has tag (.+) and url is (.+)/, sub {
        my $c = shift;
        like $c->{response}->content, qr{<$1 .*="$2"}, shift;
    }
);

$cucumber->Test;
