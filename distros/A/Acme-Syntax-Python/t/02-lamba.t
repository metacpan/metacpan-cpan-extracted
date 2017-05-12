use lib './lib';
use Acme::Syntax::Python;
import Test::More;

my $sub = lambda: (2 * 10);

my $sub2 = lambda($var1): ($var1 * 5);

ok($sub->() == 20, "Lambas Work!");
ok($sub2->(2) == 10, "Lambda with Params!");

done_testing;
