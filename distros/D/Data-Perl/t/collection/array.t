use Test::More;
use Data::Perl;
use Scalar::Util qw/refaddr/;
use Test::Output;

use strict;

# thanks to Mojo::Collection for skeleton test

# size
my $collection = array();
is $collection->count, 0, 'right size';
$collection = array(undef);
is @{$collection}, 1, 'right size';
$collection = array(23);
is $collection->count, 1, 'right size';
$collection = array([2, 3]);
is $collection->count, 1, 'right size';
$collection = array(5, 4, 3, 2, 1);
is @{$collection}, 5, 'right size';


# Array
is array(1,2,3)->[1], 2, 'right result';
is_deeply [@{array(3, 2, 1)}], [3, 2, 1], 'right result';
$collection = array(1, 2);
push @$collection, 3, 4, 5;
is_deeply [@$collection], [1, 2, 3, 4, 5], 'right result';

=begin
# each
$collection = array(3, 2, 1);
is_deeply [$collection->each], [3, 2, 1], 'right all';
$collection = array([3], [2], [1]);
my @results;
$collection->each(sub { push @results, $_->[0] });
is_deeply \@results, [3, 2, 1], 'right all';
@results = ();
$collection->each(sub { push @results, shift->[0], shift });
is_deeply \@results, [3, 1, 2, 2, 1, 3], 'right all';
=cut

#count/is_empty
is array()->count, 0, 'count correct.';
is array(1,2,3)->count, 3, 'count correct.';
is array()->is_empty, 1, 'is_empty correct.';
is array(1,2,3)->is_empty, 0, 'is_empty correct.';

# all
is_deeply [array()->all], [], 'all correct.';
is_deeply [array(1, 2, 3)->all], [1,2,3], 'all correct.';

# get
is array()->get(0), undef, 'get correct';
is array(1,2)->get(1), 2, 'get correct';

# accessor get
is array()->accessor(0), undef, 'accessor get correct';
is array(1,2)->accessor(1), 2, 'accessor get correct';
is array(1,2)->accessor(), '', 'accessor get 0 arg does nothing';

# pop
is array()->pop, undef, 'pop correct';
is array(1,2)->pop, 2, 'pop correct';

# push
my $ar = array(2); $ar->push(1);
is_deeply [$ar->all], [2,1], 'push works';

# shift
$ar = array(2,3);
is $ar->shift(), 2, 'shift works';
is_deeply [$ar->all], [3], 'shift works';

# unshift
$ar = array(3);
$ar->unshift(2);
is_deeply [$ar->all], [2,3], 'unshift works';

# splice
$ar = array(1);
$ar->splice(0,1,2);
is_deeply [$ar->all], [2], 'splice works';

$ar = array(9,8,7,6);
my ($b) = $ar->splice(0,2,2, 3, 4);
is_deeply [$b->all], [9,8], 'splice autoflatten works';

# first/first_index
$collection = array(5, 4, [3, 2], 1);
is_deeply $collection->first(sub { ref $_ eq 'ARRAY' }), [3, 2], 'right result';
is_deeply $collection->first_index(sub { ref $_ eq 'ARRAY' }), 2, 'right result';
is $collection->first(sub { $_ < 5 }), 4, 'right result';
is $collection->first_index(sub { $_ < 5 }), 1, 'right result';
is $collection->first(sub { ref $_ eq 'CODE' }), undef, 'no result';
is $collection->first_index(sub { ref $_ eq 'CODE' }), -1, 'no result';
$collection = array();
is $collection->first(sub { defined $_ }), undef, 'no result';
is $collection->first_index(sub { defined $_ }), -1, 'no result';
#is $collection->first, 5, 'right result';
#is $collection->first(qr/[1-4]/), 4, 'right result';
#is $collection->first, undef, 'no result';

# grep
$collection = array(1, 2, 3, 4, 5, 6, 7, 8, 9);
is_deeply [$collection->grep(sub {/[6-9]/})->all], [6, 7, 8, 9],
  'right all';
