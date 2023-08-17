package App::optex::textconv::doc;

our $VERSION = '1.06';

use strict;
use warnings;

use Text::Extract::Word;

sub to_text {
    Text::Extract::Word->new(shift)->get_text();
}

1;
