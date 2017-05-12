package Data::Babel::PrefixMatcher::PrefixHash;
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
# someday this class may become the base class for different implementations
# for now, the only implementation is HAH::MultiValued whose keys are $;-separated strings
#   searched by grepping prefix pattern
#   values are row indexes - code will work for ARRAY of anything
use strict;
use Carp;
use Hash::AutoHash::MultiValued qw(autohash_clear);
use List::MoreUtils qw(uniq before);
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
  my $key=join($;,before {!defined $_} @$row);
  $matcher->$key($data);	# Hash::AutoHash::MultiValued does the right thing
}
# returns list of data values (row indexes) associated with row
sub get_data {
  my($self,$row)=@_;
  my $matcher=$self->matcher;
  my $key=join($;,before {!defined $_} @$row);
  my @hits=grep /^$key/,keys %$matcher;
  my @data=uniq(flatten(@$matcher{@hits}));
  wantarray? @data: \@data;
}
sub flatten {map {'ARRAY' eq ref $_? @$_: $_} @_;}

1;
