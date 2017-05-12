package Data::Babel::PrefixMatcher;
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
#   values are row indexes - code will work for ARRAY of anything
# 
# this is base class for implementations
use strict;
use Carp;
use vars qw(@AUTO_ATTRIBUTES);
use base qw(Class::AutoClass);
@AUTO_ATTRIBUTES=qw();
Class::AutoClass::declare;

# reset matcher so it can be used on another group
sub reset {
  my $self=shift;
  confess "reset method called on base class. should call on subclass";
}
# data is row index
sub put_data {
  my($self,$row,$data)=@_;
  confess "put_data method called on base class. should call on subclass";
}
# returns list of data values (row indexes) associated with row (exact or prefix)
sub get_data {
  my($self,$row)=@_;
  confess "get_data method called on base class. should call on subclass";
  my @data;
  wantarray? @data: \@data;
}

1;
