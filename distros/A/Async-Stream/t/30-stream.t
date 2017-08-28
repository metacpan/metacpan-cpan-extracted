#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Async::Stream;
use Async::Stream::FromArray;

 plan tests => 28;


subtest 'Method new' => sub {
	plan tests => 2;
	my $i = 0;
	my $test_stream = Async::Stream->new(sub { $_[0]->($i++) });
	isa_ok($test_stream,'Async::Stream');

	eval {Async::Stream->new('bad argument')};
	ok($@, "Constructor with bad argument");
};


subtest 'Method iterator' => sub {
	plan tests => 1;
	
	my $i = 0;
	my $test_stream = Async::Stream->new(sub { $_[0]->($i++) });
	my $head = $test_stream->head;
	isa_ok($head,'Async::Stream::Item');
};


subtest 'Method iterator' => sub {
	plan tests => 1;
	
	my $i = 0;
	my $test_stream = Async::Stream->new(sub { $_[0]->($i++) });
	my $iterator = $test_stream->iterator;
	isa_ok($iterator,'Async::Stream::Iterator');
};


subtest 'Method to_arrayref' => sub {
	plan tests => 1;

	my @test_array = (1,2,3,4,5);
	my $array_to_compare = [@test_array];
	my $test_stream = Async::Stream->new(sub{$_[0]->(@test_array ? (shift @test_array):())});
	$test_stream->to_arrayref(sub {
			is_deeply($_[0], $array_to_compare, "Method to_arrayref");
		});
};



subtest 'Method min' => sub {
	plan tests => 3;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->min(sub{is($_[0],'1',"Method min 1")});

	@test_array = (3,2,1);
	$test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->min(sub{is($_[0],'1',"Method min 2")});

	eval {$test_stream->min('bad argument')};
	ok($@, "Method min with bad argument");
};


subtest 'Method max' => sub {
	plan tests => 3;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->max(sub{is($_[0],'3',"Method max 1")});

	@test_array = (3,2,1);
	$test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->max(sub{is($_[0],'3',"Method max 2")});

	eval {$test_stream->max('bad argument')};
	ok($@, "Method max with bad argument");
};


subtest 'Method reduce' => sub {
	plan tests => 2;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->sum(sub{is($_[0],'6',"Method sum")});

	eval {$test_stream->sum('bad argument')};
	ok($@, "Method sum with bad argument");
};


subtest 'Method reduce' => sub {
	plan tests => 4;
	
	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->reduce(sub{$a < $b ? $a : $b},sub{is($_[0],'1',"Method reduce find min")});
	$test_stream->reduce(sub{$a > $b ? $a : $b},sub{is($_[0],'3',"Method reduce find max")});
	$test_stream->reduce(sub{$a + $b},sub{is($_[0],'6',"Method reduce find sum")});

	eval {$test_stream->reduce('bad argument')};
	ok($@, "Method reduce with bad argument");
};


subtest 'Method grep' => sub {
	plan tests => 2;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->grep(sub{$_ != 2})
		->to_arrayref(sub{is_deeply($_[0],[grep {$_!=2} @test_array],"Method grep")});

	eval {$test_stream->grep('bad argument')};
	ok($@, "Method grep with bad argument");
};


subtest 'Method map' => sub {
	plan tests => 2;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->map(sub{$_ * 2})
		->to_arrayref(sub{is_deeply($_[0],[map {$_*2} @test_array],"Method map")});

	eval {$test_stream->transform('bad argument')};
	ok($@, "Method map with bad argument");
};

subtest 'Method transform' => sub {
	plan tests => 2;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);

	$test_stream
		->transform(sub{$_[0]->($_ * 2)})
		->to_arrayref(sub{is_deeply($_[0],[map {$_*2} @test_array],"Method transform")});

	eval {$test_stream->transform('bad argument')};
	ok($@, "Method transform with bad argument");
};


