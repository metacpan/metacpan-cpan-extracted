# The contents of this file are Copyright (c) 2010 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

###########################################
package DBR::Query::Delete;

use strict;
use base 'DBR::Query';
use Carp;

sub _params    { qw (tables where limit quiet_error) }
sub _reqparams { qw (tables where) }
sub _validate_self{ 1 } # If I exist, I'm valid

# do not run this until the last possible moment, and then only once
sub sql{
      my $self = shift;

      my $conn   = $self->instance->connect('conn') or return $self->_error('failed to connect');
      my $sql;
      my $tables = join(',', map { $_->sql( $conn ) } @{$self->{tables}} );
      my $sets   = join(',', map { $_->sql( $conn ) } @{$self->{sets}}   );

      $sql = "DELETE FROM $tables";
      $sql .= ' WHERE ' . $self->{where}->sql($conn) if $self->{where};
      $sql .= ' LIMIT ' . $self->{limit}             if $self->{limit};

      $self->_logDebug2( $sql );
      return $sql;
}

sub run{
      my $self = shift;
      my $conn = $self->instance->connect('conn') or return $self->_error('failed to connect');

      $conn->quiet_next_error if $self->quiet_error;

      return $conn->do( $self->sql ) || 0;
}

1;
