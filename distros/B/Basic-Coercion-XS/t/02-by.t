use strict;
use warnings;
use Test::More;
use Basic::Coercion::XS qw(StrToArray);

my $type = StrToArray->by(',');

my $arrayref = $type->("a,b,c");
is_deeply($arrayref, [qw(a b c)], 'by sets split pattern after construction');

$type = StrToArray()->by(qr/\d+/);
$arrayref = $type->("foo123bar456baz");
is_deeply($arrayref, [qw(foo bar baz)], 'by sets split pattern with regex object');

eval { StrToArray()->by(undef) };
like($@, qr/pattern must be a string or a regex object/, 'by croaks on bad pattern');

done_testing;
