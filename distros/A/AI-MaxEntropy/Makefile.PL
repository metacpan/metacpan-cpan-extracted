use strict;
use warnings;

use inc::Module::Install;

name            'AI-MaxEntropy';
all_from        'lib/AI/MaxEntropy.pm';
license         'MIT';

requires        'Algorithm::LBFGS'      => '0.16';
requires        'YAML::Syck'            => '0.87';

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
