# copied and rearranged from CGI-Application-Plugin-Session's t/11_sessiondelete.t

use Test::More tests => 19;
use File::Spec;
#BEGIN { use_ok('CGI::Application::Plugin::Session') };

#use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
#use TestAppSessionDelete;
my $t1_obj = TestAppSessionDelete->new(QUERY=>CGI->new());
my $t1_output = $t1_obj->run();

like($t1_output, qr/session created/, 'session created');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

my ( $original_expiry ) = $t1_output =~ /expires=(.+)\s+Date/;

# Test Plan ... create a session ... not going to test that, b/c there are
# other tests for that.  What we're going to do is now create a new CGI query
# object and call the 'logout' runmode, which will call the new session_delete
# method, which should remove the flat file as well as send a cookie header
# with an expire timestamp in the past.

# need to inject session into $query - this is done by an environment var
$ENV{HTTP_COOKIE} = "CGISESSID=$id1";
my $query = new CGI({ rm => 'logout' });
$t1_obj = TestAppSessionDelete->new( QUERY => $query );
$t1_output = $t1_obj->run();

# vanilla output came through ok?
ok( $t1_output =~ /logout finished/, 'vanilla output came through ok' );
# If that didn't pass, then I'm guessing the session wasn't injected properly

# Was the session create cookie in the output?  It shouldn't be
unlike($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'new session cookie not in output');

# Was the session delete cookie in the output?  It should be
like($t1_output, qr/Set-Cookie: CGISESSID=;/, 'delete session cookie in output');

my ( $new_expiry ) = $t1_output =~ /expires=(.+)\s+Date/;

ok( $original_expiry ne $new_expiry, 'expirations are different' );

# Need to figure out if $new_expiry < $original_expiry and $new_expiry < NOW()
SKIP: {
    eval { require Date::Parse; };
    skip "Date::Parse not installed", 2 if $@;
    Date::Parse->import();
    my $expired_time = str2time( $new_expiry );
    my $original_time = str2time( $original_expiry );
    ok( $expired_time < $original_time, 'The new expiry is older than the original expiry' );
    my $current_time = time();
    # Since the cookie is recreated with a time of minus one day, we shouldn't
    # have to worry about timezones
    ok( $expired_time < $current_time, 'The new expiry is older than now' );
}

# Session object will not disappear and be written
# to disk until it is DESTROYed
undef $t1_obj;
# Is the file gone?
ok( !-e 't/cgisess_'.$id1, 'session_delete wiped the flat file ok' );


# We do the cookie tests again, this time we set some extra custom cookies
# and make sure they don't get clobbered
$ENV{HTTP_COOKIE} = "CGISESSID=$id1";
$query = new CGI({ rm => 'logout' });
$t1_obj = TestAppSessionDelete->new( QUERY => $query );
$t1_obj->header_add( -cookie => [ CGI::Cookie->new( -name => 'test', -value => 'testing' ) ]);
$t1_obj->header_add( -cookie => [ 'test2=testing2; path=/' ]);

$t1_output = $t1_obj->run();

# vanilla output came through ok?
ok( $t1_output =~ /logout finished/, 'vanilla output came through ok' );
# If that didn't pass, then I'm guessing the session wasn't injected properly

# Was the session create cookie in the output?  It shouldn't be
unlike($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'new session cookie not in output');

# Was the session delete cookie in the output?  It should be
like($t1_output, qr/Set-Cookie: CGISESSID=;/, 'delete session cookie in output');

# Was the test cookie in the output?  It should be
like($t1_output, qr/Set-Cookie: test=testing/, 'test cookie in output');

# Was the test cookie in the output?  It should be
like($t1_output, qr/Set-Cookie: test2=testing2/, 'second test cookie in output');


# We do the cookie tests one last time, this time we clobber the session cookie
# and set a single new cookie
$ENV{HTTP_COOKIE} = "CGISESSID=$id1";
$query = new CGI({ rm => 'logout' });
$t1_obj = TestAppSessionDelete->new( QUERY => $query );
$t1_obj->session; # this sets the session cookie
$t1_obj->header_add( -cookie => 'test2=testing2; path=/');  # this clobbers the session cookie

$t1_output = $t1_obj->run();

# vanilla output came through ok?
ok( $t1_output =~ /logout finished/, 'vanilla output came through ok' );
# If that didn't pass, then I'm guessing the session wasn't injected properly

# Was the session create cookie in the output?  It shouldn't be
unlike($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'new session cookie not in output');

# Was the session delete cookie in the output?  It should be
like($t1_output, qr/Set-Cookie: CGISESSID=;/, 'delete session cookie in output');


# Was the test cookie in the output?  It should be
like($t1_output, qr/Set-Cookie: test2=testing2/, 'test cookie in output');

# copied and rearranged from CGI-Application-Plugin-Session's t/TestAppSessionDelete.pm

package TestAppSessionDelete;

use strict;

use parent 'CGI::Application';
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Header;

sub cgiapp_init {
  my $self = shift;

  $self->session_config({
                        CGI_SESSION_OPTIONS => [ "driver:File", $self->query, {Directory=>'t/'} ],
                        SEND_COOKIE         => 1,
                        DEFAULT_EXPIRY      => '+1h',
                        COOKIE_PARAMS       => {
                                                 -path    => '/testpath',
                                                 -domain  => 'mydomain.com',
                                                 -expires => '+3M',
                                               },
  });

  $self->header(
      TestAppSessionDelete::Header->new(
          query => $self->query,
      )
  );
}

sub setup {
    my $self = shift;

    $self->start_mode('start');

    $self->run_modes( [ qw( start logout ) ] );
}

sub start {
  my $self = shift;
  my $output = '';

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}

sub logout {
  my $self = shift;
  my $query = $self->query;
  if ( ! $query->cookie( 'CGISESSID' ) ) {
      return "didn't get session passed in!";
  } else {
      $self->session_delete;
      return "logout finished";
  }
}

package TestAppSessionDelete::Header;
use parent 'CGI::Header';

sub _build_alias {
    +{
        'cookies'      => 'cookie',
        'content-type' => 'type',
    };
}

sub cookies {
    my $self = shift;
    $self->cookie( @_ );
}

sub cookie {
    my $self = shift;
    return $self->header->{cookie} unless @_;
    $self->header->{cookie} = shift;
    $self;
}
