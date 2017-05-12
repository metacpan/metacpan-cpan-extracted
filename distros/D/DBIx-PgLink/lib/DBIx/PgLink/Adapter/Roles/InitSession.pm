package DBIx::PgLink::Adapter::Roles::InitSession;

use Moose::Role;

use DBIx::PgLink::Local;

after 'initialize_session' => sub {
  my $self = shift;
  $self->require_plperl(__PACKAGE__);
  die "Connection name not specified" unless defined $self->connector && $self->connector->conn_name;
  # user value does not override global value
  my $queries = pg_dbh->selectall_arrayref(<<'END_OF_SQL', {Slice=>{}}, $self->connector->conn_name);
SELECT init_query
FROM dbix_pglink.init_session
WHERE conn_name = $1
  AND (local_user = '' or local_user = session_user)
ORDER BY init_seq, local_user
END_OF_SQL

  $self->do($_->{init_query}) for @{$queries};

};


1;

__DATA__

=pod

=head1 NAME

DBIx::PgLink::Roles::InitSession - execute initializing SQL statements after connection

=head1 DESCRIPTION

Applied in PL/Perl environment only.
SQL query stored in I<dbix_pglink.init_session> table.


=cut
