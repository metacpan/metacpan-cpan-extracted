use Test::More qw(no_plan);

use File::Basename;
use lib dirname(__FILE__) . "/lib";
use Foo;
use Bar;

package Bar;
use Class::Implant;
implant qw(Foo);

package main;
can_ok(Bar,qw(hello world));
