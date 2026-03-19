package Data::Hash::Diff::Smart::Path;

use strict;
use warnings;

sub join {
    my ($base, $part) = @_;
    return $base eq '' ? "/$part" : "$base/$part";
}

1;

