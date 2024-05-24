use v5.38;
use feature 'class';
no warnings 'experimental::class';

class Archive::SCS::DirIndex 0.03;

field $dirs  :param = [];
field $files :param = [];

method dirs () { $dirs->@* }
method files () { $files->@* }
