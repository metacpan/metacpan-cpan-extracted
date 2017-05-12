package MyApp::ArgvTest;

use strict;
use base qw(App::CLI::Command);

sub run {

    my($self, @args) = @_;
    $main::RESULT = $self->argv0;
}
1;

