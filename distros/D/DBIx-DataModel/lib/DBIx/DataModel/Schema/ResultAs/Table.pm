#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Table;
#----------------------------------------------------------------------
use warnings;
use strict;

use parent 'DBIx::DataModel::Schema::ResultAs';

sub get_result {
  my ($self, $statement) = @_;

  $statement->execute;
  $statement->make_fast;
  my @headers = $statement->headers;
  my @vals = (\@headers);

  while (my $row = $statement->next) {
    push @vals, [@{$row}{@headers}];
  }
  $statement->finish;

  return \@vals;
}

1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Table

=head1 DESCRIPTION

Returns a "table", i.e. an arrayref where the first row contains
an arrayref of headers, and the following rows contain arrayrefs of
data values.

