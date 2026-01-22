#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 9;

BEGIN {
    use_ok('DBIx::Class::Async')                       || print "Bail out!\n";
    use_ok('DBIx::Class::Async::Schema')               || print "Bail out!\n";
    use_ok('DBIx::Class::Async::ResultSet')            || print "Bail out!\n";
    use_ok('DBIx::Class::Async::ResultComponent')      || print "Bail out!\n";
    use_ok('DBIx::Class::Async::ResultSet::Pager')     || print "Bail out!\n";
    use_ok('DBIx::Class::Async::Row')                  || print "Bail out!\n";
    use_ok('DBIx::Class::Async::Storage')              || print "Bail out!\n";
    use_ok('DBIx::Class::Async::Storage::DBI')         || print "Bail out!\n";
    use_ok('DBIx::Class::Async::Storage::DBI::Cursor') || print "Bail out!\n";
}

diag( "Testing DBIx::Class::Async $DBIx::Class::Async::VERSION, Perl $], $^X" );

done_testing;
