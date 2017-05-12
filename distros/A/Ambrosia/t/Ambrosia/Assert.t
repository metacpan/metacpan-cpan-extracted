#!/usr/bin/perl

{
    package test1;
    use lib qw(lib t ..);
    use Ambrosia::Assert test1 => 'nodebug';

    our $val = 0;

    sub sucess1
    {
        assert(sub {$val < 2}, 'valid condition');
        return 1;
    }

    sub sucess2
    {
        assert(sub {$val > 2}, 'invalid condition');
        return 1;
    }
}

{
    package test2;
    use lib qw(lib t ..);
    use Ambrosia::Assert test2 => 'debug';

    our $val = 0;

    sub sucess1
    {
        assert(sub {$val < 2}, 'valid condition');
        return 1;
    }

    sub sucess2
    {
        assert {$val > 2} 'invalid condition';
        return 1;
    }
}

use Test::More tests => 4;

BEGIN
{
    open(STDOUT, '>', "/dev/null") or die "Can't redirect STDOUT: $!";
    open(STDERR, ">&STDOUT")     or die "Can't dup STDOUT: $!";
}


ok(test1::sucess1() == 1, 'Debug is off. Test valid condition.');
ok(test1::sucess2() == 1, 'Debug is off. Test invalid condition.');

ok(test2::sucess1() == 1, 'Debug is on. Test valid condition.');

test2::sucess2();
END
{
    ok($?==42, 'Debug is on. Test invalid condition.');
    $? = 0 if $?==42;
}
