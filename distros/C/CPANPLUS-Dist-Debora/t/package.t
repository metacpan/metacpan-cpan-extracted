#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Config;
use File::Spec::Functions qw(catdir catfile splitpath);
use File::Temp qw(tempdir);
use Scalar::Util qw(tainted);

use CPANPLUS::Dist::Debora::Package;

use Test::More;

if (tainted($ENV{PWD})) {
    plan skip_all => 'taint mode enabled';
}
else {
    plan tests => 39;
}

use lib 't/inc';
use MockModule;
use MockPackage;

my $tempdir = tempdir(CLEANUP => 1);

my $real_package = new_ok 'CPANPLUS::Dist::Debora::Package' => [
    module      => MockModule->new,
    installdirs => 'vendor',
    outputdir   => $tempdir,
];

my $package = MockPackage->new($real_package);

is $package->installdirs, 'vendor', 'installdirs is vendor';

like $package->mm_opt, qr{INSTALLDIRS}xms,   'mm_opt contains INSTALLDIRS';
like $package->mb_opt, qr{--installdirs}xms, 'mb_opt contains --installdirs';

ok $package->sourcefile, 'can get source file';
ok $package->sourcedir,  'can get source directory';

is $package->_normalize_name('Modern-Perl'),
    'perl-Modern-Perl', 'prefix "perl-" is added to name';
is $package->_normalize_name('perl-ldap'),
    'perl-ldap', 'prefix "perl-" is not duplicated';

is $package->_normalize_version(undef), '0', 'undefined version is handled';
is $package->_normalize_version('v1.0'),
    '1.0', 'prefix "v" is removed from version';

ok $package->name,             'can get name';
ok $package->version,          'can get version';
cmp_ok $package->build_number, '>', 0, 'can get build number';

ok $package->author, 'can get author';

local $ENV{DEBFULLNAME} = 'Ian Fraser Kilmister';
local $ENV{DEBEMAIL}    = 'Lemmy <lemmy@example.com>';
is $package->packager, 'Ian Fraser Kilmister <lemmy@example.com>',
    'can get packager from DEBFULLNAME and DEBEMAIL';

is $package->vendor, 'CPANPLUS', 'vendor is CPANPLUS';

like $package->url, qr{\A https?://}xms, 'can get url';

ok $package->_get_summary_from_meta, 'can get summary from meta file';
ok $package->_get_summary_from_pod,  'can get summary from pod file';

ok $package->summary,     'can get summary';
ok $package->description, 'can get description';

my $dependencies = $package->dependencies;
isa_ok $dependencies, 'ARRAY', 'dependencies';
cmp_ok @{$dependencies}, '>', 0, 'dependencies is not empty';

my $copyrights = $package->copyrights;
isa_ok $copyrights, 'ARRAY', 'copyrights';
cmp_ok @{$copyrights}, '>', 0, 'copyrights is not empty';

my $meta_licenses = $package->_get_licenses_from_meta;
isa_ok $meta_licenses, 'ARRAY', 'meta licenses';
cmp_ok @{$meta_licenses}, '>', 0, 'meta licenses is not empty';

my $pod_licenses = $package->_get_licenses_from_pod;
isa_ok $pod_licenses, 'ARRAY', 'pod licenses';
cmp_ok @{$pod_licenses}, '>', 0, 'pod licenses is not empty';

my $licenses = $package->licenses;
isa_ok $licenses, 'ARRAY', 'licenses';
cmp_ok @{$licenses}, '>', 0, 'licenses is not empty';
isa_ok $licenses->[0], 'Software::License', 'license';
is $package->license, 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'license is Perl 5';

my $stagingdir = $package->stagingdir;
my ($volume, $archlibdir) = splitpath($Config{installarchlib}, 1);
my $testfile   = catfile($stagingdir, $archlibdir, 'perllocal.pod');
ok -f $testfile, 'perllocal.pod exists';
ok $package->sanitize_stagingdir, 'can sanitize stagingdir';
ok !-f $testfile, 'perllocal.pod does not exist';

ok $package->is_noarch, 'distribution is hardware independent';

my $files = $package->files;
isa_ok $files, 'ARRAY', 'files';
cmp_ok @{$files}, '>', 0, 'files is not empty';
