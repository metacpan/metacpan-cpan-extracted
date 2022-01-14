use strict;
use warnings;
use Test::More tests => 27;
use Config;

use CGI::Simple::Standard qw(:all -default);

# Makes forked test work OK
Test::More->builder->no_ending( 1 );

my $CRLF = "\015\012";

# A peculiarity of sending "\n" through MBX|Socket|web-server on VMS
# is that a CR character gets inserted automatically in the web server
# case but not internal to perl's double quoted strings "\n".  This
# test would need to be modified to use the "\015\012" on VMS if it
# were actually run through a web server.
# Thanks to Peter Prymmer for this

if ( $^O eq 'VMS' ) {
  $CRLF = "\n";
}

# Web servers on EBCDIC hosts are typically set up to do an EBCDIC -> ASCII
# translation hence CRLF is used as \r\n within CGI.pm on such machines.

if ( ord( "\t" ) != 9 ) {
  $CRLF = "\r\n";
}

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{QUERY_STRING}    = 'game=chess&game=checkers&weather=dull';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'the.good.ship.lollypop.com';
$ENV{HTTP_LOVE}       = 'true';

is( request_method(), 'GET', "CGI::request_method()" );
is( query_string(), 'game=chess;game=checkers;weather=dull',
  "CGI::query_string()" );
is( param(), 2, "CGI::param()" );
is( join( ' ', sort { $a cmp $b } param() ),
  'game weather', "CGI::param()" );
is( param( 'game' ),    'chess', "CGI::param()" );
is( param( 'weather' ), 'dull',  "CGI::param()" );
is( join( ' ', param( 'game' ) ), 'chess checkers', "CGI::param()" );
ok( param( -name => 'foo', -value => 'bar' ), 'CGI::param() put' );
is( param( -name => 'foo' ), 'bar', 'CGI::param() get' );
is(
  query_string(),
  'game=chess;game=checkers;weather=dull;foo=bar',
  "CGI::query_string() redux"
);
is( http( 'love' ), 'true',             "CGI::http()" );
is( script_name(),  '/cgi-bin/foo.cgi', "CGI::script_name()" );
is( url(), 'http://the.good.ship.lollypop.com:8080/cgi-bin/foo.cgi',
  "CGI::url()" );
is(
  self_url(),
  'http://the.good.ship.lollypop.com:8080/cgi-bin/foo.cgi/somewhere/else'
   . '?game=chess;game=checkers;weather=dull;foo=bar',
  "CGI::url()"
);
is( url( -absolute => 1 ),
  '/cgi-bin/foo.cgi', 'CGI::url(-absolute=>1)' );
is( url( -relative => 1 ), 'foo.cgi', 'CGI::url(-relative=>1)' );
is( url( -relative => 1, -path => 1 ),
  'foo.cgi/somewhere/else', 'CGI::url(-relative=>1,-path=>1)' );
is(
  url( -relative => 1, -path => 1, -query => 1 ),
  'foo.cgi/somewhere/else?game=chess;game=checkers;weather=dull;foo=bar',
  'CGI::url(-relative=>1,-path=>1,-query=>1)'
);
Delete( 'foo' );
ok( !param( 'foo' ), 'CGI::delete()' );

#CGI::_reset_globals();

$ENV{QUERY_STRING} = 'mary+had+a+little+lamb';

restore_parameters();
is( join( ' ', keywords() ), 'mary had a little lamb',
  'CGI::keywords' );
is(
  join( ' ', param( 'keywords' ) ),
  'mary had a little lamb',
  'CGI::keywords'
);

is(
  redirect( 'http://somewhere.else' ),
  "Status: 302 Found${CRLF}Location: http://somewhere.else${CRLF}${CRLF}",
  "CGI::redirect() 1"
);

my $h = redirect(
  -Location => 'http://somewhere.else',
  -Type     => 'text/html'
);

is(
  $h,
  "Status: 302 Found${CRLF}Location: http://somewhere.else${CRLF}"
   . "Content-Type: text/html; charset=ISO-8859-1${CRLF}${CRLF}",
  "CGI::redirect() 2"
);

is(
  redirect(
    -Location => 'http://somewhere.else/bin/foo&bar',
    -Type     => 'text/html'
  ),
  "Status: 302 Found${CRLF}Location: http://somewhere.else/bin/foo&bar${CRLF}"
   . "Content-Type: text/html; charset=ISO-8859-1${CRLF}${CRLF}",
  "CGI::redirect() 2"
);

is( escapeHTML( 'CGI' ), 'CGI', 'escapeHTML(CGI) failing again' );

SKIP: {
  skip "Fork not available on this platform", 2 unless $Config{d_fork};
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
  restore_parameters();           # trigger a reinitialisaton
  is( param( 'weather' ), 'nice', "CGI::param() from POST" );
  is( url_param( 'big_balls' ), 'basketball', "CGI::url_param()" );
}
