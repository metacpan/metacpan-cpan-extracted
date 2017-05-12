# vim: cindent ft=perl

use warnings;
use strict;
use Test::More tests => 10;
use File::Spec;

BEGIN { use_ok('Config::Scoped') }
my $p;

ok( $p = Config::Scoped->new(), 'Constructor');
isa_ok( $p, 'Config::Scoped' );
can_ok( $p, qw(parse warnings_on set_warnings));
ok( $p->parse( text => 'a=b;' ), 'basic parse test: string' );

ok(
    $p = Config::Scoped->new(
        file => File::Spec->catfile( 't', 'files', 'basic.cfg' ),
        warnings => 'off',
    ),
    'Constructor'
);
ok( $p->parse, 'basic parse test: file' );

ok( $p = EmptySubclassTest->new(), 'Constructor');
isa_ok( $p, 'EmptySubclassTest' );
can_ok( $p, qw(parse warnings_on set_warnings));

package EmptySubclassTest;
use base 'Config::Scoped';

