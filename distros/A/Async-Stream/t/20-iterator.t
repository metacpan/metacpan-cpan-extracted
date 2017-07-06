#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Async::Stream;
use Async::Stream::Iterator;

plan tests => 4;

my $i = 0;
my $test_stream = Async::Stream->new(sub {$_[0]->($i++)});
my $iterator = Async::Stream::Iterator->new($test_stream);

isa_ok($iterator,'Async::Stream::Iterator');

eval {Async::Stream::Iterator->new('bad argument')};
ok($@, "Constructor with bad argument");


$iterator->next(sub {
		my $next_val = shift;
		is($next_val, 0, "Get next item");
	});

eval {$iterator->next('bad argument')};
ok($@, "Method next with bad argument");

diag( "Testing Async::Stream $Async::Stream::Iterator::VERSION, Perl $], $^X" );
	