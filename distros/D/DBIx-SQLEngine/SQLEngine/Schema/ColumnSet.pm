=head1 NAME

DBIx::SQLEngine::Schema::ColumnSet - Array of Schema::Column objects


=head1 SYNOPSIS

  my $colset = DBIx::SQLEngine::Schema::ColumnSet->new( $column1, $column2 );
  
  print $colset->count;
  
  foreach my $column ( $colset->columns ) {
    print $column->name;
  }
  
  $column = $colset->column_named( $name );


=head1 DESCRIPTION

DBIx::SQLEngine::Schema::ColumnSet objects contain an array of DBIx::SQLEngine::Schema::Column objects

=cut

package DBIx::SQLEngine::Schema::ColumnSet;
use strict;
use Carp;

########################################################################

=head1 REFERENCE

=head2 Creation

=over 4

=item new()

  DBIx::SQLEngine::Schema::ColumnSet->new( @columns ) : $colset

Basic array constructor.

=back

=cut

sub new {
  my $package = shift;
  my @cols = map {
    ( ref($_) eq 'HASH' ) ? DBIx::SQLEngine::Schema::Column->new_from_hash(%$_)
			  : $_
  } @_;
  bless \@cols, $package;
}

########################################################################

=head2 Access to Columns

=over 4

=item columns()

  $colset->columns () : @columns

Returns a list of column objects. 

=back

=cut

sub columns {
  my $colset = shift;
  @$colset
}

sub call_method_on_columns {
  my $columns = shift;
  my $method = shift;
  return map { $_->$method( @_ ) } @$columns;
}

########################################################################

=head2 Column Names

=over 4

=item column_names()

  $colset->column_names () : @column_names

Returns the result of calling name() on each column.

=item column_named()

  $colset->column_named ( $name ) : $column

Finds the column with that name, or dies trying.

=back

=cut

# @colnames = $colset->column_names;
sub column_names {
  (shift)->call_method_on_columns( 'name' )
}

# $column = $colset->column_named( $column_name );
# $column = $colset->column_named( $column_name );
sub column_named {
  my $colset = shift;
  my $column_name = shift;
  foreach ( @$colset ) {
    return $_ if ( $_->name eq $column_name );
  }
  croak(
    "No column named $column_name in $colset->{name} table\n" . 
    "  (Perhaps you meant one of these: " . join(', ', map { $_->name() . " (". $_->type() .")" } @$colset) . "?)"
  );
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
