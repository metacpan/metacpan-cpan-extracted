use strict;
use warnings;

use inc::Module::Install;

name            'Algorithm-LBFGS';
all_from        'lib/Algorithm/LBFGS.pm';
license         'MIT';

include         'Test::Builder';
include         'Test::Builder::Module';
include         'Test::More';
include         'Test::Number::Delta';

auto_install;

WriteMakefile(
    LIBS              => ['-lm'],
    INC               => '-I.',
    OBJECT            => '$(O_FILES)'
);


