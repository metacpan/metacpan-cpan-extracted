package MyApp::StashTest;

use strict;
use base qw(App::CLI::Command);

sub run {

    my($self, @args) = @_;
    $self->stash->{result} = $args[0];
    $main::RESULT = $self->stash->{result};
}
1;