is_deeply [$collection->grep(sub { $_ > 5 })->all], [6, 7, 8, 9],
  'right all';
is_deeply [$collection->grep(sub { $_ < 5 })->all], [1, 2, 3, 4],
  'right all';
is_deeply [$collection->grep(sub { $_ == 5 })->all], [5], 'right all';
is_deeply [$collection->grep(sub { $_ < 1 })->all], [], 'no all';
is_deeply [$collection->grep(sub { $_ > 9 })->all], [], 'no all';

# map
$collection = array(1, 2, 3);
$collection->map(sub { $_ + 1 });
is_deeply [@$collection], [1, 2, 3], 'right all';
$collection->map(sub { shift() + 2 });
is_deeply [@$collection], [1, 2, 3], 'right all';

# reduce
$collection = array(1..5);
is $collection->reduce(sub { $_[0] + $_[1] }), 15, 'reduce works';

# sort
$collection = array(5,2,4,1,3);
is_deeply [$collection->sort(sub { $_[0] <=> $_[1] })->all], [1,2,3,4,5], 'sort works';

# sort_in_place
$collection = array(5,2,4,1,3);
$collection->sort_in_place(sub { $_[1] <=> $_[0] });
is_deeply [$collection->all], [5,4,3,2,1], 'sort works';
$collection->sort_in_place;
is_deeply [$collection->all], [1,2,3,4,5], 'sort works';

# shuffle
$collection = array(0 .. 10);
my $random = [$collection->shuffle->all];
is $collection->count, scalar @$random, 'same number of elements after shuffle';
isnt "@$collection", "@$random", 'different order';
is_deeply [array()->shuffle->all], [], 'no elements in shuffle';

# sort
$collection = array(2, 5, 4, 1);
is_deeply [$collection->sort->all], [1, 2, 4, 5], 'right order';
is_deeply [$collection->sort(sub { $_[1] cmp $_[0] })->all], [5, 4, 2, 1],
  'right order';
$collection = array(qw(Test perl Mojo));
is_deeply [$collection->sort(sub { uc(shift) cmp uc(shift) })->all],
  [qw(Mojo perl Test)], 'right order';
$collection = array();
is_deeply [$collection->sort->all], [], 'no all';
is_deeply [$collection->sort(sub { $_[1] cmp $_[0] })->all], [],
  'no all';

# uniq
$collection = array(1, 2, 3, 2, 3, 4, 5, 4);
is_deeply [$collection->uniq->all], [1, 2, 3, 4, 5], 'right result';
#is_deeply [$collection->uniq->reverse->uniq ], [5, 4, 3, 2, 1], 'right result';

# join
$collection = array(1, 2, 3);
is $collection->join,        '1,2,3',       'right result';
is $collection->join(''),    '123',       'right result';
is $collection->join('---'), '1---2---3', 'right result';
is $collection->join("\n"),  "1\n2\n3",   'right result';
#$collection = array(array(1, 2, 3), array(3, 2, 1));
#is $collection->join(''), "1\n2\n33\n2\n1", 'right result';
#is $collection->join('/')->url_escape, '1%2F2%2F3', 'right result';

# set
$ar = array(1,2,3);
$ar->set(0, 2);
is_deeply $ar, [2,2,3], 'set works';
$ar->set(5, 4);
is_deeply $ar, [2,2,3,undef,undef,4], 'set works';

# accessor set
$ar = array(1,2,3);
$ar->accessor(0, 2);
is_deeply $ar, [2,2,3], 'set works';
$ar->accessor(0, 2,9,9,9);
is_deeply $ar, [2,2,3], 'set works, extraneous args do nothing';
$ar->set(5, 4);
is_deeply $ar, [2,2,3,undef,undef,4], 'set works';


# delete
$ar = array(1,2,3);
$ar->delete(1);
is_deeply [$ar->all], [1,3], 'delete works';

