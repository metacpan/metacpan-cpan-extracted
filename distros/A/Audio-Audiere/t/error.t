#!/usr/bin/perl -w

# test error in device-creation

use Test::More tests => 2;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch';
  chdir 't' if -d 't';
  }

use Audio::Audiere;

# the null device should always be there
my $au = Audio::Audiere->new( 'null' );

is ($au->error(), undef, 'no error');

$au = Audio::Audiere->new( 'non-existing' );

is ($au->error(), "Could not init device 'non-existing'", "error");

