package TestApp::Plain;

use strict;
use base qw(TestApp::base);
use CGI::Application::Plugin::TT::LastModified;

sub test {
    my $self = shift;
    return $self->tt_process( 'index.html' );
}

1;
