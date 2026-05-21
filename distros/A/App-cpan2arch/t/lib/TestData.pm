package TestData;

use v5.42.0;

use strict;
use warnings;

use Exporter qw< import >;
our @EXPORT_OK = qw< expected_data test_diff >;

use Test2::V1 -utf8, qw<
    fail
    note
    pass
>;
use Text::Diff 1.45;

# Perl dists intended to cover various C2A's PKGBUILD outputs.
my %DISTS = (
    'Alien-GMP' => {
        version => '1.16',
        note    => 'EU::MM; PP; Alien dist; dup. prereqs/pkgs; unusual license (deprecated)',
    },
    'Data-Dump-Streamer' => {
        version => '2.42',
        note    => 'M::B; XS; no perl in depends + perl in makedepends',
    },
    'DateTime-Format-RFC3339' => {
        version => 'v1.10.0',
        note    => 'EU::MM; PP; multi licenses; unusual license (unrestricted); install license',
    },
    'Devel-REPL' => {
        version => '1.003029',
        note    =>
          'EU::MM; PP; dup. prereqs/pkgs; optional_features; multi optional_features; single quote in optdepends',
    },
    'FCGI-Client' => {
        version => '0.09',
        note    => 'M::B::T; PP; flagged OOD pkgs (Official)',
    },
    'File-KDBX' => {
        version => '0.906',
        note    => 'EU::MM; PP; dup. prereqs/pkgs; optional_features; failed modules; missing pkgs',
    },
    'Gtk2-Notify' => {
        version => '0.05',
        note    => 'M::I; XS; no perl in depends; unusual license (open_source); odd pkgs (AUR)',
    },
    'Lingua-EN-Titlecase-Simple' => {
        version => '1.015',
        note    => 'EU::MM; PP; single quote in abstract; install license',
    },
    'Minilla' => {
        version => 'v3.1.29',
        note    => 'M::B::T; PP; dup. prereqs/pkgs; missing pkgs; odd pkgs',
    },
    'Padre' => {
        version => '1.02',
        note    => 'M::I; XS; dup. prereqs/pkgs; missing pkgs; flagged OOD pkgs (AUR); odd pkgs',
    },
    'Perl-Critic' => {
        version => '1.156',
        note    => 'M::B; PP; dup. prereqs/pkgs; odd pkgs',
    },
    'Regexp-Common' => {
        version => '2024080801',
        note    => 'EU::MM; PP; dup. prereqs/pkgs; multi licenses; multi license files; install license; missing pkgs',
    },
    'Regexp-Debugger' => {
        version => '0.002007',
        note    => 'EU::MM; PP; no license',
    },
);

