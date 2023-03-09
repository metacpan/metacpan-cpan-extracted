package App::optex::textconv::msdoc;

our $VERSION = '1.04';

use v5.14;
use warnings;
use Carp;

##
## Import to_text() and get_list() for backward compatibility.
##
our @EXPORT_OK = qw(to_text get_list);
use App::optex::textconv::ooxml::regex qw(to_text get_list);

require App::optex::textconv::ooxml;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    @App::optex::textconv::ooxml::CONVERTER,
    );

1;
