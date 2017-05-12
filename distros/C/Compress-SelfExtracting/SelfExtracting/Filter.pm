package Compress::SelfExtracting::Filter;
use Compress::SelfExtracting 'decompress';

my %O;

sub import {
    my $me = shift;
    %O = @_;
}

use Filter::Simple sub {
    # XXX: I don't know why this gets called with empty data, but that
    # really pisses decompress() off.
    $_ = decompress($_, %O) if length;
};

1;
