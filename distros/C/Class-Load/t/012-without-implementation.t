use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

use Test::Needs 'Test::Without::Module';

Test::Without::Module->import(qw( Class::Load::PP Class::Load::XS ));

{
    like(
        exception { require Class::Load },
        qr!Can't locate Class.Load.PP\.pm in \@INC|Class.Load.PP\.pm did not return a true value!,
        'error when loading Class::Load and no implementation is available includes errors from trying to load modules'
    );
}

done_testing();
