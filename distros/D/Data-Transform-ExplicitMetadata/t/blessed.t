use strict;
use warnings;

use Data::Transform::ExplicitMetadata qw(encode decode);

use Scalar::Util qw(refaddr);
use Test::More tests => 3;

my $bless_package = 'TestPackage';

my $original = bless [ 1, 2, 3 ], $bless_package;
my $expected = {
    __refaddr => refaddr($original),
    __reftype => 'ARRAY',
    __blessed => $bless_package,
    __value => [ 1, 2, 3 ],
};
my $encoded = encode($original);

is_deeply($encoded, $expected, 'encode blessed array');

my $decoded = decode($encoded);
is_deeply($decoded, $original, 'decode blessed array');
isa_ok($decoded, $bless_package);

