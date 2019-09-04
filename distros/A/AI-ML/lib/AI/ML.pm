# ABSTRACT: Perl interface to ML
use strict;
use warnings;
package AI::ML;

use parent 'DynaLoader';
use Math::Lapack;
bootstrap AI::ML;
#sub dl_load_flags { 1 }
1;
