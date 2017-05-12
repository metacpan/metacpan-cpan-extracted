use strict;
use warnings;

use Test::More tests => 3;
use Acme::Can't;

my $mod = Some::Module->new();
is( $mod->can't('foo'), 0, 'module can foo' );
is( $mod->can't('bar'), 0, 'module can bar' );
is( $mod->can't('baz'), 1, 'module can NOT baz' );

package Some::Module;
sub new { return bless {}, 'Some::Module' }
sub foo {}
sub bar {}
