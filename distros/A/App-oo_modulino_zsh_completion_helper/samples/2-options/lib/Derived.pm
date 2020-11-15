#!/usr/bin/env perl
package
  Derived;
use strict;
use warnings;

sub MY () {__PACKAGE__}

use File::AddInc;
use base qw(Greetings_oo_modulino_with_fields);
use fields qw/width height/;

unless (caller) {
  my $self = MY->new(name => 'world', MY->SUPER::_parse_posix_opts(\@ARGV));

  my $cmd = shift
    or die "Usage: $0 COMMAND ARGS...\n";

  print $self->$cmd(@ARGV), "\n";
}

1;
