#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;

use Acme::Study::OS::DateLocales;

plan tests => 1;

if (0) {
    diag(weekday_and_month_names_dump());
    pass 'Everything is dumped, thank you!';
} else {
    pass 'Thank you, now you can read the results...';
}

__END__
