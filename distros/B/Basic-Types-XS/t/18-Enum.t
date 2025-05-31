use strict;
use warnings;
use Test::More;
use Basic::Types::XS qw(Enum);

my $type = Enum(validate => [qw/a b c/]);
is($type->("a"), "a", 'a is a valid enum value');

eval { $type->("d") };
like($@, qr/value did not pass type constraint "Enum"/, 'non-matching d in enum');

eval { $type->("abc") };
like($@, qr/value did not pass type constraint "Enum"/, 'non-matching abc in enum');

$type = Enum(validate => ["abc", "def"], message => "Not foo!");
is($type->("def"), "def");

eval { $type->("bar") };
like($@, qr/Not foo!/, 'custom error message croaks');

eval { $type->({}) };
like($@, qr/Not foo!/, 'custom error message croaks');

eval { $type->([]) };
like($@, qr/Not foo!/, 'custom error message croaks');

eval { $type->() };
like($@, qr/Not foo!/, 'custom error message croaks');

done_testing;
