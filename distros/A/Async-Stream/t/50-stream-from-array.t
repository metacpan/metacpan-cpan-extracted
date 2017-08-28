#!perl -T
use 5.018;
use strict;
use warnings;
use Test::More;

use Async::Stream::FromArray;

plan tests => 1;

my @test_items = qw(1 2 3);

my $stream = Async::Stream::FromArray->new(@test_items);

$stream->to_arrayref(sub{is_deeply($_[0],[@test_items],"Push")});

diag( "Testing Async::Stream $Async::Stream::Item::VERSION, Perl $], $^X" );
	