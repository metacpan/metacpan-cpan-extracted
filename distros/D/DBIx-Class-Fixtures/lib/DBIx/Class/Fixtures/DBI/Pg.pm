package DBIx::Class::Fixtures::DBI::Pg;
$DBIx::Class::Fixtures::DBI::Pg::VERSION = '1.001039';
use strict;
use warnings;
use base qw/DBIx::Class::Fixtures::DBI/;

sub do_insert {
  my ($class, $schema, $sub) = @_;

  $schema->txn_do(
    sub {
      eval { $schema->storage->dbh->do('SET CONSTRAINTS ALL DEFERRED') };
      $sub->();
    }
  );
}

1;
