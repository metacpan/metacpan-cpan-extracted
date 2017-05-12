use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok 'DBIx::Class::Snowflake' }
BEGIN { use_ok 'DBIx::Class::Snowflake::Fact' }
BEGIN { use_ok 'DBIx::Class::Snowflake::Dimension' }
