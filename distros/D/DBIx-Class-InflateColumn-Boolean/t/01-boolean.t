#!perl -wT
use strict;
use warnings;
use Test::More;
use Scalar::Util 'blessed';

BEGIN {
    use lib 't/lib';
    use TestDB;

    eval 'require DBD::SQLite';
    if ($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 30;
    }
};

my $schema = TestDB->init_schema;

my $rs = $schema->resultset('Snafu');

my $true = $rs->create({
    foo => 'Y',
    bar => 'oui',
    baz => 1
});

$rs->create({
    foo => 'N',
    bar => 'non',
    baz => -1
});

my $false = $rs->find(2);

ok(blessed($true->foo), '$true->foo has been inflated into an object');
ok(blessed($true->bar), '$true->bar has been inflated into an object');
ok(blessed($true->baz), '$true->baz has been inflated into an object');

ok(blessed($true->foo) && ref($true->foo) eq 'DBIx::Class::InflateColumn::Boolean::Value', 'ref($true->foo) eq "DBIx::Class::InflateColumn::Boolean::Value"');
ok(blessed($true->bar) && ref($true->bar) eq 'DBIx::Class::InflateColumn::Boolean::Value', 'ref($true->bar) eq "DBIx::Class::InflateColumn::Boolean::Value"');
ok(blessed($true->baz) && ref($true->baz) eq 'DBIx::Class::InflateColumn::Boolean::Value', 'ref($true->baz) eq "DBIx::Class::InflateColumn::Boolean::Value"');

is($true->foo, 'Y', '$true->foo eq "Y"');
is($true->bar, 'oui', '$true->bar eq "oui"');
cmp_ok($true->baz, '==', 1, '$true->baz == 1');

ok($true->foo, '$true->foo is true');
ok($true->bar, '$true->bar is true');
ok($true->baz, '$true->baz is true');

ok(blessed($false->foo), '$false->foo has been inflated into an object');
ok(blessed($false->bar), '$false->bar has been inflated into an object');
ok(blessed($false->baz), '$false->baz has been inflated into an object');

ok(blessed($false->foo) && ref($false->foo) eq 'DBIx::Class::InflateColumn::Boolean::Value', 'ref($true->foo) eq "DBIx::Class::InflateColumn::Boolean::Value"');
ok(blessed($false->bar) && ref($false->bar) eq 'DBIx::Class::InflateColumn::Boolean::Value', 'ref($true->bar) eq "DBIx::Class::InflateColumn::Boolean::Value"');
ok(blessed($false->baz) && ref($false->baz) eq 'DBIx::Class::InflateColumn::Boolean::Value', 'ref($true->baz) eq "DBIx::Class::InflateColumn::Boolean::Value"');

is($false->foo, 'N', '$false->foo eq "N"');
is($false->bar, 'non', '$false->bar eq "non"');
cmp_ok($false->baz, '==', -1, '$false->baz == -1');

ok(!$false->foo, '$false->foo is false');
ok(!$false->bar, '$false->bar is false');
ok(!$false->baz, '$false->baz is false');

$false->bar($true->bar);
$false->update;

my $row = $rs->find(2);	# re-read 2nd row 
ok(blessed($row->bar), '$row->bar has been inflated into an object');
ok(blessed($row->bar) && ref($row->bar) eq 'DBIx::Class::InflateColumn::Boolean::Value', 'ref($row->bar) eq "DBIx::Class::InflateColumn::Boolean::Value"');
is($row->bar, 'oui', '$row->bar eq "oui"');
ok($row->bar, '$true->bar is row');
ok(!blessed($row->get_column('bar')), '$row->get_column("bar") is not blessed');
is($row->get_column('bar'), 'oui', '$row->get_column("bar") eq "oui"');
