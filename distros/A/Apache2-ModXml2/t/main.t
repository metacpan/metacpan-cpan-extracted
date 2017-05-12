#!perl

use strict;
use warnings FATAL => 'all';
use lib qw(t/lib lib);
use Test::More;
use My::TestHelper qw(cmp_file_ok read_file);

use constant HAVE_APACHE_TEST => eval {
    require Apache::Test && Apache::Test->VERSION >= 1.22
};

plan tests => 7;

if (HAVE_APACHE_TEST) {

    require Apache::TestUtil;
    require Apache::TestRequest;

    Apache::TestUtil->import;
    Apache::TestRequest->import('GET');
} else {
    plan skip_all => 'Apache::Test 1.22 is not installed';
}

SKIP: {
    my $docroot = Apache::Test::vars('documentroot');

    # Basic apache test
    # make sure we can get a regular file
    {
        my $url = '/test.html';
        my $r = GET($url);
        is $r->code, 200;
        cmp_file_ok $r->content, "$docroot/test.html";
    }


    # Check if AllowOverride FileInfo is set
    {
        my $url = '/override/test.html';
        my $r = GET($url);
        is($r->code, 200, 'override') 
        or diag(qq|You will need AllowOverride FileInfo in your server configuration
to use Apache2::ModXml2 from .htaccess.|);
    }

    # 1st try to use Apache2::ModXml2 
    {
        my $url = '/xml2/test1.xml';
        my $r = GET($url);
        is $r->code, 200;
        cmp_file_ok $r->content, "$docroot/xml2/expected1.xml";
    }

    # 2nd try to use Apache2::ModXml2 
    {
        my $url = '/xml2/test2.xml';
        my $r = GET($url);
        is $r->code, 200;
        cmp_file_ok $r->content, "$docroot/xml2/expected2.xml";
    }
}


