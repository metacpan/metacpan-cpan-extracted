#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Subquery;
#----------------------------------------------------------------------
use warnings;
use strict;
use DBIx::DataModel::Carp;
use DBIx::DataModel::Statement ();

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;


sub new {
  my ($class, $alias, @other) = @_;

  ! @other or croak "-result_as => [subquery => ...] ... too many arguments";

  my $self = {alias => $alias};
  return bless $self, $class;
}



sub get_result {
  my ($self, $statement) = @_;

  $statement->_forbid_callbacks(__PACKAGE__);

  my @sqlize_args = $self->{alias} ? (-as => $self->{alias}) : ();
  $statement->sqlize(@sqlize_args) if $statement->status < DBIx::DataModel::Statement::SQLIZED;

  my ($sql, @bind) = $statement->sql;

  # make sure the $sql is in parenthesis
  $sql = "($sql)" if $sql !~ /^\(/;

  return \ [$sql, @bind]; # ref to an arrayref with SQL and bind values
}

1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Subquery - SQL and bind values in a form suitable for a subquery


=head1 SYNOPSIS

  # subquery to be used in an IN clause
  my $subquery = $source1->select(..., -result_as => 'subquery');
  my $rows     = $source2->select(
      -columns => ...,
      -where   => {foo => 123, bar => {-not_in => $subquery}}
   );

  # subquery to be used in a SELECT list
  my $subquery = $source1->select(..., -result_as => [subquery => 'col3']);
  my $rows     = $source2->select(
      -columns => ['col1', 'col2', $subquery, 'col4'],
      -where   => ...
   );


=head1 DESCRIPTION

Returns a ref to an arrayref containing C<< \["($sql)", @bind] >>.
This is meant to be passed to a second query, for example through the C<-in> or
C<-not_in> operator of L<SQL::Abstract|SQL::Abstract>, or as a column specification
in the select list.

When used in the form C<< -result_as => [subquery => $alias] >>, the alias is added
as a column alias, following the syntax specified in L<SQL::Abstract::More/column_alias>.







