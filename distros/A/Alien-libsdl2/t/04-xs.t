use Test2::V0;
use Test::Alien;
use lib -d '../t' ? './lib' : 't/lib';

use Alien::libsdl2;
use Config;
#
alien_ok 'Alien::libsdl2';
my $flags = `perl -MExtUtils::Embed -e ccopts -e ldopts`;

#  nasty hack
#$ENV{LD_LIBRARY_PATH}   = Alien::libsdl2->dist_dir . '/lib';
#$ENV{DYLD_LIBRARY_PATH} = Alien::libsdl2->dist_dir . '/lib';
#
#diag( 'dist_dir: ' . Alien::libsdl2->dist_dir . '/lib' );
#diag( 'libs: ' . Alien::libsdl2->libs );
#diag( 'cflags: ' . Alien::libsdl2->cflags );
#diag( 'cflags static: ' . Alien::libsdl2->cflags_static );
#eval { diag( 'dynamic libs: ' . join ':', Alien::libsdl2->dynamic_libs ); };
#warn $@ if $@;
#diag( 'bin dir: ' . join( ' ', Alien::libsdl2->bin_dir ) );
#
my $xs = {
    verbose => 1,
    xs      => do { local $/; <DATA> }
};
#
todo 'Includes/cflags are missing' => sub {
    xs_ok $xs, with_subtest {
        is SDL2Test::get_ver(), 2;
    }
};
#
done_testing;
__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <SDL.h>


MODULE = SDL2Test PACKAGE = SDL2Test

int
get_ver()
	CODE:
			SDL_version compiled;
			SDL_VERSION(&compiled);
			printf("# [TA_MODULE] We compiled against SDL version %d.%d.%d ...\n",
				compiled.major, compiled.minor, compiled.patch);
			RETVAL = compiled.major;
	OUTPUT:
		RETVAL
