package App::optex::textconv::ooxml;

our $VERSION = '1.04';

use strict;
use warnings;

use App::optex::textconv::Converter 'import';

our @CONVERTER;

use App::optex::textconv::ooxml::regex;

eval {
    require App::optex::textconv::ooxml::xslt;
} and do {
    import  App::optex::textconv::ooxml::xslt;
};

1;
