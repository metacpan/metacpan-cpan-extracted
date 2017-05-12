#!/usr/bin/perl -wT
use Test::More;
plan tests => 22;

use strict;
use warnings;

use CGI ();

{
    package TestAppProtectedRunmodes;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authentication;

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { user1 => '123' } ],
        STORE  => 'Store::Dummy',
    );
}

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $cgiapp = TestAppProtectedRunmodes->new;
my $authen = $cgiapp->authen;

ok($authen->protected_runmodes(qw(one)), 'we can register protected runmodes');
is_deeply( [$authen->protected_runmodes], [ 'one' ], 'verify that runmode is registered correctly' );

ok($authen->protected_runmodes(qw(two three)), 'we can register multiple protected runmodes');
is_deeply( [$authen->protected_runmodes], [ qw(one two three) ], 'verify that runmodes are cummulative' );

ok($authen->protected_runmodes(qr/^auth_/), 'we can register protected runmodes as a regexp');
is_deeply( [$authen->protected_runmodes], [ qw(one two three), qr/^auth_/ ], 'verify that this test was added' );

my $sub = sub { $_[0] eq 'sub' ? 1 : 0 };
ok($authen->protected_runmodes($sub), 'we can register protected runmodes as a subroutine reference');
is_deeply( [$authen->protected_runmodes], [ qw(one two three), qr/^auth_/, $sub ], 'verify that this test was added' );

# test valid runmodes
ok($authen->is_protected_runmode('one'), "Test 'is_protected_runmode' with valid string");
ok($authen->is_protected_runmode('two'), "Test 'is_protected_runmode' with valid string");
ok($authen->is_protected_runmode('three'), "Test 'is_protected_runmode' with valid string");
ok($authen->is_protected_runmode('auth_test'), "Test 'is_protected_runmode' with valid regexp test string");
ok($authen->is_protected_runmode('sub'), "Test 'is_protected_runmode' with valid subroutine test string");

# test invalid runmodes
ok(!$authen->is_protected_runmode('notone'), "Test 'is_protected_runmode' with invalid value");
ok(!$authen->is_protected_runmode('authtest'), "Test 'is_protected_runmode' with invalid value");
ok(!$authen->is_protected_runmode('subtest'), "Test 'is_protected_runmode' with invalid value");
ok(!$authen->is_protected_runmode(''), "Test 'is_protected_runmode' with empty string value");
ok(!$authen->is_protected_runmode( [] ), "Test 'is_protected_runmode' with invalid value (arrayref)");
ok(!$authen->is_protected_runmode( {} ), "Test 'is_protected_runmode' with invalid value (arrayref)");


ok($authen->protected_runmodes(':all'), 'we can mark all runmodes as protected');
is_deeply( [$authen->protected_runmodes], [ qw(one two three), qr/^auth_/, $sub, ':all' ], 'verify that this test was added' );
ok($authen->is_protected_runmode('anything_goes'), "Test 'is_protected_runmode' with any string");


