package DBIx::Class::Fixtures::DBI::mysql;
$DBIx::Class::Fixtures::DBI::mysql::VERSION = '1.001039';
use strict;
use warnings;
use base qw/DBIx::Class::Fixtures::DBI/;

sub do_insert {
  my ($class, $schema, $sub) = @_;

  $schema->txn_do(
    sub {
      eval { $schema->storage->dbh->do('SET foreign_key_checks=0') };
      $sub->();
      eval { $schema->storage->dbh->do('SET foreign_key_checks=1') };
    }
  );
}

1;
