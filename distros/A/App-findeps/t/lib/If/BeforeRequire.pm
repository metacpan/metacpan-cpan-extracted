package If::BeforeRequire;

use strict;
use warnings;

use parent 'Module::Exists';

use Dummy;    # must be detected if this module was required

1;
