# the contents of this file are Copyright (c) 2004-2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Handle;

use strict;
use base 'DBR::Common';
use DBR::Query;
use DBR::Interface::Object;
use DBR::Interface::DBRv1;
our $AUTOLOAD;

sub new {
      my( $package ) = shift;
      my %params = @_;

      my $self = {
		  conn     => $params{conn},
		  session   => $params{session},
		  instance => $params{instance}
		 };

      bless( $self, $package );

      return $self->_error( 'conn object is required'         ) unless $self->{conn};
      return $self->_error( 'instance parameter is required'  ) unless $self->{instance};

      $self->{schema} = $self->{instance}->schema();
      return $self->_error( 'failed to retrieve schema' ) unless defined($self->{schema}); # schema is not required

      # Temporary solution to interfaces
      $self->{dbrv1} = DBR::Interface::DBRv1->new(
						  session  => $self->{session},
						  instance => $self->{instance},
						 ) or return $self->_error('failed to create DBRv1 interface object');

      return( $self );
}

sub select{ my $self = shift; return $self->{dbrv1}->select(@_) }
sub insert{ my $self = shift; return $self->{dbrv1}->insert(@_) }
sub update{ my $self = shift; return $self->{dbrv1}->update(@_) }
sub delete{ my $self = shift; return $self->{dbrv1}->delete(@_) }

sub AUTOLOAD {
      my $self = shift;
      my $method = $AUTOLOAD;

      my @params = @_;

      $method =~ s/.*:://;
      return unless $method =~ /[^A-Z]/; # skip DESTROY and all-cap methods
      return $self->_error("Cannot autoload '$method' when no schema is defined") unless $self->{schema};

      my $table = $self->{schema}->get_table( $method ) or return $self->_error("no such table '$method' exists in this schema");

      my $object = DBR::Interface::Object->new(
					       session   => $self->{session},
					       instance => $self->{instance},
					       table    => $table,
					      ) or return $self->_error('failed to create query object');

      return $object;
}

sub begin{
      my $self = shift;

      return $self->_error('Already transaction - cannot begin') if $self->{'_intran'};

      my $conn = $self->{conn};

      if ( $conn->b_intrans && !$conn->b_nestedTrans ){ # No nested transactions
	    $self->_logDebug('BEGIN - Fake');
	    $self->{'_faketran'} = $self->{'_intran'} = 1; #already in transaction, we are not doing a real begin
	    return 1;
      }

      $conn->begin or return $self->_error('Failed to begin transaction');

      $self->{'_intran'} = 1;
      return 1;

}
sub commit{
      my $self = shift;
      return $self->_error('Not in transaction - cannot commit') unless $self->{'_intran'};

      my $conn = $self->{conn};

      if($self->{'_faketran'}){
	    $self->_logDebug('COMMIT - Fake');
	    $self->{'_faketran'} = $self->{'_intran'} = 0;

	    return 1;
      }

      $conn->commit or return $self->_error('Failed to commit transaction');

      $self->{'_intran'} = 0;
      return 1;
}

sub rollback{
      my $self = shift;
      return $self->_error('Not in transaction - cannot rollback') unless $self->{'_intran'};

      my $conn = $self->{conn};
      if($self->{'_faketran'}){

	    $self->_logDebug('ROLLBACK - Fake');
	    $self->{'_faketran'} = $self->{'_intran'} = 0;

	    return 1;
      }

      $conn->rollback or return $self->_error('Failed to roll back transaction');

      $self->{'_intran'} = 0;
      return 1;
}

sub getserial{
      my $self = shift;
      my $name = shift;
      my $table = shift  || 'serials';
      my $field1 = shift || 'name';
      my $field2 = shift || 'serial';
      return $self->_error('name must be specified') unless $name;

      $self->begin();

      my $row = $self->select(
			      -table => $table,
			      -field => $field2,
			      -where => {$field1 => $name},
			      -single => 1,
			      -lock => 'update',
			     );

      return $self->_error('serial select failed') unless defined($row);
      return $self->_error('serial is not primed') unless $row;

      my $id = $row->{$field2};

      return $self->_error('serial update failed') unless 
	$self->update(
		      -table => $table,
		      -fields => {$field2 => ['d',$id + 1]},
		      -where => {
				 $field1 => $name
				},
		     );

      $self->commit();

      return $id;
}

sub disconnect { 1 } # Dummy

sub DESTROY{
    my $self = shift;

    $self->rollback() if $self->{'_intran'};

}


=pod

=head1 NAME

DBR::Handle

=head1 SYNOPSIS

Represents a connection to a specific instance of a DBR schema
 
 use DBR ( conf => '/path/to/my/DBR.conf' ); 
 my $handle   = dbr_connect('music');

 $handle->begin;
 
 my $resultset = $handle->mytable->where( myfield => 'somevalue' );
 my $record = $resultset->next;
 print $record->myfield;
 $record->myfield('somenewvalue');
 
 $handle->commit;

Note: Do not pass DBR handles around, especially if you are using transactions. Auto rollback is associated with the handle going out of scope.

=head1 METHODS

=head2 begin

Begin a transaction;

 $handle->begin();

=head2 commit

Commit a transaction

 $handle->commit();

=head2 rollback

Roll back an open transaction

 $handle->rollback();
 
NOTE: any open transactions are automatically rolled back when the handle goes out of scope

=head2 AUTOLOAD

The handle object is aware of all tables in the associated DB schema,
therefore all tables are available as virtual methods of a given handle.

This is the primary way of gettig a table object.

Some examples:
 
 # Deconstructed example:
 
 my $mytable = $handle->mytable;
 my $resultsetAll  = $mytable->all;
 my $resultsetSome = $mytable->where( somefield => 'whatever' );

 # More normal example:
 
 my $resultsetSome = $handle->mytable->where( somefield => 'whatever' );
 where ( my $record = $resultsetSome->next ){
      print $record->somefield . "\n";
 }

=cut



1;
