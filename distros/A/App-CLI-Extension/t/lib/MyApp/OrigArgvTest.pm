package MyApp::OrigArgvTest;

use strict;
use base qw(App::CLI::Command);

sub run {

    my($self, @args) = @_;
    $main::RESULT = $self->orig_argv;
}
1;

