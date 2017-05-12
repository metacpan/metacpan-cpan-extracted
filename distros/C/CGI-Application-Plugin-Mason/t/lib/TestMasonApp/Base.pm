package TestMasonApp::Base;

use base qw(CGI::Application);
use strict;
use warnings;
use CGI::Application::Plugin::Mason;
use CGI::Application::Plugin::Stash;
use Cwd;
use File::Spec;

sub cgiapp_init {
    my $self = shift;
    $self->interp_config( comp_root => File::Spec->catfile(getcwd, "t", "template") );
}

sub setup {
    my $self = shift;
    $self->start_mode("index");
    $self->error_mode("error");
    $self->run_modes( index => "index" );
}


sub error {
    my($self, $error) = @_;
    return "ERROR: $error";
}

1;

