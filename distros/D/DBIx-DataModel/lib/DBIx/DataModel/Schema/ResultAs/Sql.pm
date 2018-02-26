#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Sql;
#----------------------------------------------------------------------
use warnings;
use strict;
use DBIx::DataModel::Statement;

use parent 'DBIx::DataModel::Schema::ResultAs';

sub get_result {
  my ($self, $statement) = @_;

  $statement->_forbid_callbacks(__PACKAGE__);
  $statement->sqlize if $statement->status < DBIx::DataModel::Statement::SQLIZED;

  return $statement->sql;
}

1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Sql - sql and bind values

=head1 DESCRIPTION

In scalar context, the result will just be the generated SQL statement.
In list context, it will be C<($sql, @bind)>, i.e. the SQL statement
together with the bind values.



