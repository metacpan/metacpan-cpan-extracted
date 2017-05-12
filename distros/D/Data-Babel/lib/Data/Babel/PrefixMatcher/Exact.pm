package Data::Babel::PrefixMatcher::Exact;
#################################################################################
#
# Author:  Nat Goodman
# Created: 13-06-19
# $Id:
#
# Copyright 2013 Institute for Systems Biology
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
#
# See http://dev.perl.org/licenses/ for more information.
#
#################################################################################
# a Prefix Matcher is able to store rows (arrays of values) and tell whether a new
#   row is a prefix of one already in the structure
# for special case of paths of length 1. ASSUMES undef values caught earlier
# for this case, can use exact match HAH::MultiValued
#   values are row indexes - code will work for ARRAY of anything
use strict;
use Carp;
use Hash::AutoHash::MultiValued qw(autohash_clear);
use List::MoreUtils qw(uniq);
use vars qw(@AUTO_ATTRIBUTES);
use base qw(Data::Babel::PrefixMatcher);
@AUTO_ATTRIBUTES=qw(matcher);
Class::AutoClass::declare;

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->matcher(new Hash::AutoHash::MultiValued);
}
# reset matcher so it can be used on another group
# clear AutoHash
sub reset {
  my $self=shift;
  autohash_clear($self->matcher);
}
# data is row index
sub put_data {
  my($self,$row,$data)=@_;
  my $matcher=$self->matcher;
  my($key)=@$row;
  # NG 13-09-02: for some reason, method notation fails when method contains apostrophe
  # $matcher->$key($data);	# Hash::AutoHash::MultiValued does the right thing
  $matcher->{$key}=$data;	# Hash::AutoHash::MultiValued does the right thing
}
# returns list of data values (row indexes) associated with row
sub get_data {
  my($self,$row)=@_;
  my $matcher=$self->matcher;
  my($key)=@$row;
  # NG 13-09-02: for some reason, method notation fails when method contains apostrophe
  # my @data=$matcher->$key;
  my $data=$matcher->{$key} || [];
  my @data=uniq @$data;
  wantarray? @data: \@data;
}

1;
