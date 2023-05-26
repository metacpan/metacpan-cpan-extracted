#! perl

use Test2::V0;
use Test::Alien;
use Test::Settings ':all';
use Time::HiRes 'time';

use Alien::XPA;
use Action::Retry 'retry';
use File::Which qw(which);
use Child 'child';

sub run { MyRun->new( @_ ) }

# so we can catch segv's
plan( 5 + ( want_smoke() ? 3 : 0 ) );

# this modifies @PATH appropriately
alien_ok 'Alien::XPA';

if ( want_smoke ) {
    my $ok = !!1;
    for my $exe ( qw( xpaaccess xpamb xpaset ) ) {
        $ok &&= ok( defined( which( $exe ) ), "found $exe" );
    }
    if ( !$ok ) {
        diag join "\n", '', 'PATH = ', split /[:;]/, $ENV{PATH};
        bail_out;
    }

}

my $version = do {
    my $run = run_ok( [ 'xpaaccess', '--version' ] );
    $run->exit_is( 0 )
      or bail_out( "can't run xpaaccess. must stop now:\n" . $run->stringify );
    $run->out;
};

# just in case there's one running, remove it.
remove_xpamb();

my $child;

## no critic (Variables::RequireLocalizedPunctuationVars)

if ( $^O eq 'MSWin32' ) {
    require Win32::Process;
    use subs qw( Win32::Process::NORMAL_PRIORITY_CLASS Win32::Process::CREATE_NO_WINDOW);
    $ENV{XPA_METHOD} = 'localhost';
    Win32::Process::Create( $child, which( 'xpamb' ),
        'xpamb', 0, Win32::Process::NORMAL_PRIORITY_CLASS | Win32::Process::CREATE_NO_WINDOW, q{.} )
      || die $^E;

}
else {
    $ENV{XPA_METHOD} = 'local';
    $child = child { exec {'xpamb'} 'xpamb' };
}

my $TSTART = time;
diag( 'waiting to contact launched xpamb' );
bail_out( sprintf( 'unable to access launched xpamb after %f seconds', time - $TSTART ) )
  unless
  retry {    ## no critic (ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions)
    my $run = run( 'xpaaccess', 'XPAMB:*' );
    if ( $run->exit != 0 && $run->exit != 1 ) {
        diag $run->dump;
        bail_out( 'error running xpaacces' );
    }
    $run->exit == 1 || die;
}            # try every 0.25 seconds for 15 seconds. Try to be nice to CPAN testers.
strategy => { Constant => { sleep_time => 250, max_retries_number => 15_000 / 250 } };
diag( sprintf( 'accessed launched xpamb after %f seconds', time - $TSTART ) );


my $xs = do { local $/ = undef; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
    my ( $module ) = @_;
    ok $module->connected, 'connected to xpamb';
    $version = $module->version;
    is( $module->version, $version, 'library version same as command line version' );
};

sub remove_xpamb {

    my $xpamb_is_running = 1;
    retry {
        my $run;

        $run              = run( 'xpaaccess', 'XPAMB:*' );
        $xpamb_is_running = $run->out =~ 'yes';

        return unless $xpamb_is_running;

        $run              = run( 'xpaset', qw [ -p xpamb -exit ] );
        $xpamb_is_running = $run->err =~ q/XPA[$]ERROR no 'xpaset' access points/;

        die if $xpamb_is_running;
    };

    # be firm if necessary
    if ( $xpamb_is_running && defined $child ) {

        diag( 'force remove our xpamb' );

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
        };
    }

    bail_out( 'unable to remove xpamb' )
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

    sub out    { $_[0]->{out} }
    sub err    { $_[0]->{err} }
    sub exit   { $_[0]->{exit} }                  ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    sub core   { $_[0]->{core} }
    sub signal { $_[0]->{signal} }
    sub cmd    { join q{ }, @{ $_[0]->{cmd} } }

    sub stringify {
        sprintf "cmd: %s\nexit: %d\ncore; %s\nsignal: %s\nstdout: %s\nstderr: %s\n",
          $_[0]->cmd,
          $_[0]->exit,
          $_[0]->core,
          $_[0]->signal,
          $_[0]->out,
          $_[0]->err;
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

int
connected(const char *class)
{
    char *names[1];
    char *messages[1];

    int found =
      XPAAccess( NULL,
                 "XPAMB:*",
                 NULL,
                 "g",
                 names,
                 messages,
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
