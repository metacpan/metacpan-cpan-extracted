package DBIx::Class::Fixtures::DBI;
$DBIx::Class::Fixtures::DBI::VERSION = '1.001039';
use strict;
use warnings;

sub do_insert {
  my ($class, $schema, $sub) = @_;

  $schema->txn_do($sub);
}

1;
