use strict;
use warnings;

use Test::More tests => 4;


BEGIN
{
	use_ok('App::cdnget');
	use_ok('App::cdnget::Exception');
	use_ok('App::cdnget::Worker');
	use_ok('App::cdnget::Downloader');
}
