package Data::Babel::PrefixMatcher::Trie;
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
# uses Tree::Trie for match engine
#   values are row indexes - code will work for ARRAY of anything
use strict;
use Carp;
use Tree::Trie;
use List::MoreUtils qw(uniq before);
use vars qw(@AUTO_ATTRIBUTES);
use base qw(Data::Babel::PrefixMatcher);
@AUTO_ATTRIBUTES=qw(matcher exact_data);
Class::AutoClass::declare;

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->matcher(new Tree::Trie end_marker=>"$;$;",freeze_end_marker=>1,deep_search=>'exact');
}
# reset matcher so it can be used on another group
# create new Trie
sub reset {
  my $self=shift;
  $self->exact_data(undef);
  $self->matcher(new Tree::Trie end_marker=>"$;$;",freeze_end_marker=>1,deep_search=>'exact');
}
# data is row index
sub put_data {
  my($self,$row,$data)=@_;
  my $matcher=$self->matcher;
  my @prefix=before {!defined $_} @$row;
  # if @prefix already in trie, add data to it
  my $old_data=$self->exact_data;
  if (defined $old_data) {
    push(@$old_data,$data);
  } else {
    $matcher->add_data(\@prefix,[$data]);
  }
}
# returns list of data values (row indexes) associated with row
sub get_data {
  my($self,$row)=@_;
  my $matcher=$self->matcher;
  my @prefix=before {!defined $_} @$row;
  my @matches=$matcher->lookup_data(\@prefix); # returns [words] => data pairs
  my @data;
  $self->exact_data(undef);	# assume no match
  # TODO: it is probably guaranteed that exact match comes first
  #       if so, optimize test for exact match
  for (my $i=0; $i<@matches; $i+=2) {
    my $old_prefix=$matches[$i];
    my $old_data=$matches[$i+1];
    $self->exact_data($old_data) if @prefix == @$old_prefix; # same length => equal
    push(@data,@$old_data);
  }
  @data=uniq @data;
  wantarray? @data: \@data;
}

1;
