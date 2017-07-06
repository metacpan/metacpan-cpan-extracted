#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Async::Stream::Item;

plan tests => 5;

my $i = 0;
my $item = Async::Stream::Item->new(
	$i++,
	sub {
		my $return_cb = shift;
		$return_cb->($i++)
	});

isa_ok($item,'Async::Stream::Item');

eval {Async::Stream::Item->new(1, 'bad argument')};
ok($@, "Constructor with bad argument");

is($item->val, 0, "Return item's value");

$item->next(sub {
		my $next_item = shift;
		is($next_item->val, 1, "Get next item");		
	});

eval {$item->next('bad argument')};
ok($@, "Method next with bad argument");

diag( "Testing Async::Stream $Async::Stream::Item::VERSION, Perl $], $^X" );
	