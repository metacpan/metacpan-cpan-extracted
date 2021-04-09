use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new();

my $from = $array->from([qw/one two three four/]);

my @array = $from->retrieve;
is($array[0], 'one');
is($array[1], 'two');
is($array[2], 'three');
is($array[3], 'four');

$from = $array->from(q|foo|);
@array = $from->retrieve;
is($array[0], 'f');
is($array[1], 'o');
is($array[2], 'o');

$from = $array->from([qw/1 2 3/], sub { $_ + $_ });
@array = $from->retrieve;
is($array[0], 2);
is($array[1], 4);
is($array[2], 6);

$from = $array->from({length => 5}, sub { $_ + $_ });
@array = $from->retrieve;
is($array[0], 0);
is($array[1], 2);
is($array[2], 4);
is($array[3], 6);
is($array[4], 8);

eval { $array->from({}) };

like($@, qr/currently cannot handle/);


done_testing;
