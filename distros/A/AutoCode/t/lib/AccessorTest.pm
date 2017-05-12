package AccessorTest;
use strict;

use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
our %conf;

BEGIN{ %conf=('$'=>[qw(aa bb)], '@'=>'cc', '%'=>['ee']); }
use AutoCode::AccessorMaker (%conf);

1;
