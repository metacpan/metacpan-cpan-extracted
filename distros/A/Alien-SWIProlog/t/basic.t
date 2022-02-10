use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::SWIProlog;

use DynaLoader;
use Path::Tiny;
use Data::Dumper;

alien_diag 'Alien::SWIProlog';
alien_ok 'Alien::SWIProlog';

my $prop = Alien::SWIProlog->runtime_prop;
my $prefix = path( $prop->{prefix} );
my $distdir = path( $prop->{distdir} );
sub _convert {
	my $p = path($_[0]);
	if( Alien::SWIProlog->install_type('share') ) {
		my $rel = $p->is_relative
			? $p
			: $p->relative($prefix);
		return "" . $distdir->child( $rel );
	}
	return $p;
}
for my $k ( qw( swipl-bin home rpath ) ) {
	if( ref $prop->{$k} eq 'ARRAY' ) {
		$prop->{$k} = [ map _convert($_), @{ $prop->{$k} } ];
	} else {
		$prop->{$k} = _convert( $prop->{$k} );
	}
}

my @swi_lib_dirs = @{ $prop->{rpath} };

use Env qw(
	$SWI_HOME_DIR
	@LD_LIBRARY_PATH @DYLD_FALLBACK_LIBRARY_PATH @PATH
);

$SWI_HOME_DIR = $prop->{home};

unshift @LD_LIBRARY_PATH, @swi_lib_dirs;
unshift @DYLD_FALLBACK_LIBRARY_PATH, @swi_lib_dirs;
unshift @PATH, @swi_lib_dirs;
unshift @DynaLoader::dl_library_path, @swi_lib_dirs;

my ($dlfile) = DynaLoader::dl_findfile('-lswipl');
if( $dlfile ) {
	note "dlfile: $dlfile";
	DynaLoader::dl_load_file($dlfile);
} else {
	note "dlfile: not found";
}

require Alien::SWIProlog::Util;
my $PLVARS = Alien::SWIProlog::Util::get_plvars($prop->{'swipl-bin'});
{
local $Data::Dumper::Terse = 1;
local $Data::Dumper::Sortkeys = 1;
note Dumper( $PLVARS );
}

my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs,  verbose => 1 }, with_subtest {
	my($module) = @_;
	ok $module->init, 'Initialises SWI-Prolog';
};

done_testing;
__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PL_version _SWI_PL_version
#include <SWI-Prolog.h>

int
init(const char *class)
{
	int PL_argc = 0;
	char empty_arg[] = "";

	char* PL_argv[1];
	PL_argv[PL_argc++] = empty_arg;

	return PL_initialise(PL_argc, PL_argv);
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int init(class);
	const char *class;
