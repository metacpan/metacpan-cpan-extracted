# vim: cindent ft=perl sm sw=4

use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );
isa_ok( $p = Config::Scoped->new(), 'Config::Scoped' );

my $text = <<'eot';
a=b; #comment after parameter assignment
{ # comment in block
    b=c; #again after assignment
    # on an own line
}
hash = { # comment within a hash
    a=b; # after an assignment
    # on an own line
}
#macro foo bar; # after a pragma
#warnings on; #again after a pragma
foo { # in a declaration
    h = { # also here, eats the leading }
        }
}
eot

my $expected = {
    'foo' => {
        'hash' => { 'a' => 'b' },
        'h'    => {},
        'a'    => 'b'
    }
};

is_deeply( $p->parse( text => $text ), $expected, 'comment tests' );

