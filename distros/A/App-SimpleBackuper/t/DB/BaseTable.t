#!/usr/bin/perl
package App::SimpleBackuper::DB::BaseTable;

use strict;
use warnings;
use Test::Spec;
use App::SimpleBackuper::DB::BaseTable;

describe BaseTable => sub {
	it _find => sub {
		my($from, $to) = App::SimpleBackuper::DB::BaseTable::_find([], "a");
		is_deeply [$from, $to], [0, -1]; # Empty table finds 0, -1
		
		($from, $to) = App::SimpleBackuper::DB::BaseTable::_find(["b"], "a");
		is_deeply [$from, $to], [0, -1]; # Value lower than lowest found at 0, -1
		
		($from, $to) = App::SimpleBackuper::DB::BaseTable::_find(["b"], "c");
		is_deeply [$from, $to], [1, 0]; # Value higher than higher found at end, end-1
		
		my @dict = ("a".."z");
		for my $size (1 .. 100) {
			for my $max_val (1 .. $#dict) {
				my @arr = sort map {$dict[int rand $max_val]} 1 .. $size;
				my $val = $dict[int rand $max_val];
				
				my $ok_from = ((grep { $val le $arr[$_] } 0 .. $#arr)[0]) // $#arr + 1;
				my $ok_to = ((grep { $val ge $arr[$_] } 0 .. $#arr)[-1]) // $ok_from - 1;
				
				my $test = "search $val in array (".join(', ', map {"$_:$arr[$_]"} 0 .. $#arr).")";
				#print "\n$test\n";
				local $SIG{ALRM} = sub {die "$test is timed out"};
				alarm 2;
				($from, $to) = App::SimpleBackuper::DB::BaseTable::_find(\@arr, $val);
				alarm 0;
				
				fail "Failed $test: ($from, $to) != ($ok_from, $ok_to)" if $from != $ok_from or $to != $ok_to;
			}
		}
	};
	
	it upsert => sub {
		is_deeply App::SimpleBackuper::DB::BaseTable::upsert(bless([] => 'App::SimpleBackuper::DB::BaseTable'), 5, 5), [5];
		is_deeply App::SimpleBackuper::DB::BaseTable::upsert(bless([4] => 'App::SimpleBackuper::DB::BaseTable'), 5, 5), [4, 5];
		is_deeply App::SimpleBackuper::DB::BaseTable::upsert(bless([6] => 'App::SimpleBackuper::DB::BaseTable'), 5, 5), [5, 6];
		is_deeply App::SimpleBackuper::DB::BaseTable::upsert(bless([4, 5, 6] => 'App::SimpleBackuper::DB::BaseTable'), 5, 5), [4, 5, 6];
	};
	
	it delete => sub {
		is_deeply App::SimpleBackuper::DB::BaseTable::delete(bless([5] => 'App::SimpleBackuper::DB::BaseTable'), 5), [];
		is_deeply App::SimpleBackuper::DB::BaseTable::delete(bless([4,5] => 'App::SimpleBackuper::DB::BaseTable'), 5), [4];
		is_deeply App::SimpleBackuper::DB::BaseTable::delete(bless([5,6] => 'App::SimpleBackuper::DB::BaseTable'), 5), [6];
	};
};

runtests unless caller;
