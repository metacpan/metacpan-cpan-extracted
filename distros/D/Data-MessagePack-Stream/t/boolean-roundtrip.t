use strict;
use warnings;
use Test::More;
use Data::MessagePack::Stream;

my $stream = Data::MessagePack::Stream->new;

$stream->feed("\xc3"); # the serialization of boolean "true"
$stream->feed("\xc2"); # the serialization of boolean "false"

ok $stream->next, 'next ok';
my $t = $stream->data;
is(0+$t, 1);
is("$t", "true");
is(ref($t), "Data::MessagePack::Boolean");

ok $stream->next, 'next ok';
$t = $stream->data;
is(0+$t, 0);
is("$t", "false");
is(ref($t), "Data::MessagePack::Boolean");

done_testing;
