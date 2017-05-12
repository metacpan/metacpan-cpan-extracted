#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'DBIx::Class::PgLog' ) || print "Bail out!\n";
    use_ok( 'DBIx::Class::Schema::PgLog' ) || print "Bail out!\n";
    use_ok( 'DBIx::Class::Schema::PgLog::Structure' ) || print "Bail out!\n";
    use_ok( 'DBIx::Class::Schema::PgLog::Structure::Log' ) || print "Bail out!\n";
    use_ok( 'DBIx::Class::Schema::PgLog::Structure::LogSet' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::PgLog $DBIx::Class::PgLog::VERSION, Perl $], $^X" );
