# the contents of this file are Copyright (c) 2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Interface::Object;

use strict;
use base 'DBR::Common';
use DBR::Config::Scope;
use DBR::ResultSet::Empty;
use DBR::Query::Select;
use DBR::Query::Insert;
use DBR::Interface::Where;
use DBR::ResultSet;
use Carp;

use constant ({
	       EMPTY => bless( [], 'DBR::ResultSet::Empty'),
	       DUMMY => bless( [], 'DBR::Misc::Dummy'),
	      });

sub new {
      my( $package ) = shift;
      my %params = @_;
      my $self = {
		  session => $params{session},
		  instance   => $params{instance},
		  table  => $params{table},
		 };

      bless( $self, $package );

      return $self->_error('table object must be specified') unless ref($self->{table}) eq 'DBR::Config::Table';
      return $self->_error('instance object must be specified')   unless $self->{instance};

      return( $self );
}

sub all{
      my $self = shift;

      my $table = $self->{table};
      my $scope = DBR::Config::Scope->new(
					  session        => $self->{session},
					  conf_instance => $table->conf_instance,
					  extra_ident   => $table->name,
					 ) or return $self->_error('Failed to get calling scope');

      my $pk = $table->primary_key or return $self->_error('Failed to fetch primary key');
      my $prefields = $scope->fields or return $self->_error('Failed to determine fields to retrieve');

      my %uniq;
      my @fields = grep { !$uniq{ $_->field_id }++ } (@$pk, @$prefields);

      my $query = DBR::Query::Select->new(
					  session  => $self->{session},
					  instance => $self->{instance},
					  scope    => $scope,
					  fields   => \@fields,
					  tables   => $table,
					 ) or return $self->_error('failed to create Query object');

      my $resultset = DBR::ResultSet->new( $query );

      return $resultset;
}

sub where{
      my $self = shift;
      my @inwhere = @_;

      my $table = $self->{table};
      my $scope = DBR::Config::Scope->new(
					  session        => $self->{session},
					  conf_instance => $table->conf_instance,
					  extra_ident   => $table->name,
					 ) or return $self->_error('Failed to get calling scope');



      my $pk = $table->primary_key or return $self->_error('Failed to fetch primary key');
      my $prefields = $scope->fields or return $self->_error('Failed to determine fields to retrieve');

      my %uniq;
      my @fields = grep { !$uniq{ $_->field_id }++ } (@$pk, @$prefields);


      my $builder = DBR::Interface::Where->new(
					       session       => $self->{session},
					       instance      => $self->{instance},
					       primary_table => $table,
					      ) or return $self->_error("Failed to generate where for ${\$table->name}");

      my $where = $builder->build( \@inwhere );

      return EMPTY if $where->is_emptyset;

      my $alias = $table->alias;
      if($alias){
	    map { $_->table_alias($alias) } @fields;
      }

      my $query = DBR::Query::Select->new(
					  session  => $self->{session},
					  instance => $self->{instance},
					  scope    => $scope,
					  fields   => \@fields ,
					  tables   => $builder->tables,
					  where    => $where,
					  builder  => $builder,
					 ) or croak('failed to create Query object');

      my $resultset = DBR::ResultSet->new( $query );

      return $resultset;
}


sub insert {
      my $self = shift;
      my %fields = @_;

      my $table = $self->{table};
      my @sets;

      foreach my $fieldname (keys %fields){

 	    my $field = $table->get_field( $fieldname ) or croak "invalid field $fieldname";
 	    my $value = $field->makevalue( $fields{ $fieldname } ) or croak "failed to build value object for $fieldname";

	    my $set = DBR::Query::Part::Set->new($field,$value) or confess 'failed to create set object';
	    push @sets, $set;
      }

      my $query = DBR::Query::Insert->new(
					  instance => $self->{instance},
					  session  => $self->{session},
					  sets     => \@sets,
					  tables   => $table,
					 ) or confess 'failed to create query object';

      return $query->run( void => !defined(wantarray) );
}


