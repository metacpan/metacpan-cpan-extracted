package # hide from PAUSE
    Local::C1;

use Class::Accessor::Array::Glob {
    accessors => {
        foo => 0,
        bar => 1,
        baz => 2,
    },
};

1;
