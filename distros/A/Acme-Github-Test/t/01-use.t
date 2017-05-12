#!perl -T

use Test::More tests => 6;
use Acme::Github::Test;

my $acme = Acme::Github::Test->new( 23 => 'skidoo' );
isa_ok($acme, 'Acme::Github::Test', 'object');

ok($acme->freep, 'freep() returns true');
ok($acme->frobulate, 'frobulate() returns true');
is($acme->frobulate, 42, 'frobulate defaults to 42');
is($acme->frobulate('barbaz'), 'barbaz', 'frobulate correctly returns passed value');
is($acme->frobulate(0), 0, 'frobulate correctly uses a false value');



