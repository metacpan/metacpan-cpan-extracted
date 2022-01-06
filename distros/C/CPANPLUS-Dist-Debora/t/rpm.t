#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use File::Temp qw(tempdir);
use Scalar::Util qw(tainted);

use CPANPLUS::Dist::Debora::Package::RPM;

use Test::More;

if (tainted($ENV{PWD})) {
    plan skip_all => 'taint mode enabled';
}
else {
    plan tests => 17;
}

use lib 't/inc';
use MockModule;
use MockPackage;

my $real_package = new_ok 'CPANPLUS::Dist::Debora::Package::RPM' => [
    module    => MockModule->new,
    outputdir => tempdir(CLEANUP => 1),
];

my $package = MockPackage->new($real_package);

isa_ok $package, 'CPANPLUS::Dist::Debora::Package';
can_ok $package, qw(format_priority create install outputname);

ok $package->sanitize_stagingdir, 'can sanitize stagingdir';

like $package->outputname, qr{[.]rpm \z}xms, 'file extension is .rpm';

my $spec = $package->spec;
like $spec, qr{^ Name: \h* perl-\S}xms,   'Name is set';
like $spec, qr{^ Version: \h* \d}xms,     'Version is set';
like $spec, qr{^ Release: \h* \d}xms,     'Release is set';
like $spec, qr{^ Summary: \h* \S}xms,     'Summary is set';
like $spec, qr{^ License: \h* \S}xms,     'License is set';
like $spec, qr{^ URL: \h* \S}xms,         'URL is set';
like $spec, qr{^ %description \v+ \S}xms, '%description exists';
like $spec, qr{^ %license \h+ \S}xms,     '%license exists';
like $spec, qr{^ %doc \h+ Changes}xms,    '%doc Changes exists';
like $spec, qr{^ %doc \h+ README}xms,     '%doc README exists';
like $spec, qr{[.]3pm[*] $}xms,           'manual page has wildcard suffix';
like $spec, qr{^ Requires: \h* perl[(]:MODULE_COMPAT_[\d.]+[)]}xms,
    'MODULE_COMPAT exists';
