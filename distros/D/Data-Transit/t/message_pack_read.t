use strict;
use warnings;
no warnings 'uninitialized';

use lib 't/lib';

use Data::MessagePack;
use Data::Transit;
use Point;
use PointReadHandler;
use Test::More;

my $mp = Data::MessagePack->new();

# scalars
is_decoded_to($mp->pack(["~#\'",undef]), undef);
is_decoded_to($mp->pack(["~#\'","foo"]), "foo");
is_decoded_to($mp->pack(["~#\'",1]), 1);

# arrays
is_decoded_to($mp->pack([]), []);
is_decoded_to($mp->pack(["foo"]), ["foo"]);

# maps
is_decoded_to($mp->pack(["^ "]), {});
is_decoded_to($mp->pack([["^ "]]), [{}]);
is_decoded_to($mp->pack(["^ ","foo",1]), {foo => 1});
is_decoded_to($mp->pack([["^ ","foo",1],"bar"]), [{foo => 1}, "bar"]);
is_decoded_to($mp->pack(["^ ","foo",["^ ","bar",1]]), {foo => {bar => 1}});

# caching
is_decoded_to($mp->pack([["^ ","foo",1,"fooo",1],["^ ","foo",1,"^0",1]]),[{foo => 1, fooo => 1}, {foo => 1, fooo => 1}]);
is_decoded_to($mp->pack([["^ ","fooo",1],["^ ","^0",1]]), [{fooo => 1}, {fooo => 1}]);

# custom handlers
is_decoded_to($mp->pack(["~#point","2,3"]), Point->new(2,3), {point => PointReadHandler->new()});
is_decoded_to($mp->pack([["~#point","2,3"],["^0","3,4"]]), [Point->new(2,3), Point->new(3,4)], {point => PointReadHandler->new()});

done_testing();

sub is_decoded_to {
	my ($message_pack, $data, $handlers) = @_;
	my $reader = Data::Transit::reader("message-pack", handlers => $handlers);
	return is_deeply($reader->read($message_pack), $data);
}
