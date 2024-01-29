package App::optex::textconv::pandoc;

our $VERSION = '1.07';

use strict;
use warnings;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.doc[xm]$/ => \&to_text ],
    [ qr/\.ppt[xm]$/ => \&to_text ],
    [ qr/\.xls[xm]$/ => \&to_text ],
    );

sub to_text {
    my $file = shift;
    my $format = q(pandoc -t plain "%s");
    my $exec = sprintf $format, $file;
    qx($exec);
}

1;
