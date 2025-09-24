use strict;
use warnings;
use lib 'lib';

use Attribute::Validate;
use Types::Standard qw/Str Int Maybe/;

use Test::Exception;
use Test::More tests => 7;

{

    sub a : Requires(Str) {
    }
    eval { a(undef); };
    unlike $@, qr@Attribute/Validate@,
      'Doesn\'t reference the module in the errors';
}

{

    sub b : Requires(Int, Maybe[Str], Str) {
        ok 'Called b';
    }
    lives_ok {
        b( 3, undef, "hola" );
    }
    'Proper calls work';
    dies_ok {
        b();
    }
    'Failures fail';
}

{
    dies_ok {
        eval 'my $a = sub : Requires(Int) { }; $a->(3);';
        if ($@) {
            die $@;
        }
    }
    'Anonymous subroutines do not work';
}

{
    sub c : Requires({strictness => 0}) {
        ok 1, 'Called c even when a not expected parameter has been passed';    
    }
    sub d : Requires({strictness => 1}) {
    }
    c(1);
    dies_ok {
        d(1);
    } 'Not called d because strictness is not disabled';
}
