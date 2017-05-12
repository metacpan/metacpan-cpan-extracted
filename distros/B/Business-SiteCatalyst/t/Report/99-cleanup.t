#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

SKIP:
{
	skip( 'Temporary report id file does not exist.', 1 )
		if ! -e 'business-sitecatalyst-report-reportid.tmp';

	ok(
		unlink( 'business-sitecatalyst-report-reportid.tmp' ),
		'Remove temporary report id file',
	);
}