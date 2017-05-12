use strictures 2;

use Test::InDistDir;
use Test::More;

use Dancer2::Plugin::LogContextual;

run();
done_testing;
exit;

sub run {
    TODO: {
        local $TODO = "tests need to be implemented";
        ok 0;
    }

    return;
}
