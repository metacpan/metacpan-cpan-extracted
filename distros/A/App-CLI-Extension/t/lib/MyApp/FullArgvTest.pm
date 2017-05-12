package MyApp::FullArgvTest;

use strict;
use base qw(App::CLI::Command);

sub run {

    my($self, @args) = @_;
    $main::RESULT = $self->full_argv0;
}
1;