# insert
$ar = array(1,2,3);
$ar->insert(1, 5);
is_deeply [$ar->all], [1,5,2,3], 'insert works';

# natatime
$ar = array(1,2,3,4,5,6,7,8,9,10,11);
my $it = $ar->natatime(5);
is_deeply [$it->()], [1,2,3,4,5], 'iterator returns correct';
is_deeply [$it->()], [6,7,8,9,10], 'iterator returns correct';
is_deeply [$it->()], [11], 'iterator returns correct';

$ar->natatime(11, sub { is_deeply([@_], [1..11], 'passing coderef works for natatime iterator')});

# shallow_clone
$ar = array(1,2,3);
my $foo = $ar->shallow_clone;
is_deeply([$ar->all], $foo, 'shallow clone is a clone');

# shallow_clone as a class method
$foo = Data::Perl::Collection::Array::shallow_clone([1,2,3]);
is_deeply($foo, [1,2,3], 'shallow clone is a clone as a class method');


isnt refaddr($ar), refaddr($foo), 'refaddr doesnt match on clone';


# flatten_deep
my $a = Data::Perl::Collection::Array->new(1, 2, [3, [4, [5] ] ], 6);
is_deeply [Data::Perl::Collection::Array->new(1, 2, [3, [4, [5] ] ], 6)->flatten_deep(2)], [1,2,3,4,[5], 6], 'flatten_deep(depth) works';
is_deeply [Data::Perl::Collection::Array->new(1, 2, [3, [4, [5] ] ], 6)->flatten_deep], [1,2,3,4,5,6], 'flatten_deep(depth) works';

# reverse
$a = array(1,2,3,4,5);
is_deeply([$a->reverse->all], [5,4,3,2,1], 'reverse works');

# print
stdout_is(sub { $a->print }, '1,2,3,4,5', 'print works');
stdout_is(sub { $a->print(*STDOUT, ':') }, '1:2:3:4:5', 'print works with join arg');
stderr_is(sub { $a->print(*STDERR) }, '1,2,3,4,5', 'print to different handle works');

=begin
# slice
$collection = array(1, 2, 3, 4, 5, 6, 7, 10, 9, 8);
is_deeply [$collection->slice(0)],  [1], 'right result';
is_deeply [$collection->slice(1)],  [2], 'right result';
is_deeply [$collection->slice(2)],  [3], 'right result';
is_deeply [$collection->slice(-1)], [8], 'right result';
is_deeply [$collection->slice(-3, -5)], [10, 6], 'right result';
is_deeply [$collection->slice(1, 2, 3)], [2, 3, 4], 'right result';
is_deeply [$collection->slice(6, 1, 4)], [7, 2, 5], 'right result';
is_deeply [$collection->slice(6 .. 9)], [7, 10, 9, 8], 'right result';

# pluck
$collection = array(array(1, 2, 3), array(4, 5, 6), array(7, 8, 9));
is $collection->pluck('reverse'), "3\n2\n1\n6\n5\n4\n9\n8\n7", 'right result';
is $collection->pluck(join => '-'), "1-2-3\n4-5-6\n7-8-9", 'right result';
=cut

# head
$collection = array(qw{a b c d e f});
is_deeply [$collection->head(0)->all], [], 'right result';
is_deeply [$collection->head(3)->all], [qw{a b c}], 'right result';
is_deeply [$collection->head(30)->all], [qw{a b c d e f}], 'right result';
is_deeply [$collection->head(-2)->all], [qw{a b c d}], 'right result';
is_deeply [$collection->head(-30)->all], [], 'right result';

# tail
is_deeply [$collection->tail(0)->all], [], 'right result';
is_deeply [$collection->tail(3)->all], [qw{d e f}], 'right result';
is_deeply [$collection->tail(30)->all], [qw{a b c d e f}], 'right result';
is_deeply [$collection->tail(-2)->all], [qw{c d e f}], 'right result';
is_deeply [$collection->tail(-30)->all], [], 'right result';

done_testing();
