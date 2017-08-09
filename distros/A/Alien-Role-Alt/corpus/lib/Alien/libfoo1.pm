package Alien::libfoo1;

use strict;
use warnings;
use base qw( Alien::Base );
use Role::Tiny::With qw( with );

with('Alien::Role::Alt');

1;
