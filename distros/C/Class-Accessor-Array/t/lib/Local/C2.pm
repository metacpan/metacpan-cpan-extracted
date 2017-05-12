package # hide from PAUSE
    Local::C2;

use Class::Accessor::Array {
    constructor => 'spawn',
    accessors => {
        foo => 0,
        bar => 1,
    },
};

1;
