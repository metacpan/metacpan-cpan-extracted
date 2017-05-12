# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Config::Table::Anon;

use strict;
use base 'DBR::Config::Table::Common';

sub get_field     { undef }
sub fields        { [] }
sub req_fields    { [] }
sub primary_key   { undef }

sub get_relation  { undef }
sub relations     { [] }
sub conf_instance { undef }

sub new{
      my( $package ) = shift;
      my %params = @_;

      my $self = {
		  session =>  $params{session}
		 };

      bless( $self, $package );

      my $name  = $params{name} or return $self->_error('name is required');
      my $alias = $params{alias};

      return $self->_error("invalid name '$name'") unless $name =~ /^[A-Z][A-Z0-9_-]*$/i;

      if(defined($alias)){
	    return $self->_error("invalid alias '$alias'") unless $alias =~ /^[A-Z][A-Z0-9_-]*$/i;
      }

      $self->{name}  = $name;
      $self->{alias} = $alias || '';

      return $self;
}

sub name { $_[0]->{name} }

1;

1;
