use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);
ok($array->splice(0, 0, 'five'));
is($array->length, 5);

my $array = Data::LnArray->new(qw/one two three four/);
ok($array->splice(0, -1, 'five'));
is($array->length, 2);
is_deeply($array, [qw/five four/]);

my $array = Data::LnArray->new(qw/one two three four/);
ok($array->splice(0, -2));
is($array->length, 2);
is_deeply($array, [qw/three four/]);





done_testing;
