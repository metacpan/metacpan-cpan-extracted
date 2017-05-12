#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

eval q(use Mojo::URL);
plan skip_all => q(Mojo::URL required)
    if $@;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;
};

use Data::Printer {
    filters => {
        q(-external) => q(URI),
    },
};

my $uri = Mojo::URL->new(q(http://mojolicio.us/));
is(p($uri), qq($uri), q(Mojo::URL));

done_testing 1;
