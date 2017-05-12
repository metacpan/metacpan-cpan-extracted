#!perl -wT
# $Id: /local/CPAN/AxKit-XSP-L10N/t/basic.t 1396 2005-03-25T03:58:41.995755Z claco  $
use strict;
use warnings;
use Test::More tests => 4;

use_ok('AxKit::XSP::L10N::Demo');
use_ok('AxKit::XSP::L10N::Demo::en_us');
use_ok('AxKit::XSP::L10N::Demo::fr');

SKIP: {
    eval 'use Apache::AxKit::Language::XSP';
    skip 'AxKit not installed', 1 if $@;

    {
        ## squelch AxKit strict/warnings
        no strict;
        no warnings;
        use_ok('AxKit::XSP::L10N');
    };
};
