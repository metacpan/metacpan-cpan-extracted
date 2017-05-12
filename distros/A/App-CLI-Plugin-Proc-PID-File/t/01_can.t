use strict;
use Test::More tests => 2;
use lib qw(t/lib);
use MyApp;

our($PF_RESULT, $PATH_RESULT);

{
    local *ARGV = [qw(can)];
    MyApp->dispatch;
}

ok($PF_RESULT == 1, "pf method test");
ok($PATH_RESULT == 1, "pf->path method test");

