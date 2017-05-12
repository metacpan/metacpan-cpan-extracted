#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

eval q(use URI::scp);
plan skip_all => q(URI::scp required)
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

my $uri = URI->new(q(scp://me@myhost:22/home/foo/bar));
is(p($uri), qq($uri), q(URI::scp));

done_testing 1;
