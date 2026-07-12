use strict;
use warnings;
use Test::More;

# Regression: loading the AGE storage must NOT clobber the core driver
# registry entry for plain 'Pg'. AGE is component-activated (the component
# registers DBIO::PostgreSQL::Age::Storage as a storage LAYER, composed over the
# resolved Pg driver), never auto-detected from a bare dbi:Pg: DSN. If the AGE
# storage registered itself as the 'Pg' driver, every plain Pg connection would
# rebless into AGE storage and run graph SQL against a non-AGE database. As a
# plain layer it must own no register_driver call at all.
#
# Mirror the real load order: plain Pg storage first, then AGE on top.

use DBIO::Storage::DBI;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Age::Storage;

my $pg_class = DBIO::Storage::DBI->driver_storage_class('Pg');

isnt $pg_class, 'DBIO::PostgreSQL::Age::Storage',
  q{loading AGE storage does not register itself as the 'Pg' driver};

is $pg_class, 'DBIO::PostgreSQL::Storage',
  q{'Pg' driver still resolves to the plain PostgreSQL storage};

done_testing;
