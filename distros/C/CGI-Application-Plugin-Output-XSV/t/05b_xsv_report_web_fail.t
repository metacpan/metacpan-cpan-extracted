#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception required to test die" if $@;
  plan tests => 2;
}

BEGIN {
  use_ok( 'CGI' );
};

use lib './t';
use XSVTest;

$ENV{CGI_APP_RETURN_ONLY}= 1;

my $app= XSVTest->new( QUERY => CGI->new({ rm => 'xsv_fail' }) );

throws_ok { $app->run }
          qr/need array reference of values or iterator to do anything/i,
          'app raises exception without values parameter';