my %EXPECTED = (
    'Alien-GMP' => {
        meta => {
            abstract   => 'Alien package for the GNU Multiple Precision library.',
            author     => 'PLICEASE',
            checksum   => '090cd48ee535bf62f178895617a851783ae11aa4c6006a1fd4d84a432f113da5',
            dependency => [
                {
                    module       => 'Test::Spelling',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Spec',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::NoTabs',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Pod::Spelling::CommonMistakes',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::More',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.98',
                },
                {
                    module       => 'Test::Pod::Coverage',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::CPAN::Changes',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'YAML',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'FindBin',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Fixme',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.07',
                },
                {
                    module       => 'Test::Strict',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Pod',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::EOL',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.006',
                },
                {
                    module       => 'Alien::Base',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.46',
                },
                {
                    module       => 'perl',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '5.006',
                },
                {
                    module       => 'Test2::V0',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0.000060',
                },
                {
                    module       => 'Test::Alien',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Alien::Build::MM',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0.32',
                },
                {
                    module       => 'ExtUtils::CBuilder',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Alien::Build',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '1.46',
                },
                {
                    module       => 'perl',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '5.006',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '6.52',
                },
                {
                    module       => 'Alien::Build::MM',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0.32',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '6.52',
                },
                {
                    module       => 'Alien::Build',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0.32',
                },
            ],
            dist               => 'Alien-GMP',
            download_url       => 'https://cpan.metacpan.org/authors/id/P/PL/PLICEASE/Alien-GMP-1.16.tar.gz',
            has_license        => 'LICENSE',
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => false,
            license            => ['lgpl_3_0'],
            name               => 'Alien-GMP-1.16',
            spdx_expression    => undef,
            version            => '1.16',
        },
        arch_prereqs => {
            checkdepends => [
                'perl-alien-build',
                'perl-test-simple',
                'perl>=5.6.0',
            ],
            depends => [
                'perl-alien-build>=0.32',
                'perl>=5.6.0',
            ],
            makedepends => [
                'perl-extutils-cbuilder',
                'perl-extutils-makemaker>=6.52',
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=PLICEASE
            # Alien dists may have dynamic dependencies not listed in metadata; manual inspection
            # and clean chroot builds are advised.
            _dist=Alien-GMP
            pkgname=perl-${_dist@L}
            pkgver=1.16
            pkgrel=1
            pkgdesc='Alien package for the GNU Multiple Precision library.'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            license=(
                'LGPL-3.0'  # Deprecated by LGPL-3.0-only and LGPL-3.0-or-later.
                            # License text is identical; manual inspection is advised.
            )
            depends=(
                'perl-alien-build>=0.32'
                'perl>=5.6.0'
            )
            makedepends=(
                'perl-extutils-cbuilder'
                'perl-extutils-makemaker>=6.52'
            )
            checkdepends=(
                'perl-alien-build'
                'perl-test-simple'
                'perl>=5.6.0'
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('090cd48ee535bf62f178895617a851783ae11aa4c6006a1fd4d84a432f113da5')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1

                /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
                make
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make install INSTALLDIRS=vendor DESTDIR="$pkgdir"
            }
            END
    },
    'Data-Dump-Streamer' => {
        meta => {
            abstract   => 'Accurately serialize a data structure as Perl code.',
            author     => 'YVES',
            checksum   => '47f6e51fb45ce7be561e01481add0c2e1c0cd85df4b9e212f3923cd3064d1cad',
            dependency => [
                {
                    module       => 'perl',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '5.006',
                },
                {
                    module       => 'Module::Build',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'ExtUtils::Depends',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'PadWalker',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0.99',
                },
                {
                    module       => 'Compress::Zlib',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Cpanel::JSON::XS',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Algorithm::Diff',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'MIME::Base64',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'overload',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'IO::File',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'strict',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'warnings',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'vars',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Hash::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'B::Utils',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'B',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Text::Balanced',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'B::Deparse',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'warnings::register',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Symbol',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'DynaLoader',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Exporter',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Data::Dumper',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Text::Abbrev',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 're',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'vars',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'warnings',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'strict',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'utf8',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::More',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'B::Deparse',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Carp',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Devel::Peek',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'overload',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'ExtUtils::CBuilder',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Config',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 're',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'base',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Symbol',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Text::Abbrev',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Data::Dumper',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
            ],
            dist               => 'Data-Dump-Streamer',
            download_url       => 'https://cpan.metacpan.org/authors/id/Y/YV/YVES/Data-Dump-Streamer-2.42.tar.gz',
            has_license        => undef,
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => true,
            license            => ['perl_5'],
            name               => 'Data-Dump-Streamer-2.42',
            spdx_expression    => undef,
            version            => '2.42',
        },
        arch_prereqs => {
            depends => [
                'perl-b-utils',
                'perl-data-dumper',
                'perl-exporter',
                'perl-io',
                'perl-text-abbrev',
                'perl-text-balanced',
                'perl>=5.6.0',
            ],
            makedepends => [
                'perl-base',
                'perl-carp',
                'perl-extutils-cbuilder',
                'perl-extutils-depends',
                'perl-module-build',
                'perl-test-simple',
            ],
            optdepends => [
                'perl-algorithm-diff',
                'perl-cpanel-json-xs',
                'perl-io-compress',
                'perl-mime-base64',
                'perl-padwalker>=0.99',
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=YVES
            _dist=Data-Dump-Streamer
            pkgname=perl-${_dist@L}
            pkgver=2.42
            pkgrel=1
            pkgdesc='Accurately serialize a data structure as Perl code.'
            arch=('x86_64')  # XS modules might depend on external libs; manual inspection is advised.
            url=https://metacpan.org/dist/$_dist
            license=('Artistic-1.0-Perl OR GPL-1.0-or-later')
            depends=(
                'perl-b-utils'
                'perl-data-dumper'
                'perl-exporter'
                'perl-io'
                'perl-text-abbrev'
                'perl-text-balanced'
                'perl>=5.6.0'
            )
            makedepends=(
                'perl-base'
                'perl-carp'
                'perl-extutils-cbuilder'
                'perl-extutils-depends'
                'perl-module-build'
                'perl-test-simple'
            )
            optdepends=(
                'perl-algorithm-diff'
                'perl-cpanel-json-xs'
                'perl-io-compress'
                'perl-mime-base64'
                'perl-padwalker>=0.99'
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('47f6e51fb45ce7be561e01481add0c2e1c0cd85df4b9e212f3923cd3064d1cad')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MB_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1 MODULEBUILDRC=/dev/null

                /usr/bin/perl Build.PL --create_packlist=0
                ./Build
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                ./Build test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                ./Build install --installdirs=vendor --destdir="$pkgdir"
            }
            END
    },
    'DateTime-Format-RFC3339' => {
        meta => {
            abstract   => 'Parse and format RFC3339 datetime strings',
            author     => 'IKEGAMI',
            checksum   => '3a5e64e7beaafd2c64a12109e3cc0fed3db3f893b0323b43b52964fc2c0c8496',
            dependency => [
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '6.74',
                },
                {
                    module       => 'Test::More',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Pod',
                    phase        => 'test',
                    relationship => 'recommends',
                    version      => '1.22',
                },
                {
                    module       => 'Pod::Coverage',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.18',
                },
                {
                    module       => 'Test::Pod::Coverage',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '1.08',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.01',
                },
                {
                    module       => 'warnings',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'DateTime',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'version',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'strict',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
            ],
            dist         => 'DateTime-Format-RFC3339',
            download_url =>
              'https://cpan.metacpan.org/authors/id/I/IK/IKEGAMI/DateTime-Format-RFC3339-v1.10.0.tar.gz',
            has_license        => 'LICENSE.txt',
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => false,
            license            => [
                'unknown',
                'unrestricted',
            ],
            name            => 'DateTime-Format-RFC3339-v1.10.0',
            spdx_expression => undef,
            version         => 'v1.10.0',
        },
        arch_prereqs => {
            checkdepends => ['perl-test-simple'],
            depends      => [
                'perl-datetime',
                'perl-version',
                'perl>=5.10.0',
            ],
            makedepends => ['perl-extutils-makemaker>=6.74'],
            optdepends  => ['perl-test-pod>=1.22'],

        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=IKEGAMI
            _dist=DateTime-Format-RFC3339
            pkgname=perl-${_dist@L}
            pkgver=v1.10.0
            pkgrel=1
            pkgdesc='Parse and format RFC3339 datetime strings'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            # Multiple licenses listed in metadata; manual inspection is advised to
            # construct a proper SPDX expression.
            license=(
                'unknown'  # License not provided in metadata.
                           # Unknown SPDX ID; manual inspection is advised.
                'unknown'  # Not an OSI approved license, but not restricted.
                           # Unknown SPDX ID; manual inspection is advised.
            )
            depends=(
                'perl-datetime'
                'perl-version'
                'perl>=5.10.0'
            )
            makedepends=('perl-extutils-makemaker>=6.74')
            checkdepends=('perl-test-simple')
            optdepends=('perl-test-pod>=1.22')
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('3a5e64e7beaafd2c64a12109e3cc0fed3db3f893b0323b43b52964fc2c0c8496')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1

                /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
                make
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make install INSTALLDIRS=vendor DESTDIR="$pkgdir"
                install -Dm644 LICENSE.txt -t "$pkgdir/usr/share/licenses/$pkgname/"
            }
            END
    },
    'Devel-REPL' => {
        meta => {
            abstract   => 'A modern perl interactive shell',
            author     => 'ETHER',
            checksum   => '7c87ebd88fe3abab2ff8c3fb681c6446ee7a2dc1390a6df7aa604f2634473c69',
            dependency => [
                {
                    module       => 'Dist::Zilla',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '5',
                },
                {
                    module       => 'Dist::Zilla::Plugin::InstallGuide',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '1.200005',
                },
                {
                    module       => 'Dist::Zilla::Plugin::SurgicalPodWeaver',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MetaYAML',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::PluginBundle::Author::ETHER',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.119',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::CleanNamespaces',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.006',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Run::AfterRelease',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.038',
                },
                {
                    module       => 'Dist::Zilla::Plugin::UseUnsafeInc',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::Check',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::GithubMeta',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.54',
                },
                {
                    module       => 'Dist::Zilla::Plugin::GenerateFile::FromShareDir',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::Portability',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '2.000007',
                },
                {
                    module       => 'Software::License::Perl_5',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::StaticInstall',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.005',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MetaResources',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::ReadmeAnyFromPod',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.142180',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Keywords',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.004',
                },
                {
                    module       => 'Dist::Zilla::Plugin::License',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '5.038',
                },
                {
                    module       => 'Pod::Weaver::Section::AllowOverride',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::PromptIfStale',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MetaJSON',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::FileFinder::Filter',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::Contributors',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.029',
                },
                {
                    module       => 'Dist::Zilla::Plugin::AutoMetaResources',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::Commit',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '2.020',
                },
                {
                    module       => 'Dist::Zilla::Plugin::CheckIssues',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::OptionalFeature',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.019',
                },
                {
                    module       => 'Dist::Zilla::Plugin::FileFinder::ByName',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MinimumPerl',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '1.006',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::Push',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::Describe',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.004',
                },
                {
                    module       => 'Dist::Zilla::Plugin::CopyFilesFromRelease',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::Compile',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '2.039',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MetaProvides::Package',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '1.15000002',
                },
                {
                    module       => 'Dist::Zilla::Plugin::CheckPrereqsIndexed',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.019',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Manifest',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::UploadToCPAN',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::ChangesHasContent',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MetaConfig',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::Kwalitee',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '2.10',
                },
                {
                    module       => 'Dist::Zilla::Plugin::GitHub::Update',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.40',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Prereqs::AuthorDeps',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.006',
                },
                {
                    module       => 'Dist::Zilla::Plugin::ExecDir',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::EOL',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.17',
                },
                {
                    module       => 'Dist::Zilla::Plugin::RunExtraTests',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.024',
                },
                {
                    module       => 'Dist::Zilla::Plugin::CheckSelfDependency',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MetaNoIndex',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Readme',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::Remote::Check',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.004',
                },
                {
                    module       => 'Dist::Zilla::Plugin::TestRelease',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::EnsureLatestPerl',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::NextRelease',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '5.033',
                },
                {
                    module       => 'Dist::Zilla::Plugin::PodSyntaxTests',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '5.040',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MetaTests',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::Tag',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Run::AfterBuild',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.041',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MojibakeTests',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.8',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::MinimumVersion',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '2.000010',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.004',
                },
                {
                    module       => 'Dist::Zilla::Plugin::ConfirmRelease',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::AutoPrereqs',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '5.038',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::Pod::No404s',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '1.003',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::NoTabs',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.08',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::ReportPrereqs',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.022',
                },
                {
                    module       => 'Dist::Zilla::Plugin::CheckMetaResources',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Git::GatherDir',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '2.016',
                },
                {
                    module       => 'Dist::Zilla::Plugin::MakeMaker',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Authority',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '1.009',
                },
                {
                    module       => 'Dist::Zilla::PluginBundle::Git::VersionManager',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.007',
                },
                {
                    module       => 'Dist::Zilla::Plugin::CheckStrictVersion',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Prereqs',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::RewriteVersion::Transitional',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.006',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Test::CPAN::Changes',
                    phase        => 'x_Dist_Zilla',
                    relationship => 'requires',
                    version      => '0.012',
                },
                {
                    module       => 'PPI',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'B::Keywords',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'IPC::Open3',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::CleanNamespaces',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.15',
                },
                {
                    module       => 'IO::Handle',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Pod::No404s',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::CPAN::Meta',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Mojibake',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Data::Dumper::Concise',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Portability::Files',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Module::Refresh',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Data::Dump::Streamer',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '2.39',
                },
                {
                    module       => 'Sys::SigAction',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::CPAN::Changes',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.19',
                },
                {
                    module       => 'Encode',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::NoTabs',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::EOL',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Pod',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '1.41',
                },
                {
                    module       => 'Lexical::Persistence',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Spec',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Next',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::MinimumVersion',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'App::Nopaste',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Kwalitee',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '1.21',
                },
                {
                    module       => 'Test::More',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.96',
                },
                {
                    module       => 'Dist::Zilla::PluginBundle::Git::VersionManager',
                    phase        => 'develop',
                    relationship => 'recommends',
                    version      => '0.007',
                },
                {
                    module       => 'Dist::Zilla::PluginBundle::Author::ETHER',
                    phase        => 'develop',
                    relationship => 'recommends',
                    version      => '0.162',
                },
                {
                    module       => 'CPAN::Meta::Requirements',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '2.120620',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'perl',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '5.008001',
                },
                {
                    module       => 'Module::Metadata',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Spec',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'if',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'perl',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '5.008001',
                },
                {
                    module       => 'Test::More',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0.88',
                },
                {
                    module       => 'Test::Fatal',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'CPAN::Meta',
                    phase        => 'test',
                    relationship => 'recommends',
                    version      => '2.120900',
                },
                {
                    module       => 'Module::Refresh',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Data::Dump::Streamer',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '2.39',
                },
                {
                    module       => 'Sys::SigAction',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Lexical::Persistence',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'PPI',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'File::Next',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'PPI::XS',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0.902',
                },
                {
                    module       => 'B::Keywords',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Data::Dumper::Concise',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'App::Nopaste',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'strict',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Term::ReadLine',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'B::Concise',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.62',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.008001',
                },
                {
                    module       => 'warnings',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Time::HiRes',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Term::ANSIColor',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'MooseX::Getopt',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.18',
                },
                {
                    module       => 'Moose',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.93',
                },
                {
                    module       => 'Moose::Role',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Moose::Meta::Role',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Scalar::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'MooseX::Object::Pluggable',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.0009',
                },
                {
                    module       => 'File::Spec',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Module::Runtime',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Task::Weaken',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'namespace::autoclean',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Devel::Peek',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
            ],
            dist               => 'Devel-REPL',
            download_url       => 'https://cpan.metacpan.org/authors/id/E/ET/ETHER/Devel-REPL-1.003029.tar.gz',
            has_license        => 'LICENCE',
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => false,
            license            => ['perl_5'],
            name               => 'Devel-REPL-1.003029',
            spdx_expression    => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
            version            => '1.003029',
        },
        arch_prereqs => {
            checkdepends => [
                'perl-extutils-makemaker',
                'perl-if',
                'perl-pathtools',
                'perl-test-fatal',
                'perl-test-simple',
                'perl>=5.8.1',
            ],
            depends => [
                'perl-module-runtime',
                'perl-moose',
                'perl-moosex-getopt>=0.18',
                'perl-moosex-object-pluggable>=0.0009',
                'perl-namespace-autoclean',
                'perl-pathtools',
                'perl-scalar-list-utils',
                'perl-task-weaken',
                'perl-term-ansicolor',
                'perl-term-readline',
                'perl-time-hires',
                'perl>=5.8.1',
            ],
            makedepends => [
                'perl-cpan-meta-requirements>=2.120620',
                'perl-extutils-makemaker',
                'perl-module-metadata',
            ],
            optdepends => [
                q{perl-app-nopaste: Nopaste plugin - upload a session\'s input and output to a Pastebin},
                'perl-b-keywords: Keywords completion driver - tab complete Perl keywords and operators',
                'perl-cpan-meta>=2.120900',
                'perl-data-dump-streamer>=2.39: DDS plugin - better format results with Data::Dump::Streamer',
                'perl-data-dumper-concise: DDC plugin - even better format results with Data::Dumper::Concise',
                'perl-file-next: INC completion driver - tab complete module names in use and require',
                'perl-lexical-persistence: LexEnv plugin - variables declared with "my" persist between statements',
                'perl-module-refresh: Refresh plugin - automatically reload libraries with Module::Refresh',
                'perl-ppi-xs>=0.902',
                'perl-ppi: Completion plugin - extensible tab completion',
                'perl-ppi: MultiLine::PPI plugin - continue reading lines until all blocks are closed',
                'perl-ppi: PPI plugin - PPI dumping of Perl code',
                'perl-sys-sigaction: Interrupt plugin - traps SIGINT to kill long-running lines',
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=ETHER
            _dist=Devel-REPL
            pkgname=perl-${_dist@L}
            pkgver=1.003029
            pkgrel=1
            pkgdesc='A modern perl interactive shell'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            license=('Artistic-1.0-Perl OR GPL-1.0-or-later')
            depends=(
                'perl-module-runtime'
                'perl-moose'
                'perl-moosex-getopt>=0.18'
                'perl-moosex-object-pluggable>=0.0009'
                'perl-namespace-autoclean'
                'perl-pathtools'
                'perl-scalar-list-utils'
                'perl-task-weaken'
                'perl-term-ansicolor'
                'perl-term-readline'
                'perl-time-hires'
                'perl>=5.8.1'
            )
            makedepends=(
                'perl-cpan-meta-requirements>=2.120620'
                'perl-extutils-makemaker'
                'perl-module-metadata'
            )
            checkdepends=(
                'perl-extutils-makemaker'
                'perl-if'
                'perl-pathtools'
                'perl-test-fatal'
                'perl-test-simple'
                'perl>=5.8.1'
            )
            optdepends=(
                $'perl-app-nopaste: Nopaste plugin - upload a session\'s input and output to a Pastebin'
                'perl-b-keywords: Keywords completion driver - tab complete Perl keywords and operators'
                'perl-cpan-meta>=2.120900'
                'perl-data-dump-streamer>=2.39: DDS plugin - better format results with Data::Dump::Streamer'
                'perl-data-dumper-concise: DDC plugin - even better format results with Data::Dumper::Concise'
                'perl-file-next: INC completion driver - tab complete module names in use and require'
                'perl-lexical-persistence: LexEnv plugin - variables declared with "my" persist between statements'
                'perl-module-refresh: Refresh plugin - automatically reload libraries with Module::Refresh'
                'perl-ppi-xs>=0.902'
                'perl-ppi: Completion plugin - extensible tab completion'
                'perl-ppi: MultiLine::PPI plugin - continue reading lines until all blocks are closed'
                'perl-ppi: PPI plugin - PPI dumping of Perl code'
                'perl-sys-sigaction: Interrupt plugin - traps SIGINT to kill long-running lines'
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('7c87ebd88fe3abab2ff8c3fb681c6446ee7a2dc1390a6df7aa604f2634473c69')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1

                /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
                make
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make install INSTALLDIRS=vendor DESTDIR="$pkgdir"
            }
            END
    },
    'FCGI-Client' => {
        meta => {
            abstract   => 'client library for fastcgi protocol',
            author     => 'TOKUHIROM',
            checksum   => 'd537cb09ce5aab3f447a6bb4415e46cc06efe01611cd56289b5582bdb46221e8',
            dependency => [
                {
                    module       => 'Test::More',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'HTTP::Request',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Perl::Critic',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::TCP',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::MinimumVersion::Fast',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.04',
                },
                {
                    module       => 'FCGI',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::CPAN::Meta',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Pod',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '1.41',
                },
                {
                    module       => 'Test::PAUSE::Permissions',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.04',
                },
                {
                    module       => 'Test::Spellunker',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => 'v0.2.7',
                },
                {
                    module       => 'IO::Socket::UNIX',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Moo',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.008001',
                },
                {
                    module       => 'Type::Tiny',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Module::Build::Tiny',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0.035',
                },
            ],
            dist               => 'FCGI-Client',
            download_url       => 'https://cpan.metacpan.org/authors/id/T/TO/TOKUHIROM/FCGI-Client-0.09.tar.gz',
            has_license        => 'LICENSE',
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => false,
            license            => ['perl_5'],
            name               => 'FCGI-Client-0.09',
            spdx_expression    => undef,
            version            => '0.09',
        },
        arch_prereqs => {
            depends => [
                'perl-io',
                'perl-moo>=2',
                {
                    'perl-type-tiny' => { flag_date => '2025-11-22' },
                },
                'perl>=5.8.1',
            ],
            makedepends => [
                'perl-module-build-tiny>=0.035',
                'perl-test-simple',
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=TOKUHIROM
            _dist=FCGI-Client
            pkgname=perl-${_dist@L}
            pkgver=0.09
            pkgrel=1
            pkgdesc='client library for fastcgi protocol'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            license=('Artistic-1.0-Perl OR GPL-1.0-or-later')
            depends=(
                'perl-io'
                'perl-moo>=2'
                'perl-type-tiny'  # Package is flagged out-of-date on 2025-11-22.
                'perl>=5.8.1'
            )
            makedepends=(
                'perl-module-build-tiny>=0.035'
                'perl-test-simple'
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('d537cb09ce5aab3f447a6bb4415e46cc06efe01611cd56289b5582bdb46221e8')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MB_OPT PERL5LIB PERL_LOCAL_LIB_ROOT

                /usr/bin/perl Build.PL --create_packlist=0
                ./Build
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                ./Build test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                ./Build install --installdirs=vendor --destdir="$pkgdir"
            }
            END
    },
    'File-KDBX' => {
        optionals => {
            'Compress::Raw::Zlib'    => ['ability to read and write compressed KDBX files'],
            'File::KDBX::XS'         => ['speed improvements (requires C compiler)'],
            'IO::Compress::Gzip'     => ['ability to read and write compressed KDBX files'],
            'IO::Uncompress::Gunzip' => ['ability to read and write compressed KDBX files'],
            'Pass::OTP'              => ['ability to generate one-time passwords from configured database entries'],
        },
        meta => {
            abstract   => 'Encrypted database to store secret text and files',
            author     => 'CCM',
            checksum   => 'b47b7f9333abb491eaaec6345a14e7f93956d143944c14b8164a7fd1b224bd6f',
            dependency => [
                {
                    module       => 'Test::Pod',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '1.41',
                },
                {
                    module       => 'Test::Pod::Coverage',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '1.08',
                },
                {
                    module       => 'Software::License::Perl_5',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Pod::Coverage::TrustPod',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::CleanNamespaces',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.15',
                },
                {
                    module       => 'Dist::Zilla::PluginBundle::Author::CCM',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::CPAN::Meta',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::KDBX::XS',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Perl::Critic',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Prereqs::Soften',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::More',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.96',
                },
                {
                    module       => 'Dist::Zilla::Plugin::OptionalFeature',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::NoTabs',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'IO::Compress::Gzip',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Pass::OTP',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::MinimumVersion',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::EOL',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '5',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Prereqs',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Compress::Raw::Zlib',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla::Plugin::Encoding',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Portability::Files',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'IO::Uncompress::Gunzip',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::CPAN::Changes',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.19',
                },
                {
                    module       => 'Test::Pod::No404s',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Deep',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'FindBin',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'IPC::Open3',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Math::BigInt',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '1.993',
                },
                {
                    module       => 'File::Spec',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Warnings',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'utf8',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Getopt::Std',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::More',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '1.001004_001',
                },
                {
                    module       => 'Test::Fatal',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'lib',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'IO::Handle',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'CPAN::Meta',
                    phase        => 'test',
                    relationship => 'recommends',
                    version      => '2.120900',
                },
                {
                    module       => 'Pass::OTP',
                    phase        => 'test',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'POSIX::1003',
                    phase        => 'test',
                    relationship => 'suggests',
                    version      => '0',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Spec',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Pass::OTP',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'IO::Uncompress::Gunzip',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'IO::Compress::Gzip',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Compress::Raw::Zlib',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'File::KDBX::XS',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Crypt::Stream::Twofish',
                    phase        => 'runtime',
                    relationship => 'suggests',
                    version      => '0',
                },
                {
                    module       => 'Crypt::Stream::Serpent',
                    phase        => 'runtime',
                    relationship => 'suggests',
                    version      => '0.055',
                },
                {
                    module       => 'Crypt::Misc',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.049',
                },
                {
                    module       => 'Data::Dumper',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'boolean',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'strict',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Temp',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Crypt::Argon2',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Iterator::Simple',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Time::Local',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.19',
                },
                {
                    module       => 'warnings',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Scope::Guard',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Storable',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Devel::GlobalDestruction',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Crypt::Cipher::AES',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'POSIX',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Crypt::Mode::CBC',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Crypt::Digest',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'XML::LibXML',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Text::ParseWords',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Symbol',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Math::BigInt',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.993',
                },
                {
                    module       => 'Crypt::Stream::Salsa20',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.055',
                },
                {
                    module       => 'Crypt::Cipher',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Module::Loaded',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'namespace::clean',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'overload',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'IO::Handle',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'XML::LibXML::Reader',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Exporter',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Scalar::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Encode',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Crypt::Stream::ChaCha',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.048',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.010',
                },
                {
                    module       => 'Carp',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Crypt::PRNG',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Module::Load',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Ref::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'List::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.33',
                },
                {
                    module       => 'IPC::Cmd',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.84',
                },
                {
                    module       => 'Time::Piece',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.33',
                },
                {
                    module       => 'Crypt::Mac::HMAC',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Hash::Util::FieldHash',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
            ],
            dist               => 'File-KDBX',
            download_url       => 'https://cpan.metacpan.org/authors/id/C/CC/CCM/File-KDBX-0.906.tar.gz',
            has_license        => 'LICENSE',
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => false,
            license            => ['perl_5'],
            name               => 'File-KDBX-0.906',
            spdx_expression    => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
            version            => '0.906',
        },
        arch_prereqs => {
            checkdepends => [
                'perl-extutils-makemaker',
                'perl-findbin',
                'perl-io',
                'perl-lib',
                'perl-math-bigint>=1.993',
                'perl-pathtools',
                'perl-test-deep',
                'perl-test-fatal',
                'perl-test-simple',
                'perl-test-warnings',
            ],
            depends => [
                'perl-boolean',
                'perl-carp',
                'perl-crypt-argon2',
                'perl-cryptx',
                'perl-data-dumper',
                'perl-devel-globaldestruction',
                'perl-encode',
                'perl-exporter',
                'perl-file-temp',
                'perl-io',
                'perl-ipc-cmd>=0.84',
                'perl-iterator-simple',
                'perl-math-bigint>=1.993',
                'perl-module-load',
                'perl-module-loaded',
                'perl-namespace-clean',
                'perl-ref-util',
                'perl-scalar-list-utils',
                'perl-scope-guard',
                'perl-storable',
                'perl-text-parsewords',
                'perl-time-local>=1.19',
                'perl-time-piece>=1.33',
                'perl-xml-libxml',
                'perl>=5.10.0',
            ],
            makedepends => ['perl-extutils-makemaker'],
            optdepends  => [
                {
                    'Crypt::Stream::Serpent' => {
                        failed  => true,
                        version => '0.055',
                    },
                },
                {
                    'Crypt::Stream::Twofish' => {
                        failed  => true,
                        version => '0',
                    },
                },
                'perl-compress-raw-zlib: ability to read and write compressed KDBX files',
                'perl-cpan-meta>=2.120900',
                {
                    'perl-file-kdbx-xs: speed improvements (requires C compiler)' => { missing => 'File::KDBX::XS' },
                },
                'perl-io-compress: ability to read and write compressed KDBX files',
                'perl-pass-otp: ability to generate one-time passwords from configured database entries',
                {
                    'perl-posix-1003' => { missing => 'POSIX::1003' },
                },
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=CCM
            _dist=File-KDBX
            pkgname=perl-${_dist@L}
            pkgver=0.906
            pkgrel=1
            pkgdesc='Encrypted database to store secret text and files'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            license=('Artistic-1.0-Perl OR GPL-1.0-or-later')
            depends=(
                'perl-boolean'
                'perl-carp'
                'perl-crypt-argon2'
                'perl-cryptx'
                'perl-data-dumper'
                'perl-devel-globaldestruction'
                'perl-encode'
                'perl-exporter'
                'perl-file-temp'
                'perl-io'
                'perl-ipc-cmd>=0.84'
                'perl-iterator-simple'
                'perl-math-bigint>=1.993'
                'perl-module-load'
                'perl-module-loaded'
                'perl-namespace-clean'
                'perl-ref-util'
                'perl-scalar-list-utils'
                'perl-scope-guard'
                'perl-storable'
                'perl-text-parsewords'
                'perl-time-local>=1.19'
                'perl-time-piece>=1.33'
                'perl-xml-libxml'
                'perl>=5.10.0'
            )
            makedepends=('perl-extutils-makemaker')
            checkdepends=(
                'perl-extutils-makemaker'
                'perl-findbin'
                'perl-io'
                'perl-lib'
                'perl-math-bigint>=1.993'
                'perl-pathtools'
                'perl-test-deep'
                'perl-test-fatal'
                'perl-test-simple'
                'perl-test-warnings'
            )
            optdepends=(
                '?'                                                                                       # Failed to fetch Crypt::Stream::Serpent module (version: 0.055).
                '?'                                                                                       # Failed to fetch Crypt::Stream::Twofish module.
                'perl-compress-raw-zlib: ability to read and write compressed KDBX files'
                'perl-cpan-meta>=2.120900'
                'perl-file-kdbx-xs: speed improvements (requires C compiler)'                             # Package for File::KDBX::XS is missing.
                'perl-io-compress: ability to read and write compressed KDBX files'
                'perl-pass-otp: ability to generate one-time passwords from configured database entries'
                'perl-posix-1003'                                                                         # Package for POSIX::1003 is missing.
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('b47b7f9333abb491eaaec6345a14e7f93956d143944c14b8164a7fd1b224bd6f')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1

                /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
                make
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make install INSTALLDIRS=vendor DESTDIR="$pkgdir"
            }
            END
    },
    'Gtk2-Notify' => {
        meta => {
            abstract   => 'Perl interface to libnotify',
            author     => 'FLORA',
            checksum   => '88189ae68dfbd54615ad133df07e2ec8048d06d8b9586add1227d74eb2ebb047',
            dependency => [
                {
                    module       => 'ExtUtils::PkgConfig',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Gtk2::CodeGen',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Glib::MakeHelper',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'ExtUtils::Depends',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Gtk2',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
            ],
            dist               => 'Gtk2-Notify',
            download_url       => 'https://cpan.metacpan.org/authors/id/F/FL/FLORA/Gtk2-Notify-0.05.tar.gz',
            has_license        => undef,
            has_module_install => true,
            has_multi_licenses => false,
            has_xs             => true,
            license            => ['open_source'],
            name               => 'Gtk2-Notify-0.05',
            spdx_expression    => undef,
            version            => '0.05',
        },
        arch_prereqs => {
            depends => [
                'gtk2-perl',
                'perl',
            ],
            makedepends => [
                'glib-perl',
                'perl-extutils-depends',
                'perl-extutils-pkgconfig',
                'perl-module-install',
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=FLORA
            _dist=Gtk2-Notify
            pkgname=perl-${_dist@L}
            pkgver=0.05
            pkgrel=1
            pkgdesc='Perl interface to libnotify'
            arch=('x86_64')  # XS modules might depend on external libs; manual inspection is advised.
            url=https://metacpan.org/dist/$_dist
            license=(
                'unknown'  # Other Open Source Initiative (OSI) approved license.
                           # Unknown SPDX ID; manual inspection is advised.
            )
            depends=(
                'gtk2-perl'
                'perl'
            )
            makedepends=(
                'glib-perl'
                'perl-extutils-depends'
                'perl-extutils-pkgconfig'
                'perl-module-install'
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('88189ae68dfbd54615ad133df07e2ec8048d06d8b9586add1227d74eb2ebb047')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1 PERL_AUTOINSTALL=--skipdeps

                /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
                make
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make install INSTALLDIRS=vendor DESTDIR="$pkgdir"
            }
            END
    },
    'Lingua-EN-Titlecase-Simple' => {
        meta => {
            abstract   => 'John Gruber\'s headline capitalization script',
            author     => 'ARISTOTLE',
            checksum   => '74555c28d16a2dc81d87cda5a82a0f7bec69f402959177b6a18fe6e91fa1f692',
            dependency => [
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.008001',
                },
                {
                    module       => 'Data::Dumper',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::More',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
            ],
            dist         => 'Lingua-EN-Titlecase-Simple',
            download_url =>
              'https://cpan.metacpan.org/authors/id/A/AR/ARISTOTLE/Lingua-EN-Titlecase-Simple-1.015.tar.gz',
            has_license        => 'LICENSE',
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => false,
            license            => ['mit'],
            name               => 'Lingua-EN-Titlecase-Simple-1.015',
            spdx_expression    => undef,
            version            => '1.015',
        },
        arch_prereqs => {
            checkdepends => [
                'perl-data-dumper',
                'perl-test-simple',
            ],
            depends => ['perl>=5.8.1'],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=ARISTOTLE
            _dist=Lingua-EN-Titlecase-Simple
            pkgname=perl-${_dist@L}
            pkgver=1.015
            pkgrel=1
            pkgdesc=$'John Gruber\'s headline capitalization script'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            license=('MIT')
            depends=('perl>=5.8.1')
            checkdepends=(
                'perl-data-dumper'
                'perl-test-simple'
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('74555c28d16a2dc81d87cda5a82a0f7bec69f402959177b6a18fe6e91fa1f692')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1

                /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
                make
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make install INSTALLDIRS=vendor DESTDIR="$pkgdir"
                install -Dm644 LICENSE -t "$pkgdir/usr/share/licenses/$pkgname/"
            }
            END
    },
    'Minilla' => {
        meta => {
            abstract   => 'CPAN module authoring tool',
            author     => 'SYOHEX',
            checksum   => 'bd6f41ee82dfe387c83f7531c952616d0ccc3a2c11d9ba051b213ac4dfc7e352',
            dependency => [
                {
                    module       => 'Test::Spellunker',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => 'v0.2.7',
                },
                {
                    module       => 'Test::PAUSE::Permissions',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.07',
                },
                {
                    module       => 'Test::CPAN::Meta',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::MinimumVersion::Fast',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '0.04',
                },
                {
                    module       => 'Test::Pod',
                    phase        => 'develop',
                    relationship => 'requires',
                    version      => '1.41',
                },
                {
                    module       => 'Devel::PPPort',
                    phase        => 'runtime',
                    relationship => 'suggests',
                    version      => '0',
                },
                {
                    module       => 'Term::ANSIColor',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'TAP::Harness::Env',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Try::Tiny',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'parent',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.010001',
                },
                {
                    module       => 'CPAN::Meta',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.132830',
                },
                {
                    module       => 'Text::MicroTemplate',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.20',
                },
                {
                    module       => 'Module::Runtime',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::pushd',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Term::Encoding',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Time::Piece',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.16',
                },
                {
                    module       => 'URI',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Moo',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.001',
                },
                {
                    module       => 'Pod::Markdown',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.322',
                },
                {
                    module       => 'Module::CPANfile',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.9025',
                },
                {
                    module       => 'File::Which',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'TOML',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.95',
                },
                {
                    module       => 'Module::Metadata',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.000037',
                },
                {
                    module       => 'App::cpanminus',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.6902',
                },
                {
                    module       => 'Archive::Tar',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.60',
                },
                {
                    module       => 'Data::Section::Simple',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.04',
                },
                {
                    module       => 'Getopt::Long',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.36',
                },
                {
                    module       => 'ExtUtils::Manifest',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.54',
                },
                {
                    module       => 'version',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::MinimumVersion::Fast',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0.04',
                },
                {
                    module       => 'Test::Spellunker',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => 'v0.2.7',
                },
                {
                    module       => 'CPAN::Uploader',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Software::License',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0.103010',
                },
                {
                    module       => 'Version::Next',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Test::Pod',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Pod::Escapes',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Test::PAUSE::Permissions',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Test::CPAN::Meta',
                    phase        => 'runtime',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'Module::Build::Tiny',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0.035',
                },
                {
                    module       => 'Test::More',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0.98',
                },
                {
                    module       => 'Module::Build::Tiny',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0.035',
                },
                {
                    module       => 'Test::Requires',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'JSON',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'CPAN::Meta::Validator',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Temp',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Output',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Copy::Recursive',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Dist::Zilla',
                    phase        => 'test',
                    relationship => 'suggests',
                    version      => '0',
                },
                {
                    module       => 'Devel::CheckLib',
                    phase        => 'test',
                    relationship => 'recommends',
                    version      => '0',
                },
            ],
            dist               => 'Minilla',
            download_url       => 'https://cpan.metacpan.org/authors/id/S/SY/SYOHEX/Minilla-v3.1.29.tar.gz',
            has_license        => 'LICENSE',
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => false,
            license            => ['perl_5'],
            name               => 'Minilla-v3.1.29',
            spdx_expression    => undef,
            version            => 'v3.1.29',
        },
        arch_prereqs => {
            checkdepends => [
                'perl-cpan-meta',
                'perl-file-copy-recursive',
                'perl-file-temp',
                'perl-json',
                'perl-module-build-tiny>=0.035',
                'perl-test-output',
                'perl-test-requires',
                'perl-test-simple',
            ],
            depends => [
                'cpanminus>=1.6902',
                'perl-archive-tar>=1.60',
                'perl-cpan-meta>=2.132830',
                'perl-data-section-simple>=0.04',
                'perl-extutils-manifest>=1.54',
                'perl-file-pushd',
                'perl-file-which',
                'perl-getopt-long>=2.36',
                'perl-module-cpanfile>=0.9025',
                'perl-module-metadata>=1.000037',
                'perl-module-runtime',
                'perl-moo>=1.001',
                'perl-parent',
                'perl-pod-markdown>=1.322',
                'perl-term-ansicolor',
                'perl-term-encoding',
                'perl-test-harness',
                'perl-text-microtemplate>=0.20',
                'perl-time-piece>=1.16',
                'perl-toml>=0.95',
                'perl-try-tiny',
                'perl-uri',
                'perl-version',
                'perl>=5.10.1',
            ],
            makedepends => ['perl-module-build-tiny>=0.035'],
            optdepends  => [
                'perl-cpan-uploader',
                'perl-devel-checklib',
                'perl-devel-ppport',
                'perl-dist-zilla',
                'perl-pod-escapes',
                'perl-software-license>=0.103010',
                {
                    'perl-spellunker>=v0.2.7' => { missing => 'Test::Spellunker' },
                },
                'perl-test-cpan-meta',
                {
                    'perl-test-minimumversion-fast>=0.04' => { missing => 'Test::MinimumVersion::Fast' },
                },
                {
                    'perl-test-pause-permissions' => { missing => 'Test::PAUSE::Permissions' },
                },
                'perl-test-pod',
                'perl-version-next',
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=SYOHEX
            _dist=Minilla
            pkgname=perl-${_dist@L}
            pkgver=v3.1.29
            pkgrel=1
            pkgdesc='CPAN module authoring tool'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            license=('Artistic-1.0-Perl OR GPL-1.0-or-later')
            depends=(
                'cpanminus>=1.6902'
                'perl-archive-tar>=1.60'
                'perl-cpan-meta>=2.132830'
                'perl-data-section-simple>=0.04'
                'perl-extutils-manifest>=1.54'
                'perl-file-pushd'
                'perl-file-which'
                'perl-getopt-long>=2.36'
                'perl-module-cpanfile>=0.9025'
                'perl-module-metadata>=1.000037'
                'perl-module-runtime'
                'perl-moo>=1.001'
                'perl-parent'
                'perl-pod-markdown>=1.322'
                'perl-term-ansicolor'
                'perl-term-encoding'
                'perl-test-harness'
                'perl-text-microtemplate>=0.20'
                'perl-time-piece>=1.16'
                'perl-toml>=0.95'
                'perl-try-tiny'
                'perl-uri'
                'perl-version'
                'perl>=5.10.1'
            )
            makedepends=('perl-module-build-tiny>=0.035')
            checkdepends=(
                'perl-cpan-meta'
                'perl-file-copy-recursive'
                'perl-file-temp'
                'perl-json'
                'perl-module-build-tiny>=0.035'
                'perl-test-output'
                'perl-test-requires'
                'perl-test-simple'
            )
            optdepends=(
                'perl-cpan-uploader'
                'perl-devel-checklib'
                'perl-devel-ppport'
                'perl-dist-zilla'
                'perl-pod-escapes'
                'perl-software-license>=0.103010'
                'perl-spellunker>=v0.2.7'              # Package for Test::Spellunker is missing.
                'perl-test-cpan-meta'
                'perl-test-minimumversion-fast>=0.04'  # Package for Test::MinimumVersion::Fast is missing.
                'perl-test-pause-permissions'          # Package for Test::PAUSE::Permissions is missing.
                'perl-test-pod'
                'perl-version-next'
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('bd6f41ee82dfe387c83f7531c952616d0ccc3a2c11d9ba051b213ac4dfc7e352')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MB_OPT PERL5LIB PERL_LOCAL_LIB_ROOT

                /usr/bin/perl Build.PL --create_packlist=0
                ./Build
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                ./Build test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                ./Build install --installdirs=vendor --destdir="$pkgdir"
            }
            END
    },
    'Padre' => {
        meta => {
            abstract   => 'Perl Application Development and Refactoring Environment',
            author     => 'SZABGAB',
            checksum   => 'e7fc64539810858750c60d7b24870585f8d481a7490549880b816786d4f63983',
            dependency => [
                {
                    module       => 'List::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.18',
                },
                {
                    module       => 'IO::Scalar',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.110',
                },
                {
                    module       => 'File::Which',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.08',
                },
                {
                    module       => 'File::Temp',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.20',
                },
                {
                    module       => 'Getopt::Long',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'version',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.80',
                },
                {
                    module       => 'Text::Patch',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.8',
                },
                {
                    module       => 'Pod::Abstract',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.16',
                },
                {
                    module       => 'Text::Diff',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.41',
                },
                {
                    module       => 'Wx',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.9916',
                },
                {
                    module       => 'PPI',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.218',
                },
                {
                    module       => 'POSIX',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'DBD::SQLite',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.35',
                },
                {
                    module       => 'IO::String',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.08',
                },
                {
                    module       => 'CGI',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.47',
                },
                {
                    module       => 'HTML::Entities',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.57',
                },
                {
                    module       => 'Pod::POM',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.17',
                },
                {
                    module       => 'LWP::UserAgent',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.815',
                },
                {
                    module       => 'Term::ReadLine',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Pod::Simple',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.07',
                },
                {
                    module       => 'Class::Adapter',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.05',
                },
                {
                    module       => 'Pod::Functions',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::ShareDir',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.00',
                },
                {
                    module       => 'ORLite::Migrate',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.10',
                },
                {
                    module       => 'File::Find::Rule',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.30',
                },
                {
                    module       => 'B::Deparse',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'IPC::Open2',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Algorithm::Diff',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.19',
                },
                {
                    module       => 'Parse::ExuberantCTags',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.00',
                },
                {
                    module       => 'Devel::Dumpvar',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.04',
                },
                {
                    module       => 'Debug::Client',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.29',
                },
                {
                    module       => 'Params::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.33',
                },
                {
                    module       => 'Wx::Scintilla',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.39',
                },
                {
                    module       => 'URI',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Parse::Functions',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.01',
                },
                {
                    module       => 'Class::XSAccessor',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.13',
                },
                {
                    module       => 'YAML::Tiny',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.32',
                },
                {
                    module       => 'File::Glob',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'ORLite',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.98',
                },
                {
                    module       => 'Module::Build',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.3603',
                },
                {
                    module       => 'Probe::Perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.01',
                },
                {
                    module       => 'LWP',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.815',
                },
                {
                    module       => 'File::Basename',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'IPC::Open3',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Text::Balanced',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.01',
                },
                {
                    module       => 'IPC::Run',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.83',
                },
                {
                    module       => 'Module::CoreList',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.22',
                },
                {
                    module       => 'FindBin',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'PPIx::Regexp',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.011',
                },
                {
                    module       => 'DBI',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.58',
                },
                {
                    module       => 'JSON::XS',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.29',
                },
                {
                    module       => 'File::Spec::Functions',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.2701',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.011000',
                },
                {
                    module       => 'File::Copy::Recursive',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.37',
                },
                {
                    module       => 'Sort::Versions',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.5',
                },
                {
                    module       => 'Wx::Perl::ProcessStream',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.32',
                },
                {
                    module       => 'App::cpanminus',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.9923',
                },
                {
                    module       => 'File::HomeDir',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.91',
                },
                {
                    module       => 'Text::FindIndent',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.10',
                },
                {
                    module       => 'threads::shared',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.33',
                },
                {
                    module       => 'Data::Dumper',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.101',
                },
                {
                    module       => 'File::Spec',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.2701',
                },
                {
                    module       => 'Storable',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.16',
                },
                {
                    module       => 'File::Remove',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.40',
                },
                {
                    module       => 'PPIx::EditorTools',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.18',
                },
                {
                    module       => 'POD2::Base',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.043',
                },
                {
                    module       => 'Capture::Tiny',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.06',
                },
                {
                    module       => 'HTML::Parser',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.58',
                },
                {
                    module       => 'Parse::ErrorString::Perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.18',
                },
                {
                    module       => 'List::MoreUtils',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.22',
                },
                {
                    module       => 'Template::Tiny',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.11',
                },
                {
                    module       => 'IO::Socket',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.30',
                },
                {
                    module       => 'Pod::Perldoc',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.23',
                },
                {
                    module       => 'File::Path',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.08',
                },
                {
                    module       => 'ExtUtils::Manifest',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.56',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '6.56',
                },
                {
                    module       => 'Module::Starter',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.60',
                },
                {
                    module       => 'Class::Inspector',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.22',
                },
                {
                    module       => 'Encode',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.26',
                },
                {
                    module       => 'Cwd',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.2701',
                },
                {
                    module       => 'Pod::Simple::XHTML',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.04',
                },
                {
                    module       => 'Devel::Refactor',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.05',
                },
                {
                    module       => 'File::pushd',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.00',
                },
                {
                    module       => 'Time::HiRes',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.9718',
                },
                {
                    module       => 'Module::Manifest',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.07',
                },
                {
                    module       => 'threads',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.71',
                },
                {
                    module       => 'Test::Script',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '1.07',
                },
                {
                    module       => 'Test::MockObject',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '1.09',
                },
                {
                    module       => 'Test::More',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0.98',
                },
                {
                    module       => 'Locale::Msgfmt',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0.15',
                },
                {
                    module       => 'Test::Warn',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0.24',
                },
                {
                    module       => 'Test::NoWarnings',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '1.04',
                },
                {
                    module       => 'Test::Exception',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0.27',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '6.59',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '6.59',
                },
                {
                    module       => 'ExtUtils::Embed',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '1.250601',
                },
                {
                    module       => 'Alien::wxWidgets',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0.62',
                },
            ],
            dist               => 'Padre',
            download_url       => 'https://cpan.metacpan.org/authors/id/S/SZ/SZABGAB/Padre-1.02.tar.gz',
            has_license        => 'COPYING',
            has_module_install => true,
            has_multi_licenses => false,
            has_xs             => true,
            license            => ['perl_5'],
            name               => 'Padre-1.02',
            spdx_expression    => undef,
            version            => '1.02',
        },
        arch_prereqs => {
            depends => [
                'cpanminus>=0.9923',
                'perl-algorithm-diff>=1.19',
                'perl-capture-tiny>=0.06',
                'perl-cgi>=3.47',
                'perl-class-adapter>=1.05',
                'perl-class-inspector>=1.22',
                'perl-class-xsaccessor>=1.13',
                'perl-data-dumper>=2.101',
                'perl-dbd-sqlite>=1.35',
                'perl-dbi>=1.58',
                {
                    'perl-debug-client>=0.29' => { flag_date => '2024-12-14' },
                },
                'perl-devel-dumpvar>=0.04',
                'perl-devel-refactor>=0.05',
                'perl-encode>=2.26',
                'perl-extutils-makemaker>=6.56',
                'perl-extutils-manifest>=1.56',
                'perl-file-copy-recursive>=0.37',
                'perl-file-find-rule>=0.30',
                'perl-file-homedir>=0.91',
                'perl-file-path>=2.08',
                'perl-file-pushd>=1.00',
                'perl-file-remove>=1.40',
                'perl-file-sharedir>=1.00',
                'perl-file-temp>=0.20',
                'perl-file-which>=1.08',
                'perl-findbin',
                'perl-getopt-long',
                'perl-html-parser>=3.57',
                'perl-io-string>=1.08',
                'perl-io-stringy>=2.110',
                'perl-io>=1.30',
                'perl-ipc-run>=0.83',
                'perl-json-xs>=2.29',
                'perl-libwww>=5.815',
                'perl-list-moreutils>=0.22',
                'perl-module-build>=0.3603',
                'perl-module-corelist>=2.22',
                'perl-module-manifest>=0.07',
                'perl-module-starter>=1.60',
                'perl-orlite-migrate>=1.10',
                {
                    'perl-orlite>=1.98' => { flag_date => '2024-11-01' },
                },
                'perl-params-util>=0.33',
                'perl-parse-errorstring-perl>=0.18',
                'perl-parse-exuberantctags>=1.00',
                'perl-parse-functions>=0.01',
                'perl-pathtools>=3.2701',
                {
                    'perl-pod-abstract>=0.16' => { missing => 'Pod::Abstract' },
                },
                'perl-pod-perldoc>=3.23',
                'perl-pod-pom>=0.17',
                'perl-pod-simple>=3.04',
                'perl-pod2-base>=0.043',
                'perl-ppi>=1.218',
                'perl-ppix-editortools>=0.18',
                'perl-ppix-regexp>=0.011',
                'perl-probe-perl>=0.01',
                'perl-scalar-list-utils>=1.18',
                'perl-sort-versions>=1.5',
                'perl-storable>=2.16',
                'perl-template-tiny>=0.11',
                'perl-term-readline',
                'perl-text-balanced>=2.01',
                'perl-text-diff>=1.41',
                'perl-text-findindent>=0.10',
                'perl-text-patch>=1.8',
                'perl-threads-shared>=1.33',
                'perl-threads>=1.71',
                'perl-time-hires>=1.9718',
                'perl-uri',
                'perl-version>=0.80',
                'perl-wx-perl-processstream>=0.32',
                'perl-wx-scintilla>=0.39',
                'perl-wx>=0.9916',
                'perl-yaml-tiny>=1.32',
                'perl>=5.11.0',
            ],
            makedepends => [
                {
                    'perl-alien-wxwidgets>=0.62' => { flag_date => '2025-10-13' },
                },
                'perl-locale-msgfmt>=0.15',
                'perl-module-install',
                'perl-test-exception>=0.27',
                'perl-test-mockobject>=1.09',
                'perl-test-nowarnings>=1.04',
                'perl-test-script>=1.07',
                'perl-test-simple',
                'perl-test-warn>=0.24',
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=SZABGAB
            _dist=Padre
            pkgname=perl-${_dist@L}
            pkgver=1.02
            pkgrel=1
            pkgdesc='Perl Application Development and Refactoring Environment'
            arch=('x86_64')  # XS modules might depend on external libs; manual inspection is advised.
            url=https://metacpan.org/dist/$_dist
            license=('Artistic-1.0-Perl OR GPL-1.0-or-later')
            depends=(
                'cpanminus>=0.9923'
                'perl-algorithm-diff>=1.19'
                'perl-capture-tiny>=0.06'
                'perl-cgi>=3.47'
                'perl-class-adapter>=1.05'
                'perl-class-inspector>=1.22'
                'perl-class-xsaccessor>=1.13'
                'perl-data-dumper>=2.101'
                'perl-dbd-sqlite>=1.35'
                'perl-dbi>=1.58'
                'perl-debug-client>=0.29'            # Package is flagged out-of-date on 2024-12-14.
                'perl-devel-dumpvar>=0.04'
                'perl-devel-refactor>=0.05'
                'perl-encode>=2.26'
                'perl-extutils-makemaker>=6.56'
                'perl-extutils-manifest>=1.56'
                'perl-file-copy-recursive>=0.37'
                'perl-file-find-rule>=0.30'
                'perl-file-homedir>=0.91'
                'perl-file-path>=2.08'
                'perl-file-pushd>=1.00'
                'perl-file-remove>=1.40'
                'perl-file-sharedir>=1.00'
                'perl-file-temp>=0.20'
                'perl-file-which>=1.08'
                'perl-findbin'
                'perl-getopt-long'
                'perl-html-parser>=3.57'
                'perl-io-string>=1.08'
                'perl-io-stringy>=2.110'
                'perl-io>=1.30'
                'perl-ipc-run>=0.83'
                'perl-json-xs>=2.29'
                'perl-libwww>=5.815'
                'perl-list-moreutils>=0.22'
                'perl-module-build>=0.3603'
                'perl-module-corelist>=2.22'
                'perl-module-manifest>=0.07'
                'perl-module-starter>=1.60'
                'perl-orlite-migrate>=1.10'
                'perl-orlite>=1.98'                  # Package is flagged out-of-date on 2024-11-01.
                'perl-params-util>=0.33'
                'perl-parse-errorstring-perl>=0.18'
                'perl-parse-exuberantctags>=1.00'
                'perl-parse-functions>=0.01'
                'perl-pathtools>=3.2701'
                'perl-pod-abstract>=0.16'            # Package for Pod::Abstract is missing.
                'perl-pod-perldoc>=3.23'
                'perl-pod-pom>=0.17'
                'perl-pod-simple>=3.04'
                'perl-pod2-base>=0.043'
                'perl-ppi>=1.218'
                'perl-ppix-editortools>=0.18'
                'perl-ppix-regexp>=0.011'
                'perl-probe-perl>=0.01'
                'perl-scalar-list-utils>=1.18'
                'perl-sort-versions>=1.5'
                'perl-storable>=2.16'
                'perl-template-tiny>=0.11'
                'perl-term-readline'
                'perl-text-balanced>=2.01'
                'perl-text-diff>=1.41'
                'perl-text-findindent>=0.10'
                'perl-text-patch>=1.8'
                'perl-threads-shared>=1.33'
                'perl-threads>=1.71'
                'perl-time-hires>=1.9718'
                'perl-uri'
                'perl-version>=0.80'
                'perl-wx-perl-processstream>=0.32'
                'perl-wx-scintilla>=0.39'
                'perl-wx>=0.9916'
                'perl-yaml-tiny>=1.32'
                'perl>=5.11.0'
            )
            makedepends=(
                'perl-alien-wxwidgets>=0.62'  # Package is flagged out-of-date on 2025-10-13.
                'perl-locale-msgfmt>=0.15'
                'perl-module-install'
                'perl-test-exception>=0.27'
                'perl-test-mockobject>=1.09'
                'perl-test-nowarnings>=1.04'
                'perl-test-script>=1.07'
                'perl-test-simple'
                'perl-test-warn>=0.24'
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('e7fc64539810858750c60d7b24870585f8d481a7490549880b816786d4f63983')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1 PERL_AUTOINSTALL=--skipdeps

                /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
                make
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make install INSTALLDIRS=vendor DESTDIR="$pkgdir"
            }
            END
    },
    'Perl-Critic' => {
        meta => {
            abstract   => 'Critique Perl source code for best-practices.',
            author     => 'PETDANCE',
            checksum   => '572a7c8758ba1c0ab6daf0bd40297c4f0dcf1516f084522df2c2bf04d525e232',
            dependency => [
                {
                    module       => 'lib',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::More',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'PPI::Document::File',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.277',
                },
                {
                    module       => 'List::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Pod::Spell',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1',
                },
                {
                    module       => 'Pod::PlainText',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'English',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Text::ParseWords',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3',
                },
                {
                    module       => 'Exception::Class',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.23',
                },
                {
                    module       => 'Scalar::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'PPIx::Utils::Traversal',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.003',
                },
                {
                    module       => 'PPI::Token::Quote::Single',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.277',
                },
                {
                    module       => 'Getopt::Long',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Term::ANSIColor',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2.02',
                },
                {
                    module       => 'File::Basename',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Exporter',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.63',
                },
                {
                    module       => 'PPI::Node',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.277',
                },
                {
                    module       => 'File::Spec::Unix',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'PPI::Document',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.277',
                },
                {
                    module       => 'charnames',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Temp',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::Builder',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.92',
                },
                {
                    module       => 'Perl::Tidy',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Spec',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'warnings',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'PPI',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.277',
                },
                {
                    module       => 'File::Path',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Pod::Select',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'PPIx::Regexp',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.027',
                },
                {
                    module       => 'Pod::Usage',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'File::Find',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.010001',
                },
                {
                    module       => 'Module::Pluggable',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '3.1',
                },
                {
                    module       => 'version',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.77',
                },
                {
                    module       => 'B::Keywords',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.23',
                },
                {
                    module       => 'File::Which',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'PPIx::QuoteLike',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'strict',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Readonly',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2',
                },
                {
                    module       => 'List::SomeUtils',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.55',
                },
                {
                    module       => 'String::Format',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.18',
                },
                {
                    module       => 'Config::Tiny',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '2',
                },
                {
                    module       => 'parent',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Carp',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'overload',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'PPIx::Regexp::Util',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0.068',
                },
                {
                    module       => 'PPI::Token::Whitespace',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '1.277',
                },
                {
                    module       => 'Carp',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Module::Build',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0.4204',
                },
                {
                    module       => 'B::Keywords',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '1.23',
                },
                {
                    module       => 'base',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'lib',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'English',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Exporter',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '5.63',
                },
                {
                    module       => 'List::SomeUtils',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0.55',
                },
            ],
            dist               => 'Perl-Critic',
            download_url       => 'https://cpan.metacpan.org/authors/id/P/PE/PETDANCE/Perl-Critic-1.156.tar.gz',
            has_license        => 'LICENSE',
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => false,
            license            => ['perl_5'],
            name               => 'Perl-Critic-1.156',
            spdx_expression    => undef,
            version            => '1.156',
        },
        arch_prereqs => {
            checkdepends => [
                'perl-lib',
                'perl-test-simple',
            ],
            depends => [
                'perl-b-keywords>=1.23',
                'perl-carp',
                'perl-config-tiny>=2',
                'perl-exception-class>=1.23',
                'perl-exporter>=5.63',
                'perl-file-path',
                'perl-file-temp',
                'perl-file-which',
                'perl-getopt-long',
                'perl-list-someutils>=0.55',
                'perl-module-pluggable>=3.1',
                'perl-parent',
                'perl-pathtools',
                'perl-pod-parser',
                'perl-pod-spell>=1',
                'perl-pod-usage',
                'perl-ppi>=1.277',
                'perl-ppix-quotelike',
                'perl-ppix-regexp>=0.027',
                'perl-ppix-utils>=0.003',
                'perl-readonly>=2',
                'perl-scalar-list-utils',
                'perl-string-format>=1.18',
                'perl-term-ansicolor>=2.02',
                'perl-test-simple',
                'perl-text-parsewords>=3',
                'perl-tidy',
                'perl-version>=0.77',
                'perl>=5.10.1',
            ],
            makedepends => [
                'perl-base',
                'perl-lib',
                'perl-module-build>=0.4204',
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=PETDANCE
            _dist=Perl-Critic
            pkgname=perl-${_dist@L}
            pkgver=1.156
            pkgrel=1
            pkgdesc='Critique Perl source code for best-practices.'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            license=('Artistic-1.0-Perl OR GPL-1.0-or-later')
            depends=(
                'perl-b-keywords>=1.23'
                'perl-carp'
                'perl-config-tiny>=2'
                'perl-exception-class>=1.23'
                'perl-exporter>=5.63'
                'perl-file-path'
                'perl-file-temp'
                'perl-file-which'
                'perl-getopt-long'
                'perl-list-someutils>=0.55'
                'perl-module-pluggable>=3.1'
                'perl-parent'
                'perl-pathtools'
                'perl-pod-parser'
                'perl-pod-spell>=1'
                'perl-pod-usage'
                'perl-ppi>=1.277'
                'perl-ppix-quotelike'
                'perl-ppix-regexp>=0.027'
                'perl-ppix-utils>=0.003'
                'perl-readonly>=2'
                'perl-scalar-list-utils'
                'perl-string-format>=1.18'
                'perl-term-ansicolor>=2.02'
                'perl-test-simple'
                'perl-text-parsewords>=3'
                'perl-tidy'
                'perl-version>=0.77'
                'perl>=5.10.1'
            )
            makedepends=(
                'perl-base'
                'perl-lib'
                'perl-module-build>=0.4204'
            )
            checkdepends=(
                'perl-lib'
                'perl-test-simple'
            )
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('572a7c8758ba1c0ab6daf0bd40297c4f0dcf1516f084522df2c2bf04d525e232')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MB_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1 MODULEBUILDRC=/dev/null

                /usr/bin/perl Build.PL --create_packlist=0
                ./Build
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                ./Build test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                ./Build install --installdirs=vendor --destdir="$pkgdir"
            }
            END
    },
    'Regexp-Common' => {
        meta => {
            abstract   => 'Provide commonly requested regular expressions',
            author     => 'ABIGAIL',
            checksum   => '0677afaec8e1300cefe246b4d809e75cdf55e2cc0f77c486d13073b69ab4fbdd',
            dependency => [
                {
                    module       => 'strict',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'warnings',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'vars',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Config',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Config',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'vars',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'strict',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'warnings',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.010',
                },
                {
                    module       => 'Test::Regexp',
                    phase        => 'test',
                    relationship => 'recommends',
                    version      => '0',
                },
                {
                    module       => 'vars',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'warnings',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'strict',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Config',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::More',
                    phase        => 'test',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Config',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'strict',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'warnings',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'vars',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
            ],
            dist               => 'Regexp-Common',
            download_url       => 'https://cpan.metacpan.org/authors/id/A/AB/ABIGAIL/Regexp-Common-2024080801.tar.gz',
            has_license        => 'COPYRIGHT',
            has_module_install => false,
            has_multi_licenses => true,
            has_xs             => false,
            license            => [
                'mit',
                'mit',
                'bsd',
                'artistic_1',
                'artistic_2',
            ],
            name            => 'Regexp-Common-2024080801',
            spdx_expression => undef,
            version         => '2024080801',
        },
        arch_prereqs => {
            checkdepends => ['perl-test-simple'],
            depends      => ['perl>=5.10.0'],
            makedepends  => ['perl-extutils-makemaker'],
            optdepends   => [
                {
                    'perl-test-regexp' => { missing => 'Test::Regexp' },
                },
            ],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=ABIGAIL
            _dist=Regexp-Common
            pkgname=perl-${_dist@L}
            pkgver=2024080801
            pkgrel=1
            pkgdesc='Provide commonly requested regular expressions'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            # Multiple licenses listed in metadata; manual inspection is advised to
            # construct a proper SPDX expression.
            license=(
                'MIT'
                'MIT'
                'BSD-3-Clause'
                'Artistic-1.0'
                'Artistic-2.0'
            )
            depends=('perl>=5.10.0')
            makedepends=('perl-extutils-makemaker')
            checkdepends=('perl-test-simple')
            optdepends=('perl-test-regexp'  # Package for Test::Regexp is missing.)
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('0677afaec8e1300cefe246b4d809e75cdf55e2cc0f77c486d13073b69ab4fbdd')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1

                /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
                make
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make install INSTALLDIRS=vendor DESTDIR="$pkgdir"

                # Multiple licenses found; manual inspection is advised to install the
                # correct file.
                install -Dm644 COPYRIGHT -t "$pkgdir/usr/share/licenses/$pkgname/"
            }
            END
    },
    'Regexp-Debugger' => {
        meta => {
            abstract   => 'Visually debug regexes in-place',
            author     => 'DCONWAY',
            checksum   => 'db096cf2e0e1e6127dacc40be6fbd526aa5ad41886a5bae00f4fe6a53a6c6ffb',
            dependency => [
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'configure',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'ExtUtils::MakeMaker',
                    phase        => 'build',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'Test::More',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'version',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '0',
                },
                {
                    module       => 'perl',
                    phase        => 'runtime',
                    relationship => 'requires',
                    version      => '5.010001',
                },
            ],
            dist               => 'Regexp-Debugger',
            download_url       => 'https://cpan.metacpan.org/authors/id/D/DC/DCONWAY/Regexp-Debugger-0.002007.tar.gz',
            has_license        => false,
            has_module_install => false,
            has_multi_licenses => false,
            has_xs             => false,
            license            => ['unknown'],
            name               => 'Regexp-Debugger-0.002007',
            spdx_expression    => undef,
            version            => '0.002007',
        },
        cpan_prereqs => {
            checkdepends => undef,
            depends      => {
                perl => {
                    dist    => 'perl',
                    version => '5.010001',
                },
                'Test::More' => {
                    dist    => 'Test-Simple',
                    version => '0',
                },
                version => {
                    dist    => 'version',
                    version => '0',
                },
            },
            makedepends => {
                'ExtUtils::MakeMaker' => {
                    dist    => 'ExtUtils-MakeMaker',
                    version => '0',
                },
            },
            optdepends => {},

        },
        arch_prereqs => {
            depends => [
                'perl-test-simple',
                'perl-version',
                'perl>=5.10.1',
            ],
            makedepends => ['perl-extutils-makemaker'],
        },
        pkgbuild => <<~'END',
            # Maintainer: Your Name <email@domain.tld>

            _author=DCONWAY
            _dist=Regexp-Debugger
            pkgname=perl-${_dist@L}
            pkgver=0.002007
            pkgrel=1
            pkgdesc='Visually debug regexes in-place'
            arch=('any')
            url=https://metacpan.org/dist/$_dist
            license=(
                'unknown'  # License not provided in metadata.
                           # Unknown SPDX ID; manual inspection is advised.
            )
            depends=(
                'perl-test-simple'
                'perl-version'
                'perl>=5.10.1'
            )
            makedepends=('perl-extutils-makemaker')
            options=('!emptydirs')
            source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
            sha256sums=('db096cf2e0e1e6127dacc40be6fbd526aa5ad41886a5bae00f4fe6a53a6c6ffb')

            build()
            {
                cd "$_dist-$pkgver"

                unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
                export PERL_MM_USE_DEFAULT=1

                /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
                make
            }

            check()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make test
            }

            package()
            {
                cd "$_dist-$pkgver"

                unset PERL5LIB PERL_LOCAL_LIB_ROOT

                make install INSTALLDIRS=vendor DESTDIR="$pkgdir"
            }
            END
    },
);

# Merge additional info to the dists.
foreach my ( $dist, $info ) (%DISTS) {
    $EXPECTED{$dist}{version} = $info->{version};
    $EXPECTED{$dist}{note}    = $info->{note};
}

sub expected_data ()
{
    return \%EXPECTED;
}

# Test text differences and show diff.
sub test_diff ( $got, $expected, $diag )
{
    # NOTE:
    #   COLOR is a feature from a fork of Text::Diff that isn't merged to
    #   upstream yet, so it needs to be replaced to get colorized diff output.
    #   E.g.
    #     cpanm --reinstall https://github.com/ryoskzypu/Text-Diff.git@colors
    if ( my $diff = diff( \$got, \$expected, { COLOR => 'always' } ) ) {
        fail("$diag is different than expected PKGBUILD");
        note($diff);
    }
    else {
        pass("$diag match");
    }
}
