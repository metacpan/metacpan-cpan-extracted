use Test::More;
use Acme;

ok(acme->is_acme);
ok(acme->is_perfect);
ok(acme->is_leon_brocard);

done_testing;
