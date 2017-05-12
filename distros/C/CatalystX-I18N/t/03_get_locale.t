#!perl
use strict;
use warnings;

use Test::Most tests=>22;
#use Test::NoWarnings; 
# Cannot run with NoWarnings since we get a warning from HTTP::BrowserDetect
# wen running under make test

use lib qw(t/testapp/lib);

use Catalyst::Test 'TestApp';

{
    my($res, $c) = ctx_request('/base/test6');
    my $request = $c->request;
    $request->header('Accept-Language','zh, fr_CH; q=0.8, sk; q=0.6');
    cmp_deeply($c->request->accept_language,['zh','fr_CH','sk','fr'],'Accept language');
    is($c->get_locale_from_browser,'fr_CH','Locale from accept-language');
}

{
    my($res, $c) = ctx_request('/base/test6');
    my $request = $c->request;
    $request->header('Accept-Language','zh, FR; q=0.8, fr_CH; q=0.6');
    cmp_deeply($c->request->accept_language,['zh','fr','fr_CH'],'Accept language');
    is($c->get_locale_from_browser,'fr','Locale from accept-language');
}

{
    my($res, $c) = ctx_request('/base/test6');
    my $request = $c->request;
    $request->header('Accept-Language','zh, de-at; q=0.8, de; q=0.6');
    cmp_deeply($c->request->accept_language,['zh','de_AT','de'],'Accept language');
    is($c->get_locale_from_browser,'de_AT','Locale from accept-language');
}

{
    my($res, $c) = ctx_request('/base/test6');
    my $request = $c->request;
    $request->header('Accept-Language','zh, de; q=0.8, de-at; q=0.6');
    cmp_deeply($c->request->accept_language,['zh','de','de_AT'],'Accept language');
    is($c->get_locale_from_browser,'de_AT','Locale from accept-language');
}

{
    my($res, $c) = ctx_request('/base/test6');
    my $request = $c->request;
    $request->header('Accept-Language','xx, de-ch; q=0.8, de-at; q=0.6');
    cmp_deeply($c->request->accept_language,['xx','de_CH','de_AT','de'],'Accept language');
    is($c->get_locale_from_browser,'de_CH','Locale from accept-language');
}

{
    my($res, $c) = ctx_request('/base/test6');
    my $request = $c->request;
    $request->header('Accept-Language','zh, sk, fr-ca');
    $request->header('User-Agent',"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; de; rv:1.9.2) Gecko/20100115 Firefox/3.6");
    cmp_deeply($c->request->accept_language,['zh','sk','fr_CA','fr'],'Accept language');
    is($c->request->browser_language,'de','Browser language');
    is($c->get_locale_from_browser,'fr','Locale from accept-language');
}

{
    my($res, $c) = ctx_request('/base/test6');
    my $request = $c->request;
    $request->header('Accept-Language','zh, sk, cz, gibe-rsih');
    $request->header('User-Agent',"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr; rv:1.9.2) Gecko/20100115 Firefox/3.6");
    cmp_deeply($c->request->accept_language,['zh','sk','cz'],'Accept language');
    is($c->request->browser_language,'fr','Browser language');
    is($c->get_locale_from_browser,'fr','Locale from browser');
}

{
    my($res, $c) = ctx_request('/base/test6');
    my $request = $c->request;
    $request->header('Accept-Language','zh, sk, cz');
    $request->address('84.20.181.0');
    cmp_deeply($c->request->accept_language,['zh','sk','cz'],'Accept language');
    is($c->request->client_country,'AT','Browser territory');
    is($c->get_locale_from_browser,'de_AT','Locale from IP');
}

{
    my($res, $c) = ctx_request('/base/test6');
    my $request = $c->request;
    $request->header('Accept-Language','giberish');
    $request->address('84.20.181.0');
    is($c->request->client_country,'AT','Browser territory');
    is($c->get_locale_from_browser,'de_AT','Locale from IP');
}

{
    my($res, $c) = ctx_request('/base/test6');
    delete $c->config->{I18N}{default_locale};
    my $request = $c->request;
    isnt($c->get_locale,'de','Locale from fallback');
}