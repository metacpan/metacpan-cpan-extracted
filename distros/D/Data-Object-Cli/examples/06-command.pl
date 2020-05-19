#!/usr/bin/env perl

package Command;

use strict;
use warnings;

use feature 'say';

use parent 'Data::Object::Cli';

sub name {

  'command <sub{command}>'
}

sub info {
  my ($self) = @_;

  'example command-line application'
}

sub auto {
  {
    echo => 'handle_echo',
  }
}

sub handle_echo {
  my ($self, %args) = @_;

  require Data::Dumper;

  say(+(shift)->help, "\n", Data::Dumper::Dumper($args{args}->unnamed));
}

run Command;
