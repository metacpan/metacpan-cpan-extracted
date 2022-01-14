# This is the original function.t file distributed with CGI.pm 2.78
# The only change is to change the use statement and change references
# from CGI to CGI::Simple

use strict;
use warnings;
use Test::More tests => 43;
use Config;

use CGI::Simple ( -default );

# Makes forked test work OK
Test::More->builder->no_ending( 1 );

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{QUERY_STRING}    = 'game=chess&game=checkers&weather=dull';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'the.good.ship.lollypop.com';
$ENV{REQUEST_URI}
 = "$ENV{SCRIPT_NAME}$ENV{PATH_INFO}?$ENV{QUERY_STRING}";
$ENV{HTTP_LOVE} = 'true';

my $q = CGI::Simple->new;
ok( $q, "CGI::Simple::new()" );
is( $q->request_method, 'GET', "CGI::Simple::request_method()" );

is( $q->query_string, 'game=chess;game=checkers;weather=dull',
  "CGI::Simple::query_string()" );

is( $q->param(), 2, "CGI::Simple::param()" );
is( join( ' ', sort $q->param() ),
  'game weather', "CGI::Simple::param()" );
is( $q->param( 'game' ),    'chess', "CGI::Simple::param()" );
is( $q->param( 'weather' ), 'dull',  "CGI::Simple::param()" );

# ensuring that multiple values of the same param keep their original order in the param() call
# probably as a side effect of just testing other stuff
is(
  join( ' ', $q->param( 'game' ) ),
  'chess checkers',
  "CGI::Simple::param()"
);

ok( $q->param( -name => 'foo', -value => 'bar' ),
  'CGI::Simple::param() put' );

is( $q->param( -name => 'foo' ), 'bar', 'CGI::Simple::param() get' );

is(
  $q->query_string,
  'game=chess;game=checkers;weather=dull;foo=bar',
  "CGI::Simple::query_string() redux"
);

is( $q->http( 'love' ), 'true', "CGI::Simple::http()" );
is( $q->script_name, '/cgi-bin/foo.cgi', "CGI::Simple::script_name()" );

is( $q->url, 'http://the.good.ship.lollypop.com:8080/cgi-bin/foo.cgi',
  "CGI::Simple::url()" );

is(
  $q->self_url,
  'http://the.good.ship.lollypop.com:8080/cgi-bin/foo.cgi/somewhere/else?'
   . 'game=chess;game=checkers;weather=dull;foo=bar',
  "CGI::Simple::url()"
);

is( $q->url( -absolute => 1 ),
  '/cgi-bin/foo.cgi', 'CGI::Simple::url(-absolute=>1)' );

is( $q->url( -relative => 1 ),
  'foo.cgi', 'CGI::Simple::url(-relative=>1)' );

is( $q->url( -relative => 1, -path => 1 ),
  'foo.cgi/somewhere/else', 'CGI::Simple::url(-relative=>1,-path=>1)' );

is(
  $q->url( -relative => 1, -path => 1, -query => 1 ),
  'foo.cgi/somewhere/else?game=chess;game=checkers;weather=dull;foo=bar',
  'CGI::Simple::url(-relative=>1,-path=>1,-query=>1)'
);

$q->delete( 'foo' );
ok( !$q->param( 'foo' ), 'CGI::Simple::delete()' );

$q->_reset_globals;
$ENV{QUERY_STRING} = 'mary+had+a+little+lamb';

ok( $q = CGI::Simple->new, "CGI::Simple::new() redux" );

is(
  join( ' ', $q->keywords ),
  'mary had a little lamb',
  'CGI::Simple::keywords'
);

is(
  join( ' ', $q->param( 'keywords' ) ),
  'mary had a little lamb',
  'CGI::Simple::keywords'
);

ok $q = CGI::Simple->new( 'foo=bar=baz' ),
 'CGI::Simple::new(), equals in value';
is $q->param( 'foo' ), 'bar=baz', 'parsed parameter containing equals';

ok( $q = CGI::Simple->new( 'foo=bar&foo=baz' ),
  "CGI::Simple::new() redux" );
is( $q->param( 'foo' ), 'bar', 'CGI::Simple::param() redux' );

