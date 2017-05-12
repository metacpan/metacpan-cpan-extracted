use strict;
use warnings;

package App::JSON::to::perl;

our $VERSION = '1.000';

use Data::Dumper ();


sub dump
{
    my $data = $_[1];

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 0;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Quotekeys = 0;

    Data::Dumper::Dumper($data) . "\n"
}

1;
