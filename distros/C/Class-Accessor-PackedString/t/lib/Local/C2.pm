package # hide from PAUSE
    Local::C2;

use Class::Accessor::PackedString {
    constructor => 'spawn',
    accessors => {
        foo => "f",
        bar => "c",
    },
};

1;