ok( $q = CGI::Simple->new( { 'foo' => 'bar', 'bar' => 'froz' } ),
  "CGI::Simple::new() redux 2" );

is( $q->param( 'bar' ), 'froz', "CGI::Simple::param() redux 2" );

# test tied interface
my $p = $q->Vars;
is( $p->{bar}, 'froz', "tied interface fetch" );
$p->{bar} = join( "\0", qw(foo bar baz) );
is( join( ' ', $q->param( 'bar' ) ),
  'foo bar baz', 'tied interface store' );

SKIP: {
  skip "Fork not available on this platform", 9
   unless $Config{d_fork};

  # test posting
  $q->_reset_globals;

  my $test_string = 'game=soccer&game=baseball&weather=nice';
  $ENV{REQUEST_METHOD} = 'POST';
  $ENV{CONTENT_LENGTH} = length( $test_string );
  $ENV{QUERY_STRING}   = 'big_balls=basketball&small_balls=golf';
  $ENV{CONTENT_TYPE}   = 'application/x-www-form-urlencoded';
  if ( open( CHILD, "|-" ) ) {    # cparent
    print CHILD $test_string;
    close CHILD;
    exit 0;
  }

  # at this point, we're in a new (child) process
  ok( $q = CGI::Simple->new, "CGI::Simple::new() from POST" );
  is( $q->param( 'weather' ), 'nice',
    "CGI::Simple::param() from POST" );
  is( $q->url_param( 'big_balls' ), 'basketball', "CGI::url_param()" );

  # test posting POSTDATA
  $q->_reset_globals;
  $test_string
   = '<post><game>soccer</game><game>baseball</game><weather>nice</weather></post>';
  $ENV{REQUEST_METHOD} = 'POST';
  $ENV{CONTENT_LENGTH} = length( $test_string );
  $ENV{QUERY_STRING}   = '';
  $ENV{CONTENT_TYPE}   = 'text/xml';
  if ( open( CHILD, "|-" ) ) {    # cparent
    print CHILD $test_string;
    close CHILD;
    exit 0;
  }
  ok( $q = CGI::Simple->new, "CGI::Simple::new from POST" );

  is( $q->param( 'POSTDATA' ),
    $test_string, "CGI::Simple::param('POSTDATA') from POST" );

  # test posting POSTDATA with nulls
  $q->_reset_globals;
  $test_string = "some nulls \0\0\0 are better than others \0\0\0";
  $ENV{REQUEST_METHOD} = 'POST';
  $ENV{CONTENT_LENGTH} = length( $test_string );
  $ENV{QUERY_STRING}   = '';
  $ENV{CONTENT_TYPE}   = 'text/plain';
  if ( open( CHILD, "|-" ) ) {    # cparent
    print CHILD $test_string;
    close CHILD;
    exit 0;
  }
  ok( $q = CGI::Simple->new, "CGI::Simple::new from POST" );

  is( $q->param( 'POSTDATA' ),
    $test_string, "CGI::Simple::param('POSTDATA') from POST w/nulls" );

  # test posting PUTDATA
  $q->_reset_globals;
  $test_string
   = '<put><game>soccer</game><game>baseball</game><weather>nice</weather></put>';
  $ENV{REQUEST_METHOD} = 'PUT';
  $ENV{CONTENT_LENGTH} = length( $test_string );
  $ENV{CONTENT_TYPE}   = 'text/xml';
  if ( open( CHILD, "|-" ) ) {    # cparent
    print CHILD $test_string;
    close CHILD;
    exit 0;
  }
  ok( $q = CGI::Simple->new, "CGI::Simple::new from PUT" );
  is( $q->param( 'PUTDATA' ),
    $test_string, "CGI::Simple::param('POSTDATA') from POST" );
}


{
   # ensuring multiple values of the same parameter preserve the order
   $ENV{QUERY_STRING}    = 'a=1&b=2&a=3&a=4&c=5&b=6';
   $ENV{REQUEST_METHOD}  = 'GET';
   my $s = CGI::Simple->new;
   is_deeply [$s->param( 'a' ) ], [1, 3, 4], 'multiple entries "a"';
   is_deeply [$s->param( 'b' ) ], [2, 6],    'multiple entries "b"';
   is_deeply [$s->param( 'c' ) ], [5],       'multiple entries "c"';
}


