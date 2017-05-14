use strict;
use warnings;
use Test::More;
use feature ':5.10';

use File::Spec;
use File::Basename 'dirname';

my $curdir = dirname(__FILE__);
my $views_dir = File::Spec->catfile( $curdir, 'views' );

use DDP;

{

    package App;
    use Dancer;
    use Dancer::Plugin::UUID;
    set views => $views_dir;

    get '/inline' => sub {
        my $uuid = uuid() // 'undef';
        return "hello, $uuid";
    };

    get '/view' => sub {
        template 'index';
    };
}

use Dancer::Test;

my $uuid;
my $test_cookie_value;

subtest "On first visit, we should get a test cookie..." => sub {
    my $response = dancer_response( 'get', '/inline' );

    my $test_cookie = $response->header('Set-Cookie');
    ok( $test_cookie, "A test cookie was droped" );

    if ( $test_cookie =~ /dancer.uuid.test=(\w+); / ) {
        $test_cookie_value = $1;
    }
    ok( $test_cookie_value, "... and the value is valid" );

    is $response->content, "hello, undef",
      "The view does not provide a UUID value";
};


subtest "If we provide a valid test cookie, we should get a UUID cookie..." =>
  sub {
    my $response = dancer_response(
        'get',
        '/inline',
        {   headers =>
              [ 'Set-Cookie' => "dancer.uuid.test=$test_cookie_value;" ],
        }
    );
    my $test_cookie = $response->header('Set-Cookie');
    if ( $test_cookie =~ /dancer\.uuid=(\w+-\w+-\w+-\w+-\w+); / ) {
        $uuid = $1;
    }

    ok( defined $uuid, "a UUID cookie was droped" );
  };

done_testing;
1;
