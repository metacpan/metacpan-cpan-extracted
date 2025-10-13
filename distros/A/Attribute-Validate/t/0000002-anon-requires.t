use strict;
use warnings;
use lib 'lib';

use Attribute::Validate qw/anon_requires/;
use Types::Standard qw/Str Int Maybe/;

use Test::Exception;
use Test::More tests => 6;

{

    my $a = anon_requires(sub {
    }, Str);
    eval { $a->(undef); };
    unlike $@, qr@Attribute/Validate@,
      'Doesn\'t reference the module in the errors';
}

{

    my $b = anon_requires(sub {
        ok 'Called b';
    }, Int, Maybe[Str], Str);
    lives_ok {
        $b->( 3, undef, "hola" );
    }
    'Proper calls work';
    dies_ok {
        $b->();
    }
    'Failures fail';
}

{
    my $c = anon_requires(sub {
        ok 1, 'Called c even when a not expected parameter has been passed';    
    }, {strictness => 0});
    my $d = anon_requires(sub {
    });
    $c->(1);
    dies_ok {
        $d->(1);
    } 'Not called d because strictness is not disabled';
}
