use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;

plan tests => 1;

# Set up the "usual" sqlite and disconnect
my $normal_schema = DBIO::SQLite::Test->init_schema( sqlite_use_file => 1 );
$normal_schema->storage->disconnect;

# Steal the dsn from the test schema
my @dsn = ($normal_schema->storage->_dbi_connect_info->[0], undef, undef, {
  RaiseError => 1
});

# Make a new clone with a new connection, using a code reference
my $code_ref_schema = $normal_schema->connect(sub { DBI->connect(@dsn); });

# Stolen from 60core.t - this just verifies things seem to work at all
my @art = $code_ref_schema->resultset("Artist")->search({ }, { order_by => 'name DESC'});
cmp_ok(@art, '==', 3, "Three artists returned");
