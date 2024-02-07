# This was forked from the original cookie.t file distributed with CGI.pm 2.78
# Originally, only modification is to change CGI::Cookie to CGI::Simple::Cookie
# whenever it appeared. Since then the tests suites for CGI.pm and CGI::Simple
# have not been kept in sync.

# to have a consistent baseline, we nail the current time
# to 100 seconds after the epoch
BEGIN {
  *CORE::GLOBAL::time = sub { 100 };
}

use strict;
use warnings;
use Test::More tests => 122;
use Test::NoWarnings;

use CGI::Simple::Util qw(escape unescape);
use POSIX qw(strftime);

#-----------------------------------------------------------------------------
# make sure module loaded
#-----------------------------------------------------------------------------

BEGIN {
  use_ok( 'CGI::Simple::Cookie' );
}

my @test_cookie = (
  'foo=123, bar=qwerty;  baz=wib=ble ; qux=1&2&',
  'foo=123; bar=qwerty; baz=wibble;',
  'foo=vixen; bar=cow; baz=bitch; qux=politician',
  'foo=a%20phrase; bar=yes%2C%20a%20phrase; baz=%5Ewibble; qux=%27',
);

#-----------------------------------------------------------------------------
# Test parse
#-----------------------------------------------------------------------------

{
  my $result = CGI::Simple::Cookie->parse( $test_cookie[0] );

  is( ref( $result ), 'HASH', "Hash ref returned in scalar context" );

  my @result = CGI::Simple::Cookie->parse( $test_cookie[0] );

  is( @result, 8, "returns correct number of fields" );

  @result = CGI::Simple::Cookie->parse( $test_cookie[1] );

  is( @result, 6, "returns correct number of fields" );

  my %result = CGI::Simple::Cookie->parse( $test_cookie[0] );

  is( $result{foo}->value, '123',     "cookie foo is correct" );
  is( $result{bar}->value, 'qwerty',  "cookie bar is correct" );
  is( $result{baz}->value, 'wib=ble', "cookie baz is correct" );
  my @values = $result{qux}->value;
  is_deeply(
    \@values,
    [ 1, 2, '' ],
    "multiple values are supported including empty values."
  );
}

#-----------------------------------------------------------------------------
# Test fetch
#-----------------------------------------------------------------------------

{

  # make sure there are no cookies in the environment
  delete $ENV{HTTP_COOKIE};
  delete $ENV{COOKIE};

  my %result = CGI::Simple::Cookie->fetch();
  ok( keys %result == 0,
    "No cookies in environment, returns empty list" );

  # now set a cookie in the environment and try again
  $ENV{HTTP_COOKIE} = $test_cookie[2];
  %result = CGI::Simple::Cookie->fetch();
  ok( eq_set( [ keys %result ], [qw(foo bar baz qux)] ),
    "expected cookies extracted" );

  is( ref( $result{foo} ),
    'CGI::Simple::Cookie', 'Type of objects returned is correct' );
  is( $result{foo}->value, 'vixen',      "cookie foo is correct" );
  is( $result{bar}->value, 'cow',        "cookie bar is correct" );
  is( $result{baz}->value, 'bitch',      "cookie baz is correct" );
  is( $result{qux}->value, 'politician', "cookie qux is correct" );

  # Delete that and make sure it goes away
  delete $ENV{HTTP_COOKIE};
  %result = CGI::Simple::Cookie->fetch();
  ok( keys %result == 0,
    "No cookies in environment, returns empty list" );

# try another cookie in the other environment variable thats supposed to work
  $ENV{COOKIE} = $test_cookie[3];
  %result = CGI::Simple::Cookie->fetch();
  ok( eq_set( [ keys %result ], [qw(foo bar baz qux)] ),
    "expected cookies extracted" );

  is( ref( $result{foo} ),
    'CGI::Simple::Cookie', 'Type of objects returned is correct' );
  is( $result{foo}->value, 'a phrase',      "cookie foo is correct" );
  is( $result{bar}->value, 'yes, a phrase', "cookie bar is correct" );
  is( $result{baz}->value, '^wibble',       "cookie baz is correct" );
  is( $result{qux}->value, "'",             "cookie qux is correct" );
}

#-----------------------------------------------------------------------------
# Test raw_fetch
#-----------------------------------------------------------------------------

