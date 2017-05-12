package Data::Babel::PrefixMatcher::BinarySearchTree;
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
# ASSUMES undef fields come at the end!! this is what makes prefix idea work...
# uses Tree::RB for match engine. balanced binary search tree
#   values are row indexes - code will work for ARRAY of anything
use strict;
use Carp;
use Tree::RB qw(LUEQUAL LUGTEQ);
use List::MoreUtils qw(uniq before);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS);
use base qw(Data::Babel::PrefixMatcher);
@AUTO_ATTRIBUTES=qw(matcher exact_data);
%DEFAULTS=();
Class::AutoClass::declare;

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->matcher(new Tree::RB);
}
# reset matcher so it can be used on another group
# create new Tree::RB
sub reset {
  my $self=shift;
  $self->exact_data(undef);
  $self->matcher(new Tree::RB);
}
# data is row index
sub put_data {
  my($self,$row,$data)=@_;
  my $matcher=$self->matcher;
  my $key=join($;,before {!defined $_} @$row);
  my $old_data=$self->exact_data;
  if (defined $old_data) {
    push(@$old_data,$data);
  } else {
    $matcher->put($key,[$data]);
  }
}
# returns list of data values (row indexes) associated with row
sub get_data {
  my($self,$row)=@_;
  my $matcher=$self->matcher;
  my $key=join($;,before {!defined $_} @$row);
  my @data;
  $self->exact_data(undef);	# assume no match
  my $iter=$matcher->iter($key);
  # TODO: further optimization - 1st match is smallest - only one that can possibly be exact
  while(my $node=$iter->next) {
    my $old_key=$node->key;
    last unless $old_key=~/^$key/;
    my $old_data=$node->val;
    $self->exact_data($old_data) if $key eq $old_key;
    push(@data,@$old_data);
  }
  @data=uniq @data;
  wantarray? @data: \@data;
}

1;