subtest 'Method count' => sub {
	plan tests => 2;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->count(sub{is($_[0],3,"Method count")});

	eval {$test_stream->count('bad argument')};
	ok($@, "Method count with bad argument");
};


subtest 'Method append' => sub {
	plan tests => 2;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	my $test_stream1 = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->append($test_stream1)
		->to_arrayref(sub {is_deeply($_[0], [@test_array,@test_array], "Method append")});

	eval {$test_stream->append('bad argument')};
	ok($@, "Method append with bad argument");
};


subtest 'Method skip' => sub {
	plan tests => 3;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->skip(1)
		->to_arrayref(sub {is_deeply($_[0], [2,3], "Method skip 1")});

	$test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->skip(0)
		->to_arrayref(sub {is_deeply($_[0], [@test_array], "Method skip 2")});

	$test_stream = Async::Stream::FromArray->new(@test_array);

	eval { $test_stream->skip(-1) };
	ok($@, "Method skip wrong argument");
};


subtest 'Method limit' => sub {
	plan tests => 3;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->limit(1)
		->to_arrayref(sub {is_deeply($_[0], [$test_array[0]], "Method limit 1")});

	$test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->limit(0)
		->to_arrayref(sub {is_deeply($_[0], [], "Method limit 2")});

	$test_stream = Async::Stream::FromArray->new(@test_array);
	eval { $test_stream->limit(-1) };
	ok($@, "Method limit wrong argument");
};


subtest 'Method sort' => sub {
	plan tests => 2;
	
	my @test_array = (3,1,2);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->sort(sub{$a <=> $b})
		->to_arrayref(sub{is_deeply($_[0],[sort {$a <=> $b} @test_array],"Method sort")});

	eval {$test_stream->sort('bad argument')};
	ok($@, "Method sort with bad argument");
};


subtest 'Method reverse' => sub {
	plan tests => 1;
	
	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->reverse
		->to_arrayref(sub{is_deeply($_[0],[reverse @test_array],"Method reverse")});
};


subtest 'Method cut_sort' => sub {
	plan tests => 5;

	my @test_array = (2,1,30,20,5,6);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream
		->cut_sort(sub {length($a) != length($b)},sub {$a <=> $b})
		->to_arrayref(sub{is_deeply($_[0],[1,2,20,30,5,6],"Method cut_sort 1")});

	@test_array = (2,1,30,20,5,6);
	$test_stream = Async::Stream::FromArray->new(@test_array);
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
};

subtest 'Method spray' => sub {
	plan tests => 2;

	my @test_array = (1,2,3,4);
	my $test_stream = Async::Stream::FromArray->new(@test_array);

	$test_stream
		->spray(sub{
				if ($_ % 2) {
					return ();
				} else {
					return (1 .. $_);
				}
			})
		->to_arrayref(sub{is_deeply($_[0],[1 .. 2, 1 .. 4],"Method spray")});

	eval {$test_stream->spray('bad argument')};
	ok($@, "Method spray with bad argument");
};

subtest 'Method peek' => sub {
	plan tests => 4;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->peek(sub{is($_,shift @test_array,"Method peek $_")})->to_arrayref(sub {});

	eval {$test_stream->peek('bad argument')};
	ok($@, "Method peek with bad argument");
};


subtest 'Method each' => sub {
	plan tests => 4;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->each(sub{is($_, shift @test_array,"Method each")});

	eval {$test_stream->each('bad argument')};
	ok($@, "Method each with bad argument");
};


