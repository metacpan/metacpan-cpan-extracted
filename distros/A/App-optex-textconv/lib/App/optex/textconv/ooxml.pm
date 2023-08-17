package App::optex::textconv::ooxml;

our $VERSION = '1.06';

use strict;
use warnings;

our $USE_XSLT = 0;

use App::optex::textconv::Converter 'import';

our @CONVERTER;

use App::optex::textconv::ooxml::regex;

if ($USE_XSLT) {
    eval {
	require App::optex::textconv::ooxml::xslt;
    } and do {
	import  App::optex::textconv::ooxml::xslt;
    };
}

1;
