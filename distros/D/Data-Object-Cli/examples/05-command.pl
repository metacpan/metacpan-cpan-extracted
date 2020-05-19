#!/usr/bin/env perl

package Command;

use strict;
use warnings;

use feature 'say';

use parent 'Data::Object::Cli';

sub name {

  'command'
}

sub info {

  'example command-line application'
}

sub main {
  my ($self, %args) = @_;

  require Data::Dumper;

  say(+(shift)->help, "\n", Data::Dumper::Dumper($args{opts}->stashed));
}

sub spec {
  {
    ehlo => {
      desc => 'display hello world',
      type => 'flag',
      flag => 'e'
    },
    help => {
      desc => 'display help text',
      type => 'flag',
      flag => 'h'
    }
  }
}

run Command;
