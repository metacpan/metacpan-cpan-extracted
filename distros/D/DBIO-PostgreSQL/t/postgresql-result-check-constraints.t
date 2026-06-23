#!perl
use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Result;

{
    package TestResult::CheckConstraint;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('test_table');
}

# 1. String form — no leading CHECK
TestResult::CheckConstraint->pg_check_constraint('foo' => 'col > 0');
is(TestResult::CheckConstraint->pg_check_constraints->{foo}{definition},
   'col > 0', 'string form stored correctly');

# 2. Hashref form with raw pg_get_constraintdef output (includes CHECK)
TestResult::CheckConstraint->pg_check_constraint('bar' => {
    constraint_name => 'bar',
    definition      => 'CHECK (col < 100)',
    columns         => ['col'],
});
is(TestResult::CheckConstraint->pg_check_constraints->{bar}{definition},
   'CHECK (col < 100)', 'hashref form stored correctly');

# 3. Verify getter returns the full constraint entry (hashref)
my $foo_entry = TestResult::CheckConstraint->pg_check_constraint('foo');
is(ref $foo_entry, 'HASH', 'getter returns entry hashref');
is($foo_entry->{definition}, 'col > 0', 'entry contains correct definition');

my $bar_entry = TestResult::CheckConstraint->pg_check_constraint('bar');
is(ref $bar_entry, 'HASH', 'getter returns entry hashref for hashref form');
is($bar_entry->{definition}, 'CHECK (col < 100)', 'hashref entry stored as-is');

done_testing;