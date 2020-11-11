#! perl

use Test2::Bundle::Extended;
use Test::Alien;

use Alien::XPA;
use Action::Retry 'retry';
use File::Which qw(which);
use Child 'child';

sub run { MyRun->new( @_ ) }

# so we can catch segv's
plan( 5 );

# this modifies @PATH appropriately
alien_ok 'Alien::XPA';


diag(  which($_) or bail_out( "can't find $_" ) )
  for qw( xpaaccess xpamb xpaset );

my $run = run_ok( [ 'xpaaccess', '--version' ] );
$run->exit_is( 0 )
  or bail_out( "can't run xpaaccess. must stop now:\n" . $run->dump );
my $version = $run->out;

# just in case there's one running, remove it.
remove_xpamb();

our $child;

if ( $^O eq 'MSWin32' ) {
    require Win32::Process;
    use subs
      qw( Win32::Process::NORMAL_PRIORITY_CLASS Win32::Process::CREATE_NO_WINDOW);
    Win32::Process::Create(
        $child,
        which( 'xpamb' ),
        "xpamb",
        0,
        Win32::Process::NORMAL_PRIORITY_CLASS | Win32::Process::CREATE_NO_WINDOW,
        "."
    ) || die $^E;
}
else {
    $child = child { exec { 'xpamb' } 'xpamb' };
}

my $xpamb_is_running;
retry {
    my $run = run( 'xpaaccess', 'XPAMB:*' );
    $xpamb_is_running = $run->exit == 1;
    if ( $run->exit != 0 && $run->exit != 1 ) {
        diag $run->dump;
        bail_out( "error running xpaacces" );
    }
    die unless $xpamb_is_running;
};

bail_out( "unable to access launched xpamb" )
  unless $xpamb_is_running;

my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
    my ( $module ) = @_;
    ok $module->connected, "connected to xpamb";
    $version = $module->version;
    is( $module->version, $version,
        "library version same as command line version" );
};

sub remove_xpamb {

    my $xpamb_is_running = 1;
    retry {
        my $run;

        $run = run( 'xpaaccess', 'XPAMB:*' );
        $xpamb_is_running = $run->out =~ 'yes';

        return unless $xpamb_is_running;

        $run = run( 'xpaset', qw [ -p xpamb -exit ] );
        $xpamb_is_running = $run->err =~ qr[XPA\$ERROR no 'xpaset' access points];

        die if $xpamb_is_running;
    };

    # be firm if necessary
    if ( $xpamb_is_running && defined $child ) {

        diag( "force remove our xpamb" );

        retry {

            if ( $^O eq 'MSWin32' ) {
                use subs qw( Win32::Process::STILL_ACTIVE );
                $child->GetExitCode( my $exitcode );
                $child->Kill( 0 ) if $exitcode == Win32::Process::STILL_ACTIVE;
            }

            else {
                $child->kill( 9 ) unless $child->is_complete;
            }

            if ( run( 'xpaaccess', 'XPAMB:*' )->out !~ 'yes' ) {
                $xpamb_is_running = 0;
                return;
            }

            die;
        }
    }

    bail_out( "unable to remove xpamb" )
      if $xpamb_is_running;
}

{
    package MyRun;
    use Capture::Tiny qw( capture );

    sub new {
        my ( $class, @args ) = @_;
        my ( $out, $err, $exit ) = capture { system { $args[0] } @args; $?; };

        my $signal = $exit & 127;
        my $core   = $exit & 128;
        $exit = $exit >> 8;

        return bless {
            cmd    => \@args,
            out    => $out,
            err    => $err,
            exit   => $exit,
            signal => $signal,
            $core  => $core,
        }, $class;
    }

    sub out  { $_[0]->{out} }
    sub err  { $_[0]->{err} }
    sub exit { $_[0]->{exit} }
    sub core { $_[0]->{core} }
    sub signal { $_[0]->{signal} }
    sub cmd { join ' ', @{ $_[0]->{cmd} } }

    sub dump {
        sprintf "cmd: %s\nexit: %d\ncore; %s\nsignal: %s\nstdout: %s\nstderr: %s\n",
          $_[0]->cmd,
          $_[0]->exit,
          $_[0]->core,
          $_[0]->signal,
          $_[0]->out,
          $_[0]->err
      }
}

END {
    remove_xpamb();
}

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <xpa.h>

const char *
connected(const char *class)
{
    char *names[1];
    char *messages[1];

    int found =
      XPAAccess( NULL,
                 "XPAMB:*",
                 NULL,
                 "g",
                 &names,
                 &messages,
                 1 );

    if ( found && names[0] && strcmp( names[0], "XPAMB:xpamb" ) ) found = 1;
    else found = 0;

    if ( names[0] ) free( names[0] );
    if ( messages[0] ) free( messages[0] );

    return found;
}

const char * version( const char* class ) {
    const char* version = XPA_VERSION;
    return version;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int connected(class);
    const char *class;

const char* version(class);
    const char *class;
