use strict;
use warnings;

use utf8;
use Test::More;
use Test::Exception;
use lib qw(t/lib);
use DBICTest;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

my $schema = DBICTest->init_schema();

plan tests => 13;

my $struct_hash = {
    b => 1,
    c => [
        { d => 2 },
    ],
    e => 3,
    house => 'château',
    heart => "\x{2764}",
};

my $struct_array = [
    'b',
    {
        c => 1,
        d => 2
    },
    'e',
];

my $struct_int = 42;

my $rs = $schema->resultset("SerializeJSON");
my ($stored, $inflated);

$stored = $rs->create({
  'testtable_id' => 2
});

ok($stored->update({ 'serial1' => $struct_hash, 'serial2' => $struct_array, 'serial3' => $struct_int }), 'deflation');

my $raw = $schema->storage->dbh_do(sub {
    my ($storage, $dbh, @args) = @_;
    $dbh->selectrow_hashref('SELECT * from testtable WHERE testtable_id = ?', {}, $stored->testtable_id);
});
like($raw->{serial1}, qr/"château"/, "raw data contains unicode, as-is, without transformation (latin1-ish 'château')");
like($raw->{serial1}, qr/"\x{2764}"/, "raw data contains unicode, as-is, without transformation (utf8-ish '\x{2764}')");

#retrieve what was serialized from DB
undef $stored;
$stored = $rs->find({'testtable_id' => 2});

ok($inflated = $stored->serial1, 'hashref inflation');
is_deeply($inflated, $struct_hash, 'the stored hash and the orginial are equal');
ok($inflated = $stored->serial2, 'arrayref inflation');
is_deeply($inflated, $struct_array, 'the stored array and the orginial are equal');
ok($inflated = $stored->serial3, 'int inflation (allowing nonrefs)');
is_deeply($inflated, $struct_int, 'the stored int and the original are equal');

throws_ok(sub {
  $stored->update({ 'serial1' => { 'bigkey' => 'n' x 1024 }
                  });
}, qr/serialization too big/, 'Serialize result bigger than size of column');


ok($stored->update({ 'serial2' => { 'bigkey' => 'n' x 1024 }
                   })
,'storing a serialization too big for a column without size');

undef $stored;
$stored = $rs->find({'testtable_id' => 2});

TODO: {
  local $TODO = 'sqlite doesn\'t truncate TEXT fields...';

  throws_ok(sub {
    $inflated = $stored->serial2
  }, qr/unexpected end of string/, 'the serialization is truncated, but at least we get an exception');

};

$stored->update({ 'serial1' => undef });

undef $stored;
$stored = $rs->find({'testtable_id' => 2});

ok(not(defined($stored->serial1)), 'serial1 is undefined');

