#!/usr/bin/perl -w

# Creation date: 2003-08-13 22:27:32
# Authors: Don
# Change log:
# $Id: 02url.t,v 1.8 2006/09/05 08:09:37 don Exp $

use strict;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { &Carp::cluck(); exit 0 };

    use Test;
    BEGIN { plan tests => 16 }

    use CGI::Utils;

    my $utils = CGI::Utils->new;

    $ENV{HTTP_HOST} = 'mydomain.com';
    $ENV{QUERY_STRING} = "stuff=1";
    $ENV{REQUEST_URI} = "/cgi-bin/test.cgi?stuff=1";
    $ENV{SCRIPT_NAME} = "/cgi-bin/test.cgi";
    $ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.0';
    $ENV{SERVER_PORT} = 80;

    my $host_url = 'http://mydomain.com';
    ok($utils->getSelfRefHostUrl eq $host_url);

    my $self_url = 'http://mydomain.com/cgi-bin/test.cgi';
    ok($utils->getSelfRefUrl eq $self_url);

    my $self_url_with_args = 'http://mydomain.com/cgi-bin/test.cgi?test=1';
    ok($utils->getSelfRefUrlWithParams({ test => 1 }) eq $self_url_with_args);

    $self_url_with_args = 'http://mydomain.com/cgi-bin/test.cgi?test=1&ab=2';
    ok($utils->get_self_ref_url_with_params({ test => 1, ab => 2 }, '&'));

    my $self_dir = 'http://mydomain.com/cgi-bin';
    ok($utils->getSelfRefUrlDir eq $self_dir);

    my $self_ref_with_query = 'http://mydomain.com/cgi-bin/test.cgi?stuff=1';
    # print STDERR "\n\nself_url_with_query=" . $utils->getSelfRefUrlWithQuery . "\n\n";
    ok($utils->getSelfRefUrlWithQuery eq $self_ref_with_query);

    $ENV{HTTPS} = 'on';
    my $ssl_host_url = 'https://mydomain.com';
    ok($utils->getSelfRefHostUrl eq $ssl_host_url);

    my $params_to_add = { field1 => 'val1', field2 => 'val2' };
    
    my $url1 = 'http://mydomain/cgi-bin/test.cgi';
    my $want1_1 = 'http://mydomain/cgi-bin/test.cgi?field1=val1;field2=val2';
    my $want1_2 = 'http://mydomain/cgi-bin/test.cgi?field2=val2;field1=val1';
    my $rv1 = $utils->addParamsToUrl($url1, $params_to_add);
    ok($rv1 eq $want1_1 or $rv1 eq $want1_2);

    my $url2 = 'http://mydomain/cgi-bin/test.cgi?';
    my $rv2 = $utils->addParamsToUrl($url2, $params_to_add);
    ok($rv2 eq $want1_1 or $rv2 eq $want1_2);

    my $url3 = 'http://mydomain/cgi-bin/test.cgi?stuff=1';
    my $want3_1 = 'http://mydomain/cgi-bin/test.cgi?stuff=1;field1=val1;field2=val2';
    my $want3_2 = 'http://mydomain/cgi-bin/test.cgi?stuff=1;field2=val2;field1=val1';
    my $want3_3 = 'http://mydomain/cgi-bin/test.cgi?field1=val1;stuff=1;field2=val2';
    my $want3_4 = 'http://mydomain/cgi-bin/test.cgi?field2=val2;stuff=1;field1=val1';
    my $want3_5 = 'http://mydomain/cgi-bin/test.cgi?field1=val1;field2=val2;stuff=1';
    my $want3_6 = 'http://mydomain/cgi-bin/test.cgi?field2=val2;field1=val1;stuff=1';
    my $rv3 = $utils->addParamsToUrl($url3, $params_to_add);
    ok($rv3 eq $want3_1 or $rv3 eq $want3_2 or $rv3 eq $want3_3
      or $rv3 eq $want3_4 or $rv3 eq $want3_5 or $rv3 eq $want3_6);

    my $url4 = 'http://mydomain/cgi-bin/test.cgi?stuff=1&stuff2=2';
    my $want4_1 = 'http://mydomain/cgi-bin/test.cgi?stuff2=2&stuff=1&field1=val1&field2=val2';
    my $want4_2 = 'http://mydomain/cgi-bin/test.cgi?stuff2=2&stuff=1&field2=val2&field1=val1';
    my $want4_3 = 'http://mydomain/cgi-bin/test.cgi?stuff2=2&field1=val1&stuff=1&field2=val2';
    my $want4_4 = 'http://mydomain/cgi-bin/test.cgi?stuff2=2&field2=val2&stuff=1&field1=val1';
    my $want4_5 = 'http://mydomain/cgi-bin/test.cgi?stuff2=2&field1=val1&field2=val2&stuff=1';
    my $want4_6 = 'http://mydomain/cgi-bin/test.cgi?stuff2=2&field2=val2&field1=val1&stuff=1';

    my $want4_7 = 'http://mydomain/cgi-bin/test.cgi?stuff=1&stuff2=2&field1=val1&field2=val2';
    my $want4_8 = 'http://mydomain/cgi-bin/test.cgi?stuff=1&stuff2=2&field2=val2&field1=val1';
    my $want4_9 = 'http://mydomain/cgi-bin/test.cgi?field1=val1&stuff2=2&stuff=1&field2=val2';
    my $want4_10 = 'http://mydomain/cgi-bin/test.cgi?field2=val2&stuff2=2&stuff=1&field1=val1';
    my $want4_11 = 'http://mydomain/cgi-bin/test.cgi?field1=val1&stuff2=2&field2=val2&stuff=1';
    my $want4_12 = 'http://mydomain/cgi-bin/test.cgi?field2=val2&stuff2=2&field1=val1&stuff=1';

    my $want4_13 = 'http://mydomain/cgi-bin/test.cgi?stuff=1&field1=val1&stuff2=2&field2=val2';
    my $want4_14 = 'http://mydomain/cgi-bin/test.cgi?stuff=1&field2=val2&stuff2=2&field1=val1';
    my $want4_15 = 'http://mydomain/cgi-bin/test.cgi?field1=val1&stuff=1&stuff2=2&field2=val2';
    my $want4_16 = 'http://mydomain/cgi-bin/test.cgi?field2=val2&stuff=1&stuff2=2&field1=val1';
    my $want4_17 = 'http://mydomain/cgi-bin/test.cgi?field1=val1&field2=val2&stuff2=2&stuff=1';
    my $want4_18 = 'http://mydomain/cgi-bin/test.cgi?field2=val2&field1=val1&stuff2=2&stuff=1';

    my $want4_19 = 'http://mydomain/cgi-bin/test.cgi?stuff=1&field1=val1&field2=val2&stuff2=2';
    my $want4_20 = 'http://mydomain/cgi-bin/test.cgi?stuff=1&field2=val2&field1=val1&stuff2=2';
    my $want4_21 = 'http://mydomain/cgi-bin/test.cgi?field1=val1&stuff=1&field2=val2&stuff2=2';
    my $want4_22 = 'http://mydomain/cgi-bin/test.cgi?field2=val2&stuff=1&field1=val1&stuff2=2';
    my $want4_23 = 'http://mydomain/cgi-bin/test.cgi?field1=val1&field2=val2&stuff=1&stuff2=2';
    my $want4_24 = 'http://mydomain/cgi-bin/test.cgi?field2=val2&field1=val1&stuff=1&stuff2=2';

    my $rv4 = $utils->addParamsToUrl($url4, $params_to_add);
    ok($rv4 eq $want4_1 or $rv4 eq $want4_2 or $rv4 eq $want4_3
       or $rv4 eq $want4_4 or $rv4 eq $want4_5 or $rv4 eq $want4_6
       or $rv4 eq $want4_7 or $rv4 eq $want4_8 or $rv4 eq $want4_9
       or $rv4 eq $want4_10 or $rv4 eq $want4_11 or $rv4 eq $want4_12
       or $rv4 eq $want4_13 or $rv4 eq $want4_14 or $rv4 eq $want4_15
       or $rv4 eq $want4_16 or $rv4 eq $want4_17 or $rv4 eq $want4_18
       or $rv4 eq $want4_19 or $rv4 eq $want4_20 or $rv4 eq $want4_21
       or $rv4 eq $want4_22 or $rv4 eq $want4_23 or $rv4 eq $want4_24
      );

    my $url5 = 'http://example.com/my_page';
    my $want5 = $url5 . '?field1=val1&field2=val2&field3=val3';
    my $rv5 = $utils->add_params_to_url($url5, { field1 => 'val1',
                                                 field2 => 'val2',
                                                 field3 => 'val3',
                                               },
                                        '&');
    ok($rv5 eq $want5);

    my $rel_url = 'doit.cgi';
    my $url = $utils->convertRelativeUrlWithParams($rel_url, { 's' => 1 });
    my $want = 'https://mydomain.com/cgi-bin/doit.cgi?s=1';
    ok($url eq $want);

    $rel_url = '../doit.cgi';
    $url = $utils->convertRelativeUrlWithParams($rel_url, { 's' => 1 });
    $want = 'https://mydomain.com/doit.cgi?s=1';
    ok($url eq $want);

    $rel_url = '../doit.cgi';
    $url = $utils->convert_relative_url_with_params($rel_url, { 's' => 1, 'a' => 2 }, '&');
    $want = 'https://mydomain.com/doit.cgi?a=2&s=1';
    ok($url eq $want);

    my $uri = $utils->getSelfRefUri;
    ok($uri eq '/cgi-bin/test.cgi');
}

exit 0;

###############################################################################
# Subroutines

