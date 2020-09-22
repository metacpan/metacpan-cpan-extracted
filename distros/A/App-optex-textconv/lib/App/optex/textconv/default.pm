package App::optex::textconv::default;

use v5.14;
use warnings;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
# moved to pdf.pm
#   [ qr/\.pdf$/i    => "pdftotext -nopgbrk \"%s\" -" ],
    [ qr/\.jpe?g$/i  => "exif \"%s\"" ],
    [ qr[^https?://] => "w3m -dump \"%s\"" ],
    );

1;
