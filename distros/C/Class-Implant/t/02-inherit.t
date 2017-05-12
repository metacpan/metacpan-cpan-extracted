use Test::More qw(no_plan);

use File::Basename;
use lib dirname(__FILE__) . "/lib";
use Foo;
use Bar;

package Bar;
use Class::Implant;
implant qw(Foo), { inherit => 1 };

package main;
$bar = Bar->new;
use_ok("Bar", qw(hello world));
isa_ok($bar, "Foo");
