use strict;
use warnings;

use lib 't/lib';

use Test::More;

use Data::Transit;
use Point;
use PointWriteHandler;

# scalars
is_converted_to(undef, '{"~#\'":null}');
is_converted_to("foo", '{"~#\'":"foo"}');
is_converted_to(1, '{"~#\'":1}');

# arrays
is_converted_to([], '[]');
is_converted_to(["foo"], '["foo"]');

# maps
is_converted_to({}, "{}");
is_converted_to([{}], "[{}]");
is_converted_to({foo => 1}, '{"foo":1}');
is_converted_to([{foo => 1}, "bar"], '[{"foo":1},"bar"]');

# no caching
is_converted_to([{foo => 1}, {foo => 1}], '[{"foo":1},{"foo":1}]');
is_converted_to([{fooo => 1}, {fooo => 1}], '[{"fooo":1},{"fooo":1}]');

# custom handlers
is_converted_to(Point->new(2,3), '{"~#point":[2,3]}', {Point => PointWriteHandler->new()});
is_converted_to([Point->new(2,3), Point->new(3,4)], '[{"~#point":[2,3]},{"~#point":[3,4]}]', {Point => PointWriteHandler->new()});

done_testing();

sub is_converted_to {
	my ($data, $json, $handlers) = @_;
	my $output;
	open my ($output_fh), '>>', \$output;
	Data::Transit::writer("json-verbose", $output_fh, handlers => $handlers)->write($data);
	is($output, $json);
}
