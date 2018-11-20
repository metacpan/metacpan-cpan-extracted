use strict;
use warnings;
use Test::Needs 'Mojo::Collection';
use Test::More;
use Data::Dict 'd';
use Scalar::Util 'blessed';

# to_collection
my $dict = d(a => 3, b => 2, c => 3);
my @keys = keys %$dict;
my @values = values %$dict;
my $c = $dict->to_collection;
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is_deeply [@$c], [$keys[0], $values[0], $keys[1], $values[1], $keys[2], $values[2]], 'right elements';

# to_collection_sorted
$dict = d(a => 3, b => 2, c => 3);
@keys = sort keys %$dict;
@values = @$dict{sort keys %$dict};
$c = $dict->to_collection_sorted;
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is_deeply [@$c], [$keys[0], $values[0], $keys[1], $values[1], $keys[2], $values[2]], 'right elements';

# each_c
$dict = d(a => 3, b => 2, c => 1);
@keys = keys %$dict;
@values = values %$dict;
$c = $dict->each_c;
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is_deeply [map { [@$_] } @$c], [[$keys[0],$values[0]], [$keys[1],$values[1]], [$keys[2],$values[2]]], 'right elements';

# each_sorted_c
$dict = d(a => 3, b => 2, c => 1);
@keys = sort keys %$dict;
@values = @$dict{sort keys %$dict};
$c = $dict->each_sorted_c;
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is_deeply [map { [@$_] } @$c], [[$keys[0],$values[0]], [$keys[1],$values[1]], [$keys[2],$values[2]]], 'right elements';

# keys_c
$dict = d();
$c = $dict->keys_c;
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is @$c, 0, 'no keys';
is_deeply [@$c], [], 'no keys';
$dict = d(a => 3, b => 2, c => 1);
@keys = keys %$dict;
$c = $dict->keys_c;
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is @$c, 3, 'right number of keys';
is_deeply [@$c], \@keys, 'right keys';

# map_c
$dict = d(a => 1, b => 2, c => 3);
@values = values %$dict;
$c = $dict->map_c(sub { $_[1] + 1 });
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is join('', @$c), join('', map { $_ + 1 } @values), 'right result';
$c = $dict->map_c(sub { my $v = $_[1]; $v + 2 });
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is join('', @$c), join('', map { $_ + 2 } @values), 'right result';

# map_sorted_c
$dict = d(a => 1, b => 2, c => 3);
@values = @$dict{sort keys %$dict};
$c = $dict->map_sorted_c(sub { $_[1] + 1 });
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is join('', @$c), join('', map { $_ + 1 } @values), 'right result';
$c = $dict->map_sorted_c(sub { my $v = $_[1]; $v + 2 });
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is join('', @$c), join('', map { $_ + 2 } @values), 'right result';

# values_c
$dict = d();
$c = $dict->values_c;
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is @$c, 0, 'no values';
is_deeply [@$c], [], 'no values';
$dict = d(a => 3, b => 2, c => 1);
@values = values %$dict;
$c = $dict->values_c;
ok blessed($c) && $c->isa('Mojo::Collection'), 'collection object';
is @$c, 3, 'right number of values';
is_deeply [@$c], \@values, 'right values';

done_testing;
