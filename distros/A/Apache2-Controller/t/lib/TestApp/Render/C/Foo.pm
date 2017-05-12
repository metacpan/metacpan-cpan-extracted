package TestApp::Render::C::Foo;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    TestApp::Render::ControllerBase
);

use Apache2::Const -compile => qw(HTTP_OK);
use Log::Log4perl qw(:easy);

sub allowed_methods {qw( bar default )}

sub default {
    my ($self) = @_;
    DEBUG("This is a test.  default()");
    $self->render();
    return Apache2::Const::HTTP_OK;
}

# test path_args:
sub bar {
    my ($self) = @_;
    DEBUG("This is a test.  bar()");
    $self->render();
    return Apache2::Const::HTTP_OK;
}


1;
