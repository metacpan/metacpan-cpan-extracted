=head1 NAME

DBIx::SQLEngine::Driver::NullP - Extends SQLEngine for Simple Testing

=head1 SYNOPSIS

B<DBI Wrapper>: Adds methods to a DBI database handle.

  my $sqldb = DBIx::SQLEngine->new( 'dbi:NullP:' );
  
B<Testing Subclass:> To allow basic framework testing.
  
  $sqldb->next_result(
    rowcount => 1,
    hashref => [ { id => 201, name => "Dave Jones" } ],
  );
  
  my $rows = $sqldb->fetch_select( 
    table => 'students' 
  );
  
  ok( $sqldb->last_query, 'select * from students' );
  ok( scalar @$rows == $sqldb->last_result->{rowcount} );


=head1 DESCRIPTION

This package provides a subclass of DBIx::SQLEngine which works with the DBI's DBD::NullP to provide a simple testing capability. See the "t/null.t" test script for a usage example.

Queries using the NullP driver and subclass keep track of the SQL statements that are executed against them, allowing a simple way of checking whether the SQL generation code is working as expected. You can also provide raw results to be returned by the next query, in order to confirm that other aspects of the result processing are operational.

=cut

########################################################################

package DBIx::SQLEngine::Driver::NullP;

use strict;
use Carp;

########################################################################

=head1 TESTING INTERFACE

To simulate normal driver operation, before executing your query, load the results you would expect to receive using next_result, and afterwards confirm that the SQL statement and parameters used matched what you expected.

=over 4

=item next_result()

  $sqldb->next_result( 
    rowcount => $number, 
    hashref => $array_of_hashes, 
    arrayref => $array_of_arrays, 
    columns => $array_of_hashes,
  )

Sets up the values that will be returned by the next query. 

=item last_query()

  $sqldb->last_query() : $statement_and_params

Returns the most recent query and parameters captured by prepare_execute(). Parameters are joined by "/" characters. 

=item last_result()

  $sqldb->last_result() : $result_hash_ref

Returns the values set with next_result() and used by the most recent query.

=back

=cut

sub next_result {
  my ( $self, %results ) = @_;
  $results{rowcount} ||= ( $results{hashref}  ? scalar @{ $results{hashref} }  :
			   $results{arrayref} ? scalar @{ $results{arrayref} } :
						0 );
  $self->{_next_result} = \%results;
}

sub last_result {
  my ( $self ) = @_;
  $self->{_last_result};
}

sub last_query {
  my $self = shift;
  join('/', $self->{_last_sth_statement}, @{ $self->{_last_sth_params} } )
}

########################################################################

=head1 INTERNAL STATEMENT METHODS (DBI STH)

=head2 Statement Handle Lifecycle 

=over 4

=item prepare_execute()

  $sqldb->prepare_execute ($sql, @params) : $sth

Captures the statement and parameters that would otherwise have been sent to the Null driver to be used for later reporting by last_query().

=item done_with_query()

  $sqldb->done_with_query ($sth) : ()

Clears the values stored by next_result.

=back

=cut

# $sth = $self->prepare_execute($sql);
# $sth = $self->prepare_execute($sql, @params);
sub prepare_execute {
  my ($self, $sql, @params) = @_;
  
  my $sth;
  $sth = $self->prepare_cached($sql);
  $self->{_last_sth_params} = [];
  for my $param_no ( 0 .. $#params ) {
    my $param_v = $params[$param_no];
    my @param_v = ( ref($param_v) eq 'ARRAY' ) ? @$param_v : $param_v;
    # $sth->bind_param( $param_no+1, @param_v );
    $self->{_last_sth_params}[ $param_no ] = $param_v;
  }
  $self->{_last_sth_execute} = $sth->execute();
  $self->{_last_sth_statement} = $sth->{Statement};
  $self->{_last_result} = $self->{_next_result};
  
  return $sth;
}

# $self->done_with_query( $sth );
sub done_with_query {
  my $self = shift;
  $self->{_next_result} = undef;
  $self->SUPER::done_with_query( @_ );
}

########################################################################

=head2 Retrieving Rows from a Statement

=over 4

=item get_execute_rowcount()

  $sqldb->get_execute_rowcount ($sth) : $row_count

Returns the value stored by next_result() using the key "rowcount".

=item fetchall_hashref()

  $sqldb->fetchall_hashref ($sth) : $array_of_hashes

Returns the value stored by next_result() using the key "hashref".

=item fetchall_hashref_columns()

  $sqldb->fetchall_hashref ($sth) : $array_of_hashes
  $sqldb->fetchall_hashref ($sth) : ( $array_of_hashes, $column_info )

Returns the value stored by next_result() using the key "hashref", and if called in a list context, also returns the value for the key "columns".

=item fetchall_arrayref()

  $sqldb->fetchall_arrayref ($sth) : $array_of_arrays

Returns the value stored by next_result() using the key "arrayref".

=item fetchall_arrayref_columns()

  $sqldb->fetchall_hashref ($sth) : $array_of_arrays
  $sqldb->fetchall_hashref ($sth) : ( $array_of_arrays, $column_info )

Returns the value stored by next_result() using the key "arrayref", and if called in a list context, also returns the value for the key "columns".

=item retrieve_columns()

  $sqldb->retrieve_columns ($sth) : $column_info

Retrieves the value stored by next_result() using the key "columns". 

=item visitall_hashref()

  $sqldb->visitall_hashref ($sth, $coderef) : ()

Uses the value stored by next_result() using the key "hashref". Calls the coderef on each row with values as a hashref, and returns a list of their results.

=item visitall_array()

  $sqldb->visitall_array ($sth, $coderef) : ()

Uses the value stored by next_result() using the key "arrayref". Calls the coderef on each row with values as a list, and returns a list of their results.

=back

=cut

sub get_execute_rowcount { (shift)->{_next_result}{rowcount} }
sub fetchall_arrayref    { (shift)->{_next_result}{arrayref} }
sub fetchall_hashref     { (shift)->{_next_result}{hashref}  }
sub retrieve_columns     { (shift)->{_next_result}{columns}  }

sub fetchall_arrayref_columns {
  my ($self, $sth) = @_;
  my $cols = wantarray() ? $self->{_next_result}{columns} : undef;
  my $rows = $self->{_next_result}{arrayref};
  wantarray ? ( $rows, $cols ) : $rows;
}

sub fetchall_hashref_columns {
  my ($self, $sth) = @_;
  my $cols = wantarray() ? $self->{_next_result}{columns} : undef;
  my $rows = $self->{_next_result}{hashref};
  wantarray ? ( $rows, $cols ) : $rows;
}

# $self->visitall_hashref( $sth, $coderef );
  # Calls a codref for each row returned by the statement handle
sub visitall_hashref {
  my ($self, $sth, $coderef) = @_;
  my $rows = $self->{_next_result}{hashref} or return;
  map &$coderef( $_ ), @$rows
}

# $self->visitall_array( $sth, $coderef );
  # Calls a codref for each row returned by the statement handle
sub visitall_array {
  my ($self, $sth, $coderef) = @_;
  my $rows = $self->{_next_result}{arrayref} or return;
  map &$coderef( @$_ ), @$rows
}

########################################################################

1;

__END__

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################
