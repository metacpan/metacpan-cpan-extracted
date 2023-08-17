package App::optex::textconv::default;

use strict;
use warnings;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.jpe?g$/i  => 'exif "%s"' ],
    [ qr[^https?://] => 'w3m -dump "%s"' ],
    [ qr/\.gpg$/i  => 'gpg --quiet --no-mdc-warning --decrypt "%s"' ],
    );

1;
