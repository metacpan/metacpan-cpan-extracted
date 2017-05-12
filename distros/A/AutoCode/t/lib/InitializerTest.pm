package InitializerTest;
use strict;

use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
our %conf;

BEGIN{ %conf=('$'=>[qw(aa bb)], '@'=>[qw(cc)]); }

use AutoCode::AccessorMaker (%conf, _initialize => '');
# use AutoCode::Initializer(%conf);

1;
