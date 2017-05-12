package CMMITTestClass;

use strict;
use warnings;

use Class::Mockable methods => { _test_method => 'test_method' };

sub test_method { return "called test_method on $_[0] with [".join(', ', @_[1 .. $#_])."]\n"; }

1;
