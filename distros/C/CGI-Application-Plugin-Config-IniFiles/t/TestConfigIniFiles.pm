package TestConfigIniFiles;

use base "CGI::Application";
use CGI::Application::Plugin::Config::IniFiles;
use Data::Dumper;
$Data::Dumper::Indent = 1;

sub cgiapp_init {
  my($self) = @_;
  if ( $self->param('config_object') ) { # for testing passing an object
    $self->config_file( $self->param('config_object') );
  } else { # for testing using filename
    my $file = -f "test.conf" ? "test.conf" : "../test.conf";
    $self->config_file($file);
  }
  return;
}

sub setup {
  my($self) = @_;
  $self->run_modes('start' => \&run_mode);
  $self->start_mode("start");
  return;
}

sub run_mode {
  my($self) = @_;
  my $out;

  my $title = $self->config->val("main","title");
  $out .= sprintf "title=\"%s\"\n",$title;

  my @db = $self->cfg->GroupMembers("db");
  $out .= sprintf "dbs=%s\n",join ",",map { (split "\\s+",$_,2)[1] } @db;

  return $out;
}

1;
