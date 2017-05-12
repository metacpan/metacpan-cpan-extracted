use strict;
use warnings;
no warnings 'uninitialized';

use lib 't/lib';

use Data::MessagePack;
use Data::Transit;
use Point;
use PointWriteHandler;
use Test::More;

my $mp = Data::MessagePack->new();

# scalars
is_converted_to(undef, $mp->pack(["~#\'",undef]));
is_converted_to("foo", $mp->pack(["~#\'","foo"]));
is_converted_to(1, $mp->pack(["~#\'",1]));

# arrays
is_converted_to([], $mp->pack([]));
is_converted_to(["foo"], $mp->pack(["foo"]));

# # maps
is_converted_to({}, $mp->pack(["^ "]));
is_converted_to([{}], $mp->pack([["^ "]]));
is_converted_to({foo => 1}, $mp->pack(["^ ","foo",1]));
is_converted_to([{foo => 1}, "bar"], $mp->pack([["^ ","foo",1],"bar"]));

# caching
is_converted_to([{foo => 1}, {foo => 1}], $mp->pack([["^ ","foo",1],["^ ","foo",1]]));
is_converted_to([{fooo => 1}, {fooo => 1}], $mp->pack([["^ ","fooo",1],["^ ","^0",1]]));

# custom handlers
is_converted_to(Point->new(2,3), $mp->pack(["~#point","2,3"]), {Point => PointWriteHandler->new()});
is_converted_to([Point->new(2,3), Point->new(3,4)], $mp->pack([["~#point","2,3"],["^0","3,4"]]), {Point => PointWriteHandler->new()});

done_testing();

sub is_converted_to {
	my ($data, $message_pack, $handlers) = @_;
	my $output;
	open my ($output_fh), '>>', \$output;
	Data::Transit::writer("message-pack", $output_fh, handlers => $handlers)->write($data);
	is($output, $message_pack);
}