#Fetch by Primary key
sub get{
      my $self = shift;
      my $pkval = shift;
      croak('get only accepts one argument. Use an arrayref to specify multiple pkeys.') if shift;

      my $table = $self->{table};
      my $pk = $table->primary_key or return $self->_error('Failed to fetch primary key');
      scalar(@$pk) == 1 or return $self->_error('the get method can only be used with a single field pkey');
      my $field = $pk->[0];

      my $scope = DBR::Config::Scope->new(
					  session        => $self->{session},
					  conf_instance => $table->conf_instance,
					  extra_ident   => $table->name,
					 ) or return $self->_error('Failed to get calling scope');

      my $prefields = $scope->fields or return $self->_error('Failed to determine fields to retrieve');

      my %uniq;
      my @fields = grep { !$uniq{ $_->field_id }++ } (@$pk, @$prefields);

      my $value = $field->makevalue( $pkval ) or return $self->_error("failed to build value object for ${\$field->name}");

      return ref($pkval) ? EMPTY : DUMMY if $value->is_emptyset;

      my $outwhere = DBR::Query::Part::Compare->new( field => $field, value => $value ) or return $self->_error('failed to create compare object');

      my $query = DBR::Query::Select->new(
					  session => $self->{session},
					  instance => $self->{instance},
					  fields => \@fields,
					  tables => $table,
					  where  => $outwhere,
					  scope  => $scope,
					 ) or return $self->_error('failed to create Query object');

      my $resultset = DBR::ResultSet->new( $query );

      if(ref($pkval)){
	    return $resultset;
      }else{
	    return $resultset->next;
      }
}

sub enum{
      my $self = shift;
      my $fieldname = shift;

      my $table = $self->{table};
      my $field = $table->get_field( $fieldname ) or return $self->_error("invalid field $fieldname");

      my $trans = $field->translator or return $self->_error("Field '$fieldname' has no translator");
      $trans->module eq 'Enum' or return $self->_error("Field '$fieldname' is not an enum");

      my $opts = $trans->options or return $self->_error('Failed to get opts');

      return wantarray?@{$opts}:$opts;
}


sub parse{
      my ($self, $fieldname, $value) = @_;

      my $field = $self->{table}->get_field( $fieldname ) or croak "Invalid field $fieldname";
      my $trans = $field->translator;

      if($trans){
	    my $obj = $trans->parse( $value );
	    defined($obj) || return $self->_error("Invalid value " .
						  ( defined($value) ? "'$value'" : '(undef)' ) .
						  " for " . $field->name );
	    return $obj;
      }else{
	    $field->testsub->($value) || return $self->_error("Invalid value " .
							      ( defined($value) ? "'$value'" : '(undef)' ) .
							      " for " . $field->name );
	    return $value;
      }
}

1;

__END__

=pod

=head1 NAME

DBR::Interface::Object
An object representing a table about to be queried. This object is the entry point for executing queries against a given table

=head1 SYNOPSIS

 $dbrh->tableA->all();
 $dbrh->tableA->get( $primary_key );
 $dbrh->tableA->where( field => 'value' );
 $dbrh->tableA->where( 'relationshipB.field' => 'value' );

=head1 Methods


=head2 B<new>

Constructor for DBR::Interface::Object - 
Called by DBR::Handle->tablename (autoloaded)

=head2 B<where>

Initiates a database query based on provided constraints.

Arguments: Key value pairs of relationships/fields and values.

Returns: DBR::Query::ResultSet object containing resultant query

 # Simple use case:
 $dbrh->tableA->where( fieldname => $somevalue );

 # Constrain by related data:
 $dbrh->tableA->where( 'relationshipB.fieldX' => $somevalue );

 # Constrain by more related data:
 $dbrh->tableA->where(
                      'relB.fieldX' => 'value',
                      'relB.fieldY' => $somevalue, # same relationship twice, different fields - do the right thing
                      'relC.relD.relE.fieldZ' => $far_removed_value, # ...ad infinitum
                     );


By default, equality comparisons are assumed. ( field = 'value')
For other types of comparisons:

 use DBR::Util::Operator; # Imports operators into your scope
 $dbrh->tableA->where( fieldname => NOT 'value' );
 $dbrh->tableA->where( fieldname => GT 123 );
 $dbrh->tableA->where( fieldname => LT 123 );
 $dbrh->tableA->where( fieldname => LIKE 'value%' );
 # And so on

For more details, See: L<DBR::Util::Operator>



=head2 B<get>

Initiates a database queryFetch all rows from a given table.

Arguments: single scalar value, or one arrayref of primary key ids.

 my $single_record = $dbrh->tablename->get( 123 ); # pkey 123
 my $resultset_obj = $dbrh->tablename->get( [ 123, 456 ] );

If given arrayref, Returns a single L<DBR::Query::ResultSet> object containing resultant query

If given single value, Returns a single L<DBR::Query::Record> object  (dynamically created)


=head2 B<all>

Initiates a database query with NO constraints. Fetch all rows from a given table.

Arguments: None

Returns: L<DBR::Query::ResultSet> object containing resultant query

=head2 B<insert>

=head2 B<enum>

=head2 B<parse>

=cut
