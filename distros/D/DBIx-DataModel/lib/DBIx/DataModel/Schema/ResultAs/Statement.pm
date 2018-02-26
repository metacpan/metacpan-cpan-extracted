#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Statement;
#----------------------------------------------------------------------
use warnings;
use strict;

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;

sub get_result {
  my ($self, $statement) = @_;

  delete $statement->{args}{-result_as};
  return $statement;
}

1;



__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Statement - returns the statement

=head1 DESCRIPTION

Merely returns the L<DBIx::DataModel::Statement> object.

