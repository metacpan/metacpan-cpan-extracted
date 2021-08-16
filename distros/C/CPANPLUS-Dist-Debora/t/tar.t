#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Scalar::Util qw(tainted);

use CPANPLUS::Dist::Debora::Package::Tar;

use open ':std', ':encoding(utf8)';
use Test::More;

if (tainted($ENV{PWD})) {
    plan skip_all => 'taint mode enabled';
}
else {
    plan tests => 9;
}

use lib 't/inc';
use MockModule;
use MockPackage;

my $real_package = new_ok 'CPANPLUS::Dist::Debora::Package::Tar' => [
    module => MockModule->new
];

my $package = MockPackage->new($real_package);

isa_ok $package, 'CPANPLUS::Dist::Debora::Package';
can_ok $package, qw(format_priority create install outputname);

like $package->outputname, qr{[.]tar[.]gz \z}xms, 'file extension is .tar.gz';

ok $package->sanitize_stagingdir, 'can sanitize stagingdir';

my $tar = $package->_tar_create;
isa_ok $tar, 'Archive::Tar';
my @files = $tar->list_files;
ok grep(m{\A [^/]}xms,     @files), 'all tar archive files are relative';
ok grep(m{/Changes \z}xms, @files), 'tar archive contains Changes file';
ok grep(m{[.]pm \z}xms,    @files), 'tar archive contains .pm file';
