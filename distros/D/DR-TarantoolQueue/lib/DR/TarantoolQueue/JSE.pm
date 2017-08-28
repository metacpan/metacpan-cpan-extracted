package DR::TarantoolQueue::JSE;
use Mouse::Role;
use utf8;
use strict;
use warnings;
use DR::TarantoolQueue::PackUnpack;


has jse => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => sub {
        DR::TarantoolQueue::PackUnpack->new
    }
);





1;
