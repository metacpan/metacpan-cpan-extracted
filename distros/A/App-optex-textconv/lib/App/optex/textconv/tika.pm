package App::optex::textconv::tika;

our $VERSION = '1.02';

use strict;
use warnings;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.doc[xm]?$/ => \&to_text ],
    [ qr/\.ppt[xm]?$/ => \&to_text ],
    [ qr/\.xls[xm]?$/ => \&to_text ],
    );

sub to_text {
    my $file = shift;
    my $format = q(tika --text "%s");
    my $exec = sprintf $format, $file;
    qx($exec);
}

1;
