use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Catalyst/Controller/HTML/FormFu.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/Form.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/FormConfig.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/FormMethod.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/MultiForm.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/MultiFormConfig.pm',
    'lib/Catalyst/Controller/HTML/FormFu/Action/MultiFormMethod.pm',
    'lib/Catalyst/Controller/HTML/FormFu/ActionBase/Form.pm',
    'lib/Catalyst/Helper/HTML/FormFu.pm',
    'lib/HTML/FormFu/Constraint/RequestToken.pm',
    'lib/HTML/FormFu/Element/RequestToken.pm',
    'lib/HTML/FormFu/Plugin/RequestToken.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
