# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
package t::model;
use strict;
use warnings;
use base qw(ClearPress::model);
use Test::More;

__PACKAGE__->mk_accessors(fields());

sub fields {
  return qw(test_pk test_field);
}

########
# disable reading from database
#
sub create { return 1; }
sub read   { return 1; } ## no critic
sub update { return 1; }
sub delete { return 1; } ## no critic

1;
