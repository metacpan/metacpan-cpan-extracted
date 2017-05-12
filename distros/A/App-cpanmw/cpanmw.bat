@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!perl
#line 15
use 5.008001;
use strict;
use File::Which;

our $VERSION = '0.03';
$App::cpanmw::VERSION = $VERSION;

my ( $IS_WIN32, $IS_WIN60 );

# Conditional load
BEGIN {
    $IS_WIN32 = $^O eq 'MSWin32';
    $IS_WIN60 = $IS_WIN32 && $ENV{HOMEPATH} && $ENV{HOMEPATH} =~ /^\\Users\\/;
    if ($IS_WIN32) {
        require Win32::Console::ANSI;
        Win32::Console::ANSI->import();
    }
    use Term::ANSIColor;
}

use FindBin;
$| = 1;

# HACK
my $cpanm_file = File::Which::which 'cpanm';
$cpanm_file =~ s/\\/\//g;

# override system & symlink for App::cpanminus::script
if ($IS_WIN32) {
    no warnings 'once';
    *App::cpanminus::script::system = sub {
        my $cmd = shift;
        $cmd .= ' 2>&1';
        CORE::system $cmd;
    };
    # hack for making 'latest-build' as symlink
    # Windows6.x can make symlink via 'mklink' utility
    if ($IS_WIN60) {
        *CORE::GLOBAL::symlink = sub {
            my ( $org, $dest ) = @_;
            return 1 unless ( $org || $dest );
            my $flag = '';
            if ( -d $org ) {
                $flag = '/J';
                rmdir $dest;
            }
            !system qq{mklink $flag "$dest" "$org" >NUL};
        };
    }
}

#== customizing cpanm!!

eval qq{require '$cpanm_file'};
my $app = App::cpanminus::script->new;

my $org_m;
{
    no strict 'refs';
    $org_m = +{
        map { $_ => \&{ "App::cpanminus::script::" . $_ } }
#            qw/diag diag_ok diag_fail run_timeout/ };
            qw/_diag run_timeout/
    };
}

## Hooks for Win6.0
if ($IS_WIN60) {
# hack: kill -9,$pid[perlport#kill@win32] does not work on perl-5.18.
#       use 'taskkill' instead.
    *_kill_group = sub {
        my ($pid) = @_;
        if ( $] >= 5.020 ) {    # bug is resolved on perl-5.20
            CORE::kill '-TERM', $pid;
        }
        else {                  # but collapsed on perl-5.18
            system 'taskkill /F /T /PID ' . $pid . ' >NUL 2>&1';
        }
    };
