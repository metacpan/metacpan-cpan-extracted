use strict;
use warnings;
use Test::More;
use Command::Runner::LineBuffer;

my $buf = Command::Runner::LineBuffer->new(keep => 1);
$buf->add("foo\n");
$buf->add("bar\n");

my @line = $buf->get;
is_deeply \@line, [ "foo", "bar" ];

@line = $buf->get;
is @line, 0;

$buf->add("baz\n");
$buf->add("aaa");

@line = $buf->get;
is_deeply \@line, [ "baz" ];

@line = $buf->get;
is @line, 0;


@line = $buf->get(1);
is_deeply \@line, [ "aaa" ];

@line = $buf->get(1);
is @line, 0;

my $raw = $buf->raw;

is $raw, "foo\nbar\nbaz\naaa";

done_testing;
