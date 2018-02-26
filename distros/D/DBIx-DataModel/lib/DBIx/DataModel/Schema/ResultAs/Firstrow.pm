#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Firstrow;
#----------------------------------------------------------------------
use warnings;
use strict;

use parent 'DBIx::DataModel::Schema::ResultAs';

sub get_result {
  my ($self, $statement) = @_;

  return $statement->_next_and_finish;
}

1;


=head1 NAME

DBIx::DataModel::Schema::ResultAs::Firstrow - first data row

=head1 DESCRIPTION

Returns the first data row and finishes the statement.
