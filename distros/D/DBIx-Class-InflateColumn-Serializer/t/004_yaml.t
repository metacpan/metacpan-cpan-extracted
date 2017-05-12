use utf8;
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

#eval { require YAML };
#plan( skip_all => 'YAML not installed; skipping' ) if $@;

plan tests => 11;

my $schema = DBICTest->init_schema();

my $struct_hash = {
    c => 1,
    d => [
        { e => 2 },
    ],
    f => 3,
    house => 'château',
    heart => "\x{2764}",
};

my $struct_array = [
    'c',
    {
        d => 1,
        e => 2
    },
    'f',
];

my $rs = $schema->resultset("SerializeYAML");
my ($stored, $inflated);

$stored = $rs->create({
  'testtable_id' => 3
});

ok($stored->update({ 'serial1' => $struct_hash, 'serial2' => $struct_array }), 'deflation');

my $raw = $schema->storage->dbh_do(sub {
    my ($storage, $dbh, @args) = @_;
    $dbh->selectrow_hashref('SELECT * from testtable WHERE testtable_id = ?', {}, $stored->testtable_id);
});
like($raw->{serial1}, qr/château/, "raw data contains unicode, as-is, without transformation (latin1-ish 'château')");
like($raw->{serial1}, qr/\x{2764}/, "raw data contains unicode, as-is, without transformation (utf8-ish '\x{2764}')");

#retrieve what was serialized from DB
undef $stored;
$stored = $rs->find({'testtable_id' => 3});

ok($inflated = $stored->serial1, 'hashref inflation');
is_deeply($inflated, $struct_hash, 'the stored hash and the orginial are equal');
ok($inflated = $stored->serial2, 'arrayref inflation');
is_deeply($inflated, $struct_array, 'the stored array and the orginial are equal');

throws_ok(sub {
  $stored->update({ 'serial1' => { 'bigkey' => 'm' x 1024 }
                  });
}, qr/serialization too big/, 'Serialize result bigger than size of column');


ok($stored->update({ 'serial2' => { 'bigkey' => 'm' x 1024 }
                   })
,'storing a serialization too big for a column without size');

undef $stored;
$stored = $rs->find({'testtable_id' => 3});

TODO: {
  local $TODO = 'sqlite doesn\'t truncate TEXT fields...';

  throws_ok(sub {
    $inflated = $stored->serial2
  }, qr/YAML Error/, 'the serialization is truncated, but at least we get an exception');

};

$stored->update({ 'serial1' => undef });

undef $stored;
$stored = $rs->find({'testtable_id' => 3});

ok(not(defined($stored->serial1)), 'serial1 is undefined');

