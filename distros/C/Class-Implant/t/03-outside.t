use Test::More qw(no_plan);

use File::Basename;
use lib dirname(__FILE__) . "/lib";
use Foo;
use Bar;

use Class::Implant;

implant qw(Foo), { into => "Bar" };

use_ok("Bar", qw(hello world));
