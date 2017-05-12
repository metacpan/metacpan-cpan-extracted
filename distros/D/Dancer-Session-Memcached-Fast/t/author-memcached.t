#!perl -T

BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use Modern::Perl;
use Test::Most;

plan tests => 3;

{

    package Webservice;
    use Dancer;

    setting session_memcached_fast_servers => '/tmp/memcached.socket';
    set appname                            => __PACKAGE__;
    set session                            => 'Memcached::Fast';

    get '/a' => sub { session->id };
    get '/b' => sub { session( 'time' => time ) };
    get '/c' => sub { session('time') };
    get '/d' => sub { session->destroy };
}

use Dancer::Test;

my $R;

$R = dancer_response GET => '/a';
my $id = $R->{content};

$R = dancer_response GET => '/a';
is $R->{content} => $id, 'session id survive';

$R = dancer_response GET => '/b';
my $time = $R->{content};

$R = dancer_response GET => '/c';
is $R->{content} => $time, 'storage get time';

dancer_response GET => '/d';
$R = dancer_response GET => '/a';
isnt $R->{content} => $id, 'session destroy';

done_testing;
