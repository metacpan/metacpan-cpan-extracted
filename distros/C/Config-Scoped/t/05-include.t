# vim: cindent ft=perl

use warnings;
use strict;

use Test::More tests => 5;
use File::Spec;

BEGIN { use_ok('Config::Scoped') }
my $cfg_file = File::Spec->catfile( 't', 'files', 'include.cfg' );

my ( $p, $cfg );
my $text = "%include $cfg_file; foo{}";

isa_ok( $p = Config::Scoped->new( warnings => { perm => 'off' } ),
    'Config::Scoped' );
ok( eval { $cfg = $p->parse( text => $text ) }, 'include test' );

my $expected = {
    'foo' => {
        'scalar' => '1',
        'hash'   => {
            'c' => 'C',
            'a' => 'A',
            'b' => 'B'
        },
        'list' => [ 'a', 'b', 'c', 'd' ]
    }
};
is_deeply( $cfg, $expected, 'datastructure after include' );

$text = <<eot;
{
    %include $cfg_file
}
foo {}
eot

$expected = { foo => {} };

$p = Config::Scoped->new( warnings => { perm => 'off' } );
is_deeply( $p->parse( text => $text ), $expected, 'include in block' );
