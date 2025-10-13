use v5.38.2;

use strict;
use warnings;
use lib 'lib';

use Attribute::Validate;
use Types::Standard qw/Str Maybe/;

use Test::Exception;
use Test::More tests => 3;

{
    sub a:
    Requires(
            {strictness => 0},
            Str,
            Maybe[Str]
    ) 
    ($hola, $adios, @extra)  {
            ok 1, 'Got called a because the validation passed';
    }
    lives_ok {
        a("hola", undef, 0..10);
    } 'We can use modern signatures';

    dies_ok {
        a();
    } 'And will fail on error';
}
