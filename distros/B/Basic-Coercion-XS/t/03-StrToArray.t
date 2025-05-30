use strict;
use warnings;
use Test::More;
use Basic::Coercion::XS qw(StrToHash);

my $type = StrToHash();
my $hashref = $type->("a 1 b 2 c 3");
is_deeply($hashref, { a => 1, b => 2, c => 3 }, 'split by whitespace into hash');

$type = StrToHash(by => ',');
$hashref = $type->("a,1,b,2,c,3");
is_deeply($hashref, { a => 1, b => 2, c => 3 }, 'split by comma into hash');

$type = StrToHash(by => ':');
$hashref = $type->("a:1:b:2:c:3");
is_deeply($hashref, { a => 1, b => 2, c => 3 }, 'split by colon into hash');

$type = StrToHash();
$hashref = $type->("a 1 b 2 c 3");
ok(ref($hashref) eq 'HASH', 'returns a hashref even with odd elements');

$type = StrToHash();
$hashref = $type->("α β γ δ");
is_deeply($hashref, { "α" => "β", "γ" => "δ" }, 'unicode keys and values');

eval { $type->("a b c") };
like($@, qr/StrToHash requires an even number of elements in hash assignment/, 'undef input croaks');


done_testing;
