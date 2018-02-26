#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Subquery;
#----------------------------------------------------------------------
use warnings;
use strict;

use parent 'DBIx::DataModel::Schema::ResultAs';

sub get_result {
  my ($self, $statement) = @_;

  $statement->_forbid_callbacks(__PACKAGE__);
  $statement->sqlize if $statement->status < DBIx::DataModel::Statement::SQLIZED;

  my ($sql, @bind) = $statement->sql;
  return \ ["($sql)", @bind]; # ref to an arrayref with SQL and bind values
}

1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Subquery - SQL and bind values in a form suitable for a subquery

=head1 DESCRIPTION

Returns a ref to an arrayref containing C<< \["($sql)", @bind] >>.
This is meant to be passed to a second query through the C<-in> or
C<-not_in> operator of L<SQL::Abstract|SQL::Abstract>, as in :

  my $subquery = $source1->select(..., -result_as => 'subquery');
  my $rows     = $source2->select(
      -columns => ...,
      -where   => {foo => 123, bar => {-not_in => $subquery}}
   );



