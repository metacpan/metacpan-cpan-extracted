#!/usr/bin/perl
use strict;
use Test::More tests => 5;
use Test::Exception;
BEGIN { use_ok('DBI'); }
use Getopt::Long;

my ($dsn, $user, $password, $catalog, $schema, $table);

GetOptions(
  'dsn|d=s'      => \$dsn,
  'user|u:s'     => \$user,
  'password|p:s' => \$password,
  'catalog|C:s'  => \$catalog,
  'schema|S:s'   => \$schema,
  'table|T:s'    => \$table,
) or die "invalid options";


my $dbh;

lives_ok {
  $dbh = DBI->connect($dsn, $user, $password, {RaiseError=>1}) or die "connection failed";
} "connect";

lives_ok {
  $dbh->table_info($catalog, $schema, $table, "'TABLE','VIEW'");
} "table_info";

lives_ok {
  $dbh->column_info($catalog, $schema, $table, '%');
} "column_info";

lives_ok {
  $dbh->primary_key_info($catalog, $schema, $table);
} "primary_key_info";

