package Data::Babel::MapTable;
#################################################################################
#
# Author:  Nat Goodman
# Created: 10-07-26
# $Id: 
#
# Copyright 2010 Institute for Systems Biology
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
#
# See http://dev.perl.org/licenses/ for more information.
#
#################################################################################
use strict;
use Carp;
use Class::AutoClass;
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %AUTODB);
use base qw(Data::Babel::Base);

# babel, name, id, autodb, verbose - methods defined in Base
# inputs, namespace, query are for Pipeline. 
#   used here to generate Pipeline Steps for implicit masters
#   will be needed someday for redundant MapTables
@AUTO_ATTRIBUTES=qw(idtypes inputs namespace query);
@OTHER_ATTRIBUTES=qw();
@CLASS_ATTRIBUTES=qw();
%SYNONYMS=(tablename=>'name');
%AUTODB=
  (-collection=>'MapTable ',-keys=>qq(name string,idtype_names string));
Class::AutoClass::declare;

# sub tablename {
#   my $self=shift;
#   @_? $self->{tablename}=$_[0]: $self->name;
# }
# in config file, idtypes is space-separated list of names
# in object, idtypes is ARRAY of IdType objects
sub connect_idtypes {
  my $self=shift;
  my $babel=$self->babel;
  my $idtypes=$self->idtypes;
  # split $idtypes if string
  my @idtypes=ref $idtypes? @$idtypes: split(/\s+/,$idtypes);
  # convert any strings in @idtypes to IdType objects
  @idtypes=
    map {ref $_? $_: 
	   $babel->name2idtype($_) 
	     or confess "MapTable ".$self->name." contains unkown IdType $_"} @idtypes;
  $self->idtypes(\@idtypes);
#   return if ref $idtypes;	# already done
#   $self->idtypes
#     ([map {$babel->name2idtype($_) 
# 	     or confess "MapTable ".$self->name." contains unkown IdType $_"}
#       split(/\s+/,$idtypes)]);
}
# NG 13-06-11: check for unkown IdTypes before connecting to MapTables
sub unknown_idtypes {
  my $self=shift;
  my $babel=$self->babel;
  my $idtypes=$self->idtypes;
  # split $idtypes if string
  my @idtypes=ref $idtypes? @$idtypes: split(/\s+/,$idtypes);
  # only have to check IdTypes that are passed as strings
  grep {!ref $_ && !$babel->name2idtype($_)} @idtypes;
}
# only used in collection
sub idtype_names {
  my $self=shift;
  join(', ',map {$_->name} @{$self->idtypes});
}
# # only used in collection
# sub has_query {
#   my $self=shift;
#   $self->query? 'yes': 'no';
# }

# NG 10-08-08. sigh.'verbose' in Class::AutoClass::Root conflicts with method in Base
#              because AutoDB splices itself onto front of @ISA.
sub verbose {Data::Babel::Base::verbose(@_)}
1;
