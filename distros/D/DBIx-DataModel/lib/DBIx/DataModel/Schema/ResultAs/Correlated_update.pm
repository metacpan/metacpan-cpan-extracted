#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Correlated_update;
#----------------------------------------------------------------------
use warnings;
use strict;
use DBIx::DataModel::Statement;

use parent 'DBIx::DataModel::Schema::ResultAs';

sub new {
  my ($class, $to_set) = @_;
  bless {to_set => $to_set}, $class;
}

sub get_result {
  my ($self, $statement) = @_;

  $statement->_forbid_callbacks(__PACKAGE__);
  $statement->sqlize;

  my ($sql, @bind)   = $statement->sql;
  my $schema         = $statement->schema;
  my $to_set         = $self->{to_set};
  $sql = "UPDATE ($sql) SET " . join ", ", map {"$_=$to_set->{$_}"} keys %$to_set;
  $schema->_debug(do {no warnings 'uninitialized'; $sql . " / " . CORE::join(", ", @bind);});

  my $prepare_method = $schema->dbi_prepare_method;
  my $sth            = $schema->dbh->$prepare_method($sql);

  $statement->sql_abstract->bind_params($sth, @bind);
  return $sth->execute(); # will return the number of updated records
}

1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Correlated_update - update from a SELECT query

=head1 SYNOPSIS

  my $count_updates = $schema->join(qw/Activity employee department/)->select(
    -columns   => [qw/d_birth d_begin dpt_name/],
    -result_as => [correlated_update =>
       {'T_Activity.remark' => "'started in ' || dpt_name || ' at age ' || d_begin-d_birth"}
     ]);

=head1 DESCRIPTION

Performs a "correlated update", i.e. an update operation on the result of a SELECT query.
Not all DBMS support this feature. Oracle does; for others, check your documentation.

The syntax is

  $source->select(..., -result_as => [correlated_update => \%columns_to_set]);

which executes an SQL statement of shape :

  UPDATE (<select query>) SET k1=v1, k2=v2, ...

where C<k1>, C<v1>, C<k2>, C<v2>, etc. are keys and values of C<%columns_to_set>.
Note that unlike the regular UPDATE METHOD, here values C<v1>, C<v2>, ... are treated
as I<literals>, not bind values, because the point of such correlated updates is to
take values from joined tables for updating columns in the main table. 

The return value is the number of updated records.
