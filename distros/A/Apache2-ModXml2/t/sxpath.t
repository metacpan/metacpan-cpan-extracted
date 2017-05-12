#!perl

use strict;
use warnings FATAL => 'all';
use lib qw(t/lib lib);
use Test::More;
use My::TestHelper qw(cmp_file_ok read_file);

use constant HAVE_APACHE_TEST => eval {
    require Apache::Test && Apache::Test->VERSION >= 1.22
};

plan tests => 6;

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


    # 3rd test use sxpath filter 
    {
        my $url = '/sxpath/test3.html';
        my $r = GET($url);
        is $r->code, 200;

        cmp_file_ok $r->content, "$docroot/sxpath/expected3.html";
    }

    # 4th test use sxpath filter with INCLUDES 
    {
        my $url = '/sxpath/test4.html';
        my $r = GET($url);
        is $r->code, 200;

        cmp_file_ok $r->content, "$docroot/sxpath/expected4.html";
    }

    # 5th test use sxpath filter with osm to track down a segfault 
    {
        my $url = '/sxpath/test5.osm';
        my $r = GET($url);
        is $r->code, 200;

        cmp_file_ok $r->content, "$docroot/sxpath/expected5.osm";
    }

}


