package MyAppEnv::YAMLTest;

use strict;
use base qw(App::CLI::Command);

sub run {

    my($self, @args) = @_;
    $main::RESULT = $self->config;
}
1;

