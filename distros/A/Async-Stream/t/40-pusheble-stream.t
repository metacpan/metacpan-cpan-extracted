#!perl -T
use 5.018;
use strict;
use warnings;
use Test::More;

use Async::Stream::Pushable;

plan tests => 3;

my $stream = Async::Stream::Pushable->new;

my @test_items = qw(1 2 3);

$stream->push(@test_items)->finalize;

$stream->to_arrayref(sub{is_deeply($_[0],[@test_items],"Push")});

eval { $stream->push('Push to finalized sream') };
ok($@, "Method push on finalized stream");

eval { $stream->finalize };
ok($@, "Method finalize on finalized stream");

diag( "Testing Async::Stream $Async::Stream::Item::VERSION, Perl $], $^X" );
	