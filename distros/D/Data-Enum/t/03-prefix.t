use Test::Most;

use Scalar::Util qw/ refaddr /;

use Data::Enum;

ok my $colors = Data::Enum->new( { prefix => 'has_' }, qw/ red green blue /), 'new class';

is_deeply [ $colors->values ], [qw/ blue green red /], 'values';

throws_ok {
 $colors->new("pink")
} qr/invalid value: 'pink'/;

ok my $red = $colors->new("red"), "new item";

is_deeply [ $red->values ], [qw/ blue green red /], 'values';

isa_ok $red, $colors;

can_ok( $red, qw/ values predicates has_red has_green has_blue / );

is_deeply [ $red->predicates ], [sort qw/ has_red has_green has_blue / ], 'predicates';

is $red->prefix, "has_";

ok $red->has_red, 'has_red';
ok !$red->has_blue, '!has_blue';
ok !$red->has_green, '!has_green';

is "$red", "red", "stringify";

ok $red eq "red", "equality";
ok $red eq $red, "equality";
ok $colors->new("red") eq $red, "equality";
ok "red" eq $red, "equality";

ok my $ro = $colors->new($red), "implicit clone";
is $ro, $red, "equality";

my $blue = $colors->new("blue");

ok $red ne "blue", "inequality";
ok $red ne "bllue", "inequality";
ok $red ne $blue, "inequality";
ok $colors->new("green") ne $red, "inequality";
ok "blue" ne $red, "inequality";

ok !( $colors->new("blue") eq $red ), "equality";
ok $colors->new("blue") eq $blue, "equality";

ok !$blue->has_red, '!has_red';
ok $blue->has_blue, 'has_blue';
ok !$blue->has_green, '!has_green';

is refaddr($red), refaddr( $colors->new("red") ), 'refaddr equality';

ok my $alt = Data::Enum->new(qw/ green red blue /), 'new class';
is $alt, $colors, "cached classes";

for my $value (qw/ red green blue /) {
    is $colors->new($value), $alt->new($value), "same value";
}

my $sizes = Data::Enum->new(qw/ big small blue /);
isnt $sizes, $colors, "different classes";

isnt $sizes->new("blue"), $alt->new("blue"), "members of different classes are different";
isnt $sizes->new("small"), $alt->new("blue"), "members of different classes are different";

is $$red, "red", "deref";

throws_ok {
 $$red = "pink"
} qr/Modification of a read-only value attempted/, "error when changing value";

is "$red", "red", "unchanged";

done_testing;
