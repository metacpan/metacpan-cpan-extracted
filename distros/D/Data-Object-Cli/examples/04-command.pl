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

  say +(shift)->help
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
