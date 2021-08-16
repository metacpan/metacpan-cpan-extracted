#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use CPANPLUS::Dist::Debora;

use open ':std', ':encoding(utf8)';
use Test::More tests => 1;

my @methods = qw(format_available init prepare create install);
can_ok 'CPANPLUS::Dist::Debora', @methods;
