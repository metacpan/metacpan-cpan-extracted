package TestApp::Render::ControllerBase;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    Apache2::Controller
    Apache2::Controller::Render::Template
    Apache2::Request
);

use YAML::Syck;
use Log::Log4perl qw(:easy);

sub render {
    my ($self) = @_;
    DEBUG "Assigning Dump() to stash";
    $self->{stash}{Dump} = \&Dump;
    return $self->SUPER::render();
}

1;
