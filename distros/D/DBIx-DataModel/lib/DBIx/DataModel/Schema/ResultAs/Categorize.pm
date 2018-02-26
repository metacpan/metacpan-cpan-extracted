#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Categorize;
#----------------------------------------------------------------------
use warnings;
use strict;
use Carp::Clan              qw[^(DBIx::DataModel::|SQL::Abstract)];
use List::Categorize 0.04   qw/categorize/;

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;

sub new {
  my $class = shift;

  @_ or croak "-result_as => [categorize => ...] ... need field names ";

  my $self = {cols => \@_};
  return bless $self, $class;
}

sub get_result {
  my ($self, $statement) = @_;

  my @cols = @{$self->{cols}};

  $statement->execute;
  my $rows = $statement->all;
  my %result = categorize {@{$_}{@cols}} @$rows;
  $statement->finish;

  return \%result;
}


1;


__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Categorize - tree of categorized lists of rows

=head1 SYNOPSIS

  my $tree = $source->select(..., -result_as => [categorize => ($key1, $key2)]);

=head1 DESCRIPTION

Builds a tree of rows through module L<List::Categorize>, with
C<$key1>, C<$key2>, etc. as categorization keys. This is quite similar
to the C<hashref> result kind, except that the categorization keys
need not be unique : each leaf of the tree will contain I<lists>
of rows matching those categories, while the C<hashref> result kind
only keeps the I<last> row matching the given keys.


