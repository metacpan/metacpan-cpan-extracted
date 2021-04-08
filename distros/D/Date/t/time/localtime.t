use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[time-localtime]");

subtest 'list context' => sub {
    is_deeply([&localtime(1193525999)], [59, 59, 2, 28, 9, 2007, 0, 300, 1]);
    is_deeply([&localtime(1193526000)], [0, 0, 2, 28, 9, 2007, 0, 300, 0]);
    is_deeply([&localtime(1193529599)], [59, 59, 2, 28, 9, 2007, 0, 300, 0]);
    is_deeply([&localtime(1193529600)], [0, 0, 3, 28, 9, 2007, 0, 300, 0]);
};

subtest 'scalar context' => sub {
    like(scalar &localtime(1387727619), qr/^\S+ \S+ 22 19:53:39 2013$/);
};

done_testing();
