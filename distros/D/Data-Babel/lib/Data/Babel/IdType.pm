package Data::Babel::IdType;
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
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS %AUTODB);
use base qw(Data::Babel::Base);

# babel, name, id, autodb, verbose - methods defined in Base
@AUTO_ATTRIBUTES=qw(master maptables referent defdb meta format sql_type internal);
@OTHER_ATTRIBUTES=qw(display_name external tablename history);
@CLASS_ATTRIBUTES=qw();
%SYNONYMS=(perl_format=>'format');
%DEFAULTS=(maptables=>[]);
%AUTODB=
  (-collection=>'IdType',
   -keys=>qq(name string,display_name string,referent string,defdb string,meta string,
             perl_format string,sql_type string,internal string));
   
Class::AutoClass::declare;

# must run after Babel initialized
sub connect_master {
  my $self=shift;
  my $master_name=$self->name.'_master'; # append '_master' to idtype name
  $self->{master}=$self->babel->name2master($master_name)
    or confess 'Trying to connect IdType '.$self->name.' to non-existent Master';
  # NG 13-06-11: propogate history if it exists
  if (exists $self->{history}) {
    $self->master->history($self->{history}) unless $self->master->history;
    delete $self->{history};
  }
}
# must run after Babel initialized
sub add_maptable {
  # my($self,$maptable)=@_;
  push(@{shift->maptables},shift);
}
# degree is number of MapTables containing this IdType
sub degree {scalar @{shift->maptables}}

our $WARN_INTERNAL=": FOR INTERNAL USE ONLY";
sub display_name {
  my $self=shift;
  my $display_name=@_? $self->{_display_name}=shift: $self->{_display_name};
  $self->internal? "$display_name$WARN_INTERNAL": $display_name;
}

# opposite of internal
sub external {
  my $self=shift;
  @_? !$self->internal(!$_[0]): !$self->internal;
}
# tablename - delegates to master
sub tablename {
  my $self=shift;
  defined $self->master && $self->master->tablename(@_);
}
# history - delegate to master
# NG 13-06-11: maintain history here until connected to master
sub history {
  my $self=shift;
  return $self->master->history(@_) if defined $self->master;
  @_? $self->{history}=$_[0]: $self->{history};
}

# NG 10-08-08. sigh.'verbose' in Class::AutoClass::Root conflicts with method in Base
#              because AutoDB splices itself onto front of @ISA.
sub verbose {Data::Babel::Base::verbose(@_)}
1;
