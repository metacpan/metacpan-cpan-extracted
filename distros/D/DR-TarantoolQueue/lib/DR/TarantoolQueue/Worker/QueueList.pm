use utf8;
use strict;
use warnings;
package DR::TarantoolQueue::Worker::QueueList;
use Mouse::Role;

use Mouse::Util::TypeConstraints;
use Scalar::Util 'blessed';

subtype QueueList => as 'ArrayRef[DR::TarantoolQueue]';

coerce QueueList => from 'DR::TarantoolQueue', via { [ $_ ] };
coerce QueueList => from 'Undef', via { [] };
coerce QueueList =>
    from 'ArrayRef',
    via {
        require DR::TarantoolQueue;
        [ map { blessed $_ ? $_ : DR::TarantoolQueue->new($_) } @$_ ]
    };

no Mouse::Util::TypeConstraints;

has queue  =>
    isa         => 'QueueList',
    is          => 'ro',
    required    => 1,
    coerce      => 1;


1
;
