package DBR::Interface::Where;

use strict;
use Carp;
use DBR::Query::Part;
use Clone;
use Digest::MD5 qw(md5_base64);
use DBR::Misc::General;

sub new {
      my( $package ) = shift;
      my %params = @_;

      my $self = {};

      $self->{session}  = $params{session}       or croak "session is required";
      $self->{instance} = $params{instance}      or croak "instance is required";
      $self->{table}    = $params{primary_table} or croak "primary_table is required";

      croak('primary_table object must be specified') unless ref($self->{table}) eq 'DBR::Config::Table';

      bless( $self, $package );

      $self->{tables} = [$self->{table}];
      $self->{aliascount} = 0;

      return( $self );
}

sub tables { shift->{tables} }

sub _andify{ 
      my $self = shift;
      return $_[0] if (@_ == 1);
      return DBR::Query::Part::And->new( @_ );
}

# fast way to discern the difference between one where clause
# and another without actually doing the work of assembling everything
sub digest{
      my $self = shift;
      md5_base64( join ( "\0|", map {_expandstr($_)} @{ shift() } ) );
}
sub digest_clear{
      my $self = shift;
      join ( "\0|", map {_expandstr($_)} @{ shift() } );
}
sub build{
      my $self = shift;
      my @input = @{shift()}; # Make a shallow copy
      scalar (@input) || croak "input is required";

      my $pendgroup = { table => $self->{table} }; # prime the pump.

      my @andparts = (); # Storage for finished query part objects
      my $pendct;
      while (@input){ # Iterate over key/value pairs
	    my $next    = shift @input;
	    if(ref($next) eq 'DBR::_LOP'){ # Logical OPerator
		  my $op = $next->operator;
		  scalar(@andparts) || $pendct || croak('Cannot use an operator without a preceeding comparison');

		  if ($op eq 'And'){
			if( $next->only_contains_and ){
			      # This is an optomisation to prevent unnecessary recusion,
			      # and to avoid duplication of subqueries when possible.
			      # Because: A and ( B and C ) is equivelant to A and B and C...
			      # We are able to collapse the contents of the AND into the current context,
			      # provided the sequence is maintained. Thus unshift, not push
			      unshift @input, @{$next->value};
			}else{
			      # We have to recurse to handle this situation properly
			      # A AND (B OR C) is not equivelant to A AND B OR C
			      push @andparts,  $self->build( $next->value );
			}
		  } elsif ( $op eq 'Or' ){
			if($pendct){
			      push @andparts, $self->_reljoin( $pendgroup ); # Everything before me (pending)...
			}
			my $A = $self->_andify( @andparts );
			my $B = $self->build( $next->value );         # Compared to everything inside

			@andparts = ( DBR::Query::Part::Or->new( $A, $B ) ); # Russian dolls... Get in mahh belly

			$pendgroup = { table => $self->{table} };      # Reset
			$pendct = 0;                                   # Reset
		  }else{
			confess "Sanity error. Invalid operator."
		  }

		  next;
	    }

	    my $rawval = shift @input;
	    $pendct++;
 	    $self->_process_comparison($next, $rawval, $pendgroup); # add it to the hopper

      }

      scalar(@input) and croak('Odd number of arguments in where parameters'); # I hate leftovers

      push @andparts, $self->_reljoin( $pendgroup );

      return wantarray?(@andparts):$self->_andify(@andparts); # don't wrap it in an and if we want an array
}