# hook for run_timeout
# alarm() works on Windows, but need hack for stability.
    *App::cpanminus::script::run_timeout = sub {
### run_timeout_arg[cmd]: $_[1]
        my ( $self, $cmd, $timeout ) = @_;
        return $self->run($cmd) if $self->{verbose} || !$timeout;
        $cmd = $self->shell_quote(@$cmd) if ref $cmd eq 'ARRAY';
        $cmd .= ' >> ' . $self->shell_quote( $self->{log} ) . ' 2>&1';
        my ( $pid, $exit_code );
        local $SIG{ALRM} = sub {
            CORE::die "alarm\n";
        };
        eval {
            $pid = system 1, $cmd;
            alarm $timeout;
            waitpid $pid, 0;
            $exit_code = $?;
            alarm 0;
        };
        if ( $@ && $@ eq "alarm\n" ) {
            $self->diag_fail(
                "Timed out (> ${timeout}s). Use --verbose to retry.");
            _kill_group($pid);
            waitpid $pid, 0;
            return;
        }
        return !$exit_code;
    };
}
## GLOBAL hook
{
    *App::cpanminus::script::_diag = sub {
        my $caller = ( caller(1) )[3];
        goto &{ $org_m->{_diag} }
            unless $caller =~ s/^App::cpanminus::script:://;
### $caller
        my @arg = @_;
        if ( $caller eq 'diag_ok' ) {
            $arg[1] = colored( $arg[1], 'bold green' );
        }
        elsif ( $caller eq 'diag_fail' ) {
            $arg[1] = colored( $arg[1], 'bold red' );
        }
        elsif ( $caller eq 'diag_progress' ) {
            $arg[1]
                =~ s/^(Fetching|Configuring|Building(?: and testing)?)/colored($1,'cyan')/e;
        }
        elsif ( $arg[1] =~ /^-->/ ) {
            $arg[1]
                =~ s/(?<=--> Working on )(\S+)/colored( $1, 'bold yellow' )/e;
        }
        elsif ( $arg[1] =~ /^==>/ ) {
            $arg[1] =~ s/(Found dependencies)/colored($1,'bold magenta')/e;
        }
        elsif ( $arg[1] =~ s/^(Successfully \S*)/colored($1,'bold green')/e )
        {
        }
        elsif ( $_[0]->{verbose} ) {
            $arg[1] = colored( $arg[1], 'cyan' );
        }
        @_ = @arg;
        goto &{ $org_m->{_diag} };
    };

    *App::cpanminus::script::chat = sub {
        my $self = shift;
        print STDERR colored( join( $,, @_ ), 'yellow' ) if $self->{verbose};
        $self->log(@_);
    };
    $app->parse_options(@ARGV);
    if ( $app->{action} eq 'show_version' ) {
        $org_m->{show_version} = \&App::cpanminus::script::show_version;
        *App::cpanminus::script::show_version = sub {
            print "cpanmw [App::cpanmw] version $App::cpanmw::VERSION ($0)\n";
            print "\n";
            print "=== cpanm version info ===\n";
            local $0 = $cpanm_file;
            $org_m->{show_version}(@_);
        };
    }
    if (   $app->{action} eq 'show_help'
        || !$app->{argv}
        || !$app->{load_from_stdin} )
    {
        $org_m->{show_help} = \&App::cpanminus::script::show_help;
        require IO::Callback;
        my $cb = sub {
            my $s = shift;
            $s =~ s/cpanm /cpanmw /g;
            $s =~ s/PERL_CPANM_OPT /PERL_CPANM_OPT( not CPANM*W* ) /g;
            print STDOUT $s;
        };
        my $fh = IO::Callback->new( '>', $cb );
        *App::cpanminus::script::show_help = sub {
            select $fh;
            $org_m->{show_help}(@_);
        };
    }

### @ARGV
}

$app->doit();
__END__

=pod

=head1 NAME

cpanmw - the cpanm wrapper

=head1 SYNOPSIS

    # type "cpanmw" instead of "cpanm"

    $ cpanmw Acme::Bleach

    $ cpanmw --verbose Plack

    $ cpanmw -L Twiggy@0.10

=head1 DESCRIPTION

This script is wrapper for L<cpanm>.

It can use like cpanm, but has some features.

=over 4

=item - colorized messages and keywords

    This feature requires L<Win32::Console::ANSI> on MSWin32.

=item - Supports --<PHASE>-timeout options
on MSWin32

    In cpanm they are replaced to --<PHASE>.

=item - Create ~/.cpanm/build.log as hardlink on MSWin32

    Requires Windows 6.0(Vista) or later.
    Otherwise, it is copied from work directory.

=item - Create ~/.cpanm/latest-build/ as junction point on MSWin32

    Requires the same conditions about OS version.
    Doesn't create it if not.

=back

Commands and options are completely the same as cpanm.
See L<cpanm> for details.

=head1 DEPENDENCIES

App::cpanminus

File::Which

FindBin

Term::ANSIColor

Win32::Console::ANSI ( MSWin32 only )

IO::Callback

version

=head1 AUTHOR

KPEE

=head1 LICENSE

Copyright (C) 2014 KPEE
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<App::cpanminus>

L<cpanm>

=cut

:endofperl
