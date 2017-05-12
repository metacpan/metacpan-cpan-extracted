use warnings;
use strict;

use Test::Pod tests => 10;
 
pod_file_ok('lib/DBIx/Connection.pm', "should have value lib/DBIx/Connection.pm POD file");
pod_file_ok('lib/DBIx/QueryCursor.pm', "should have value lib/DBIx/QueryCursor.pm POD file");
pod_file_ok('lib/DBIx/PLSQLHandler.pm', "should have value lib/DBIx/PLSQLHandler.pm POD file");
pod_file_ok('lib/DBIx/SQLHandler.pm', "should have value lib/DBIx/SQLHandler.pm POD file");
pod_file_ok('lib/DBIx/Connection/PostgreSQL/SQL.pm', "should have value lib/DBIx/Connection/PosteerSQL/SQL.pm POD file");
pod_file_ok('lib/DBIx/Connection/PostgreSQL/PLSQL.pm', "should have value lib/DBIx/Connection/PostgreSQL/PLSQL.pm POD file");
pod_file_ok('lib/DBIx/Connection/Oracle/SQL.pm', "should have value lib/DBIx/Connection/Oracle/SQL.pm POD file");
pod_file_ok('lib/DBIx/Connection/Oracle/PLSQL.pm', "should have value lib/DBIx/Connection/Oracle/PLSQL.pm POD file");
pod_file_ok('lib/DBIx/Connection/MySQL/SQL.pm', "should have value lib/DBIx/Connection/MySQL/SQL.pm POD file");
pod_file_ok('lib/DBIx/Connection/MySQL/PLSQL.pm', "should have value lib/DBIx/Connection/MySQL/PLSQL.pm POD file");