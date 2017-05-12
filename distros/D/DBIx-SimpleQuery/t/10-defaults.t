use Test::More tests => 6;
use DBIx::SimpleQuery;

use strict;

DBIx::SimpleQuery::set_defaults("dsn"	    => "1",
				"user"	    => "2",
				"password"  => "3");

is(DBIx::SimpleQuery::get_dsn,
   1,
   "set_defaults Check: DSN");

is(DBIx::SimpleQuery::get_user,
   2,
   "set_defaults Check: User");

is(DBIx::SimpleQuery::get_password,
   3,
   "set_defaults Check: Password");

DBIx::SimpleQuery::set_defaults({
    "dsn"	=> "4",
    "user"	=> "5",
    "password"  => "6"
});

is(DBIx::SimpleQuery::get_dsn,
   4,
   "set_defaults hashref Check: DSN");

is(DBIx::SimpleQuery::get_user,
   5,
   "set_defaults hashref Check: User");

is(DBIx::SimpleQuery::get_password,
   6,
   "set_defaults hashref Check: Password");