{

  # make sure there are no cookies in the environment
  delete $ENV{HTTP_COOKIE};
  delete $ENV{COOKIE};

  my %result = CGI::Simple::Cookie->raw_fetch();
  ok( keys %result == 0,
    "No cookies in environment, returns empty list" );

  # now set a cookie in the environment and try again
  $ENV{HTTP_COOKIE} = $test_cookie[2];
  %result = CGI::Simple::Cookie->raw_fetch();
  ok( eq_set( [ keys %result ], [qw(foo bar baz qux)] ),
    "expected cookies extracted" );

  is( ref( $result{foo} ), '',           'Plain scalar returned' );
  is( $result{foo},        'vixen',      "cookie foo is correct" );
  is( $result{bar},        'cow',        "cookie bar is correct" );
  is( $result{baz},        'bitch',      "cookie baz is correct" );
  is( $result{qux},        'politician', "cookie qux is correct" );

  # Delete that and make sure it goes away
  delete $ENV{HTTP_COOKIE};
  %result = CGI::Simple::Cookie->raw_fetch();
  ok( keys %result == 0,
    "No cookies in environment, returns empty list" );

# try another cookie in the other environment variable thats supposed to work
  $ENV{COOKIE} = $test_cookie[3];
  %result = CGI::Simple::Cookie->raw_fetch();
  ok( eq_set( [ keys %result ], [qw(foo bar baz qux)] ),
    "expected cookies extracted" );

  is( ref( $result{foo} ), '',           'Plain scalar returned' );
  is( $result{foo},        'a%20phrase', "cookie foo is correct" );
  is( $result{bar}, 'yes%2C%20a%20phrase', "cookie bar is correct" );
  is( $result{baz}, '%5Ewibble',           "cookie baz is correct" );
  is( $result{qux}, '%27',                 "cookie qux is correct" );
}

#-----------------------------------------------------------------------------
# Test new
#-----------------------------------------------------------------------------

{

  # Try new with full information provided
  my $c = CGI::Simple::Cookie->new(
    -name       => 'foo',
    -value      => 'bar',
    -expires    => '+3M',
    -domain     => '.capricorn.com',
    -path       => '/cgi-bin/database',
    -secure     => 1,
    -httponly   => 1,
    -samesite   => 'Lax',
    -priority   => 'High',
    -partitioned => 1
  );
  is( ref( $c ), 'CGI::Simple::Cookie',
    'new returns objects of correct type' );
  is( $c->name,  'foo', 'name is correct' );
  is( $c->value, 'bar', 'value is correct' );
  like(
    $c->expires,
    '/^[a-z]{3},\s*\d{2}-[a-z]{3}-\d{4}/i',
    'expires in correct format'
  );
  is( $c->domain, '.capricorn.com',    'domain is correct' );
  is( $c->path,   '/cgi-bin/database', 'path is correct' );
  ok( $c->secure,   'secure attribute is set' );
  ok( $c->httponly, 'httponly attribute is set' );
  is( $c->samesite, 'Lax', 'samesite attribute is correct' );
  is( $c->priority, 'High', 'priority attribute is correct' );
  is( $c->partitioned, 1, 'partitioned attribute is correct' );

# now try it with the only two manditory values (should also set the default path)
  $c = CGI::Simple::Cookie->new(
    -name  => 'baz',
    -value => 'qux',
  );
  is( ref( $c ), 'CGI::Simple::Cookie',
    'new returns objects of correct type' );
  is( $c->name,  'baz', 'name is correct' );
  is( $c->value, 'qux', 'value is correct' );
  ok( !defined $c->expires, 'expires is not set' );
  ok( !defined $c->max_age, 'max_age is not set' );
  ok( !defined $c->domain,  'domain attributeis not set' );
  is( $c->path, '/', 'path atribute is set to default' );
  ok( !defined $c->secure,   'secure attribute is not set' );
  ok( !defined $c->httponly, 'httponly attribute is not set' );
  ok( !defined $c->samesite, 'samesite attribute is not set' );
  ok( !$c->partitioned, 'partitioned attribute is not set' );

  # I'm really not happy about the restults of this section.  You pass
  # the new method invalid arguments and it just merilly creates a
  # broken object :-)
  # I've commented them out because they currently pass but I don't
  # think they should.  I think this is testing broken behaviour :-(

#    # This shouldn't work
#    $c = CGI::Simple::Cookie->new(-name => 'baz' );
#
#    is(ref($c), 'CGI::Simple::Cookie', 'new returns objects of correct type');
#    is($c->name   , 'baz',     'name is correct');
#    ok(!defined $c->value, "Value is undefined ");
#    ok(!defined $c->expires, 'expires is not set');
#    ok(!defined $c->domain , 'domain attributeis not set');
#    is($c->path   , '/', 'path atribute is set to default');
#    ok(!defined $c->secure , 'secure attribute is set');

}

