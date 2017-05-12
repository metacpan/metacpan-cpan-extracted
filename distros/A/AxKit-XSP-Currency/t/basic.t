#!perl -wT
# $Id: /local/CPAN/AxKit-XSP-Currency/t/basic.t 1434 2005-03-05T01:08:13.559154Z claco  $
use strict;
use warnings;
use Test::More tests => 1;

SKIP: {
    eval 'use Apache::AxKit::Language::XSP';
    skip 'AxKit not installed', 1 if $@;

    {
        ## squelch AxKit strict/warnings
        no strict;
        no warnings;
        use_ok('AxKit::XSP::Currency');
    };
};
