use lib './lib';
use Acme::Syntax::Python;
import Test::More;

def test($var1):
    if ($var1 == 1):
        ok(1, "If == 1");
    elif ($var1 == 2):
        ok(1, "If == 2");
    else:
        ok(1, "If doesn't equal 1 or 2");

test(1);
test(2);
test(3);

done_testing();
