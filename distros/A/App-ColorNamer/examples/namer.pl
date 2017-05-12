#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(lib ../lib);
use App::ColorNamer;

@ARGV
    or die "Usage: $0 XXX (where XXX is either 3 or 6 digit hex code)\n";

my $code = shift;

my $app = App::ColorNamer->new;

my $color = $app->get_name( $code )
    or die $app->error;

print "Exact match!\n"
    if $color->{exact};

printf "Color name: %s\nHEX: #%s\nRGB: %s\nHSL: %s\n",
    @$color{ qw/name  hex/ },
    join(', ', @{ $color->{rgb} }{ qw/r g b/ }),
    join(', ', @{ $color->{hsl} }{ qw/h s l/ });
