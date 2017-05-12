#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

eval q(use URI::sftp);
plan skip_all => q(URI::sftp required)
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

my $uri = URI->new(q(sftp://me@myhost:29/home/me/foo/bar));
is(p($uri), qq($uri), q(URI::sftp 1));

$uri = URI->new(q(sftp://host.example.com:22/orders.xml?Delete=true));
is(p($uri), qq($uri), q(URI::sftp 2));

done_testing 2;
