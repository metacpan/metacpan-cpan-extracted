package My::Test;
# ABSTRACT: Test helpers for DBIO::GraphQL

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw( fresh_schema deploy_schema );

use DBIO::SQLite::Deploy;

# Workaround for DBIO 0.900: DBIO::SQLite::Storage::dbio_deploy_class is
# wiped by namespace::clean, so $schema->deploy falls through to the
# deployment_statements path which expects a DDL file. The native Deploy
# class itself works fine - we just have to invoke it directly.
sub deploy_schema {
  my ($db) = @_;
  DBIO::SQLite::Deploy->new(schema => $db)->install;
  return $db;
}

# fresh_schema($schema_class, \%seed_rows)
#
# Connect an in-memory SQLite schema, deploy it, optionally seed rows.
# Returns ($db, $result) where $result is DBIO::GraphQL->to_graphql($db).
sub fresh_schema {
  my ($schema_class, $seed) = @_;
  my $db = $schema_class->connect('dbi:SQLite:dbname=:memory:');
  deploy_schema($db);
  if ($seed && ref $seed eq 'HASH') {
    while (my ($rs_name, $rows) = each %$seed) {
      my $rs = $db->resultset($rs_name);
      $rs->create($_) for @$rows;
    }
  }
  my $r = DBIO::GraphQL->to_graphql($db);
  return ($db, $r);
}

1;
