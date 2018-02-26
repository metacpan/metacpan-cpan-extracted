#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Flat_arrayref;
#----------------------------------------------------------------------
use warnings;
use strict;

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;

sub get_result {
  my ($self, $statement) = @_;

  $statement->execute;
  $statement->make_fast;
  my @vals;
  my @headers = $statement->headers;
  while (my $row = $statement->next) {
    push @vals, @{$row}{@headers};
  }
  $statement->finish;

  return \@vals;
}

# THINK : should we take a list of columns as arguments,
# i.e. -result_as => [flat_arrayref => ($col1, ...)], instead of taking
# ->headers ? Easy to implement, but it wouldn't really make sense,
# because the choice of columns is done in the -columns arg to
# select().



1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Flat_arrayref - accumulates columns into a flat arrayref

=head1 SYNOPSIS

  $source->select(..., -columns => [$col1, ...], -result_as => 'flat_arrayref');

=head1 DESCRIPTION

Retrieves all data rows from the statement; for each row, the columns
specified in the C<-columns> argument are pushed into a global, flat array.
See L<DBIx::DataModel::Doc::Reference/flat_arrayref> for examples.

