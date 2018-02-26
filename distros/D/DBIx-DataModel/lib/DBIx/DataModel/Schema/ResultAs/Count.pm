#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Count;
#----------------------------------------------------------------------
use warnings;
use strict;

use parent 'DBIx::DataModel::Schema::ResultAs';

sub get_result {
  my ($self, $statement) = @_;

  $statement->refine(-columns => 'COUNT(*)|N_ROWS');
  $statement->execute();

  my $count_row = $statement->_next_and_finish;
  return $count_row->{N_ROWS};
}

1;


=head1 NAME

DBIx::DataModel::Schema::ResultAs::Count - count rows

=head1 DESCRIPTION

Refines the statement with C<< -columns => 'COUNT(*) >> and returns the count
of rows.

