use lib './lib';
use Acme::Syntax::Python;
from Data::Dumper import Dumper, DumperX;
import Test::More;

def test:
    ok(1, "Functions Working");

def test2: ok(1, "Single Line Functions Work Too");

def test3($var1):
    ok($var1, "Functions with Params works");

test();
test2();
test3(1);
done_testing();
