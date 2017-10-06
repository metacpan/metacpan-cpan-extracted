#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Capture::Tiny qw(capture);
use Cwd;
use English qw( -no_match_vars );
use File::Spec;

use Test::More;
use Test::MockModule;
use Test::TempDir::Tiny;

use lib qw(.);

## no critic (RegularExpressions::RequireDotMatchAnything)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)
## no critic (Subroutines::RequireArgUnpacking)

main();

sub main {
    if ( !eval { my @x = getpwuid $EUID; 1 } ) {
        plan skip_all => 'The getpwuid function is unimplemented';
    }

    require_ok('bin/sshss') or BAIL_OUT();

    # If this exists (for whatever strange reason), remove it.
    delete $ENV{SSH_ORIGINAL_COMMAND};

    my $tmpdir = tempdir();

    # create a dummy "shell"
    my $shell = File::Spec->catfile( $tmpdir, 'shell.pl' );
    open my $fh, '>', $shell;
    close $fh;
    chmod 0755, $shell;

    # mock get_abs_script_basedir and _exec
    my $script_basedir;
    my @exec_args;
    my $sshss = Test::MockModule->new( 'App::SSH::SwitchShell', no_auto => 1 );
    $sshss->mock( get_abs_script_basedir => sub { return $script_basedir } );
    $sshss->mock( _exec => sub (&@) { @exec_args = @_; return; } );

    # Change to a different tempdir to see if the chdir functionality works
    my $basedir = tempdir();
    chdir $basedir;

    note('login shell, script inside .ssh dir');
    {
        local $ENV{HOME}  = '/home/dummy';
        local $ENV{SHELL} = '/bin/dummy';

        $script_basedir = File::Spec->catdir( $tmpdir, '.ssh' );
        mkdir $script_basedir;

        local @ARGV = ($shell);

        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::main() };
        is( $result[0],  undef,   'main() returns undef (because we mocked _exec)' );
        is( $stdout,     q{},     '... prints nothing to STDOUT' );
        is( $stderr,     q{},     '... prints nothing to STDERR' );
        is( $ENV{HOME},  $tmpdir, '... HOME environment variable is correctly set' );
        is( $ENV{SHELL}, $shell,  '... SHELL environment variable is correctly set' );
        is( cwd(),       $tmpdir, '... cwd is correctly changed' );
        my $exec_file = ( shift @exec_args )->();
        is( $exec_file, $shell, '... the correct shell was run' );
        is_deeply( \@exec_args, [qw(-shell.pl)], '... with the correct arguments' );

        chdir $basedir;
    }

    note(q{run 'perl -v', script inside .ssh dir});
    {
        local $ENV{HOME}                 = '/home/dummy';
        local $ENV{SHELL}                = '/bin/dummy';
        local $ENV{SSH_ORIGINAL_COMMAND} = "$EXECUTABLE_NAME -v";

        $script_basedir = File::Spec->catdir( $tmpdir, '.ssh' );

        local @ARGV = ($shell);

        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::main() };
        is( $result[0],  undef,   'main() returns undef (because we mocked _exec)' );
        is( $stdout,     q{},     '... prints nothing to STDOUT (because we mocked _exec)' );
        is( $stderr,     q{},     '... prints nothing to STDERR' );
        is( $ENV{HOME},  $tmpdir, '... HOME environment variable is correctly set' );
        is( $ENV{SHELL}, $shell,  '... SHELL environment variable is correctly set' );
        is( cwd(),       $tmpdir, '... cwd is correctly changed' );
        my $exec_file = ( shift @exec_args )->();
        is( $exec_file, $shell, '... the correct shell was run' );
        is_deeply( \@exec_args, [ 'shell.pl', '-c', "$EXECUTABLE_NAME -v" ], '... with the correct arguments' );

        chdir $basedir;
    }

    note('login shell, script in "invalid directory"');
    {
        local $ENV{HOME}  = '/home/dummy';
        local $ENV{SHELL} = '/bin/dummy';

        my $not_existing_home = File::Spec->catdir( $tmpdir, 'dir_does_not_exist' );
        $script_basedir = File::Spec->catdir( $not_existing_home, '.ssh' );

        local @ARGV = ($shell);

        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::main() };
        is( $result[0], undef, 'main() returns undef (because we mocked _exec)' );
        is( $stdout,    q{},   '... prints nothing to STDOUT' );
        like( $stderr, qr{^Could not chdir to home '$not_existing_home': }, '... prints that chdir() failed to STDERR' );
        is( $ENV{HOME},  $not_existing_home, '... HOME environment variable is correctly set' );
        is( $ENV{SHELL}, $shell,             '... SHELL environment variable is correctly set' );
        is( cwd(),       $basedir,           '... cwd is not changed because dir does not exist' );
        my $exec_file = ( shift @exec_args )->();
        is( $exec_file, $shell, '... the correct shell was run' );
        is_deeply( \@exec_args, [qw(-shell.pl)], '... with the correct arguments' );

        chdir $basedir;
    }

    note('login shell, script in ~/.ssh');
    {
        local $ENV{HOME}  = $tmpdir;
        local $ENV{SHELL} = '/bin/dummy';

        chdir $tmpdir;
        $script_basedir = File::Spec->catdir( $tmpdir, '.ssh' );

        local @ARGV = ($shell);

        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::main() };
        is( $result[0],  undef,   'main() returns undef (because we mocked _exec)' );
        is( $stdout,     q{},     '... prints nothing to STDOUT' );
        is( $stderr,     q{},     '... prints nothing to STDERR' );
        is( $ENV{HOME},  $tmpdir, '... HOME environment variable is correctly set' );
        is( $ENV{SHELL}, $shell,  '... SHELL environment variable is correctly set' );
        is( cwd(),       $tmpdir, '... cwd is correctly changed' );
        my $exec_file = ( shift @exec_args )->();
        is( $exec_file, $shell, '... the correct shell was run' );
        is_deeply( \@exec_args, [qw(-shell.pl)], '... with the correct arguments' );

        chdir $basedir;
    }

    note('login shell, HOME and script basedir are reached through symlink');
    {
        my $homedir = File::Spec->catdir( $tmpdir, 'HOMEDIR' );
        mkdir $homedir;

        my $homelnk = File::Spec->catfile( $tmpdir, 'HOMELINK' );
        symlink 'HOMEDIR', $homelnk;

        $script_basedir = File::Spec->catdir( $homelnk, 'abc' );
        mkdir $script_basedir;
        $script_basedir = File::Spec->catdir( $script_basedir, '.ssh' );
        mkdir $script_basedir;

        local $ENV{HOME}  = $homelnk;
        local $ENV{SHELL} = '/bin/dummy';

        local @ARGV = ($shell);

        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::main() };
        is( $result[0], undef, 'main() returns undef (because we mocked _exec)' );
        is( $stdout,    q{},   '... prints nothing to STDOUT' );
        is( $stderr,    q{},   '... prints nothing to STDERR' );
        is( $ENV{HOME}, File::Spec->catdir( $homelnk, 'abc' ), '... HOME environment variable is correctly set' );
        is( $ENV{SHELL}, $shell, '... SHELL environment variable is correctly set' );
        is( cwd(), File::Spec->catdir( $homedir, 'abc' ), '... cwd is correctly changed' );
        my $exec_file = ( shift @exec_args )->();
        is( $exec_file, $shell, '... the correct shell was run' );
        is_deeply( \@exec_args, [qw(-shell.pl)], '... with the correct arguments' );

        chdir $basedir;
    }

    note('login shell, HOME is reached through symlink, script basedir is not');
    {
        my $homedir = File::Spec->catdir( $tmpdir, 'HOMEDIR' );
        my $homelnk = File::Spec->catfile( $tmpdir, 'HOMELINK' );

        local $ENV{HOME}  = $homelnk;
        local $ENV{SHELL} = '/bin/dummy';

        $script_basedir = File::Spec->catdir( $homedir, 'abc', '.ssh' );

        local @ARGV = ($shell);

        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::main() };
        is( $result[0], undef, 'main() returns undef (because we mocked _exec)' );
        is( $stdout,    q{},   '... prints nothing to STDOUT' );
        is( $stderr,    q{},   '... prints nothing to STDERR' );
        is( $ENV{HOME}, File::Spec->catdir( $homedir, 'abc' ), '... HOME environment variable is correctly set' );
        is( $ENV{SHELL}, $shell, '... SHELL environment variable is correctly set' );
        is( cwd(), File::Spec->catdir( $homedir, 'abc' ), '... cwd is correctly changed' );
        my $exec_file = ( shift @exec_args )->();
        is( $exec_file, $shell, '... the correct shell was run' );
        is_deeply( \@exec_args, [qw(-shell.pl)], '... with the correct arguments' );

        chdir $basedir;
    }

    note('login shell, script basedir is reached through symlink, HOME is not');
    {
        my $homedir = File::Spec->catdir( $tmpdir, 'HOMEDIR' );
        my $homelnk = File::Spec->catfile( $tmpdir, 'HOMELINK' );

        local $ENV{HOME}  = $homedir;
        local $ENV{SHELL} = '/bin/dummy';

        $script_basedir = File::Spec->catdir( $homelnk, 'abc', '.ssh' );

        local @ARGV = ($shell);

        my ( $stdout, $stderr, @result ) = capture { App::SSH::SwitchShell::main() };
        is( $result[0], undef, 'main() returns undef (because we mocked _exec)' );
        is( $stdout,    q{},   '... prints nothing to STDOUT' );
        is( $stderr,    q{},   '... prints nothing to STDERR' );
        is( $ENV{HOME}, File::Spec->catdir( $homelnk, 'abc' ), '... HOME environment variable is correctly set' );
        is( $ENV{SHELL}, $shell, '... SHELL environment variable is correctly set' );
        is( cwd(), File::Spec->catdir( $homedir, 'abc' ), '... cwd is correctly changed' );
        my $exec_file = ( shift @exec_args )->();
        is( $exec_file, $shell, '... the correct shell was run' );
        is_deeply( \@exec_args, [qw(-shell.pl)], '... with the correct arguments' );

        chdir $basedir;
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
