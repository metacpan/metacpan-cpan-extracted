use v5.28;
use warnings;
use Object::Pad 0.73;

class Archive::SCS::DirIndex 1.04;

field $dirs  :param = [];
field $files :param = [];

method dirs () { $dirs->@* }
method files () { $files->@* }

1;
