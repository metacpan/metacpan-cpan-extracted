#!/usr/bin/env perl

package Command;

use strict;
use warnings;

use feature 'say';

use parent 'Data::Object::Cli';

sub main {

  say +(shift)->help
}

run Command;
