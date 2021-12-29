package App::optex::textconv::ooxml;

our $VERSION = '0.1401';

use v5.14;
use warnings;
use Carp;

use App::optex::textconv::Converter 'import';

our @CONVERTER;

BEGIN {

    require App::optex::textconv::ooxml::regex;

    if (eval { require App::optex::textconv::ooxml::xslt }) {
	@CONVERTER = (
	    [ qr/\.doc[xm]$/ => \&App::optex::textconv::ooxml::xslt::to_text ],
	    [ qr/\.ppt[xm]$/ => \&App::optex::textconv::ooxml::xslt::to_text ],
	    [ qr/\.xls[xm]$/ => \&App::optex::textconv::ooxml::regex::to_text ],
	    );
    } else {
	@CONVERTER = (
	    [ qr/\.doc[xm]$/ => \&App::optex::textconv::ooxml::regex::to_text ],
	    [ qr/\.ppt[xm]$/ => \&App::optex::textconv::ooxml::regex::to_text ],
	    [ qr/\.xls[xm]$/ => \&App::optex::textconv::ooxml::regex::to_text ],
	    );
    }

}

1;
