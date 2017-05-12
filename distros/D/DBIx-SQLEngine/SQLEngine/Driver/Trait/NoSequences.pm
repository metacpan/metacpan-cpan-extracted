=head1 NAME

DBIx::SQLEngine::Driver::Trait::NoSequences - For databases without native sequences

=head1 SYNOPSIS

  # Classes can import this behavior if they don't have native sequences
  use DBIx::SQLEngine::Driver::Trait::NoSequences ':all';
  
  # Public interface for NoSequences functionality
  $nextid = $sqldb->seq_increment( $table, $field );

  # Housekeeping functions for setup and removal
  $sqldb->seq_create_table();
  $sqldb->seq_insert_record( $table, $field );
  $sqldb->seq_delete_record( $table, $field );
  $sqldb->seq_drop_table();

=head1 DESCRIPTION

This package supports SQL database servers which do natively support
an auto-incrementing or unique sequence trigger. Instead, a special
table is allocated to store sequence values, and queries are used
to atomically retrieve and increment the sequence value to ensure
uniqueness.

=head2 About Driver Traits

You do not need to use this package directly; it is used internally by those driver subclasses which need it. 

For more information about Driver Traits, see L<DBIx::SQLEngine::Driver/"About Driver Traits">.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Trait::NoSequences;

use Exporter;
sub import { goto &Exporter::import } 
@EXPORT_OK = qw( 
  do_insert_with_sequence
  seq_table_name seq_create_table seq_drop_table 
  seq_insert_record seq_delete_record 
  seq_fetch_current sql_seq_fetch_current 
  seq_increment sql_seq_increment 
  seq_bootstrap_init
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

use strict;
use Carp;

########################################################################

=head1 REFERENCE

The following methods are provided:

=cut

########################################################################

=head2 Insert to Add Data 

=over 4

=item do_insert_with_sequence()

  $sqldb->do_insert_with_sequence( $seq_name, %sql_clauses ) : $row_count

Insert a single row into a table in the datasource, using a sequence to fill in the values of the column named in the first argument. Should return 1, unless there's an exception.

Implemented with _seq_do_insert_preinc() and seq_increment().

=back

=cut

# $rows = $self->do_insert_with_sequence( $sequence, %clauses );
sub do_insert_with_sequence { 
  (shift)->_seq_do_insert_preinc( @_ )
}

########################################################################

=head2 Sequence Table 

=over 4

=item seq_fetch_current()

  $sqldb->seq_fetch_current( $table, $field ) : $current_value

Fetches the current sequence value. 

Implemented as an exception-handling wrapper around the query defined in
sql_seq_fetch_current(), which attempts to create the sequence table if it
doesn't exist and insert a row for this sequence if needed.

=item sql_seq_fetch_current()

  $sqldb->sql_seq_fetch_current( $table, $field ) : $sql, @params

Returns a SQL statement to fetch the current value from the sequence table.

=cut

# $current_id = $sqldb->seq_fetch_current( $table, $field );
sub seq_fetch_current {
  my ($self, $table, $field) = @_;

  my $seq_table = $self->seq_table_name;

  my $current;
  eval {
    local $SIG{__DIE__};
    $current = $self->fetch_one_value( 
      sql => [ $self->sql_seq_fetch_current($table, $field) ] 
    );
    unless ( defined $current and length $current ) {
      $self->seq_insert_record( $table, $field ); 
      $current = 0; # $self->seq_bootstrap_init( $table, $field ) || 0;
    }
  };
  
  if ( my $err = $@ ) {
    eval {
      local $SIG{__DIE__};
      $self->seq_create_table();
      $self->seq_insert_record( $table, $field );
      $current = 0;
    };
    if ( $@ ) {
      confess "Unable to select from sequence table $seq_table: $err\n" . 
	      "Also unable to automatically create sequence table: $@";
    }
  }
  return $current;
}

# $sql, @params = $sqldb->sql_seq_fetch_current( $table, $field );
sub sql_seq_fetch_current {
  my ($self, $table, $field) = @_;
  my $seq_table = $self->seq_table_name;
  $self->sql_select(
    table => $seq_table,
    columns => 'seq_value',
    criteria => [ 'seq_name = ?', "$table.$field" ],
  );
}

########################################################################

=pod

=item seq_increment()

  $sqldb->seq_increment( $table, $field ) : $new_value

Increments the sequence, and returns the newly allocated value. 

This is the primary "public" interface of this package. 

If someone else has completed the same increment before we have, our update will have no effect and we'll immediately try again and again until successful.

If the table does not yet exist, attempts to create it automatically. 

If the sequence record does not yet exist, attempts to create it automatically.

=item sql_seq_increment()

  $sqldb->sql_seq_increment( $table, $field, $current, $next ) : $sql, @params

Generates a SQL statement for use by seq_increment().

=cut

# $nextid = $sqldb->seq_increment( $table, $field );
# $nextid = $sqldb->seq_increment( $table, $field, $value);
sub seq_increment {
  my ($self, $table, $field, $next) = @_;
  
  ATTEMPT: {
    my $current = $self->seq_fetch_current( $table, $field );

    $next = $current + 1 unless ( $next and $next > $current );
    
    return $next if $self->do_update(
      sql => [ $self->sql_seq_increment( $table, $field, $current, $next ) ] 
    );
    
    redo ATTEMPT;
  }
}

# $sql, @params = $sqldb->sql_seq_increment( $table, $field, $current, $next );
sub sql_seq_increment {
  my ($self, $table, $field, $current, $next) = @_;
  my $seq_table = $self->seq_table_name;
  $self->sql_update(
    table => $seq_table,
    values => { seq_value => $next },
    criteria => ['seq_name = ? and seq_value = ?', "$table.$field", $current]
  );
}

########################################################################

########################################################################

=pod

=item seq_table_name()

Constant 'dbix_sqlengine_seq'.

=cut

use constant seq_table_name => 'dbix_sqlengine_seq';

########################################################################

=pod

=item seq_create_table()

  $sqldb->seq_create_table()

Issues a SQL create table statement to create the sequence table.

=item seq_drop_table()

  $sqldb->seq_drop_table()

Issues a SQL drop table statement to remove the sequence table.

=cut

sub seq_create_table {
  my $self = shift;
  my $seq_table = $self->seq_table_name;
  $self->do_create_table( $seq_table, [
    { type => 'text',    name => 'seq_name', length => 48, required => 1 }, 
    { type => 'int',     name => 'seq_value',              required => 1 }, 
    { type => 'primary', name => 'seq_name' }, 
  ] );
  # warn "Created sequence table '$seq_table'";
}

# $sqldb->seq_drop_table();
sub seq_drop_table {
  my $self = shift;
  my $seq_table = $self->seq_table_name;
  $self->do_drop_table( $seq_table );
  # warn "Dropped sequence table '$seq_table'";
}

########################################################################

=pod

=item seq_insert_record()

  $sqldb->seq_insert_record( $table, $field )

Creates a record in the sequence table for a given field in a particular table. 

=item seq_delete_record()

  $sqldb->seq_delete_record( $table, $field )

Removes the corresponding record in the sequence table.

=cut

# $sqldb->seq_insert_record( $table, $field ); 
sub seq_insert_record {
  my $self = shift;
  my ($table, $field) = @_;
  $self->do_insert(
    table => $self->seq_table_name,
    values => { seq_name => "$table.$field", seq_value => 0, },
  );
}

# $sqldb->seq_delete_record( $table, $field );
sub seq_delete_record {
  my $self = shift;
  my ($table, $field) = @_;
  $self->do_delete(
    table => $self->seq_table_name,
    criteria => [ 'seq_name = ?', "$table.$field" ],
  );
}

########################################################################

=pod

=item seq_bootstrap_init()

  $sqldb->seq_bootstrap_init( $table, $field ) : $current_value

Scans the designated field in a given table to determine its maximum value, and then stores that in sequence table.

=cut

# $sqldb->seq_bootstrap_init( $table, $field ); 
sub seq_bootstrap_init {
  my $self = shift;
  my ($table, $field) = @_;
  
  my $max = $self->fetch_one_value(
    table => $table,
    columns => "max($field)",
  );
  
  return unless $max;
  
  $self->seq_increment( $table, $field, $max );
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

See L<DBIx::Sequence> for another version of the sequence-table functionality, which greatly inspired this module.

=cut

########################################################################

1;

