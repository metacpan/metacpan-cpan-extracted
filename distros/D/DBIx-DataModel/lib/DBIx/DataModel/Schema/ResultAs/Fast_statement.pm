#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Fast_statement;
#----------------------------------------------------------------------
use warnings;
use strict;

use parent 'DBIx::DataModel::Schema::ResultAs';

sub get_result {
  my ($self, $statement) = @_;

  $statement->execute;
  $statement->make_fast;
  return $statement;
}

1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Fast_statement - statement with reusable memory for rows

=head1 DESCRIPTION

Applies the L<DBIx::DataModel::Doc::Reference/make_fast()> method
to the current statement. This allocates some fixed memory for storing
data rows; as a result, data retrieval through the C<< $statement->next >>
method will be faster, but each row should be "consumed" before fetching
the next row.



