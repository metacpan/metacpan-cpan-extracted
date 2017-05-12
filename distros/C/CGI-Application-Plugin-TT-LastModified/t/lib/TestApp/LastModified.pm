package TestApp::LastModified;

use strict;
use base qw(TestApp::base);
use CGI::Application::Plugin::TT::LastModified;

sub test {
    my $self = shift;
    my $html = $self->tt_process( 'index.html' );
    $self->tt_set_last_modified_header();
    return $html;
}

1;
