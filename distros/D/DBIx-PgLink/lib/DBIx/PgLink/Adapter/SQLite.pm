package DBIx::PgLink::Adapter::SQLite;

# Note: DBD::SQLite 1.14 fixes a number of bugs with re-using statements
# do not use v1.13 or earlier

use Moose;

extends 'DBIx::PgLink::Adapter';

has '+are_transactions_supported' => (default=>1);

with 'DBIx::PgLink::Adapter::Roles::EmulateColumnInfo';


around 'expand_table_info' => sub {
  my ($next, $self, $info) = @_;

  # skip system table
  return 0 if $info->{TABLE_NAME} =~ /^sqlite_sequence$/;
  $next->($self, $info);
};


1;

__END__

=head1 NOTES

Reuse of statement handle after database error (i.e. constraint violation) depends on DBD::SQLite version:

1.14 repeat last error (and sometimes core dumps under v5.8.8 built for MSWin32-x86-multi-thread)
1.13 repeat last error
1.12 seems ok

Strange devolution :(

=cut
