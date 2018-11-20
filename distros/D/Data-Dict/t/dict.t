use strict;
use warnings;
use Test::More;
use Data::Dict 'd';

# Hash
is d(a => 1, b => 2, c => 3)->{b}, 2, 'right result';
is_deeply {%{d(a => 3, b => 2, c => 1)}}, {a => 3, b => 2, c => 1}, 'right result';
my $dict = d(a => 1, b => 2);
$dict->{c} = 3;
is_deeply {%$dict}, {a => 1, b => 2, c => 3}, 'right result';

# Tap into method chain
is_deeply d(a => 1, b => 2, c => 3)->tap(sub { $_->{b} += 2 })->to_hash, {a => 1, b => 4, c => 3}, 'right result';

# delete
$dict = d(a => 1, b => 2, c => 3, d => 4, e => 5);
is_deeply $dict->delete('a')->to_hash, {a => 1}, 'right result';
is_deeply $dict->delete('b')->to_hash, {b => 2}, 'right result';
is_deeply $dict->delete('a')->to_hash, {a => undef}, 'right result';
is_deeply {%$dict}, {c => 3, d => 4, e => 5}, 'right result';
is_deeply $dict->delete('z')->to_hash, {z => undef}, 'right result';
is_deeply $dict->delete(qw(b c d))->to_hash, {b => undef, c => 3, d => 4}, 'right result';
is_deeply {%$dict}, {e => 5}, 'right result';

# each
$dict = d(a => 3, b => 2, c => 1);
my @keys = keys %$dict;
my @values = values %$dict;
is_deeply [$dict->each], [[$keys[0], $values[0]], [$keys[1], $values[1]], [$keys[2], $values[2]]], 'right elements';
$dict = d(a => [3], b => [2], c => [1]);
@keys = keys %$dict;
@values = values %$dict;
my @results;
$dict->each(sub { push @results, $_[1][0] });
is_deeply \@results, [$values[0][0], $values[1][0], $values[2][0]], 'right elements';
@results = ();
$dict->each(sub { push @results, $_[0], $_[1][0] });
is_deeply \@results, [$keys[0], $values[0][0], $keys[1], $values[1][0], $keys[2], $values[2][0]], 'right elements';

# each_sorted
$dict = d(a => 3, b => 2, c => 1);
@keys = sort keys %$dict;
@values = @$dict{sort keys %$dict};
is_deeply [$dict->each_sorted], [[$keys[0], $values[0]], [$keys[1], $values[1]], [$keys[2], $values[2]]], 'right elements';
$dict = d(a => [3], b => [2], c => [1]);
@keys = sort keys %$dict;
@values = @$dict{sort keys %$dict};
@results = ();
$dict->each_sorted(sub { push @results, $_[1][0] });
is_deeply \@results, [$values[0][0], $values[1][0], $values[2][0]], 'right elements';
@results = ();
$dict->each_sorted(sub { push @results, $_[0], $_[1][0] });
is_deeply \@results, [$keys[0], $values[0][0], $keys[1], $values[1][0], $keys[2], $values[2][0]], 'right elements';

# extract
$dict = d(a => 1, b => 2, c => 3, d => 4, e => 5, f => 6, g => 7, h => 8, i => 9);
is_deeply $dict->extract(qr/[f-i]/)->to_hash, {f => 6, g => 7, h => 8, i => 9},
  'right elements';
is_deeply {%$dict}, {a => 1, b => 2, c => 3, d => 4, e => 5}, 'right elements';
is_deeply $dict->extract(sub { $_[1] < 5 })->to_hash, {a => 1, b => 2, c => 3, d => 4},
  'right elements';
is_deeply {%$dict}, {e => 5}, 'right elements';
is_deeply $dict->extract(sub { $_[1] < 1 })->to_hash, {}, 'no elements';
is_deeply $dict->extract(sub { $_[1] > 9 })->to_hash, {}, 'no elements';
is_deeply {%$dict}, {e => 5}, 'right elements';

# grep
$dict = d(a => 1, b => 2, c => 3, d => 4, e => 5, f => 6, g => 7, h => 8, i => 9);
is_deeply $dict->grep(qr/[f-i]/)->to_hash, {f => 6, g => 7, h => 8, i => 9},
  'right elements';
is_deeply $dict->grep(sub { $_[0] =~ m/[f-i]/ })->to_hash, {f => 6, g => 7, h => 8, i => 9},
  'right elements';
