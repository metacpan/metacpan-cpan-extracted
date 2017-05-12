# https://github.com/typester/Data-MessagePack-Stream/issues/3

use strict;
use warnings;
use Test::More;

plan tests => 1;

use Data::MessagePack::Stream;
use Data::MessagePack;

my $orig = [0,0,200,''];

my $packed = Data::MessagePack->new->pack($orig);

my $unpacker = Data::MessagePack::Stream->new;
$unpacker->feed($packed);
if ($unpacker->next) {
    is_deeply($unpacker->data, $orig);
}

