use strict;
use warnings;
use Test::More 0.98;
use File::Path;

{
    package TestApp;
    use strict;
    use warnings;
    use Catalyst qw/File::RotateLogs/;
    __PACKAGE__->config(
        home => './t',
    );
    __PACKAGE__->setup();
}
use Catalyst::Test 'TestApp';
mkdir 't/root';

my($res, $c) = ctx_request('/');

isa_ok($c->log, 'Catalyst::Plugin::File::RotateLogs::Backend');
can_ok($c->log, 'debug');
can_ok($c->log, 'info');
can_ok($c->log, 'warn');
can_ok($c->log, 'fatal');

File::Path::rmtree(['t/root']);

done_testing;
