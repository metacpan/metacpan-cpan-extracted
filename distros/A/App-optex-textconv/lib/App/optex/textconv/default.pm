package App::optex::textconv::default;

use strict;
use warnings;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.pdf$/i    => "pdftotext -nopgbrk \"%s\" -" ],
    [ qr/\.jpe?g$/i  => "exif \"%s\"" ],
    [ qr[^https?://] => "w3m -dump \"%s\"" ],
    );

1;
