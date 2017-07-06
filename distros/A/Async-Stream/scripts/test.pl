#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

use Async::Stream;


# my $i = 0;
# my $stream = Async::Stream->new(sub {
# 		my $return_cb = shift;
# 		if ($i <= 20) {
# 			$return_cb->($i++);	
# 		} else {
# 			$return_cb->(undef);	
# 		}
# 	});

# #my $item = $stream->transform(sub {$_ * 2})->each(sub {print @_,"\n";});
# local $, = ' ';
# $stream->max( sub {print @_,"<- max\n";});

# $stream->count( sub {print @_,"<- count\n";});


# $stream = Async::Stream->new_from(3,1,2,8,5,220,171,2000,1,20,11,13,11);

# $stream->cut_sort(sub {length($a) != length($b)},sub {$a <=> $b})->peek(sub {print $_,"\n"})->to_arrayref(sub {print @{$_[0]},"\n"});


my @test_array = (1,2,3,4,5,6,7,8,9,10);
my $test_stream = Async::Stream->new_from(@test_array);
$test_stream->reduce(sub{$a < $b ? $a : $b},sub{print $_[0]});


