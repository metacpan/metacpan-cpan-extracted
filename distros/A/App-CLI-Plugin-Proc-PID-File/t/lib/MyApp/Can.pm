package MyApp::Can;

use strict;
use base qw(App::CLI::Command);

sub run {

    my($self, @args) = @_;
    $main::PF_RESULT = ($self->can("pf")) ? 1 : 0;
    $main::PATH_RESULT = ($self->pf->can("path")) ? 1 : 0;
}

1;

