use Test::Most;

use Scalar::Util qw/ refaddr /;

use Data::Enum;

ok my $colors = Data::Enum->new( { name => 'Foo' }, qw/ red green blue /), 'new class';

is_deeply [ $colors->values ], [qw/ blue green red /], 'values';

throws_ok {
 $colors->new("pink")
} qr/invalid value: 'pink'/;

ok my $red = $colors->new("red"), "new item";

isa_ok $red, "Foo", "Data::Enum";

ok my $col = Foo->new("red"), "use named class";

isa_ok $col, "Foo", "Data::Enum";

is $col, $red, "named class object is same as abstract class object";

done_testing;