#-----------------------------------------------------------------------------
# Test as_string
#-----------------------------------------------------------------------------

{
  my $c = CGI::Simple::Cookie->new(
    -name        => 'Jam',
    -value       => 'Hamster',
    -expires     => '+3M',
    '-max-age'   => '+3M',
    -domain      => '.pie-shop.com',
    -path        => '/',
    -secure      => 1,
    -httponly    => 1,
    -samesite    => 'strict',
    -priority    => 'high',
    -partitioned => 1,
  );

  my $name = $c->name;
  like( $c->as_string, "/$name/", "Stringified cookie contains name" );

  my $value = $c->value;
  like( $c->as_string, "/$value/",
    "Stringified cookie contains value" );

  my $expires = $c->expires;
  like( $c->as_string, "/$expires/",
    "Stringified cookie contains expires" );

  my $max_age = $c->max_age;
  like( $c->as_string, "/$max_age/",
    "Stringified cookie contains max_age" );

  my $domain = $c->domain;
  like( $c->as_string, "/$domain/",
    "Stringified cookie contains domain" );

  my $path = $c->path;
  like( $c->as_string, "/$path/", "Stringified cookie contains path" );

  like( $c->as_string, '/secure/',
    "Stringified cookie contains secure" );

  like( $c->as_string, '/HttpOnly/',
    "Stringified cookie contains HttpOnly" );

  like( $c->as_string, '/SameSite=Strict/',
    "Stringified cookie contains normalized SameSite" );

  like( $c->as_string, '/Priority=High/',
    "Stringified cookie contains normalized Priority" );

  like( $c->as_string, '/Partitioned/',
    "Stringified cookie contains Partitioned" );

  $c = CGI::Simple::Cookie->new(
    -name  => 'Hamster-Jam',
    -value => 'Tulip',
  );

  $name = $c->name;
  like( $c->as_string, "/$name/", "Stringified cookie contains name" );

  $value = $c->value;
  like( $c->as_string, "/$value/",
    "Stringified cookie contains value" );

  ok( $c->as_string !~ /expires/,
    "Stringified cookie has no expires field" );

  ok( $c->as_string !~ /max-age/,
    "Stringified cookie has no max_age field" );

  ok( $c->as_string !~ /domain/,
    "Stringified cookie has no domain field" );

  $path = $c->path;
  like( $c->as_string, "/$path/", "Stringified cookie contains path" );

  ok( $c->as_string !~ /secure/,
    "Stringified cookie does not contain secure" );

  ok( $c->as_string !~ /HttpOnly/,
    "Stringified cookie does not contain HttpOnly" );

  ok( $c->as_string !~ /SameSite/,
    "Stringified cookie does not contain SameSite" );

  ok( $c->as_string !~ /Priority/,
    "Stringified cookie does not contain Priority" );

  ok( $c->as_string !~ /Partitioned/,
    "Stringified cookie does not contain Partitioned" );
}

#-----------------------------------------------------------------------------
# Test compare
#-----------------------------------------------------------------------------

{
  my $c1 = CGI::Simple::Cookie->new(
    -name     => 'Jam',
    -value    => 'Hamster',
    -expires  => '+3M',
    -domain   => '.pie-shop.com',
    -path     => '/',
    -secure   => 1,
    -httponly => 1
  );

  # have to use $c1->expires because the time will occasionally be
  # different between the two creates causing spurious failures.
  my $c2 = CGI::Simple::Cookie->new(
    -name     => 'Jam',
    -value    => 'Hamster',
    -expires  => $c1->expires,
    -domain   => '.pie-shop.com',
    -path     => '/',
    -secure   => 1,
    -httponly => 1
  );

  # This looks titally whacked, but it does the -1, 0, 1 comparison
  # thing so 0 means they match
  is( $c1->compare( "$c1" ), 0, "Cookies are identical" );
  is( $c1->compare( "$c2" ), 0, "Cookies are identical" );

  $c1 = CGI::Simple::Cookie->new(
    -name   => 'Jam',
    -value  => 'Hamster',
    -domain => '.foo.bar.com'
  );

  # have to use $c1->expires because the time will occasionally be
  # different between the two creates causing spurious failures.
  $c2 = CGI::Simple::Cookie->new(
    -name  => 'Jam',
    -value => 'Hamster',
  );

  # This looks titally whacked, but it does the -1, 0, 1 comparison
  # thing so 0 (i.e. false) means they match
  is( $c1->compare( "$c1" ), 0, "Cookies are identical" );
  ok( $c1->compare( "$c2" ), "Cookies are not identical" );

  $c2->domain( '.foo.bar.com' );
  is( $c1->compare( "$c2" ), 0, "Cookies are identical" );
}

