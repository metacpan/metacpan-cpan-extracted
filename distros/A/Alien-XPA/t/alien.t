#! perl

use Test2::Bundle::Extended;
use Test::Alien;

use Alien::XPA;
use Action::Retry 'retry';


# this modifies @PATH appropriately
alien_ok 'Alien::XPA';



my $run = run_ok( [ 'xpaaccess', '--version' ] );
$run->exit_is( 0 )
  or bail_out( "can't find xpaaccess. must stop now" );
my $version = $run->out;

my $xpamb_already_running = run_ok( [ qw[ xpaaccess XPAMB:* ] ])->out eq 'yes';

unless ( $xpamb_already_running ) {
    exec( 'xpamb' ) if ! fork;

    my $found_it;

    retry {
        die unless
          $found_it = qx/xpaaccess 'XPAMB:*'/ =~ 'yes';
    };

    bail_out( "unable to access launched xpamb" )
      unless $found_it;;

}

my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
    my ( $module ) = @_;

    ok $module->connected, "connected to xpamb";

    $version = $module->version;

    is( $module->version, $version, "library version same as command line version" );

};

END {
    system( qw[ xpaset -p xpamb -exit ] )
      unless $xpamb_already_running;
}

done_testing;

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
