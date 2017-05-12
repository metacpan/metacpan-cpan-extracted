# The contents of this file are Copyright (c) 2010 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

###########################################
package DBR::Query::Insert;

use strict;
use base 'DBR::Query';
use Carp;

sub _params    { qw (sets tables where limit quiet_error) }
sub _reqparams { qw (sets tables) }

sub sets{
      my $self = shift;
      exists( $_[0] )  or return wantarray?( @$self->{sets} ) : $self->{sets} || undef;
      my @sets = $self->_arrayify(@_);
      scalar(@sets) || croak('must provide at least one set');

      for (@sets){
	    ref($_) eq 'DBR::Query::Part::Set' || croak('arguments must be Sets');
      }
      
      $self->{sets} = \@sets;
      
      $self->_check_fields;

      return 1;
}

sub _check_fields{
      my $self = shift;

      # Make sure we have sets for all required fields
      # It may be slightly more efficient to enforce this in ::Interface::Object->insert, but it seems more correct here.

      return 0 unless $self->{sets} && $self->{tables};

      my %fids = map { $_->field->field_id => 1 } grep { defined $_->field->field_id } @{ $self->{sets} };
      
      my $reqfields = $self->primary_table->req_fields();
      my @missing;
      foreach my $field ( grep { !$fids{ $_->field_id } } @$reqfields ){
            if ( defined ( my $v = $field->default_val ) ){
                  my $value = $field->makevalue( $v ) or croak "failed to build value object for " . $field->name;
                  my $set = DBR::Query::Part::Set->new($field,$value) or confess 'failed to create set object';
                  push @{ $self->{sets} }, $set;
            }else{
                  push @missing, $field;
            }
      
      }
      if(@missing){
	    croak "Invalid insert. Missing fields (" .
	    join(', ', map { $_->name } @missing) . ")";
      }
      $self->{_fields_checked} = 1;
}

sub _validate_self{
      my $self = shift;

      @{$self->{tables}} == 1 or croak "Must have exactly one table";
      $self->{sets} or croak "Must have at least one set";
      
      $self->_check_fields unless $self->{_fields_checked};
      
      return 1;
}

sub sql{
      my $self = shift;

      my $conn   = $self->instance->connect('conn') or return $self->_error('failed to connect');
      my $sql;
      my $tables = join(',', map {$_->sql} @{$self->{tables}} );

      my @fields;
      my @values;
      for ( @{$self->{sets}} ) {
	    push @fields, $_->field->sql( $conn );
	    push @values, $_->value->sql( $conn );
      }

      $sql = "INSERT INTO $tables (" . join (', ', @fields) . ') values (' . join (', ', @values) . ')';

      $sql .= ' WHERE ' . $self->{where}->sql( $conn ) if $self->{where};
      $sql .= ' FOR UPDATE'                            if $self->{lock};
      $sql .= ' LIMIT ' . $self->{limit}               if $self->{limit};

      $self->_logDebug2( $sql );
      return $sql;
}

sub run{
      my $self = shift;
      my %params = @_;

      my $conn = $self->instance->connect('conn') or return $self->_error('failed to connect');

      $conn->quiet_next_error if $self->quiet_error;
      $conn->prepSequence() or confess 'Failed to prepare sequence';

      my $rows = $conn->do( $self->sql ) or return $self->_error("Insert failed");

      # Tiny optimization: if we are being executed in a void context, then we
      # don't care about the sequence value. save the round trip and reduce latency.
      return 1 if $params{void};

      my ($sequenceval) = $conn->getSequenceValue();

      return $sequenceval;

}

1;