#-----------------------------------------------------------------------------
# Test name, value, domain, secure, expires and path
#-----------------------------------------------------------------------------

{
  my $c = CGI::Simple::Cookie->new(
    -name     => 'Jam',
    -value    => 'Hamster',
    -expires  => '+3M',
    -domain   => '.pie-shop.com',
    -path     => '/',
    -secure   => 1,
    -httponly => 1,
    -samesite => 'strict'
  );

  is( $c->name,            'Jam',   'name is correct' );
  is( $c->name( 'Clash' ), 'Clash', 'name is set correctly' );
  is( $c->name,            'Clash', 'name now returns updated value' );

  # this is insane!  it returns a simple scalar but can't accept one as
  # an argument, you have to give it an arrary ref.  It's totally
  # inconsitent with these other methods :-(
  is( $c->value, 'Hamster', 'value is correct' );
  is( $c->value( ['Gerbil'] ), 'Gerbil', 'value is set correctly' );
  is( $c->value, 'Gerbil', 'value now returns updated value' );

  my $exp = $c->expires;
  like(
    $c->expires,
    '/^[a-z]{3},\s*\d{2}-[a-z]{3}-\d{4}/i',
    'expires is correct'
  );
  like(
    $c->expires( '+12h' ),
    '/^[a-z]{3},\s*\d{2}-[a-z]{3}-\d{4}/i',
    'expires is set correctly'
  );
  like(
    $c->expires,
    '/^[a-z]{3},\s*\d{2}-[a-z]{3}-\d{4}/i',
    'expires now returns updated value'
  );
  isnt( $c->expires, $exp, "Expiry time has changed" );

  is( $c->domain, '.pie-shop.com', 'domain is correct' );
  is( $c->domain( '.wibble.co.uk' ),
    '.wibble.co.uk', 'domain is set correctly' );
  is( $c->domain, '.wibble.co.uk', 'domain now returns updated value' );

  is( $c->path,               '/',        'path is correct' );
  is( $c->path( '/basket/' ), '/basket/', 'path is set correctly' );
  is( $c->path, '/basket/', 'path now returns updated value' );

  ok( $c->secure,       'secure attribute is set' );
  ok( !$c->secure( 0 ), 'secure attribute is cleared' );
  ok( !$c->secure,      'secure attribute is cleared' );

  ok( $c->httponly,       'httponly attribute is set' );
  ok( !$c->httponly( 0 ), 'httponly attribute is cleared' );
  ok( !$c->httponly,      'httponly attribute is cleared' );

  is( $c->samesite,           'Strict', 'SameSite is correct' );
  is( $c->samesite( 'Lax' ), 'Lax',    'SameSite is set correctly' );
  is( $c->samesite,          'Lax',    'SameSite now returns updated value' );

  is( $c->samesite( 'None' ), 'None',    'SameSite is set correctly' );
  is( $c->samesite,          'None',    'SameSite now returns updated value' );
}

#----------------------------------------------------------------------------
# Max-age
#----------------------------------------------------------------------------

MAX_AGE: {
  {
    my $cookie = CGI::Simple::Cookie->new(
      -name      => 'a',
      value      => 'b',
      '-expires' => 'now',
    );
    is $cookie->expires, 'Thu, 01-Jan-1970 00:01:40 GMT';
    is $cookie->max_age => undef,
     'max-age is undefined when setting expires';
  }

  {
    my $cookie
     = CGI::Simple::Cookie->new( -name => 'a', 'value' => 'b' );
    $cookie->max_age( '+4d' );

    is $cookie->expires, undef, 'expires is undef when setting max_age';
    is $cookie->max_age => 4 * 24 * 60 * 60, 'setting via max-age';

    $cookie->max_age( '113' );
    is $cookie->max_age => 13, 'max_age(num) as delta';
  }

  {
    my $cookie
     = CGI::Simple::Cookie->new( -name=>'a', value=>'b', '-max-age' => '+3d');
    is( $cookie->max_age,3*24*60*60,'-max-age in constructor' );
    ok( !$cookie->expires,' ... lack of expires' );
  }

  {
    my $cookie = CGI::Simple::Cookie->new(
      -name    => 'a',
      value    => 'b',
      -expires => 'now',
      '-max-age' => '+3d'
    );
    is( $cookie->max_age,3*24*60*60,'-max-age in constructor' );
    ok( $cookie->expires,'-expires in constructor' );
  }
}

