#!perl
#
# This file is part of Audio-MPD-Common
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Audio::MPD::Common::Output;
use Test::More tests => 4;


my %kv = (
    id      => 3,
    name    => "my soundcard",
    enabled => 1,
);

my $s = Audio::MPD::Common::Output->new( \%kv );
isa_ok( $s, 'Audio::MPD::Common::Output', 'object creation' );
is( $s->id,      3,              'accessor: id' );
is( $s->name,    "my soundcard", 'accessor: name' );
is( $s->enabled, 1,              'accessor: enabled' );