is_deeply $dict->grep(sub { $_[1] > 5 })->to_hash, {f => 6, g => 7, h => 8, i => 9},
  'right elements';
is_deeply $dict->grep(sub { $_[1] < 5 })->to_hash, {a => 1, b => 2, c => 3, d => 4},
  'right elements';
is_deeply $dict->grep(sub { $_[1] == 5 })->to_hash, {e => 5},
  'right elements';
is_deeply $dict->grep(sub { $_[1] < 1 })->to_hash, {}, 'no elements';
is_deeply $dict->grep(sub { $_[1] > 9 })->to_hash, {}, 'no elements';

# keys
$dict = d();
is $dict->keys, 0, 'no keys';
is_deeply [$dict->keys], [], 'no keys';
$dict = d(a => 3, b => 2, c => 1);
@keys = keys %$dict;
is $dict->keys, 3, 'right number of keys';
is_deeply [$dict->keys], \@keys, 'right keys';
@results = ();
$dict->keys(sub { push @results, $_ });
is_deeply \@results, \@keys, 'right keys';

# map
$dict = d(a => 1, b => 2, c => 3);
@values = values %$dict;
is join('', $dict->map(sub { $_[1] + 1 })), join('', map { $_ + 1 } @values), 'right result';
is_deeply {%$dict}, {a => 1, b => 2, c => 3}, 'right elements';
is join('', $dict->map(sub { my $v = $_[1]; $v + 2 })), join('', map { $_ + 2 } @values), 'right result';
is_deeply {%$dict}, {a => 1, b => 2, c => 3}, 'right elements';

# map_sorted
$dict = d(a => 1, b => 2, c => 3);
@values = @$dict{sort keys %$dict};
is join('', $dict->map_sorted(sub { $_[1] + 1 })), join('', map { $_ + 1 } @values), 'right result';
is_deeply {%$dict}, {a => 1, b => 2, c => 3}, 'right elements';
is join('', $dict->map_sorted(sub { my $v = $_[1]; $v + 2 })), join('', map { $_ + 2 } @values), 'right result';
is_deeply {%$dict}, {a => 1, b => 2, c => 3}, 'right elements';

# size
$dict = d();
is $dict->size, 0, 'right size';
$dict = d('' => undef);
is $dict->size, 1, 'right size';
$dict = d(23 => 23);
is $dict->size, 1, 'right size';
$dict = d(23 => {2 => 3});
is $dict->size, 1, 'right size';
$dict = d(a => 5, b => 4, c => 3, d => 2, e => 1);
is $dict->size, 5, 'right size';
$dict = d(a => 1, a => 2);
is $dict->size, 1, 'right size';

# slice
$dict = d(a => 1, b => 2, c => 3, d => 4, e => 5, f => 6, g => 7, h => 10, i => 9, j => 8);
is_deeply $dict->slice('a')->to_hash,       {a => 1}, 'right result';
is_deeply $dict->slice('b')->to_hash,       {b => 2}, 'right result';
is_deeply $dict->slice('c')->to_hash,       {c => 3}, 'right result';
is_deeply $dict->slice('z')->to_hash,       {z => undef}, 'right result';
is_deeply $dict->slice(qw(b c d))->to_hash, {b => 2, c => 3, d => 4}, 'right result';
is_deeply $dict->slice(qw(g b e))->to_hash, {g => 7, b => 2, e => 5}, 'right result';
is_deeply $dict->slice('g'..'j')->to_hash,  {g => 7, h => 10, i => 9, j => 8}, 'right result';

# transform
$dict = d(a => 1, b => 2, c => 3);
is_deeply $dict->transform(sub { ($_[0], $_[1]+1) }), {a => 2, b => 3, c => 4}, 'right result';
is_deeply {%$dict}, {a => 1, b => 2, c => 3}, 'right elements';
is_deeply $dict->transform(sub { my ($k, $v) = @_; ($k, $v+2) }), {a => 3, b => 4, c => 5}, 'right result';
is_deeply {%$dict}, {a => 1, b => 2, c => 3}, 'right elements';

# values
$dict = d();
is $dict->values, 0, 'no values';
is_deeply [$dict->values], [], 'no values';
$dict = d(a => 3, b => 2, c => 1);
@values = values %$dict;
is $dict->values, 3, 'right number of values';
is_deeply [$dict->values], \@values, 'right values';
@results = ();
$dict->values(sub { push @results, $_++ });
is_deeply \@results, \@values, 'right values';
is_deeply {%$dict}, {a => 4, b => 3, c => 2}, 'right elements';

done_testing;
