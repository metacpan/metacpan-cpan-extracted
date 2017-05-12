#!/usr/bin/env perl

# Creation date: 2008-10-31T02:09:42Z
# Authors: don

use strict;
use warnings;

use Test;

if ($] < 5.006) {
    plan tests => 0;
    exit 0;
}

plan tests => 1;

use CGI::Utils;

# avoid breaking syntax check for Perl < 5.006
eval q{
my $str = "Don's House of \x{706b}";

my $sf_str = CGI::Utils->url_encode($str);

ok($sf_str eq 'Don%27s%20House%20of%20%e7%81%ab');
};
