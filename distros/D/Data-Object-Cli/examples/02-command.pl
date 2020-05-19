#!/usr/bin/env perl

package Command;

use strict;
use warnings;

use feature 'say';

use parent 'Data::Object::Cli';

sub main {

  say +(shift)->help
}

sub spec {
  {
    help => {
      desc => 'display help text',
      type => 'boolean',
      flag => 'h'
    }
  }
}

run Command;
