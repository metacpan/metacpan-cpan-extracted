package # hide from PAUSE
    Local::C2;

use Class::Accessor::Array::Glob {
    accessors => {
        foo => 0,
        bar => 1,
        baz => 2,

        qux => 3,
        quux => 4,
    },

    glob_attribute => 'quux',
};

1;
