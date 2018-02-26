#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Rows;
#----------------------------------------------------------------------
use warnings;
use strict;

use parent 'DBIx::DataModel::Schema::ResultAs';

sub get_result {
  my ($self, $statement) = @_;

  return $statement->all;
}

1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Rows - all data rows

=head1 DESCRIPTION

Returns an arrayref of all data rows.

