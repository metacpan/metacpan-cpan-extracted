use Test::Most;

use Scalar::Util qw/ refaddr /;

use Data::Enum;

ok my $colors = Data::Enum->new( qw/ Red red /), 'new class';

is_deeply [ $colors->values ], [qw/ Red red /], 'values';

throws_ok {
 $colors->new("RED")
} qr/invalid value: 'RED'/;

ok my $r1 = $colors->new("Red"), "new item";
ok my $r2 = $colors->new("red"), "new item";

isnt $r1, $r2, "difference case";

done_testing;
