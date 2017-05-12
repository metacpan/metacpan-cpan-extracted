=head1 NAME

DBIx::SQLEngine::Record::Extras - Provide extra methods

=head1 SYNOPSIS

  package My::Record;
  use DBIx::SQLEngine::Record::Class '-isasubclass', 'Extras';
  
  my $sqldb = DBIx::SQLEngine->new( ... );
  My::Record->table( $sqldb->table( 'foo' ) );


=head1 DESCRIPTION

This package provides a multiply-composable collection of functionality for Record classes. 

Don't use this module directly; instead, pass its name as a trait when you create a new record class. This package provides a multiply-composable collection of functionality for Record classes. It is combined with the base class and other traits by DBIx::SQLEngine::Record::Class. 

=cut

########################################################################

package DBIx::SQLEngine::Record::Extras;

use strict;
use Carp;

########################################################################

=head1 REFERENCE

=cut

########################################################################

sub demand_table { (shift)->get_table() }
sub datasource { (shift)->get_table()->sql_engine() }
sub do_sql     { (shift)->get_table()->sql_engine()->do_sql( @_ ) }

########################################################################

=head2 Selecting Records

=over 4

=item fetch_records

  $recordset = My::Students->fetch_records( criteria => {status=>'active'} );

Fetch all matching records and return them in a RecordSet.

=item fetch_one

  $dave = My::Students->fetch_one( criteria => { name => 'Dave' } );

Fetch a single matching record.

=item fetch_id

  $prisoner = My::Students->fetch_id( 6 );

Fetch a single record based on its primary key.

=item visit_records

  @results = My::Students->visit_records( \&mysub, criteria=> ... );

Calls the provided subroutine on each matching record as it is retrieved. Returns the accumulated results of each subroutine call (in list context).

=item refetch_record

  $record->refetch_record();

Re-retrieve the values for this record from the database based on its primary key. 

=back

=cut

sub new { (shift)->new_with_values( @_ ) }

########################################################################

sub fetch_records { (shift)->fetch_select( @_ ) }
sub visit_records { (shift)->visit_select( @_ ) }
sub fetch_sql     { (shift)->fetch_select( sql => [ @_ ] ) }
sub fetch_id      { (shift)->select_record( @_ ) }

sub fetch {
  (shift)->fetch_select( 
	( ref $_[0] or ! defined $_[0] ) ? (where=>$_[0], order=>$_[1]) 
					: @_ 
  );
}

sub fetch_one {
  my $self = shift;
  my $records = $self->fetch( @_ );
  ( scalar @$records < 2 ) or
      carp "Multiple matches for fetch_one: " . join(', ', map "'$_'", @_ );
  
  $records->[0];
}

sub refetch_record {
  my $self = shift();
  my $db_row = $self->get_table()->select_row( $self )
    or confess;
  %$self = %$db_row;
  $self->post_fetch;
  $self;
}

########################################################################

sub change { (shift)->change_values() }

########################################################################

sub save_row   { (shift)->save_record(@_) }
sub insert_row { (shift)->insert_record( @_ ) }
sub update_row { (shift)->update_record( @_ ) }
sub delete_row { (shift)->delete_record( @_ ) }

########################################################################

1;
