use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::PLplot;


alien_diag 'Alien::PLplot';
alien_ok 'Alien::PLplot';

my $version_re = qr/^(\d+)\.(\d+)\.(\d+)$/;

my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
	my($module) = @_;
	like $module->version, $version_re;
};

done_testing;
__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <plplot.h>

SV*
version(const char *class)
{
	char ver[80];
	c_plgver(ver);

	SV* ver_sv = newSVpv( ver, strlen(ver) );

	return ver_sv;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

SV* version(class);
	const char *class;
