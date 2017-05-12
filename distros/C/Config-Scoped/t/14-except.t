# vim: cindent ft=perl

use warnings;
use strict;
use Test::More tests => 17;

use File::Spec;

BEGIN { use_ok('Config::Scoped') }

my ( $p, $cfg );
eval { $p = Config::Scoped->new('odd number');};
isa_ok( $@, 'Config::Scoped::Error' );
like( $@, qr/odd number/i, "$@" );

eval { $p = Config::Scoped->new(file => \*STDIN);};
isa_ok( $@, 'Config::Scoped::Error' );
like( $@, qr/filehandle/i, "$@" );

eval { $p = Config::Scoped->new(config => 'foo')};
isa_ok( $@, 'Config::Scoped::Error' );
like( $@, qr/no hash ref/i, "$@" );

eval { $p = Config::Scoped->new(safe => 'foo')};
isa_ok( $@, 'Config::Scoped::Error' );
like( $@, qr/reval/i, "$@" );

$p = Config::Scoped->new;
eval { $cfg = $p->parse('odd number')};
isa_ok( $@, 'Config::Scoped::Error' );
like( $@, qr/odd number/i, "$@" );

$p = Config::Scoped->new;
eval { $cfg = $p->parse};
isa_ok( $@, 'Config::Scoped::Error' );
like( $@, qr/no text/i, "$@" );

$p = Config::Scoped->new(
    file => File::Spec->catfile( 't', 'files', 'null' ),
    warnings => { perm => 'off' } );
eval { $cfg = $p->parse};
isa_ok( $@, 'Config::Scoped::Error' );
like( $@, qr/is empty/i, "$@" );

$p = Config::Scoped->new(
    file => File::Spec->catfile( 't', 'files', 'increc1' ),
    warnings => { perm => 'off' } );
eval { $cfg = $p->parse; };
isa_ok( $@, 'Config::Scoped::Error' );
like( $@, qr/include loop/i, "$@" );
