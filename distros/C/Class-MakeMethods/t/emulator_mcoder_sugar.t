BEGIN {
  eval q{ local $SIG{__DIE__}; require Test::More; 1 };
  if ( $@ ) {
    plan( tests => 1 );
    print "Skipping test on this platform (test requires Test::More).\n";
    ok( 1 );
    exit 0;
  }
}

use Class::MakeMethods::Emulator::mcoder ('-take_namespace');

# Test taken from mcoder 0.05:

package Legs;
sub run { "running" };
sub walk { "walking" };
use mcoder new => 'new';

package Man;

use mcoder::proxy legs => qw(run walk);
use mcoder::set qw(legs arms);
use mcoder::get qw(legs arms);
use mcoder new => 'new';

package testing;

use Test::More tests => 5;

my $l;
ok ($l=Legs->new(), "new legs");

my $m;
ok ($m=Man->new(), "new man");

$m->set_legs($l);
is($l, $m->legs, "man legs");

is($m->run, "running", "running");

is($m->walk, "walking", "walking");

