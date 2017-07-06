use strict;
use warnings;
use lib 'inc';
use My::ModuleBuild;
use Test::More;

plan skip_all => 'developer test' unless $ENV{USER} =~ /^(ollisg|gollis)$/ || $ENV{TRAVIS};
plan tests => 4;

my $url1 = My::ModuleBuild->_fetch_index1;
ok $url1,    "url1 = $url1";

my($url2, $zipfile) = My::ModuleBuild->_fetch_index2($url1);
ok $url2,    "url2 = $url2";
ok $zipfile, "name = $zipfile";

my $zip = My::ModuleBuild->_fetch_zip($url2);
ok $zip,     "zip  = data";
