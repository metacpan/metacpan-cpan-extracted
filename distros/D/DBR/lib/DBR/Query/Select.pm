# The contents of this file are Copyright (c) 2010 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

###########################################
package DBR::Query::Select;

use strict;
use base 'DBR::Query';
use Carp;
use DBR::Record::Maker;

sub _params    { qw (fields tables where builder limit lock quiet_error) }
sub _reqparams { qw (fields tables) }
sub _validate_self{ 1 } # If I exist, I'm valid

sub fields{
      my $self = shift;
      exists( $_[0] ) or return wantarray?( @{$self->{fields}||[]} ) : $self->{fields} || undef;

      my @fields = $self->_arrayify(@_);
      scalar(@fields) || croak('must provide at least one field');

      my $lastidx = -1;
      for (@fields){
	    ref($_) =~ /^DBR::Config::Field/ || croak('must specify field as a DBR::Config::Field object'); # Could also be ::Anon
	    $_->index( ++$lastidx );
      }
      $self->{last_idx} = $lastidx;
      $self->{fields}   = \@fields;

      return 1;
}


sub sql{
      my $self = shift;
      my $conn   = $self->instance->connect('conn') or return $self->_error('failed to connect');
      my $sql;

      my $tables = join(',', map { $_->sql( $conn ) } @{$self->{tables}} );
      my $fields = join(',', map { $_->sql( $conn ) } @{$self->{fields}} );

      $sql = "SELECT $fields FROM $tables";
      $sql .= ' WHERE ' . $self->{where}->sql($conn) if $self->{where};
      $sql .= ' FOR UPDATE'                          if $self->{lock};
      $sql .= ' LIMIT ' . $self->{limit}             if $self->{limit};

      $self->_logDebug2( $sql );
      return $sql;
}

sub lastidx  { $_[0]{last_idx} }
sub can_be_subquery { scalar( @{ $_[0]->fields || [] } ) == 1 }; # Must have exactly one field

sub run {
      my $self = shift;
      return $self->{sth} ||= $self->instance->getconn->prepare( $self->sql ) || confess "Failed to prepare"; # only run once
}
sub reset {
      my $self = shift;
      return $self->{sth} && $self->{sth}->finish;
}

# HERE - it's a little funky that we are handling split queries here,
# but non-split queries in ResultSet. Not horrible... just funky.
sub fetch_segment{
      my $self = shift;
      my $value = shift;

      return ( $self->{spvals} ||= $self->_do_split )->{ $value } || [];
}

sub _do_split{
      my $self = shift;

      # Should have a splitfield if we're getting here. Don't check for it. speeed.
      defined( my $idx = $self->{splitfield}->index ) or croak 'field object must provide an index';

      my $sth = $self->run;

      defined( $sth->execute ) or croak 'failed to execute statement (' . $sth->errstr. ')';

      my $row;
      my $code = 'while($row = $sth->fetch){ push @{$groupby{ $row->[' . $idx . '] }}, [@$row] }';
      $self->_logDebug3($code);

      my %groupby;
      eval $code;
      $@ && confess $@;

      $sth->finish;
      return \%groupby;
}


sub get_record_obj{
      my $self = shift;

      # Only make the record-maker object once per query. Even split queries should be able to share the same one.
      return $self->{recordobj} ||= DBR::Record::Maker->new(
							    session  => $self->{session},
							    query    => $self,  # This value is not preserved by the record maker, thus no memory leak
							   ) or confess ('failed to create record class');
}

sub DESTROY{
      my $self = shift;

      # Can't finish the sth when going out of scope, it might live longer than this object.

      return 1;
}
1;
