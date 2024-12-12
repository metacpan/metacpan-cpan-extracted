use strict;
use warnings FATAL => 'all';
use Test::More 0.98;

use Daje::Plugin::GenerateSQL;

 use_ok $_ for qw(
     Daje::Plugin::GenerateSQL
     Daje::Plugin::SQL::Base::Common
     Daje::Plugin::SQL::Manager
     Daje::Plugin::SQL::Script::Fields
     Daje::Plugin::SQL::Script::Index
     Daje::Plugin::SQL::Script::ForeignKey
     Daje::Plugin::SQL::Script::Sql
     Daje::Plugin::Output::Table
     Daje::Plugin::Input::ConfigManager
     Daje::Plugin::Database::Operations
     Daje::Plugin::Database::SqlLite
 );

#ok (1==1);
done_testing;

