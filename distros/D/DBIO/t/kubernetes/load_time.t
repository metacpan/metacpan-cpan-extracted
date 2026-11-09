use strict;
use warnings;

use Test::More;

# What this file claims: loading DBIO::Test::Kubernetes must not drag DBI or a
# DBD into the process.
#
# The module is a live-test tool -- it provisions database pods -- but loading
# it is not running one. Its file-scope %DB_SPECS decided with a real
# "require DBD::MariaDB" which of two DSN spellings the mysql spec should
# carry, so every process that so much as loaded this module initialised an XS
# database driver plus DBI for the sake of a template string. Same coupling as
# k173 on DBIO::Optional::Dependencies, same fix: probe @INC for the file
# instead of loading it.
#
# Nothing here talks to Kubernetes or to a database; %INC is the whole subject.

my @forbidden = qw( DBI.pm DBD/MariaDB.pm DBD/mysql.pm );

require DBIO::Test::Kubernetes;

ok !exists $INC{$_}, "$_ not in %INC after loading DBIO::Test::Kubernetes"
  for @forbidden;

done_testing;
