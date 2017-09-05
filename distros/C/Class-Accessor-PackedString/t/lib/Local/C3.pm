package # hide from PAUSE
    Local::C3;

BEGIN { require Local::C1; our @ISA = qw(Local::C1) }

use Class::Accessor::PackedString {
    accessors => {
        %Local::C1::HAS_PACKED,
        baz => "A2",
    },
};

1;
