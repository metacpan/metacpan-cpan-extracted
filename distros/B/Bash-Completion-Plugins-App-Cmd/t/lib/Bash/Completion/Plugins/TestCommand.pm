package Bash::Completion::Plugins::TestCommand;

use strict;
use warnings;
use parent 'Bash::Completion::Plugins::App::Cmd';

sub should_activate {
    return [ 'test-command' ];
}

sub command_class { 'TestCommand' }

1;
