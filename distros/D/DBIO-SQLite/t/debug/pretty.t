use strict;
use warnings;
use DBIO::SQLite::Test;
use Test::More;

BEGIN {
    require DBIO;
    plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_prettydebug')
      unless DBIO::Optional::Dependencies->req_ok_for ('test_prettydebug');
}

BEGIN { delete @ENV{qw(DBIO_TRACE_PROFILE)} }

{
   my $schema = DBIO::SQLite::Test->init_schema();

   isa_ok($schema->storage->debugobj, 'DBIO::Storage::Statistics');
}

{
   local $ENV{DBIO_TRACE_PROFILE} = 'console';

   my $schema = DBIO::SQLite::Test->init_schema();

   isa_ok($schema->storage->debugobj, 'DBIO::Storage::Debug::PrettyTrace');;
   is($schema->storage->debugobj->_sqlat->indent_string, ' ', 'indent string set correctly from console profile');
}

{
   local $ENV{DBIO_TRACE_PROFILE} = './t/lib/awesome.json';

   my $schema = DBIO::SQLite::Test->init_schema();

   isa_ok($schema->storage->debugobj, 'DBIO::Storage::Debug::PrettyTrace');;
   is($schema->storage->debugobj->_sqlat->indent_string, 'frioux', 'indent string set correctly from file-based profile');
}

done_testing;
