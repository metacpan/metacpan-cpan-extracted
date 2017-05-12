package TestApp;

use strict;
use base qw(CGI::Application);
use CGI::Application::Plugin::CaptureIO;

sub cgiapp_init {

  my $self = shift;
  mkdir "tmp";
  $self->capture_init( capture_ttl => 1, capture_dir => "tmp", non_capture_rm => ["non_capture"]);
}

sub setup {

  my $self =  shift;
  $self->start_mode("capture");
  $self->mode_param("rm");
  $self->run_modes( capture => "capture", non_capture => "non_capture" );
}

sub capture {

  my $self = shift;
  return $self->get_current_runmode;
}

package main;
use strict;
use Test::More tests => 3;

$ENV{HTTP_HOST} = "local.domain";
$ENV{QUERY_STRING} = "rm=capture";
$ENV{REQUEST_URI} = "/app?" . $ENV{QUERY_STRING};
$ENV{REQUEST_METHOD} = "GET";

our $CAPTURE_DIR = "tmp";

my $app = TestApp->new;
isa_ok($app, "TestApp");
can_ok($app, qw(add_non_capture_runmodes capture_init current_url delete_non_capture_runmodes));
cmp_ok($app->current_url, "eq", (sprintf "%s://%s%s", "http", $ENV{HTTP_HOST}, $ENV{REQUEST_URI}));
my $body = $app->run;

exec "rm", "-rf", "tmp";



