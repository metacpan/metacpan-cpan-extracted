use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok('DBIO::ChangeLog');
  use_ok('DBIO::ChangeLog::Schema');
  use_ok('DBIO::ChangeLog::Entry');
  use_ok('DBIO::ChangeLog::Set');
  use_ok('DBIO::ChangeLog::Table');
}

done_testing;