# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

###########################################
package DBR::Query::Part::Subquery;
use strict;
use base 'DBR::Query::Part';
use Carp;

sub new{
      my( $package ) = shift;
      my ($field,$query,$runflag) = @_;

      croak('first argument must be a Field object') unless ref($field) =~ /^DBR::Config::Field/; # Could be ::Anon
      croak('second argument must be a Select object') unless ref($query) eq 'DBR::Query::Select';

      my $sqfield = $query->fields->[0];
      my $self = [ $field, $query, $runflag, ! $sqfield->is_numeric ];

      bless( $self, $package );
      return $self;
}

sub type { return 'SUBQUERY' };
sub field   { return $_[0]->[0] }
sub query   { return $_[0]->[1] }
sub runflag { return $_[0]->[2] }
sub quoted  { return $_[0]->[3] }

sub sql   {
      my $self = shift;
      my $conn = shift or croak 'conn is required';

      if ( $self->runflag ){
	    my $sth = $self->query->run();
	    $sth->execute;

	    my ($val,@list);

	    $sth->bind_col(1, \$val) || die "Failed to bind column";
	    push @list, $val while $sth->fetch;

	    $sth->finish;

        return '0' unless @list; # HACK - this should abort the query this feeds into, but this will patch the bug for now
        
	    if( $self->quoted ){
		  return $self->field->sql($_[1]) . ' IN (' . join(',', map { $conn->quote( $_ ) } @list ) . ')';
	    }else{
		  return $self->field->sql($_[1]) . ' IN (' . join(',', @list ) . ')';
	    }
      }else{
	    return $self->field->sql($_[1]) . ' IN (' . $self->query->sql($_[1]) . ')'
      }
}

sub _validate_self{ 1 }

sub is_emptyset { $_[0]->query->where->is_emptyset }
1;

###########################################


1;
