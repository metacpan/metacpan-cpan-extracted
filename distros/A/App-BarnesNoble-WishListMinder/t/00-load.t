#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 2;

BEGIN {
    use_ok('App::BarnesNoble::WishListMinder');
    use_ok('Web::Scraper::BarnesNoble::WishList');
}

diag("Testing App::BarnesNoble::WishListMinder $App::BarnesNoble::WishListMinder::VERSION");
