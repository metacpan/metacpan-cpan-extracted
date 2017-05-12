package MyAppOption::YAMLTest;

use strict;
use base qw(App::CLI::Command);
use constant options => ("configfile=s" => "configfile");

sub run {

    my($self, @args) = @_;
    $main::RESULT = $self->config;
}
1;

