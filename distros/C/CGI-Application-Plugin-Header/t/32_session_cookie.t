# copied and rearranged from CGI-Application-Plugin-Session's t/10_sessioncookie.t

use Test::More tests => 16;
use File::Spec;
#BEGIN { use_ok('CGI::Application::Plugin::Session') };

#use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
#use TestAppSessionCookie;
my $t1_obj = TestAppSessionCookie->new(QUERY=>CGI->new());
my $t1_output = $t1_obj->run();

like($t1_output, qr/session created/, 'session created');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

# check domain
like($t1_output, qr/domain=mydomain.com;/, 'domain found in cookie');

# check path
like($t1_output, qr/path=\/testpath/, 'path found in cookie');

# check expires (should not exist)
unlike($t1_output, qr/expires=/, 'expires not found in cookie');

# Session object will not disappear and be written
# to disk until it is DESTROYed
undef $t1_obj;

unlink File::Spec->catdir('t', 'cgisess_'.$id1);


my $query = new CGI({ rm => 'existing_session_cookie' });
$t1_obj = TestAppSessionCookie->new( QUERY => $query );
$t1_output = $t1_obj->run();

unlike($t1_output, qr/Set-Cookie: CGISESSID=test/, 'existing session cookie was deleted');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'new session cookie set');

($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

undef $t1_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id1);


$query = new CGI({ rm => 'existing_session_cookie_plus_extra_cookie' });
$t1_obj = TestAppSessionCookie->new( QUERY => $query );
$t1_output = $t1_obj->run();

unlike($t1_output, qr/Set-Cookie: CGISESSID=test/, 'existing session cookie was deleted');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'new session cookie set');
like($t1_output, qr/Set-Cookie: TESTCOOKIE=testvalue/, 'existing cookie was not deleted');

($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

undef $t1_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id1);


$query = new CGI({ rm => 'existing_extra_cookie' });
$t1_obj = TestAppSessionCookie->new( QUERY => $query );
$t1_output = $t1_obj->run();

like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'new session cookie set');
like($t1_output, qr/Set-Cookie: TESTCOOKIE=testvalue/, 'existing cookie was not deleted');

($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

undef $t1_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id1);

# copied and rearranged from CGI-Application-Plugin-Session's t/TestAppSessionCookie.pm

package TestAppSessionCookie;

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
                                                 -name    => CGI::Session->name,
                                                 -value   => '1111',
                                                 -path    => '/testpath',
                                                 -domain  => 'mydomain.com',
                                                 -expires => '',
                                               },
  });

  $self->header(
      TestAppSessionCookie::Header->new(
          query => $self->query,
      )
  );
}

sub setup {
    my $self = shift;

    $self->start_mode('test_mode');

    $self->run_modes([qw(test_mode existing_session_cookie existing_session_cookie_plus_extra_cookie existing_extra_cookie)]);
}

sub test_mode {
  my $self = shift;
  my $output = '';

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}

sub existing_session_cookie {
  my $self = shift;
  my $output = '';

  $self->header_add(-cookie => 
      $self->query->cookie(-name => 'CGISESSID', -value => 'test'),
  );

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}

sub existing_session_cookie_plus_extra_cookie {
  my $self = shift;
  my $output = '';

  $self->header_add(-cookie => [
      $self->query->cookie(-name => 'CGISESSID', -value => 'test'),
      $self->query->cookie(-name => 'TESTCOOKIE', -value => 'testvalue'),
  ]);

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}

sub existing_extra_cookie {
  my $self = shift;
  my $output = '';

  $self->header_add(-cookie => 
      $self->query->cookie(-name => 'TESTCOOKIE', -value => 'testvalue'),
  );

  my $session = $self->session;

  $output .= $session->is_new ? "session created\n" : "session found\n";
  $output .= "id=".$session->id."\n";

  return $output;
}

package TestAppSessionCookie::Header;
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
