use strict;
use warnings;

use Test::More;

# pg_qualified_table answers an SQL name: every part is written by the server's
# quote_ident rule, so the result can stand in a statement as it is.

{
  package QT::Result;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
}

sub qname {
  my ($schema, $table) = @_;
  my $class = 'QT::Result';
  $class->_pg_schema_name($schema);
  $class->table($table);
  return $class->pg_qualified_table;
}

is qname('auth', 'users'), 'auth.users', 'plain names stay bare';
is qname(undef, 'users'), 'users', 'no schema: the table alone';
is qname('Auth', 'users'), '"Auth".users', 'a schema with capitals is quoted';
is qname('auth', 'UserAccount'), 'auth."UserAccount"', 'a mixed-case table is quoted';
is qname('auth', 'user accounts'), 'auth."user accounts"', 'a table with a blank is quoted';
is qname('my schema', 'a"b'), '"my schema"."a""b"', 'a quote inside a name is doubled';
is qname('public', 'user'), 'public."user"', 'a reserved word is quoted';
is qname(undef, 'MixedCase'), '"MixedCase"', 'a lone mixed-case table is quoted';

done_testing;
