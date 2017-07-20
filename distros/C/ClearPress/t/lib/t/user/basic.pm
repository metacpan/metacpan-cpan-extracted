# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
package t::user::basic;
use strict;
use warnings;
use base qw(ClearPress::model);

sub fields {
  return qw(username);
}

sub is_member_of {
  my ($self, $groupname) = @_;
  return;
}

1;
