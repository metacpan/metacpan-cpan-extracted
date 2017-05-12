package Data::Babel::Master;
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
# inputs, namespace, query, view are for Pipeline. 
#   used here to generate Pipeline Steps for implicit masters
#   will be needed someday for redundant MapTables
@AUTO_ATTRIBUTES=qw(idtype implicit history view inputs namespace query);
@OTHER_ATTRIBUTES=qw(explicit degree);
@CLASS_ATTRIBUTES=qw();
%SYNONYMS=(tablename=>'name');
%AUTODB=
  (-collection=>'Master ',-keys=>qq(name string,implicit int));
Class::AutoClass::declare;

# sub tablename {
#   my $self=shift;
#   my $tablename=@_? $self->{tablename}: $self->{tablename};
#   unless ($tablename) {
#     $tablename=$self->name;
#     $tablename.='_master' unless $tablename=~/_master$/;
#   }
#   $tablename;
# }
# must run after Babel initialized
sub connect_idtype {
  my $self=shift;
  my $idtype_name=$self->name;
  $idtype_name=~s/_master$//;	# strip _master from Master name
  $self->{idtype}=$self->babel->name2idtype($idtype_name)
    or confess 'Trying to define Master for unkown IdType '.$idtype_name;
  # NG 13-06-11: propogate history from idtype if it exists
  if (exists $self->idtype->{history}) {
    $self->history($self->idtype->{history}) unless $self->history;
    delete $self->idtype->{history};
  }
}
# opposite of implicit
sub explicit {
  my $self=shift;
  @_? !$self->implicit(!$_[0]): !$self->implicit;
}
# degree is number of MapTables containing this guy's IdType
# compute degree & maptables from IdType
sub degree {shift->idtype->degree}
sub maptables {shift->idtype->maptables}

# for compatibility with MapTable. so code can call $xxx->idtypes w/o worrying
sub idtypes { [shift->idtype] }

# # only used in collection
# sub has_query {
#   my $self=shift;
#   $self->query? 'yes': 'no';
# }
1;
