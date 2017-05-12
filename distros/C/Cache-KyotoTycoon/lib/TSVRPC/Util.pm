package TSVRPC::Util;
use strict;
use warnings;

sub parse_content_type {
    my ($content_type) = @_;
    if ($content_type =~ m{text/tab-separated-values(?:; colenc=([BUQ]))?}) {
        return defined $1 ? $1 : '';
    } else {
        return undef;
    }
}

1;
