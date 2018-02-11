use 5.010;
use strict;
use warnings;

use Data::Visitor::Tiny;

my $hoh = {
    a => { b => 1, c => 2 },
    d => { e => 3, f => 4 },
};

# print leaf (non-ref) values on separate lines (1 2 3 4)
visit( $hoh, sub { return if ref; say } );

# transform leaf value for a given key
visit(
    $hoh,
    sub {
        my ( $key, $valueref ) = @_;
        $$valueref = "replaced" if $key eq 'e';
    }
);
say $hoh->{d}{e}; # "replaced"

#
# This file is part of Data-Visitor-Tiny
#
# This software is Copyright (c) 2018 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: set ts=4 sts=4 sw=4 et tw=75:
