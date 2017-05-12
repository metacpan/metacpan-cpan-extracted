#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Test::More import => ['!pass'];

{
    BEGIN {
        use Dancer;
        set plugins => { 'Locale::TextDomain' => { locale_path => 't/locale' } };

    };
    use Dancer::Plugin::Locale::Detect;
    use Dancer::Plugin::Locale::TextDomain;

    get '/' => sub {
        return __"greet";
    };
}

use Dancer::Test;

response_content_is [GET => '/?locale=nl'], "Hallo", "locale from param";
response_content_is [GET => '/?locale=fr'], "Bonjour", "locale from param";

my $res;

$res = dancer_response('GET', '/', { headers => ['Accept-Language' => 'en-CA,en;q=0.8,en-US;q=0.6'] });
is $res->{content}, "Hello", "locale from parse Accept-Language header";
$res = dancer_response('GET', '/', { headers => ['Accept-Language' => 'fr'] });
is $res->{content}, "Bonjour", "locale from parse Accept-Language header";

$res = dancer_response('GET', '/?locale=nl', { headers => ['Accept-Language' => 'fr'] });
is $res->{content}, "Hallo", "locale param takes precedence";

done_testing 5;

