#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Async::Stream;

 plan tests => 50;

### Method new ###
my $i = 0;
my $test_stream = Async::Stream->new(sub { $_[0]->($i++) });
isa_ok($test_stream,'Async::Stream');

eval {Async::Stream->new('bad argument')};
ok($@, "Constructor with bad argument");

### Method head ###
my $head = $test_stream->head;
isa_ok($head,'Async::Stream::Item');

### Method iterator ###
my $iterator = $test_stream->iterator;
isa_ok($iterator,'Async::Stream::Iterator');

### Method to_arrayref ###
my @test_array = (1,2,3,4,5);
my $array_to_compare = [@test_array];
$test_stream = Async::Stream->new(sub{$_[0]->(@test_array ? (shift @test_array):())});
$test_stream->to_arrayref(sub {
		is_deeply($_[0], $array_to_compare, "Method to_arrayref");
	});

### Method new_from ###
@test_array = (1,2,3,4,5);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->to_arrayref(sub {
		is_deeply($_[0], \@test_array, "Method new_from");
	});

eval {$test_stream->to_arrayref('bad argument')};
ok($@, "Method new_from with bad argument");

### Method min ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->min(sub{is($_[0],'1',"Method min 1")});

@test_array = (3,2,1);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->min(sub{is($_[0],'1',"Method min 2")});

eval {$test_stream->min('bad argument')};
ok($@, "Method min with bad argument");

### Method max ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->max(sub{is($_[0],'3',"Method max 1")});

@test_array = (3,2,1);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->max(sub{is($_[0],'3',"Method max 2")});

eval {$test_stream->max('bad argument')};
ok($@, "Method max with bad argument");

### Method sum ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->sum(sub{is($_[0],'6',"Method sum")});

eval {$test_stream->sum('bad argument')};
ok($@, "Method sum with bad argument");

### Method reduce ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->reduce(sub{$a < $b ? $a : $b},sub{is($_[0],'1',"Method reduce find min")});
$test_stream->reduce(sub{$a > $b ? $a : $b},sub{is($_[0],'3',"Method reduce find max")});
$test_stream->reduce(sub{$a + $b},sub{is($_[0],'6',"Method reduce find sum")});

eval {$test_stream->reduce('bad argument')};
ok($@, "Method reduce with bad argument");

### Method filter ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->filter(sub{$_ != 2})
	->to_arrayref(sub{is_deeply($_[0],[grep {$_!=2} @test_array],"Method filter")});

eval {$test_stream->filter('bad argument')};
ok($@, "Method filter with bad argument");

### Method smap ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->smap(sub{$_ * 2})
	->to_arrayref(sub{is_deeply($_[0],[map {$_*2} @test_array],"Method smap")});

eval {$test_stream->smap('bad argument')};
ok($@, "Method smap with bad argument");

### Method transform ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->transform(sub{$_[0]->($_ * 2)})
	->to_arrayref(sub{is_deeply($_[0],[map {$_*2} @test_array],"Method transform")});

eval {$test_stream->transform('bad argument')};
ok($@, "Method transform with bad argument");

### Method count ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->count(sub{is($_[0],3,"Method count")});

eval {$test_stream->count('bad argument')};
ok($@, "Method count with bad argument");

### Method concat ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->concat($test_stream)
	->to_arrayref(sub {is_deeply($_[0], [@test_array,@test_array], "Method concat")});

eval {$test_stream->concat('bad argument')};
ok($@, "Method concat with bad argument");

### Method skip ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->skip(1)
	->to_arrayref(sub {is_deeply($_[0], [2,3], "Method skip 1")});

$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->skip(0)
	->to_arrayref(sub {is_deeply($_[0], [@test_array], "Method skip 2")});

$test_stream = Async::Stream->new_from(@test_array);

eval { $test_stream->skip(-1) };
ok($@, "Method skip wrong argument");

### Method limit ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->limit(1)
	->to_arrayref(sub {is_deeply($_[0], [$test_array[0]], "Method limit 1")});

$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->limit(0)
	->to_arrayref(sub {is_deeply($_[0], [], "Method limit 2")});

$test_stream = Async::Stream->new_from(@test_array);
eval { $test_stream->limit(-1) };
ok($@, "Method limit wrong argument");

### Method sort ###
@test_array = (3,1,2);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->sort(sub{$a <=> $b})
	->to_arrayref(sub{is_deeply($_[0],[sort {$a <=> $b} @test_array],"Method sort")});

eval {$test_stream->sort('bad argument')};
ok($@, "Method sort with bad argument");

### Method cut_sort ###
@test_array = (2,1,30,20,5,6);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->cut_sort(sub {length($a) != length($b)},sub {$a <=> $b})
	->to_arrayref(sub{is_deeply($_[0],[1,2,20,30,5,6],"Method cut_sort 1")});

@test_array = (2,1,30,20,5,6);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream
	->limit(0)
	->cut_sort(sub {length($a) != length($b)},sub {$a <=> $b})
	->to_arrayref(sub{is_deeply($_[0],[],"Method cut_sort 2")});

eval {$test_stream->cut_sort('bad argument', sub{})};
ok($@, "Method cut_sort with bad argument 1");

eval {$test_stream->cut_sort(sub{}, 'bad argument')};
ok($@, "Method cut_sort with bad argument 2");

eval {$test_stream->cut_sort('bad argument','bad argument')};
ok($@, "Method cut_sort with bad argument 3");

### Method peek ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->peek(sub{is($_,shift @test_array,"Method peek")})->to_arrayref(sub {});

eval {$test_stream->peek('bad argument')};
ok($@, "Method peek with bad argument");

### Method each ###
@test_array = (1,2,3);
$test_stream = Async::Stream->new_from(@test_array);
$test_stream->each(sub{is(shift,shift @test_array,"Method each")});

eval {$test_stream->each('bad argument')};
ok($@, "Method each with bad argument");



diag( "Testing Async::Stream $Async::Stream::VERSION, Perl $], $^X" );
 	