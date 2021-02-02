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

  @_ or croak "-result_as => [categorize => ...] ... need field names or sub{} ";

  my $self;

  if ((ref $_[0] || '') eq 'CODE') {
    $self = {make_key => shift};
    !@_ or croak "-result_as => [categorize => sub {...}] : improper other args after sub{}";
  }
  else {
    $self = {cols => \@_};
  }

  return bless $self, $class;
}

sub get_result {
  my ($self, $statement) = @_;


  my $make_key = $self->{make_key} || do {
    my @cols = @{$self->{cols}};
    sub {my $row = shift; @{$row}{@cols}};
  };


  $statement->execute;
  my $rows = $statement->all;
  my %result = categorize {$make_key->($_)} @$rows;
  $statement->finish;

  return \%result;
}


1;


__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Categorize - tree of categorized lists of rows

=head1 SYNOPSIS

  my $tree = $source->select(..., -result_as => [categorize => ($column1, ...)]);
  # or
  my $tree = $source->select(..., -result_as => [categorize => sub {...}]);


=head1 DESCRIPTION

Builds a tree of lists of rows through module L<List::Categorize>, with
the content of C<$column1>, etc. as categorization keys. This is quite similar
to the C<hashref> result kind, except that the categorization keys
need not be unique : each leaf of the tree will contain I<lists>
of rows matching those categories, while the C<hashref> result kind
only keeps the I<last> row matching the given keys.

Instead of a list of column names, the argument can be a reference
to a subroutine. That subroutine will we called
for each row and should return a list of scalar values to be used as categorization keys.


