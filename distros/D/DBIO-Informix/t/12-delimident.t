use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Test;

# The storage quotes identifiers with double quotes (sql_quote_char '"').
# Informix reads a double-quoted token as an identifier only when the
# DELIMIDENT environment variable is set when the connection is made;
# without it  SELECT COUNT(*) FROM "artist" "me"  is -201 "syntax error"
# (measured against Informix 15.0.1, karr k20). The storage therefore has
# to put DELIMIDENT into the environment of the connect, and leave the
# caller's environment as it was.

my $seen;
my $declared = DBIO::Test::Schema->clone(
  storage_type => '+DBIO::Informix::Storage',
);
my $schema = $declared->connect(sub {
  $seen = $ENV{DELIMIDENT};
  DBI->connect('dbi:NullP:', '', '', { RaiseError => 1 });
});

delete local $ENV{DELIMIDENT};
$schema->storage->ensure_connected;

is $seen, 'y', 'DELIMIDENT is set while the connection is made';
ok !exists $ENV{DELIMIDENT}, 'the caller environment is left as it was';

done_testing;
