use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;
use Test::Exception;
use Test::Differences;

use Data::CompactReadonly;

(undef, my $filename) = tempfile(UNLINK => 1);

Data::CompactReadonly->create($filename, [
    [5, 4, 3, 2, 1, 0],
    {},
    {
        hash  => { lemon => 'curry' },
        array => [ qw(lemon curry) ],
    },
    'fishfingers',
    []
]);

subtest 'tieing with fast_collections cache' => sub {
    my $tied = Data::CompactReadonly->read($filename, 'tie' => 1, fast_collections => 1);
    ok(tied(@{$tied}), "db is tied");

    is($tied->[2]->{hash}->{lemon}, 'curry', "can read from hashes");
    eq_or_diff(
        $tied->[2]->{array},
        [qw(lemon curry)],
        "read some more"
    );
};

my $tied   = Data::CompactReadonly->read($filename, 'tie' => 1);
my $untied = Data::CompactReadonly->read($filename);

is($#{$tied}, $untied->count() - 1, "can de-ref and count elements in an Array");
is($tied->[3], 'fishfingers', "can de-ref and retrieve an array element");
is($#{$tied->[0]}, $untied->element(0)->count() - 1, "those work on nested arrays");
throws_ok { $tied->[5] } qr/Invalid element: 5: out of range/, "can't fetch illegal array index";
throws_ok { $tied->[2] = 3 } qr/Illegal access: store: this is a read-only database/, "can't update an array element";
throws_ok { push @{$tied->[0]}, 8 } qr/Illegal access: store: this is a read-only database/, "can't push onto an array";
throws_ok { pop @{$tied->[0]} } qr/Illegal access: store: this is a read-only database/, "can't pop from an array";
throws_ok { unshift @{$tied->[0]}, 8 } qr/Illegal access: store: this is a read-only database/, "can't unshift onto an array";
throws_ok { shift @{$tied->[0]} } qr/Illegal access: store: this is a read-only database/, "can't shift from an array";
throws_ok { delete $tied->[0]->[3] } qr/Illegal access: store: this is a read-only database/, "can't delete from an array";
throws_ok { @{$tied->[0]} = () } qr/Illegal access: store: this is a read-only database/, "can't clear an array";
throws_ok { splice(@{$tied->[0]}, 0, 2, 4) } qr/Illegal access: store: this is a read-only database/, "can't splice an array";
throws_ok { $#{$tied->[0]} = 94 } qr/Illegal access: store: this is a read-only database/, "can't update an array's length";

ok(exists($tied->[0]), "exists() works on an existent index");
ok(!exists($tied->[10]), "... and on a non-existent index");
ok(!exists($tied->[4]->[0]), "... and on an empty array");

throws_ok { $tied->[2]->{cow} } qr/Invalid element: cow: doesn't exist/, "can't fetch illegal dict key";
throws_ok { $tied->[2]->{hash} = 'pipe' } qr/Illegal access: store: this is a read-only database/, "can't update a hash element";
throws_ok { delete($tied->[2]->{hash}) } qr/Illegal access: store: this is a read-only database/, "can't delete from a hash";
throws_ok { %{$tied->[2]->{hash}} = () } qr/Illegal access: store: this is a read-only database/, "can't clear a hash";
is($tied->[2]->{hash}->{lemon}, 'curry', "can de-ref and retrieve Dictionary elements");

ok(exists($tied->[2]->{hash}->{lemon}), "exists() works on an existent key");
ok(!exists($tied->[2]->{hash}->{lime}), "... and on a non-existent key");
ok(!exists($tied->[1]->{wibble}), "... and on an empty hash");

eq_or_diff([keys %{$tied->[2]}], [qw(array hash)], "can get keys of a Dictionary");
eq_or_diff([keys %{$tied->[1]}], [], "can get keys of an empty Dictionary");
is(scalar(%{$tied->[2]}), 2, "can count keys in the hash");

eq_or_diff(
    [@{$tied->[0]}],
    [5, 4, 3, 2, 1, 0],
    "can de-ref an array completely"
);
eq_or_diff(
    { %{$tied->[2]} },
    { hash => { lemon => 'curry' }, array => [qw(lemon curry)] },
    "can de-ref a dictionary completely"
);

done_testing;
