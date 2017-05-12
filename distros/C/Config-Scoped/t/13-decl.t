# vim: cindent ft=perl sm sw=4

use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );

my $text = <<'eot';
{
    # defaults, lexically scoped
    community = public;
    variables = [ ifInOctets, ifOutOctets ];
    oids = {
	ifInOctets  = 1.3.6.1.2.1.2.2.1.10;
	ifOutOctets = 1.3.6.1.2.1.2.2.1.16;
    };

    %warnings parameter off;    ### allow parameter redefinition

    devices rtr001 {
	ports = [ 1, 2, 8, 9 ];
    }

    devices rtr007 {
	community = 'really top secret!';
	ports = [ 1, 2, 3, 4 ];
    }
}
eot

my $expected = {
    'devices' => {
        'rtr001' => {
            'ports'     => [ '1', '2', '8', '9' ],
            'community' => 'public',
            'variables' => [ 'ifInOctets', 'ifOutOctets' ],
            'oids'      => {
                'ifInOctets'  => '1.3.6.1.2.1.2.2.1.10',
                'ifOutOctets' => '1.3.6.1.2.1.2.2.1.16'
            }
        },
        'rtr007' => {
            'ports'     => [ '1', '2', '3', '4' ],
            'community' => 'really top secret!',
            'variables' => [ 'ifInOctets', 'ifOutOctets' ],
            'oids'      => {
                'ifInOctets'  => '1.3.6.1.2.1.2.2.1.10',
                'ifOutOctets' => '1.3.6.1.2.1.2.2.1.16'
            }
        }
    }
};


isa_ok( $p = Config::Scoped->new(), 'Config::Scoped' );
is_deeply( $p->parse( text => $text ), $expected, 'decl test' );

$text = <<'eot';
Foo BAR BaZ { LowerCase = 'Values dont convert' };
eot

$expected =
  { 'foo' => { 'bar' => { 'baz' => { 'lowercase' => 'Values dont convert' } } }
  };


$p = Config::Scoped->new(lc => 1);
is_deeply( $p->parse( text => $text ), $expected, 'lowercase conversion' );

