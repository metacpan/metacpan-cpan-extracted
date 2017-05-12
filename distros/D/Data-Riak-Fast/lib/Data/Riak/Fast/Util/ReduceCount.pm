package Data::Riak::Fast::Util::ReduceCount;

use Mouse;

extends 'Data::Riak::Fast::MapReduce::Phase::Reduce';

has '+language' => (
    default => 'erlang'
);

has '+function' => (
    default => 'reduce_count_inputs'
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