# Process ONE comparison.
# Walk the relation.relation.relation.field chain and set up the heirarchical hash structure for reljoin.
sub _process_comparison{
      my $self = shift;

      my $key = shift;
      my $rawval = shift;
      my $ref = shift;

      $key =~ /^\s+|\s+$/g; # trim junk
      my @parts = split(/\s*\.\s*/,$key); # Break down each key into parts

      my $tablect;

      my $cur_table = $self->{table}; # Start

      while ( my $part = shift @parts ){
	    my $last = (scalar(@parts) == 0)?1:0;

		  if($last){ # The last part should always be a field
			croak ('Duplicate field ' .$part ) if $ref->{fields}->{$part};

			my $field = $cur_table->get_field( $part ) or croak("invalid field $part");
			my $value = $field->makevalue( $rawval )   or croak("failed to build value object for $part");

			my $out = DBR::Query::Part::Compare->new( field => $field, value => $value ) or confess('failed to create compare object');
			my $conn = $self->{instance}->connect;

			$ref->{fields}->{$part} = $out;

		  }else{
			#test for relation?
			$ref = $ref->{kids}->{$part} ||= {}; # step deeper into the tree

			if( $ref->{been_here} ){ # Dejavu - merge any common paths together

			      $cur_table = $ref->{table};  # next!

			}else{

			      my $relation = $cur_table->get_relation($part) or croak("invalid relationship $part");
			      my $maptable = $relation->maptable             or confess("failed to get maptable");

			      # Any to_one relationship results in a join. we'll need some table aliases for later.
			      # Do them now so everything is in sync. I originally assigned the alias in _reljoin,
			      # but it didn't always alias the fields that needed to be aliased due to the order of execution.
			      if( $relation->is_same_schema && $relation->is_to_one ){
				    croak ('No more than 25 tables allowed in a join') if $self->{aliascount} > 24;

				    $cur_table ->alias() || $cur_table ->alias( chr(97 + $self->{aliascount}++)  ); # might be doing this one again
				    $maptable  ->alias( chr(97 + $self->{aliascount}++)  );
			      }

			      $ref->{relation}  = $relation;
			      $ref->{prevtable} = $cur_table;
			      $ref->{table}     = $maptable;
			      $ref->{been_here} = 1;

			      $cur_table = $maptable; # next!
			}
		  }

	    };
}
sub _reljoin{
      my $self = shift;
      my $ref  = shift;
      my $tables = shift || $self->{tables}; # Allow override of table list for subqueries

      confess ('ref must be hash') unless ref($ref) eq 'HASH';

      my @and;

      if($ref->{kids}){
	    foreach my $key (sort keys %{$ref->{kids}}){ # sort for consistent sql ordering
		  my $kid = $ref->{kids}->{ $key };
		  my $relation = $kid->{relation};

		  # it's important we use the same table objects to preserve aliases

		  my $table     = $kid->{table}      or confess("failed to get table");
		  my $prevtable = $kid->{prevtable}  or confess("failed to get prev_table");

		  my $field     = $relation->mapfield or confess('Failed to fetch field');
		  my $prevfield = $relation->field    or confess('Failed to fetch prevfield');

		  my $prevalias = $prevtable ->alias();
		  my $alias     = $table     ->alias();

		  $prevfield ->table_alias( $prevalias ) if $prevalias;
		  $field     ->table_alias( $alias     ) if $alias;

		  if ($relation->is_same_schema && $relation->is_to_one) { # Do a join

			$prevalias or die('Sanity error: prevtable alias is required');
			$alias     or die('Sanity error: table alias is required');

			push @$tables, $table;

			my $where = $self->_reljoin( $kid, $tables ) or confess('_reljoin failed');
			push @and, $where;

			my $join = DBR::Query::Part::Join->new($field,$prevfield) or confess('failed to create join object');
			push @and, $join;

		  }else{ # if it's a to_many relationship ( or cross schema ), then subqery
			my @tables = $table;
			my $where = $self->_reljoin( $kid, \@tables ) or confess('_reljoin failed');

			my $instance = $self->{instance};
			unless ( $relation->is_same_schema ){
			      $instance = $table->schema->get_instance( $instance->class ) or return $self->_error('Failed to retrieve db instance for subquery table');
			}

 			my $query = DBR::Query::Select->new(
							    instance => $instance,
							    session  => $self->{session},
							    fields => [$field],
							    tables   => \@tables,
							    where    => $where,
							   ) or confess('failed to create query object');

			my $runflag = ! $relation->is_same_schema;
 			my $subquery = DBR::Query::Part::Subquery->new($prevfield, $query, $runflag) or confess ('failed to create subquery object');
			push @and, $subquery;
		  }

	    }
      }

      # It's important that fields are evaluated after all relationships are processed for this node
      if($ref->{fields}){
	    my $alias = $ref->{table}->alias;

	    foreach my $key (sort keys %{$ref->{fields}}){
		  my $compare = $ref->{fields}->{ $key };
		  $compare->field->table_alias( $alias ) if $alias;
		  push @and, $compare;
	    }
      }

      return wantarray?(@and):$self->_andify(@and); # don't wrap it in an and if we want an array
}

1;
