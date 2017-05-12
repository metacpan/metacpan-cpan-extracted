package Data::Riak::Fast::Util::MapCount;

use Mouse;

extends 'Data::Riak::Fast::MapReduce::Phase::Map';

has '+language' => (
	default => 'erlang'
);

has '+function' => (
    default => 'map_object_value'
);

has '+arg' => (
    default => 'filter_notfound'
);

has '+module' => (
    default => 'riak_kv_mapreduce'
);

no Mouse;

1;

__END__
