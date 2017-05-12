package MyApp::ConfigTest;

use strict;
use base qw(App::CLI::Command);
use constant options => ("c|color=s" => "color");

sub run {

    my($self, @args) = @_;
    $main::RESULT = $self->config->{$self->{color}};
}
1;

