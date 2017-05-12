#!perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use Text::Diff;
use Catalyst::Test 'TestApp4';

my $root = $FindBin::Bin;

my ( $stderr, $old_stderr );
BEGIN {
    no warnings 'redefine';

    *Catalyst::Test::local_request = sub {
        my ( $class, $request ) = @_;

        require HTTP::Request::AsCGI;
        my $cgi = HTTP::Request::AsCGI->new( $request, %ENV )->setup;

        $class->handle_request;

        return $cgi->restore->response;
    };
}

open(SAVEERR, ">&STDERR");
close STDERR or print "cannot close STDERR\n";
open(STDERR, ">", \$stderr) or print "CAnnot open: $!\n";

run_tests();

close STDERR;
open(STDERR, ">&SAVEERR");

sub reset_stderr {
    close STDERR or print "cannot close STDERR\n";
    print "Current stderr: " . $stderr . "\n";
    $stderr = '';
    open(STDERR, ">", \$stderr) or print "CAnnot open: $!\n";
}

sub run_tests {

    # test first available view
    is($stderr, undef, 'empty stderr at start');
    reset_stderr();
    {
        my $expected = 'Everything is OK';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/test_ok' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->header( 'Content-Type' ), 'text/html; charset=utf-8', 'Content Type' );
        is( $response->code, 200, 'Response Code' );

        is($response->content, $expected, 'Content OK' );
        isnt( $stderr, '', "No stderr output");
    }

    reset_stderr();
    # Lets test a dying action
    {
        my $expected = qq{500 error happened};
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/test_die' );

        ok( my $response = request($request), 'Request' );
        ok( ! $response->is_success, 'Response Successful 2xx' );
        is( $response->header( 'Content-Type' ), 'text/html; charset=utf-8', 'Content Type' );
        is( $response->code, 500, 'Response Code' );
        my $content = $response->content;

        isnt( $response->content, $expected, 'Content OK' );
        isnt( $stderr, '[error] Caught exception in TestApp4->test_die "Death by action at ' . $root . '/lib/TestApp4.pm line 20."' . "\n");
    }
    reset_stderr();

    # lets try a 404 error to render template
    {
      my $expected = qq{Page not found};
      my $request  =
        HTTP::Request->new( GET => 'http://localhost:3000/test_404' );

      ok( my $response = request($request), 'Request' );
      ok( ! $response->is_success, 'Response Successful 2xx' );
      is( $response->header( 'Content-Type' ), 'text/html; charset=utf-8', 'Content Type' );
      is( $response->code, 404, 'Response Code' );
      is( $response->content, $expected, 'Content OK' );
      like( $stderr, qr|\[error\] Couldn\'t render template "file error - test_404: not found| );

    }
    reset_stderr();

}

done_testing();
