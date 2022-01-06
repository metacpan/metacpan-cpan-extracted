#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use File::Temp qw(tempdir);
use Scalar::Util qw(tainted);

use CPANPLUS::Dist::Debora::Package::Mageia;

use Test::More tests => 3;

use lib 't/inc';
use MockModule;
use MockPackage;

my $real_package = new_ok 'CPANPLUS::Dist::Debora::Package::Mageia' => [
    module    => MockModule->new,
    outputdir => tempdir(CLEANUP => 1),
];

my $package = MockPackage->new($real_package);

isa_ok $package, 'CPANPLUS::Dist::Debora::Package';
can_ok $package, qw(format_priority create install outputname);
