#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use File::Temp qw(tempdir);
use Scalar::Util qw(tainted);
use Software::LicenseUtils;

use CPANPLUS::Dist::Debora::Package::Debian;

use open ':std', ':encoding(utf8)';
use Test::More;

if (tainted($ENV{PWD})) {
    plan skip_all => 'taint mode enabled';
}
else {
    plan tests => 32;
}

use lib 't/inc';
use MockModule;
use MockPackage;

my $real_package = new_ok 'CPANPLUS::Dist::Debora::Package::Debian' => [
    module      => MockModule->new,
    installdirs => 'site',
    outputdir   => tempdir(CLEANUP => 1),
    debiandir   => tempdir,
];

my $package = MockPackage->new($real_package);

isa_ok $package, 'CPANPLUS::Dist::Debora::Package';
can_ok $package, qw(format_priority create install outputname);

is $package->_normalize_name('Modern-Perl'),
    'libmodern-perl-perl', 'Modern-Perl is converted to libmodern-perl-perl';
is $package->_normalize_name('perl-ldap'),
    'libnet-ldap-perl', 'perl-ldap is converted to libnet-ldap-perl';
is $package->_normalize_name('libwww-perl'),
    'libwww-perl', 'libwww-perl is not changed';

ok $package->sanitize_stagingdir, 'can sanitize stagingdir';

like $package->outputname, qr{[.]deb \z}xms, 'file extension is .deb';

my $changelog = $package->changelog;
isnt $changelog, q{}, 'changelog is not empty';

my $control = $package->control;
like $control, qr{^ Source: \h* \S}xms,              'Source is set';
like $control, qr{^ Maintainer: \h* \S}xms,          'Maintainer is set';
like $control, qr{^ Standards-Version: \h* \S}xms,   'Standards-Version is set';
like $control, qr{^ Package: \h* \S}xms,             'Package is set';
like $control, qr{^ Architecture: \h* (all|any)}xms, 'Architecture is set';
like $control, qr{^ Description: \h* \S}xms,         'Description is set';

my $copyright = $package->copyright;
like $copyright, qr{^ Files: \h* \S}xms,     'Files is set';
like $copyright, qr{^ Copyright: \h* \S}xms, 'Copyright is set';
like $copyright, qr{^ License: \h* \S}xms,   'License is set';

my $docs = $package->docs;
like $docs, qr{^ README}xms, 'README is installed';

my $rules = $package->rules;
like $rules, qr{^ \t+ dh_installchangelogs \h+ Changes}xms,
    'Changes is installed';

my $epoch_for = $package->_read_epochs;
isa_ok $epoch_for, 'HASH';
ok $epoch_for->{'libscalar-list-utils-perl'}, 'epoch is set for List::Util';

sub license_from_name {
    my $short_name = shift;

    my $holder = 'unknown author';

    return Software::LicenseUtils->new_from_short_name({
        short_name => $short_name,
        holder     => $holder,
    });
}

sub license_from_spdx {
    my $spdx_expression = shift;

    my $holder = 'unknown author';

    return Software::LicenseUtils->new_from_spdx_expression({
        spdx_expression => $spdx_expression,
        holder          => $holder,
    });
}

like $package->_get_license_text(license_from_spdx('Apache-2.0')),
    qr{Apache[ ]License \b .+ \b Version[ ]2[.]0 \b}xms,
    '_get_license_apache_2_0 works';
like $package->_get_license_text(license_from_spdx('CC0-1.0')),
    qr{CC0[ ]1[.]0[ ]Universal}xms,
    '_get_license_cc0_1_0 works';
like $package->_get_license_text(license_from_name('GPL-1')),
    qr{GNU[ ]General[ ]Public[ ]License \b .+ \b version[ ]1 \b}xms,
    '_get_license_fsf(GPL-1) works';
like $package->_get_license_text(license_from_name('GPL-2')),
    qr{GNU[ ]General[ ]Public[ ]License \b .+ \b version[ ]2 \b}xms,
    '_get_license_fsf(GPL-2) works';
like $package->_get_license_text(license_from_name('GPL-3')),
    qr{GNU[ ]General[ ]Public[ ]License \b .+ \b version[ ]3 \b}xms,
    '_get_license_fsf(GPL-3) works';
like $package->_get_license_text(license_from_name('LGPL-2.1')),
    qr{GNU[ ]Lesser[ ]General[ ]Public[ ]License \b .+ \b version[ ]2[.]1 \b}xms,
    '_get_license_fsf(LGPL-2.1) works';
like $package->_get_license_text(license_from_name('LGPL-3.0')),
    qr{GNU[ ]Lesser[ ]General[ ]Public[ ]License \b .+ \b version[ ]3[.]0 \b}xms,
    '_get_license_fsf(LGPL-3.0) works';
like $package->_get_license_text(license_from_spdx('MPL-1.1')),
    qr{Mozilla[ ]Public[ ]License \b .+ \b version[ ]1[.]1 \b}xms,
    '_get_license_mozilla(MPL-1.1) works';
like $package->_get_license_text(license_from_spdx('MPL-2.0')),
    qr{Mozilla[ ]Public[ ]License \b .+ \b version[ ]2[.]0 \b}xms,
    '_get_license_mozilla(MPL-2.0) works';
like $package->_get_license_text(
    license_from_spdx('Artistic-1.0-Perl OR GPL-1.0-or-later')),
    qr{Artistic[ ]License}xms,
    '_get_license_perl_5 works';
