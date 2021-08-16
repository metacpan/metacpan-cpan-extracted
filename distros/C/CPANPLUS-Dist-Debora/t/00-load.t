#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use English qw(-no_match_vars);

use open ':std', ':encoding(utf8)';
use Test::More tests => 1;

BEGIN { use_ok('CPANPLUS::Dist::Debora') || say 'Bail out!' }

diag(
    "Testing CPANPLUS::Dist::Debora $CPANPLUS::Dist::Debora::VERSION, ",
    "Perl $PERL_VERSION, ",
    $EXECUTABLE_NAME
);
