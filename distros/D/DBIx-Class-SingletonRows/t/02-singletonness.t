# $Id: 02-singletonness.t,v 1.6 2008-06-24 17:33:32 cantrelld Exp $

use strict;
use warnings;

use Test::More tests => 10;
use File::Temp;
use DBI;
use Data::Dumper;

use lib qw(t/lib);

use DBIx::Class::SingletonRows::Tests::TestSchema;

my $dbname = File::Temp->new()->filename();

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", '', '');
$dbh->do("
    CREATE TABLE hlagh (
        key1 INT,
        key2 INT,
        somedata VARCHAR(256),
        PRIMARY KEY (key1, key2)
    )
");
$dbh->do("
    INSERT INTO hlagh (key1, key2, somedata) VALUES (1, 2, 'three')
");

my $schema = DBIx::Class::SingletonRows::Tests::TestSchema->connect(
    "dbi:SQLite:dbname=$dbname"
);

{ 
    my $outer_row = ($schema->resultset('Hlagh')->search({key1 => 1, key2 => 2}))[0];
    ok($outer_row->somedata() eq 'three', "'outer' row has right data");
    {
        my $inner_row = update_and_return();
        ok($inner_row->somedata() eq 'four', "'inner' row got updated data");
        ok($outer_row->somedata() eq 'four', "and 'outer' row was magickally updated");
        ok(2 == $inner_row->_DCS_refcount(), "refcount == 2 in cache");
        ok(
            $outer_row->isa('DBIx::Class::SingletonRows::Tests::TestSchema::Hlagh'),
            "cached object pretends to be the right type"
        );
        {
            no strict;
            is_deeply(
                [@{ref($outer_row)."::ISA"}],
                [],
                "but \@ISA knows the truth"
            );
        }
        ok(
            $outer_row->can('set_inflated_columns'),
            "cached object says that it can('method')"
        );
    }
    ok(1 == $outer_row->_DCS_refcount(), "'inner' var went out of scope, refcount == 1 in cache");
    ok($outer_row->somedata() eq 'four', "'outer' row still magickally updated");
}

is_deeply(
    $DBIx::Class::SingletonRows::cache->{'DBIx::Class::SingletonRows::Tests::TestSchema::Hlagh'},
    {},
    "'outer' var now out of scope, object expired from cache"
);

sub update_and_return {
    my $row = ($schema->resultset('Hlagh')->search({key1 => 1, key2 => 2}))[0];
    $row->somedata('four');
    $row->update();
    return $row;
}
