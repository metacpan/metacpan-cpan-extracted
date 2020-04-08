use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);
ok($array = $array->slice(0, 1));
is($array->length, 2);
is_deeply($array, [qw/one two/]);


done_testing;
