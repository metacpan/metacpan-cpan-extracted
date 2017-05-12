use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Module::Implementation 0.04 ();

use_ok 'Test::Class::Load';

diag(     'Using '
        . Module::Implementation::implementation_for('Class::Load')
        . ' implementation' );

done_testing;
