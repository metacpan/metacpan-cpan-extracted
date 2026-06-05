use v5.42.0;

use strict;
use warnings;
no source::encoding;  # Avoid dying on v5.42.0 (non-ASCII char in POD).

use Object::Pad 0.825;

package App::cpan2arch::WritePkgbuild;  # For toolchain compatibility.
role App::cpan2arch::WritePkgbuild;

use open qw< :std :encoding(UTF-8) >;

use File::Basename qw< basename >;
use Scalar::Util   qw< looks_like_number >;
use List::Util     qw<
    any
    first
    reduce
    uniq
>;

$|++;  # Disable STDOUT buffering.

our $VERSION = 'v1.1.2';

field $_install_license;
field %_generated_meta;
field %_pkgbuild :reader :writer;

# Generate the PKGBUILD bash script.
#
# References:
#   https://wiki.archlinux.org/title/Perl_package_guidelines
method generate_pkgbuild ()
{
    $self->_psub;

    $self->_get_pkgbuild_vars;

    my %opts = $self->opts;
    my %meta = $self->meta;
    my $mb   = false;

    # build()
    my $build;
    {
        my %arch_prereqs = $self->arch_prereqs;
        my @has_mb;

        # Set the builder to use in PKGBUILD
        # (Prefer M::B or M::B::T and use EU::MM as fallback)

        if ( !$meta{has_module_install} ) {
            @has_mb = grep { /\Aperl-module-build(?> -tiny)? (?> [<>=] | \z )/x } $arch_prereqs{makedepends}->@*;
            $mb     = true if scalar @has_mb;
        }

        $build = $mb
          ? <<~'END'
              unset PERL_MB_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
              export PERL_MM_USE_DEFAULT=1 MODULEBUILDRC=/dev/null

              /usr/bin/perl Build.PL --create_packlist=0
              ./Build
          END
          : <<~'END';
              unset PERL_MM_OPT PERL5LIB PERL_LOCAL_LIB_ROOT
              export PERL_MM_USE_DEFAULT=1

              /usr/bin/perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1
              make
          END

        # Do not auto-install prereqs with Module::Install.
        $build =~ s{( PERL_MM_USE_DEFAULT=1(?=\n))}{$1 PERL_AUTOINSTALL=--skipdeps}
          if $meta{has_module_install};

        chomp $build;

        # Module::Build::Tiny does not support PERL_MM_USE_DEFAULT and MODULEBUILDRC.
        $build =~ s{^ {4}+export [^\n]+\n}{}m
          if scalar @has_mb && $has_mb[0] =~ /tiny/;
    }

    # check()
    my $test = $mb ? q{./Build test} : q{make test};

    # package()
    my $install;
    {
        $install =
          $mb
          ? q{./Build install --installdirs=vendor --destdir="$pkgdir"}
          : q{make install INSTALLDIRS=vendor DESTDIR="$pkgdir"};

        $self->_pdump( '$_install_license', \$_install_license, "\n" );

        # Install a license file if it exists.
        if ( $_install_license && $meta{has_license} ) {
            my $cmd = qq{\n    install -Dm644 $meta{has_license} -t "\$pkgdir/usr/share/licenses/\$pkgname/"};

            $install
              .= $meta{has_multi_licenses}
              ? qq{\n\n    # Multiple licenses found; manual inspection is advised to install the\n    # correct file.$cmd}
              : $cmd;
        }
    }

    my $pkgbuild = <<~"END";
        _author=$_pkgbuild{author}
        _dist=$_pkgbuild{dist}
        pkgname=perl-\${_dist\@L}
        pkgver=$_pkgbuild{pkgver}
        pkgrel=1
        pkgdesc=$_pkgbuild{pkgdesc}
        arch=$_pkgbuild{arch}
        url=$_pkgbuild{url}
        $_pkgbuild{license}
        depends=$_pkgbuild{depends}
        makedepends=$_pkgbuild{makedepends}
        checkdepends=$_pkgbuild{checkdepends}
        optdepends=$_pkgbuild{optdepends}
        options=('!emptydirs')
        source=("$_pkgbuild{source}")
        sha256sums=('$_pkgbuild{sha256sums}')

        build()
        {
            cd "\$_dist-\$pkgver"

        $build
        }

        check()
        {
            cd "\$_dist-\$pkgver"

            unset PERL5LIB PERL_LOCAL_LIB_ROOT

            $test
        }

        package()
        {
            cd "\$_dist-\$pkgver"

            unset PERL5LIB PERL_LOCAL_LIB_ROOT

            $install
        }
        END

    # No need to set maintainer attribution on --update.
    $pkgbuild =~ s{\A}{# Maintainer: $_pkgbuild{packager}\n\n}
      unless defined $opts{update};

    # Warn the packager if the dist is an Alien.
    # See https://metacpan.org/pod/Alien.
    {
        my $NOTE_ALIEN = <<~'END';
            # Alien dists may have dynamic dependencies not listed in metadata; manual inspection
            # and clean chroot builds are advised.
            END

        if ( $_pkgbuild{dist} =~ /\AAlien-/ ) {
            $pkgbuild =~ s{^(?= _dist= )}{$NOTE_ALIEN}mx;
        }
    }

    # Strip empty deps arrays.
    $pkgbuild =~ s{^(?> make | check | opt )depends=\n}{}gmx;

    $_pkgbuild{output} = $pkgbuild;

    return $self;
}

# Map PKGBUILD variables for its generation.
method _get_pkgbuild_vars ()
{
    $self->_psub;

    my %env  = $self->env;
    my %opts = $self->opts;
    my %meta = $self->meta;

    %_pkgbuild = (
        packager => $env{packager},
        author   => $meta{author},
        dist     => $meta{dist},
        pkgver   => $meta{version},
        pkgdesc  => do {
            # Trim + escape single quotes with ANSI-C quoting.
            my $desc = trim( $meta{abstract} =~ s{'}{\\'}gr );
            $desc =~ /'/ ? qq{\$'$desc'} : qq{'$desc'};
        },
        arch => $meta{has_xs}
        ? q{('x86_64')  # XS modules might depend on external libs; manual inspection is advised.}
        : q{('any')},

        url => 'https://metacpan.org/dist/$_dist',

        license      => $self->_build_license_array,
        depends      => $self->_build_deps_array('depends'),
        makedepends  => $self->_build_deps_array('makedepends'),
        checkdepends => $self->_build_deps_array('checkdepends'),
        optdepends   => $self->_build_deps_array('optdepends'),

        source => $meta{download_url} =~ s{
            \A
            https://cpan\.metacpan\.org/authors/id/
            \K
            [A-Z] / [A-Z]{2} / [A-Z]{3,9} / \Q$meta{name}\E
        }
        {\${_author::1}/\${_author::2}/\$_author/\$_dist-\$pkgver}rx,

        sha256sums => $meta{checksum},
    );

    $self->_pdump( '%_pkgbuild', \%_pkgbuild, "\n" );

    return $self;
}

# Construct PKGBUILD's license array.
#
# NOTE:
#   Licenses not found in the licenses package must be installed at /usr/share/licenses/$pkgname/.
#
#   CPAN Meta only covers few licenses and some of them are deprecated because
#   of its SPDX ID (e.g. AGPL-3.0), but the license text is the same and exist
#   at /usr/share/licenses/spdx under a different SPDX ID.
#
# References:
#   https://metacpan.org/pod/CPAN::Meta::Spec#license
#   https://wiki.archlinux.org/title/PKGBUILD#license
#   https://lists.archlinux.org/hyperkitty/list/arch-dev-public@lists.archlinux.org/thread/NFSB7734U2VVDULPRY65ECXDE3XGNZXM/
#   https://spdx.github.io/spdx-spec/latest/annexes/spdx-license-expressions/
method _build_license_array ()
{
    $self->_psub;

    my $prog = $self->prog;

    # Get the licenses from licenses package.
    my %arch_licenses;
    {
        my $SPDX_PATH = '/usr/share/licenses/spdx';

        if ( -d $SPDX_PATH ) {
            %arch_licenses = map { basename( s{\.txt\z}{}r ) => 1 } glob "$SPDX_PATH/*.txt";
        }
        # Fallback to its hardcoded licenses.
        else {
            $self->_pdbg("$SPDX_PATH does not exist\n");

            # NOTE:
            #   This is necessary for the CI tests since they do not ship with
            #   Arch, so may be outdated.
            %arch_licenses = (
                'AGPL-3.0-only'                   => 1,
                'AGPL-3.0-or-later'               => 1,
                'Apache-2.0'                      => 1,
                'Artistic-1.0-Perl'               => 1,
                'Artistic-2.0'                    => 1,
                'BSL-1.0'                         => 1,
                'CC-BY-1.0'                       => 1,
                'CC-BY-2.0'                       => 1,
                'CC-BY-2.5'                       => 1,
                'CC-BY-3.0'                       => 1,
                'CC-BY-3.0-AT'                    => 1,
                'CC-BY-3.0-US'                    => 1,
                'CC-BY-4.0'                       => 1,
                'CC-BY-NC-1.0'                    => 1,
                'CC-BY-NC-2.0'                    => 1,
                'CC-BY-NC-2.5'                    => 1,
                'CC-BY-NC-3.0'                    => 1,
                'CC-BY-NC-4.0'                    => 1,
                'CC-BY-NC-ND-1.0'                 => 1,
                'CC-BY-NC-ND-2.0'                 => 1,
                'CC-BY-NC-ND-2.5'                 => 1,
                'CC-BY-NC-ND-3.0'                 => 1,
                'CC-BY-NC-ND-3.0-IGO'             => 1,
                'CC-BY-NC-ND-4.0'                 => 1,
                'CC-BY-NC-SA-1.0'                 => 1,
                'CC-BY-NC-SA-2.0'                 => 1,
                'CC-BY-NC-SA-2.5'                 => 1,
                'CC-BY-NC-SA-3.0'                 => 1,
                'CC-BY-NC-SA-4.0'                 => 1,
                'CC-BY-ND-1.0'                    => 1,
                'CC-BY-ND-2.0'                    => 1,
                'CC-BY-ND-2.5'                    => 1,
                'CC-BY-ND-3.0'                    => 1,
                'CC-BY-ND-4.0'                    => 1,
                'CC-BY-SA-1.0'                    => 1,
                'CC-BY-SA-2.0'                    => 1,
                'CC-BY-SA-2.0-UK'                 => 1,
                'CC-BY-SA-2.1-JP'                 => 1,
                'CC-BY-SA-2.5'                    => 1,
                'CC-BY-SA-3.0'                    => 1,
                'CC-BY-SA-3.0-AT'                 => 1,
                'CC-BY-SA-4.0'                    => 1,
                'CC-PDDC'                         => 1,
                'CC0-1.0'                         => 1,
                'CDDL-1.0'                        => 1,
                'CDDL-1.1'                        => 1,
                'CPL-1.0'                         => 1,
                'EPL-1.0'                         => 1,
                'EPL-2.0'                         => 1,
                'FSFAP'                           => 1,
                'GFDL-1.1-invariants-only'        => 1,
                'GFDL-1.1-invariants-or-later'    => 1,
                'GFDL-1.1-no-invariants-only'     => 1,
                'GFDL-1.1-no-invariants-or-later' => 1,
                'GFDL-1.1-only'                   => 1,
                'GFDL-1.1-or-later'               => 1,
                'GFDL-1.2-invariants-only'        => 1,
                'GFDL-1.2-invariants-or-later'    => 1,
                'GFDL-1.2-no-invariants-only'     => 1,
                'GFDL-1.2-no-invariants-or-later' => 1,
                'GFDL-1.2-only'                   => 1,
                'GFDL-1.2-or-later'               => 1,
                'GFDL-1.3-invariants-only'        => 1,
                'GFDL-1.3-invariants-or-later'    => 1,
                'GFDL-1.3-no-invariants-only'     => 1,
                'GFDL-1.3-no-invariants-or-later' => 1,
                'GFDL-1.3-only'                   => 1,
                'GFDL-1.3-or-later'               => 1,
                'GPL-1.0-only'                    => 1,
                'GPL-1.0-or-later'                => 1,
                'GPL-2.0-only'                    => 1,
                'GPL-2.0-or-later'                => 1,
                'GPL-3.0-only'                    => 1,
                'GPL-3.0-or-later'                => 1,
                'GPL-CC-1.0'                      => 1,
                'LGPL-2.0-only'                   => 1,
                'LGPL-2.0-or-later'               => 1,
                'LGPL-2.1-only'                   => 1,
                'LGPL-2.1-or-later'               => 1,
                'LGPL-3.0-only'                   => 1,
                'LGPL-3.0-or-later'               => 1,
                'LGPLLR'                          => 1,
                'LPPL-1.0'                        => 1,
                'LPPL-1.1'                        => 1,
                'LPPL-1.2'                        => 1,
                'LPPL-1.3a'                       => 1,
                'LPPL-1.3c'                       => 1,
                'MPL-1.0'                         => 1,
                'MPL-1.1'                         => 1,
                'MPL-2.0'                         => 1,
                'PHP-3.01'                        => 1,
                'PHP-3.0'                         => 1,
                'PSF-2.0'                         => 1,
                'Ruby'                            => 1,
                'Unlicense'                       => 1,
                'W3C'                             => 1,
                'WTFPL'                           => 1,
                'ZPL-1.1'                         => 1,
                'ZPL-2.0'                         => 1,
                'ZPL-2.1'                         => 1,
            );
        }

        $self->_pdump( '%arch_licenses', \%arch_licenses, "\n" );
    }

    my %opts = $self->opts;
    my %meta = $self->meta;

    # Prefer x_spdx_expression string over license array in metadata.
    {
        my $x_spdx = $meta{spdx_expression};

        if ( defined $x_spdx ) {
            # Install license file whether IDs from SPDX expression exist in licenses package.
            foreach my $id ( split /\s+(?> AND | OR )\s+/x, $x_spdx ) {
                $_install_license = true unless exists $arch_licenses{$id};
            }

            push $_generated_meta{license}->@*, $x_spdx if defined $opts{update};

            return "license=('$x_spdx')";
        }
    }

    # Process metadata's license array.

    my $nl     = '';
    my $indent = '';
    my $SPACE  = q{ };
    my $START  = '(';
    my $END    = ')';
    my $array  = $START;

    # Multiline and indent the array string.
    my sub multiline_array ()
    {
        $nl     = "\n";
        $indent = $SPACE x 4;
        $array  = "${START}$nl";
    }

    multiline_array() if scalar $meta{license}->@* > 1;

    # Pre-process licenses to get their info.
    my @licenses;
    {
        my $NOTE = 'Unknown SPDX ID; manual inspection is advised.';

        foreach my ( $idx, $license ) ( indexed $meta{license}->@* ) {
            my $desc =
                $license eq 'open_source'  ? 'Other Open Source Initiative (OSI) approved license.'
              : $license eq 'restricted'   ? 'Requires special permission from copyright holder.'
              : $license eq 'unrestricted' ? 'Not an OSI approved license, but not restricted.'
              : $license eq 'unknown'      ? 'License not provided in metadata.'
              :                              ();

            if ( defined $desc ) {
                multiline_array() if $idx == 0;

                $_install_license = true;

                push @licenses, {
                    name => q{'unknown'},
                    desc => $desc,
                    note => $NOTE,
                };

                next;
            }

            # Guess license
            my @guesses;
            {
                require Software::LicenseUtils;
                Software::LicenseUtils->VERSION('0.104007');

                @guesses = Software::LicenseUtils->guess_license_from_meta_key($license);
                $self->_pdump( '@guesses', \@guesses, "\n" );
            }

            my $spdx = $guesses[0]->spdx_expression;
            $self->_pdump( '$spdx', \$spdx, "\n" );

            if ( !defined $spdx ) {
                $_install_license = true;

                push @licenses, {
                    name => q{'unknown'},
                    note => $NOTE,
                };

                next;
            }

            if ( exists $arch_licenses{$spdx} ) {
                # Do not install license.
                push @licenses, { name => qq{'$spdx'} };
                next;
            }
            # License text exists in licenses package under a different SPDX ID.
            elsif ( $spdx =~ /\A( AGPL-3\.0 | LGPL-(?> 2\.1 | 3\.0) )\z/x ) {
                multiline_array() if $idx == 0;

                push @licenses, {
                    name => qq{'$spdx'},
                    desc => "Deprecated by $1-only and $1-or-later.",
                    note => 'License text is identical; manual inspection is advised.',
                };

                next;
            }
            else {
                # Install license file whether IDs from SPDX expression exist in licenses package.
                foreach my $id ( split /\s+(?> AND | OR )\s+/x, $spdx ) {
                    $_install_license = true unless exists $arch_licenses{$id};
                }

                push @licenses, { name => qq{'$spdx'} };
            }
        }

        $self->_pdump( '@licenses', \@licenses, "\n" );
    }

    if ( defined $opts{update} ) {
        foreach my $license (@licenses) {
            push $_generated_meta{license}->@*, $license->{name} =~ s{\A' | '\z}{}grx;
        }
    }

    # Post-process licenses and build the license array string.
    {
        my $max_str = 0;

        # Get the maximum length string to align comments.
        $max_str =
          length reduce { length $a > length $b ? $a : $b } map { $_->{name} } @licenses;

        foreach my $info (@licenses) {
            my ( $name, $desc, $note ) = $info->@{ qw< name desc note > };
            my $pad1 = $SPACE x 2;
            my $pad2 = $pad1;

            my ( $len_indent, $len_name, $len_pad1, $len_pad2 ) =
              map { length } ( $indent, $name, $pad1, $pad2 );

            if ( $len_name < $max_str ) {
                $pad1 = $SPACE x ( $max_str - $len_name + $len_pad1 );
                $pad2 = $SPACE x ( $len_indent + $len_name + $len_pad2 + ( $max_str - $len_name ) );
            }
            else {
                $pad2 = $SPACE x ( $len_indent + $len_name + $len_pad2 );
            }

            if ( defined $desc ) {
                chomp( $array .= <<~"END" );
                    ${indent}${name}$pad1# $desc
                    $pad2# ${note}$nl
                    END

                next;
            }

            $array .= "${indent}${name}$nl";
        }

        $array .= $END;

        my $multi_note = '';

        # Warn the packager when multiple licenses are listed in metadata.
        if ( scalar $meta{license}->@* > 1 ) {
            $multi_note = <<~'END';
                # Multiple licenses listed in metadata; manual inspection is advised to
                # construct a proper SPDX expression.
                END
        }

        $array = "${multi_note}license=$array";
    }

    $self->_pdbg( '$array = ' . $array . "\n\n" );

    return $array;
}

# Construct PKGBUILD's dependencies array.
method _build_deps_array ($var)
{
    $self->_psub;
    $self->_pdump( '$var', \$var, "\n" );

    my %arch_prereqs = $self->arch_prereqs;
    return '' unless exists $arch_prereqs{$var};

    my $nl      = '';
    my $indent  = '';
    my $SPACE   = q{ };
    my $START   = '(';
    my $END     = ')';
    my $max_str = 0;

    # Multiline and indent the array on multiple packages.
    if ( scalar $arch_prereqs{$var}->@* > 1 ) {
        $nl     = "\n";
        $indent = $SPACE x 4;

        # Get the maximum length from string for comments alignment.

        my @normalize =
          map { defined reftype $_ && reftype $_ eq 'HASH' ? keys $_->%* : $_ } $arch_prereqs{$var}->@*;

        $max_str = length reduce { length $a > length $b ? $a : $b } @normalize;
    }

    my $array = "${START}$nl";

    foreach my $dep ( $arch_prereqs{$var}->@* ) {
        my $deptype = reftype $dep // '';

        # Append a comment for packages that are flagged or not found in the Official/AUR repos.
        if ( $deptype eq 'HASH' ) {
            my $pad = $SPACE x 2;

            foreach my ( $pkg, $status ) ( $dep->%* ) {
                my ( $failed, $missing, $date ) = $status->@{ qw< failed missing flag_date > };
                my $version = $status->{version} ? " (version: $status->{version})" : '';

                my $comment =
                    defined $failed  ? "Failed to fetch $pkg module$version.$nl"
                  : defined $missing ? "Package for $missing is missing.$nl"
                  : defined $date    ? "Package is flagged out-of-date on $date.$nl"
                  :                    ();

                $pkg = '?' if defined $failed;

                my $len_pkg = length $pkg;

                $pad = $SPACE x ( $max_str - $len_pkg + length $pad )
                  if $len_pkg < $max_str;

                # Escape single quotes with ANSI-C quoting (for optdepends descriptions).
                my $ansi = $pkg =~ /'/ ? '$' : '';

                $array .= "${indent}$ansi'$pkg'$pad# $comment";

                $self->_pdbg("found commented pkg\n");
                $self->_pdump( '$dep', $dep, "\n" );
            }
        }
        else {
            my $ansi = $dep =~ /'/ ? '$' : '';
            $array .= "${indent}$ansi'$dep'$nl";
        }
    }

    $array .= $END;
    $self->_pdbg( '$array = ' . $array . "\n\n" );

    return $array;
}

# Write the generated PKBUILD to STDOUT or its file in the current dir.
method write_pkgbuild ()
{
    $self->_psub;

    return 0 unless defined $_pkgbuild{output};

    my %opts = $self->opts;
    my $prog = $self->prog;

    if ( defined $opts{update} || defined $opts{write} ) {
        require Path::Tiny;
        Path::Tiny->VERSION('0.150');
        Path::Tiny->import( qw< path > );
    }

    my %FILES = (
        outfile  => 'PKGBUILD',
        metadata => '.SRCINFO',
    );
    $self->_pdump( '%FILES', \%FILES, "\n" );

    # --update
    if ( defined $opts{update} ) {
        foreach my ( $k, $fname ) (%FILES) {
            if ( !-f $fname ) {
                warn "$prog: $fname does not exist\n";
                return 1;
            }
        }

        my %env        = $self->env;
        my %meta       = $self->meta;
        my $pkgname    = lc "perl-$_pkgbuild{dist}";
        my $gen_output = $_pkgbuild{output};

        # Get .SRCINFO data.
        my %srcinfo_meta;
        {
            my @srcinfo = path( $FILES{metadata} )->lines_utf8( { chomp => 1 } );

            if ( scalar @srcinfo ) {
                # Split packages do not make sense in Perl packages.
                my $index = first { $srcinfo[$_] =~ /\Apkgname = / } 0 .. $#srcinfo;
                splice @srcinfo, $index if defined $index;
            }

            $self->_pdump( '@srcinfo', \@srcinfo, "\n" );

            my @VARS = (
                qw<
                    pkgbase
                    pkgver
                    pkgrel
                    epoch
                    pkgdesc
                    url
                    install
                    changelog
                >
            );
            my @NEEDED_VARS = (
                qw<
                    pkgbase
                    pkgver
                    pkgrel
                >
            );

            # References:
            #   https://wiki.archlinux.org/title/.SRCINFO
            #   https://man.archlinux.org/man/SRCINFO.5
            #   https://man.archlinux.org/man/alpm-pkgver.7
            #   https://man.archlinux.org/man/alpm-pkgrel.7
            foreach my $line (@srcinfo) {
                next if $line eq '';

                my ( $key, $val ) = split / = /, $line;
                next unless defined $val;
                $key =~ s{\A\t}{};

                if ( any { $key eq $_ } @VARS ) {
                    $srcinfo_meta{$key} = $val;
                    next;
                }

                push $srcinfo_meta{$key}->@*, $val;
            }

            $self->_pdump( '%srcinfo_meta', \%srcinfo_meta, "\n" );

            foreach my ($var) (@NEEDED_VARS) {
                if ( !exists $srcinfo_meta{$var} ) {
                    warn "$prog: $var is not declared in $FILES{metadata}\n";
                    return 1;
                }
            }

            if ( $pkgname ne $srcinfo_meta{pkgbase} ) {
                warn "$prog: $FILES{metadata} package ($srcinfo_meta{pkgbase}) is different than $pkgname\n";
                return 1;
            }
        }

        # .SRCINFO pkgver must not be newer than generated PKGBUILD pkgver.
        {
            my $ret = $self->_comp_vers( $_pkgbuild{pkgver}, $srcinfo_meta{pkgver}, '<' );
            return 1 if defined $ret && $ret == 1;

            if ( defined $ret && $ret == 0 ) {
                warn "$prog: $FILES{metadata} version ($srcinfo_meta{pkgver}) is newer than $_pkgbuild{pkgver}\n";
                return 1;
            }
        }

        if ( !looks_like_number( $srcinfo_meta{pkgrel} ) ) {
            warn "$prog: pkgrel $srcinfo_meta{pkgrel} is not a number\n";
            return 1;
        }

        # Add epoch if newer version breaks pacman's version comparison logic.
        #
        # References:
        #   https://wiki.archlinux.org/title/PKGBUILD#epoch
        #   https://man.archlinux.org/man/core/pacman/PKGBUILD.5.en#:~:text=epoch
        #   https://man.archlinux.org/man/alpm-epoch.7
        #   https://man.archlinux.org/man/vercmp.8
        #   https://gitlab.archlinux.org/pacman/pacman/-/blob/master/lib/libalpm/version.c
        my $has_epoch = false;
        {
            my $ret = $self->_comp_vers( $_pkgbuild{pkgver}, $srcinfo_meta{pkgver}, '>' );
            return 1 if defined $ret && $ret == 1;

            if ( defined $ret && $ret == 0 ) {
                require Devel::CheckBin;
                Devel::CheckBin->VERSION('0.04');

                my $cmd_path = Devel::CheckBin::can_run('vercmp');
                $self->_pdump( '$cmd_path', \$cmd_path, '' );

                if ( defined $cmd_path ) {
                    require Capture::Tiny;
                    Capture::Tiny->VERSION('0.50');

                    my ( $stdout, $stderr, $exit ) = Capture::Tiny::capture(
                        sub { system( $cmd_path, $_pkgbuild{pkgver}, $srcinfo_meta{pkgver} ) }
                    );

                    $self->_pdump( '$stdout', \$stdout, '' );
                    $self->_pdump( '$stderr', \$stderr, '' );
                    $self->_pdump( '$exit',   \$exit,   '' );

                    if ( $exit != 0 ) {
                        warn $stderr;
                        warn "$prog: failed to run vercmp\n";

                        return 1;
                    }

                    # New version breaks vercmp logic.
                    if ( $stdout < 0 ) {
                        my $epoch = $srcinfo_meta{epoch} // 1;

                        if ( exists $srcinfo_meta{epoch} ) {
                            ++$epoch;
                            $self->_pdbg("bump epoch to $epoch\n");
                        }

                        if ( $gen_output =~ s{^pkgrel=[^\n]+\n\K}{epoch=$epoch\n}m ) {
                            $has_epoch = true;
                            $self->_pdbg("add epoch\n");
                        }
                    }

                    $self->_pdbg("\n");
                }
                else {
                    warn "$prog: vercmp is not installed\n";
                    return 1;
                }
            }
        }

        # Sort metadatas for proper comparison.
        my %meta_a;  # .SRCINFO
        my %meta_b;  # Generated PKGBUILD
        {
            my sub sort_meta (%m)
            {
                my %sorted;

                foreach my ( $var, $deps ) (%m) {
                    my $type = reftype $deps;

                    if ( defined $type && $type eq 'ARRAY' ) {
                        push $sorted{$var}->@*, sort $deps->@*;
                        next;
                    }

                    $sorted{$var} = $deps;
                }

                return %sorted;
            }

            # Build the generated PKGBUILD metadata hash for sorting.
            {
                my %arch_prereqs = $self->arch_prereqs;

                foreach my ( $var, $pkgs ) (%arch_prereqs) {
                    foreach my $pkg ( $pkgs->@* ) {
                        my $pkgtype = reftype $pkg;

                        # Normalize pkgs.
                        push $_generated_meta{$var}->@*,
                          defined $pkgtype && $pkgtype eq 'HASH'
                          ? keys $pkg->%*
                          : $pkg;
                    }
                }

                $_generated_meta{pkgbase} = $pkgname;
                $_generated_meta{pkgver}  = $meta{version};
                $_generated_meta{pkgrel}  = 1;
                $_generated_meta{pkgdesc} = $meta{abstract};
                $_generated_meta{url}     = "https://metacpan.org/dist/$meta{dist}";
                push $_generated_meta{arch}->@*,       $meta{has_xs} ? 'x86_64' : 'any';
                push $_generated_meta{options}->@*,    '!emptydirs';
                push $_generated_meta{source}->@*,     $meta{download_url};
                push $_generated_meta{sha256sums}->@*, $meta{checksum};

                #$self->_pdump( '%_generated_meta', \%_generated_meta, "\n" );
            }

            %meta_a = sort_meta(%srcinfo_meta);
            %meta_b = sort_meta(%_generated_meta);

            $self->_pdump( '%meta_a', \%meta_a, "\n" );
            $self->_pdump( '%meta_b', \%meta_b, "\n" );
        }

        # Compare and show metadata differences.
        my $is_diff = false;
        {
            require List::Compare;
            List::Compare->VERSION('0.55');

            require Term::Table;

            my %compare_data = (
                missing => {
                    meta_a => undef,
                    meta_b => undef,
                },
                unique => {
                    meta_a => undef,
                    meta_b => undef,
                },
                different => {
                    meta_a => undef,
                    meta_b => undef,
                },
            );

            # Get missing vars from both metadatas.
            #
            # NOTE:
            #   pkgrel and epoch must not be in the comparison since the generated
            #   pkgrel value is always 1 and epoch is never generated.

            my @vars_a;
            my @vars_b;

            foreach my $var ( sort keys %meta_a ) {
                next if $var eq 'pkgrel' || $var eq 'epoch';

                if ( !exists $meta_b{$var} ) {
                    $is_diff = true;

                    $meta_b{$var} = [];
                    push $compare_data{missing}{meta_b}->@*, $var;
                }

                push @vars_a, $var;
            }

            foreach my $var ( sort keys %meta_b ) {
                next if $var eq 'pkgrel' || $var eq 'epoch';

                if ( !exists $meta_a{$var} ) {
                    $is_diff = true;

                    $meta_a{$var} = [];
                    push $compare_data{missing}{meta_a}->@*, $var;
                }

                push @vars_b, $var;
            }

            my @vars = uniq @vars_a, @vars_b;

            # Compare both metadatas to get their unique and different vars.
            foreach my $var (@vars) {
                my $type_a = reftype $meta_a{$var} // '';
                my $type_b = reftype $meta_b{$var} // '';

                # Unique
                if ( $type_a eq 'ARRAY' && $type_b eq 'ARRAY' ) {
                    my $lc = List::Compare->new( \$meta_a{$var}->@*, \$meta_b{$var}->@* );

                    if ( !$lc->is_LequivalentR ) {
                        my @lonly = $lc->get_Lonly;
                        my @ronly = $lc->get_Ronly;

                        if ( scalar @lonly ) {
                            $is_diff = true;
                            push $compare_data{unique}{meta_a}{$var}->@*, @lonly;
                        }

                        if ( scalar @ronly ) {
                            $is_diff = true;
                            push $compare_data{unique}{meta_b}{$var}->@*, @ronly;
                        }
                    }
                }
                # Different
                else {
                    my $str_a = $type_a eq 'ARRAY' ? 'N/A' : $meta_a{$var};
                    my $str_b = $type_b eq 'ARRAY' ? 'N/A' : $meta_b{$var};

                    if ( $str_a ne $str_b ) {
                        $is_diff = true;

                        $compare_data{different}{meta_a}{$var} = $str_a;
                        $compare_data{different}{meta_b}{$var} = $str_b;
                    }
                }
            }

            $self->_pdump( '%compare_data', \%compare_data, "\n" );

            # Show comparison in a table.
            if ($is_diff) {
                warn "$prog: $FILES{metadata} is different than generated metadata\n";
                warn "\nMetadata comparison\n";

                my @rows;

                foreach my $meta ( sort keys $compare_data{missing}->%* ) {
                    foreach my $var ( $compare_data{missing}{$meta}->@* ) {
                        push @rows, [ $var, 'N/A', '-',   "Missing from $FILES{metadata}" ] if $meta eq 'meta_a';
                        push @rows, [ $var, '-',   'N/A', 'Missing from Generated' ]        if $meta eq 'meta_b';
                    }
                }

                foreach my $meta ( sort keys $compare_data{unique}->%* ) {
                    foreach my $var ( sort keys $compare_data{unique}{$meta}->%* ) {
                        my $pkgs = join ', ', $compare_data{unique}{$meta}{$var}->@*;

                        push @rows, [ $var, $pkgs, '-', "Only in $FILES{metadata}" ] if $meta eq 'meta_a';
                        push @rows, [ $var, '-', $pkgs, 'Only in Generated' ] if $meta eq 'meta_b';
                    }
                }

                if ( keys $compare_data{different}{meta_a}->%* ) {
                    foreach my $var ( sort keys $compare_data{different}{meta_a}->%* ) {
                        my $str_a = $compare_data{different}{meta_a}{$var};
                        my $str_b = $compare_data{different}{meta_b}{$var};

                        push @rows, [ $var, $str_a, $str_b, 'Differs' ];
                    }
                }

                #$self->_pdump( '@rows', \@rows, "\n" );

                my $table = Term::Table->new(
                    collapse => 1,
                    header   => [ 'Variable', '.SRCINFO', 'Generated', 'Status' ],
                    rows     => \@rows,
                );

                print STDERR $_, "\n" foreach $table->render;
                $self->_pdbg("\n");
            }
        }

        # Preserve the PKGBUILD contributor attributions.
        my @file_contents;
        my @contributors;
        {
            @file_contents = path( $FILES{outfile} )->lines_utf8( { chomp => 1 } );
            @contributors =
              grep { /\A \# \s* (?> (?> Co-)?Mai?ntainer | Contributor )\s*:\s*[^\n]+\z/ix } @file_contents;

            $self->_pdump( '@file_contents', \@file_contents, "\n" );
            $self->_pdump( '@contributors',  \@contributors,  "\n" );
        }

        # Set past maintainer/contributor attributions.
        {
            # Whether PACKAGER is the current maintainer.
            my $has_packager = false;
            if ( defined $contributors[0] ) {
                $has_packager = true
                  if $contributors[0] =~ /\b$env{packager}\z/;
            }

            $contributors[0] = "# Maintainer: $env{packager}" if $has_packager;

            if ( !scalar @contributors || !$has_packager ) {
                # Update maintainer anyway.
                unshift @contributors, "# Maintainer: $env{packager}";
            }

            my $maintainer = shift @contributors;

            # Preserve co-maintainers if PACKAGER is the current maintainer.
            if ($has_packager) {
                my @preserved;

                foreach my $contrib (@contributors) {
                    if ( $contrib =~ s{\A \# \s* (?> Co-)?Mai?ntainer\s*:\s*}{# Maintainer: }ix ) {
                        push @preserved, $contrib;
                        next;
                    }
                    push @preserved, $contrib =~ s{\A[^:]+:\s*}{# Contributor: }r;
                }

                @contributors = @preserved;
            }
            else {
                @contributors = map { s{\A[^:]+:\s*}{# Contributor: }r } @contributors;
            }

            my $attributions = join "\n", $maintainer, @contributors;
            $gen_output =~ s{\A}{$attributions\n\n};
        }

        # Bump pkgrel only when pkgver numbers are equal.
        {
            my $ret = $self->_comp_vers( $srcinfo_meta{pkgver}, $_generated_meta{pkgver}, '==' );
            return 1 if defined $ret && $ret == 1;

            if ( defined $ret && $ret == 0 ) {
                my $pkgrel = ++$srcinfo_meta{pkgrel};
                $gen_output =~ s{^pkgrel=\K[^\n]+$}{$pkgrel}m;

                $self->_pdbg("bump pkgrel to $pkgrel\n\n");

                if ( !$is_diff ) {
                    warn "$prog: $FILES{metadata} is the same as generated metadata;"
                      . " maybe pkgrel shouldn't have been bumped?\n";

                    $self->_pdbg("\n");
                }
            }
        }

        # Preserve epoch
        if ( exists $srcinfo_meta{epoch} && !$has_epoch ) {
            $gen_output =~ s{^pkgrel=[^\n]+\n\K}{epoch=$srcinfo_meta{epoch}\n}m;
        }

        # Update
        {
            my $file_output = join "\n", @file_contents;
            $file_output .= "\n";

            # Avoid writing needlessly.
            if ( $gen_output ne $file_output ) {
                path( $FILES{outfile} )->spew_utf8($gen_output);

                $self->_pdbg("update $FILES{outfile}\n");
            }
        }
    }
    # --write
    elsif ( defined $opts{write} ) {
        if ( -f $FILES{outfile} && !$opts{force} ) {
            warn "$prog: $FILES{outfile} file exists; use --force to overwrite it\n";
            return 1;
        }

        path( $FILES{outfile} )->spew_utf8( $_pkgbuild{output} );

        $self->_pdbg("write to $FILES{outfile}\n");
    }
    else {
        print $_pkgbuild{output};
    }

    return 0;
}

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

App::cpan2arch::WritePkgbuild - generate and output PKGBUILD

=head1 SYNOPSIS

  use App::cpan2arch;

  my $cpan2arch = App::cpan2arch->new;

  ...

=head1 DESCRIPTION

This role handles the generation and output of the C<PKGBUILD> for the module/distribution.

=head1 METHODS

=head2 generate_pkgbuild

  $cpan2arch->generate_pkgbuild;

Takes no arguments and returns C<self>.

=head2 write_pkgbuild

  $cpan2arch->write_pkgbuild;

Takes no arguments and returns C<0> on success.

=head2 PKGBUILD EXAMPLE

=for highlighter language=bash

  # Maintainer: Your Name <email@domain.tld>

  _author=RYOSKZYPU
  _dist=App-cpan2arch
  pkgname=perl-${_dist@L}
  pkgver=v1.0.0
  pkgrel=1
  pkgdesc='generate PKGBUILD from CPAN metadata'
  arch=('any')
  url=https://metacpan.org/dist/$_dist
  license=('MIT-0')
  depends=(
      'perl-archive-tar'
      'perl-capture-tiny>=0.50'
      'perl-chi>=0.61'
      'perl-cpanel-json-xs>=4.40'
      'perl-devel-checkbin>=0.04'
      'perl-encode'
      'perl-encode-locale>=1.05'
      'perl-io-socket-ssl>=2.098'
      'perl-list-compare>=0.55'
      'perl-module-corelist>=5.20260420'
      'perl-mojo-useragent-cached>=1.25'  # Package for Mojo::UserAgent::Cached is missing.
      'perl-mojolicious'
      'perl-object-pad>=0.825'
      'perl-path-tiny>=0.150'
      'perl-pathtools'
      'perl-pod-usage'
      'perl-scalar-list-utils'
      'perl-software-license>=0.104007'
      'perl-term-readkey>=2.38'
      'perl-term-table'
      'perl-time-piece'
      'perl-version>=0.9934'
      'perl>=5.42.0'
  )
  makedepends=('perl-extutils-makemaker')
  checkdepends=(
      'perl-capture-tiny>=0.50'
      'perl-devel-checkbin>=0.04'
      'perl-path-tiny>=0.150'
      'perl-test-simple'
      'perl-text-diff>=1.45'
  )
  optdepends=(
      'perl-data-printer>=1.002001'
      'perl-getopt-long-more>=0.007'  # Package for Getopt::Long::More is missing.
  )
  options=('!emptydirs')
  source=("https://cpan.metacpan.org/authors/id/${_author::1}/${_author::2}/$_author/$_dist-$pkgver.tar.gz")
  sha256sums=('9bdd428eb2afc2f836216ad79afd9ebf2b935201be3067da11044b3b740f096f')

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

=head1 BUGS

Report bugs at L<https://github.com/ryoskzypu/App-cpan2arch/issues>.

=head1 AUTHOR

ryoskzypu <ryoskzypu@proton.me>

=head1 SEE ALSO

=over 4

=item *

L<https://wiki.archlinux.org/title/Perl_package_guidelines>

=item *

L<SRCINFO(5)|https://man.archlinux.org/man/SRCINFO.5>

=item *

L<PKGBUILD(5)|https://man.archlinux.org/man/core/pacman/PKGBUILD.5>

=back

=head1 COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.

=cut
