#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Capture::Tiny qw(capture);
use Cwd;

use Test::More;
use Test::TempDir::Tiny;

use lib qw(.);

main();

sub main {
    require_ok('bin/sshss') or BAIL_OUT();

    package App::SSH::SwitchShell;
    use subs 'getpwuid';

    package main;

    my $tmpdir = tempdir();

    my $shell_from_getpwuid = "$tmpdir/sh";
    open my $fh, '>', $shell_from_getpwuid;
    close $fh;

    chmod 0755, $shell_from_getpwuid;

    my @getpwuid_ref = ( 'username', 'x', 1000, 1000, q{}, q{}, q{}, '/tmp', $shell_from_getpwuid );

    *App::SSH::SwitchShell::getpwuid = sub {
        return @getpwuid_ref;
    };

    {
        local $ENV{SHELL} = '/bin/dummy';
        local @ARGV = ("$tmpdir/does_not_exist");
        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::configure_shell() };
        is( $result[0],  $shell_from_getpwuid,                              "'$tmpdir/does_not_exist' returns shell from getpwuid()" );
        is( $ENV{SHELL}, $shell_from_getpwuid,                              '... SHELL env variable is set correctly' );
        is( $stdout,     q{},                                               '... prints nothing to STDOUT' );
        is( $stderr,     "Shell '$tmpdir/does_not_exist' does not exist\n", '... prints that non existing shell does not exist to STDERR' );
    }

    my $shell_1 = "$tmpdir/testshell";
    open $fh, '>', $shell_1;
    close $fh;

    chmod 0644, $shell_1;
    {
        local $ENV{SHELL} = '/bin/dummy';
        local @ARGV = ($shell_1);
        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::configure_shell() };
        is( $result[0],  $shell_from_getpwuid,                   "'$shell_1' (not executable) returns shell from getpwuid()" );
        is( $ENV{SHELL}, $shell_from_getpwuid,                   '... SHELL env variable is set correctly' );
        is( $stdout,     q{},                                    '... prints nothing to STDOUT' );
        is( $stderr,     "Shell '$shell_1' is not executable\n", '... prints that shell is not executable to STDERR' );
    }

    chmod 0755, $shell_1;
  SKIP: {
        skip "File '$shell_1' is not executable - this OS seems to require more then chmod 0755" if !-x $shell_1;

        local $ENV{SHELL} = '/bin/dummy';
        local @ARGV = ($shell_1);
        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::configure_shell() };
        is( $result[0],  $shell_1, "'$shell_1' (executable) returns '$shell_1'" );
        is( $ENV{SHELL}, $shell_1, '... SHELL env variable is set correctly' );
        is( $stdout,     q{},      '... prints nothing to STDOUT' );
        is( $stderr,     q{},      '... prints nothing to STDERR' );
    }

    {
        my $cwd = cwd();
        chdir $tmpdir;

        local $ENV{SHELL} = '/bin/dummy';
        local @ARGV = ('testshell');
        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::configure_shell() };
        is( $result[0],  $shell_from_getpwuid,                          q{'testshell' returns shell from getpwuid()} );
        is( $ENV{SHELL}, $shell_from_getpwuid,                          '... SHELL env variable is set correctly' );
        is( $stdout,     q{},                                           '... prints nothing to STDOUT' );
        is( $stderr,     "Shell 'testshell' is not an absolute path\n", '... prints that shell is not absolute path to STDERR' );

        chdir $cwd;
    }

    chmod 0644, $shell_from_getpwuid;
    {
        local $ENV{SHELL} = '/bin/dummy';
        local @ARGV = ();
        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::configure_shell() };
        is( $result[0],  $shell_from_getpwuid, "no shell specified as argument returns '$shell_from_getpwuid' (not executable) from getpwuid()" );
        is( $ENV{SHELL}, $shell_from_getpwuid, '... SHELL env variable is set correctly' );
        is( $stdout,     q{},                  '... prints nothing to STDOUT' );
        is( $stderr,     q{},                  '... prints nothing to STDERR' );
    }

    chmod 0644, $shell_1;
    {
        local $ENV{SHELL} = '/bin/dummy';
        local @ARGV = ($shell_1);
        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::configure_shell() };
        is( $result[0],  $shell_from_getpwuid,                   "'$shell_1' (not executbale) returns '$shell_from_getpwuid' (not executable) from getpwuid()" );
        is( $ENV{SHELL}, $shell_from_getpwuid,                   '... SHELL env variable is set correctly' );
        is( $stdout,     q{},                                    '... prints nothing to STDOUT' );
        is( $stderr,     "Shell '$shell_1' is not executable\n", "... prints that '$shell_1' is not executable to STDERR" );
    }

    {
        my $cwd = cwd();
        chdir $tmpdir;

        local $ENV{SHELL} = '/bin/dummy';
        local @ARGV = ('testshell');
        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::configure_shell() };
        is( $result[0],  $shell_from_getpwuid,                          "'testshell' returns '$shell_from_getpwuid' (not executable) from getpwuid()" );
        is( $ENV{SHELL}, $shell_from_getpwuid,                          '... SHELL env variable is set correctly' );
        is( $stdout,     q{},                                           '... prints nothing to STDOUT' );
        is( $stderr,     "Shell 'testshell' is not an absolute path\n", '... prints not absolute path error message to STDERR' );

        chdir $cwd;
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
