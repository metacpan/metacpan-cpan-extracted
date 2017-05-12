use strict;
use warnings;

use Test::More;
use Alien::NSS;

BEGIN {
	# require version 0.06 for compatability with recent Alien::Base
	eval {
		require Test::CChecker;
		if ( Test::CChecker->VERSION < 0.06 ) {
			diag("Test::CChecker version too small: ".Test::CChecker->VERSION);
			return 0;
		}
		Test::CChecker->import();
		plan tests => 1;
		1;
	} or do {
		plan skip_all => "Test::CChecker not installed";
	};
}

compile_with_alien 'Alien::NSS';

compile_run_ok <<SOURCE, 'basic compile test for nss';
#include <pk11func.h>
#include <seccomon.h>
#include <secmod.h>
#include <secitem.h>
#include <secder.h>
#include <cert.h>
#include <certdb.h>
#include <ocsp.h>
#include <keyhi.h>
#include <secerr.h>
#include <blapit.h>

#include <nspr.h>
#include <plgetopt.h>
#include <prio.h>
#include <nss.h>

int main()
{
	SECStatus status = NSS_NoDB_Init(NULL);
  return 0;
}
SOURCE
