package CSRFApp::Base;

use base qw(CGI::Application);
use strict;
use warnings;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::ProtectCSRF;
use Cwd;
use File::Spec;

sub cgiapp_init {
    my $self = shift;
    $self->tmpl_path(File::Spec->catfile(getcwd, "t", "template"));
    $self->protect_csrf_config( csrf_error_tmpl => "csrf_error.tmpl", csrf_error_tmpl_param => { MESSAGE => "your access is csrf!" } );
}

sub setup {
    my $self = shift;
    $self->start_mode("index");
    $self->error_mode("error");
    $self->mode_param("rm");
    $self->run_modes( index => "index", finish => "finish" );
}


sub error {
    my($self, $error) = @_;
    return "ERROR: $error";
}

1;

