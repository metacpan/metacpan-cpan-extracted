# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More;

BEGIN {
	eval { use Cv -nomore };
	eval { require XSLoader; XSLoader::load('Cv::t', $Cv::VERSION) };
	if ($@) {
		plan skip_all => "make INST_ARCHLIB=t BASEEXT=Test FULLEXT=Cv/Test dynamic";
	}
	plan tests => 1;
}
BEGIN { use_ok('Cv', -nomore) }