subtest 'Prefetch' => sub {
	plan tests => 2;

	my $i = 0;
	my @queue;
	my $test_stream = Async::Stream->new(sub { 
		my $return_cb = shift;
		$i++;
		if ($i < 5) {
			if ($i % 2) {
				push @queue, $return_cb;
			} else {
				my $j = $i;
				shift(@queue)->($j);
				$return_cb->($j - 1);
			}
		} else {
			$return_cb->();
		}
	}, prefetch => 4);

	$test_stream->to_arrayref(sub{is_deeply($_[0],[2,4,3,1],"Generator with prefetch")});

	my @test_array = (1,2,3,4);
	$test_stream = Async::Stream::FromArray->new(@test_array);
	$i = 0;
	@queue = ();
	$test_stream->set_prefetch(2)->transform(sub {
			my $return_cb = shift;
			$i++;
			if ($i % 2) {
				push @queue, [$return_cb, $_];
			} else {
				my $tmp = shift @queue;
				$tmp->[0]->($tmp->[1]);
				$return_cb->($_);
			}
		}, 'async');

	$test_stream->to_arrayref(sub{is_deeply($_[0],[1,3,4,2],"set prefetch after init")});
};

subtest 'Merge_in' => sub {
	plan tests => 3;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	my $test_stream1 = Async::Stream::FromArray->new(@test_array);

	$test_stream->merge_in(sub{ $a <=> $b }, $test_stream1);

	$test_stream->to_arrayref(sub {
			is_deeply(
				$_[0], 
				[sort {$a <=> $b} (@test_array, @test_array)], 
				"Method merge_in",
			);
		});

	eval { $test_stream->merge_in('bad argument') };
	ok($@, "Static method merge_in with bad argument 1");

	eval { $test_stream->merge_in(sub{$a <=> $b},1) };
	ok($@, "Static method merge_in with bad argument 2");

};

subtest 'Branch_out' => sub {
	plan tests => 3;

	my @test_array = (1,2,3,4,5,6);
	my $test_stream = Async::Stream::FromArray->new(@test_array);

	my $odd_stream = $test_stream->branch_out(sub {$_ % 2});
	$odd_stream->to_arrayref(sub {is_deeply($_[0], [1, 3, 5], "Branch part of stream")});
	$test_stream->to_arrayref(sub {is_deeply($_[0], [2, 4, 6], "Main part of stream")});

	eval { $test_stream->branch_out('bad argument') };
	ok($@, "Static method branch with bad argument");
};

subtest 'Distinct' => sub {
	plan tests => 3;

	my @test_array = (1,1,2,2,3,3,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);

	$test_stream->distinct()->to_arrayref(sub {is_deeply($_[0], [1,2,3], "Distinct stream 1")});

	@test_array = (1,1,2,2,3,3,3);
	$test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->distinct(sub {int($_)})->to_arrayref(sub {is_deeply($_[0], [1,2,3], "Custom serialize for distinct stream")});

	@test_array = (1,1,2,2,3,3,3);
	$test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->distinct(sub {"single_key"})->to_arrayref(sub {is_deeply($_[0], [1], "Single key for distinct stream")});
};

subtest 'Any' => sub {
	plan tests => 2;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);

	$test_stream->any(sub{$_ == 2},sub{is($_[0], 2, "Any item is found")});

	$test_stream->any(sub{$_ == 4},sub{ok(!defined $_[0], "Any item isn't found")});
};

subtest 'Shift' => sub {
	plan tests => 5;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);

	$test_stream->shift(sub{is($_[0], 1, "Shift item 1")});
	$test_stream->shift(sub{is($_[0], 2, "Shift item 2")});
	$test_stream->shift(sub{is($_[0], 3, "Shift item 3")});
	$test_stream->count(sub{is($_[0],0,"Method count for shift")});

	eval { $test_stream->each('bad argument') };
	ok($@, "Method each with bad argument");
};

subtest 'Method shift_each' => sub {
	plan tests => 5;

	my @test_array = (1,2,3);
	my $test_stream = Async::Stream::FromArray->new(@test_array);
	$test_stream->shift_each(sub{is($_, shift @test_array,"Method shift_each")});
	$test_stream->count(sub{is($_[0],0,"Method count for shift_each")});

	eval { $test_stream->shift_each('bad argument') };
	ok($@, "Method each with bad argument");
};


diag( "Testing Async::Stream $Async::Stream::VERSION, Perl $], $^X" );
 	