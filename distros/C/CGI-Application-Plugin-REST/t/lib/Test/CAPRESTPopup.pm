package Test::CAPRESTPopup;
use strict;
use warnings;
use base 'CGI::Application';

BEGIN {
    $ENV{CAP_DEVPOPUP_EXEC} = 1;
}
use CGI::Application::Plugin::DevPopup;
use CGI::Application::Plugin::REST qw( rest_route );

sub setup {
    my ($self) = @_;

    $self->rest_route('/foo/:one/:two/:three/' => 'doop');

    return;
}

sub doop {
    my ($self) = @_;

    return CGI::Application::Plugin::REST::_rest_devpopup($self);
}

1;
