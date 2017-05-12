use strict;
use warnings;

use Test::More;
use Test::Exception;
use lib qw(t/lib);
use DBICTest;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

#eval { require Storable };
#plan( skip_all => 'Storable not installed; skipping' ) if $@;

plan tests => 9;

my $schema = DBICTest->init_schema();

my $struct_hash = {
    a => 1,
    b => [
        { c => 2 },
    ],
    d => 3,
};

my $struct_array = [
    'a',
    {
        b => 1,
        c => 2
    },
    'd',
    house => 'château',
    heart => "\x{2764}",
];

my $rs = $schema->resultset("SerializeStorable");
my ($stored, $inflated);

$stored = $rs->create({
  'testtable_id' => 1
});

ok($stored->update({ 'serial1' => $struct_hash, 'serial2' => $struct_array }), 'deflation');

#retrieve what was serialized from DB
undef $stored;
$stored = $rs->find({'testtable_id' => 1});

ok($inflated = $stored->serial1, 'hashref inflation');
is_deeply($inflated, $struct_hash, 'the stored hash and the orginial are equal');
ok($inflated = $stored->serial2, 'arrayref inflation');
is_deeply($inflated, $struct_array, 'the stored array and the orginial are equal');

throws_ok(sub {
  $stored->update({ 'serial1' => { 'bigkey' => '-' x 1024 }
                  });
}, qr/serialization too big/, 'Serialize result bigger than size of column');


ok($stored->update({ 'serial2' => { 'bigkey' => '-' x 1024 }
                   })
,'storing a serialization too big for a column without size');

undef $stored;
$stored = $rs->find({'testtable_id' => 1});

TODO: {
  local $TODO = 'sqlite doesn\'t truncate TEXT fields...';

  throws_ok(sub {
    $inflated = $stored->serial2
  }, qr/Storable couldn't thaw the value/, 'the serialization is truncated, but at least we get an exception');

};

$stored->update({ 'serial1' => undef });

undef $stored;
$stored = $rs->find({'testtable_id' => 1});

ok(not(defined($stored->serial1)), 'serial1 is undefined');



