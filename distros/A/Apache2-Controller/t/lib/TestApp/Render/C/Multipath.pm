package TestApp::Render::C::Multipath;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    TestApp::Render::ControllerBase
);

use Readonly;
use Apache2::Const -compile => qw(HTTP_OK);
use Log::Log4perl qw(:easy);

sub allowed_methods {qw( test )}

sub test {
    my ($self) = @_;
    DEBUG("This is a test.  default()");
    $self->render();
    return Apache2::Const::HTTP_OK;
}



1;
