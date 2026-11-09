use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::MSSQL::Test::Conformance;

# karr k71. Core's conformance_quote_ident (ADR 0060, view case
# ddl-view-declared) quotes through the quote_char of the connected
# storage's SQL maker. For SQL Server that must be [name]. Pinned here so a
# change of the driver's quote character, or of the default, fails offline.
# Since karr k81 the driver overrides the hook with the same rule written out:
# the runner resolves a view definition before the database of the case exists,
# and over DBD::Sybase the storage's SQL maker cannot be had without a
# connection to it. The test compares the override with the default.

my $class = 'DBIO::MSSQL::Test::Conformance';

ok defined &DBIO::MSSQL::Test::Conformance::conformance_quote_ident,
  'the driver class answers conformance_quote_ident without the storage';
is $class->conformance_quote_ident(undef, 'a]b'), '[a]]b]',
  '... with no schema at hand';

for my $quote_names (0, 1) {
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::MSSQL::Storage',
    no_deploy    => 1,
    ($quote_names ? (quote_names => 1) : ()),
  );
  is $class->conformance_quote_ident($schema, 'order'), '[order]',
    "quoting gives [name] (quote_names => $quote_names)";
  is $class->conformance_quote_ident($schema, 'a]b'), '[a]]b]',
    '... a closing bracket in the name is doubled (core, table version 2)';
  for my $name ('order', 'a]b', 'plain') {
    is $class->conformance_quote_ident($schema, $name),
      $class->DBIO::Test::Conformance::conformance_quote_ident($schema, $name),
      "... the same as the default of core for '$name'";
  }
}

done_testing;
