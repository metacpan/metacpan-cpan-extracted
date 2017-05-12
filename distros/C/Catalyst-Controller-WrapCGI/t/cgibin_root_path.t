#!perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More tests => 3;

# Test configurable path root and dir
{ package root_test;

  use Test::More;
  use HTTP::Request::Common;
  use Catalyst::Test 'TestCGIBinRoot';

    my $response = request POST '/cgi/path/test.pl', [
        foo => 'bar',
        bar => 'baz'
       ];

    is($response->content, 'foo:bar bar:baz', 'POST to Perl CGI File');
}

# test another variation on specifying the root path
{ package another_root_test;

  use Test::More;
  use HTTP::Request::Common;
  use Catalyst::Test 'TestCGIBinRoot2';

  my $response = request POST '/cgi/path/test.pl', [
      foo => 'bar',
      bar => 'baz'
     ];

  is($response->content, 'foo:bar bar:baz', 'POST to Perl CGI File 2');
}

# test yet another variation on specifying the root path
{ package root_test_3;

  use Test::More;
  use HTTP::Request::Common;
  use Catalyst::Test 'TestCGIBinRoot3';

  my $response = request POST '/cgi/path/test.pl', [
      foo => 'bar',
      bar => 'baz'
     ];

  is($response->content, 'foo:bar bar:baz', 'POST to Perl CGI File 3');
}
