package Data::Babel::PrefixMatcher::BinarySearchList;
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
# uses List::BinarySearch for match engine
#   values are row indexes - code will work for ARRAY of anything
use strict;
use Carp;
# NG 13-09-18: List::BinarySearch v0.12 introduces 'binsearch_pos' function
#              and deprecates 'bsearch_str_pos'. the latter will go away soon.
# use List::BinarySearch qw(bsearch_str_pos);
use List::BinarySearch qw(binsearch_pos);
use List::MoreUtils qw(uniq before);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS);
use base qw(Data::Babel::PrefixMatcher);
@AUTO_ATTRIBUTES=qw(keys values insertion_point);
%DEFAULTS=(keys=>[],values=>[],insertion_point=>0);
Class::AutoClass::declare;

# reset matcher so it can be used on another group
sub reset {
  my $self=shift;
  $self->set(keys=>[],values=>[],insertion_point=>0);
}
# data is row index
sub put_data {
  my($self,$row,$data)=@_;
  my $key=join($;,before {!defined $_} @$row);
  my($keys,$values,$insertion_point)=$self->get(qw(keys values insertion_point)); 
  my $old_key=$keys->[$insertion_point];
  if ($old_key eq $key) {
    push(@{$values->[$insertion_point]},$data);
  } else {
    splice(@$keys,$insertion_point,0,$key);
    splice(@$values,$insertion_point,0,[$data]);
  }
}
# returns list of data values (row indexes) associated with row
sub get_data {
  my($self,$row)=@_;
  my($keys,$values)=$self->get(qw(keys values)); 
  my $key=join($;,before {!defined $_} @$row);
  my $length=@$keys;
  # NG 13-09-18: List::BinarySearch v0.12 introduces 'binsearch_pos' function
  #              and deprecates 'bsearch_str_pos'. the latter will go away soon.
  # my $insertion_point=$self->insertion_point(bsearch_str_pos($key,@$keys));
  # my $insertion_point=
  #   $self->insertion_point
  #     (List::BinarySearch->VERSION<0.12? List::BinarySearch::bsearch_str_pos($key,@$keys):
  #      List::BinarySearch::binsearch_pos {$a cmp $b} $key,@$keys);
  my $insertion_point=$self->insertion_point(binsearch_pos {$a cmp $b} $key,@$keys);
  my @data;
  for (my $i=$insertion_point; $i<$length; $i++) {
    last unless $keys->[$i]=~/^$key/;
    push(@data,@{$values->[$i]});
  }
  @data=uniq @data;
  wantarray? @data: \@data;
}

1;
