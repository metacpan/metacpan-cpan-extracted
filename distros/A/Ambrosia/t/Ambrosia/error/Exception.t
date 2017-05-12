#!/usr/bin/perl
use strict;
use Test::More tests => 15;
use lib qw(lib t ..);

BEGIN
{
    use_ok( 'Ambrosia::error::Exceptions' ); #test #1
}

sub err1
{
    throw Ambrosia::error::Exception 'error in "err1()"';
}

sub err2
{
    eval
    {
        err1(1,2,3);
    };
    if ( $@ )
    {
        ok($@->message() eq 'error in "err1()"', 'ok 1');
        throw Ambrosia::error::Exception 'error in "err2()"', $@;
    }
}

sub err3
{
    eval
    {
        err2(4,5,6);
    };
    if ( $@ )
    {
        ok($@->message() =~ m/error in "err2\(\)"/s, 'ok 2');
        throw Ambrosia::error::Exception 'error in "err3()"', $@;
    }
}

eval
{
    err3(7,8,9);
};
if ( $@ )
{
    ok($@->message() =~ m/error in "err3\(\)"/s, 'ok 3');

    my $stack = $@->stack();
    ok($stack =~ m/err1\( 1, 2, 3 \)/s, 'stack ok 1');
    ok($stack =~ m/err2\( 4, 5, 6 \)/s, 'stack ok 2');
    ok($stack =~ m/err3\( 7, 8, 9 \)/s, 'stack ok 3');

    #print "ERROR:\n$stack\n";
}

#### Exception ####
eval
{
    throw Ambrosia::error::Exception('Exception');
};
if ( $@ )
{
    ok($@->code() eq Ambrosia::error::Exception::CODE(), 'Exception');
    ok($@->message() eq 'Exception', 'Exception');
}

#### BadUsage ####
eval
{
    throw Ambrosia::error::Exception::BadUsage('BadUsage');
};
if ( $@ )
{
    ok($@->code() eq Ambrosia::error::Exception::BadUsage::CODE(), 'BadUsage');
    ok($@->message() eq 'BadUsage', 'BadUsage');
}

#### BadParams ####
eval
{
    throw Ambrosia::error::Exception::BadParams('BadParams');
};
if ( $@ )
{
    ok($@->code() eq Ambrosia::error::Exception::BadParams::CODE(), 'BadParams');
    ok($@->message() eq 'BadParams', 'BadParams');
}

#### AccessDenied ####
eval
{
    throw Ambrosia::error::Exception::AccessDenied('AccessDenied');
};
if ( $@ )
{
    ok($@->code() eq Ambrosia::error::Exception::AccessDenied::CODE(), 'AccessDenied');
    ok($@->message() eq 'AccessDenied', 'AccessDenied');
}
