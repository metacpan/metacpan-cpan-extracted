use v5.42.0;

use strict;
use warnings;
no source::encoding;  # Avoid dying on v5.42.0 (non-ASCII char in POD).

use Object::Pad 0.825;

package App::cpan2arch::CheckPackages;  # For toolchain compatibility.
role App::cpan2arch::CheckPackages;

use List::Util qw< any uniq >;

our $VERSION = 'v1.1.2';

field $_mua_arch;
field %_arch_prereqs :reader :writer;

# Check whether prerequisite dists exist as packages in Arch's Official/AUR repos
# and build PKGBUILD data.
#
# References:
#   https://wiki.archlinux.org/title/Official_repositories_web_interface
#   https://wiki.archlinux.org/title/Aurweb_RPC_interface
method check_packages ()
{
    $self->_psub;

    $self->_init_mua_arch;

    # Query Arch's perl pkg and Official + AUR Perl pkgs in bulk.
    my $perl;
    my %pkgs = (
        official => undef,
        aur      => undef,
    );
    {
        my %QUERIES = (
            perl     => 'https://archlinux.org/packages/core/x86_64/perl/json/',
            official => 'https://archlinux.org/packages/search/json/?q=perl-&repo=Core&repo=Extra',
            aur      => 'https://aur.archlinux.org/rpc/v5/search/perl-?by=name',
        );

        my %json = (
            perl     => undef,
            official => undef,
            aur      => undef,
        );

        foreach my $q ( keys %QUERIES ) {
            $self->_pdump( '$q', \$q, "\n" );

            $json{$q} = $self->_get_json( $QUERIES{$q} );
            return 1 if $json{$q} == 1;

            if ( $q eq 'perl' ) {
                $perl = $json{perl};
            }
            elsif ( $q eq 'official' ) {
                $pkgs{official} = [ $json{official}{results}->@* ];

                foreach my $page ( 2 .. $json{official}{num_pages} ) {
                    my $url = $QUERIES{official} . "&page=$page";

                    my $j = $self->_get_json($url);
                    return 1 if $j == 1;

                    push $pkgs{official}->@*, $j->{results}->@*;
                }
            }
            elsif ( $q eq 'aur' ) {
                $pkgs{aur} = [ $json{aur}{results}->@* ];
            }
        }

        #$self->_pdump('$perl', \$perl, '');
        #$self->_pdump('%pkgs', \%pkgs, "\n");
    }

    my $core_modules = $self->_get_corelist( $perl->{pkgver} );
    return 1 if $core_modules == 1;

    my $prereqs = $self->_preproc_prereqs( $core_modules, $perl, %pkgs );
    return 1 if $prereqs == 1;

    $self->_postproc_prereqs( $prereqs->%* );

    return 0;
}

# Pre-process prerequisites while checking for Arch packages.
method _preproc_prereqs ( $core_modules, $perl, %pkgs )
{
    $self->_psub;

    my %cpan_prereqs = $self->cpan_prereqs;
    my %prereqs;
    my %seen_pkgs;

    # Regexes to validate Perl pkgs in Official/AUR repos.
    my %RE = (
        words   => qr{\b(?> Perl | CPAN )\b}ix,
        url     => qr{\Ahttps?://(?> search\.m? | meta)cpan\.org/}x,
        license => qr{(?> Perl | Artistic )}x,
        name    => qr{(?> \Aperl- | \Aperl\z )}x,
    );

    my sub build_pkgnames ($p)
    {
        # Some packages do not prepend the perl prefix or exclude 'app-' (e.g. ack,
        # perl-tidy, jq-lite, cpanminus, perlbrew), so include them in the search.
        return (
            "perl-$p",
            "perl-$p" =~ tr{_}{-}r,
            $p        =~ tr{_}{-}r,
            $p        =~ s{\Aapp-}{}r,
            $p,
        );
    }

    my sub is_official_pkg ($res)
    {
        my @vars = (
            $res->{depends}->@*,
            $res->{makedepends}->@*,
            $res->{checkdepends}->@*,
            $res->{optdepends}->@*,
            $res->{provides}->@*,
        );

        return
            $res->{pkgdesc} =~ $RE{words}                       ? true
          : $res->{url} =~ $RE{url}                             ? true
          : ( any { $_ =~ $RE{name} } @vars )                   ? true
          : ( any { $_ =~ $RE{license} } $res->{licenses}->@* ) ? true
          :                                                       false;
    }

    my sub is_aur_pkg ($res)
    {
        my $desc = $res->{Description} // '';
        my $url  = $res->{URL}         // '';
        my @kwords;
        my @license;
        my @vars;

        my @PKG_VARS = (
            qw<
                Depends
                MakeDepends
                CheckDepends
                OptDepends
                Provides
            >
        );

        foreach my $var (@PKG_VARS) {
            push @vars, $res->{$var}->@* if defined $res->{$var};
        }
        push @license, $res->{License}->@*  if defined $res->{License};
        push @kwords,  $res->{Keywords}->@* if defined $res->{Keywords};

        return
            ( any { $_ =~ $RE{words} } @kwords )    ? true
          : $desc =~ $RE{words}                     ? true
          : $url =~ $RE{url}                        ? true
          : ( any { $_ =~ $RE{name} } @vars )       ? true
          : ( any { $_ =~ $RE{license} } @license ) ? true
          :                                           false;
    }

    # NOTE:
    #   Sort keys to ensure 'depends' runs before makedepends for correct deduplication.
    foreach my $var ( sort keys %cpan_prereqs ) {
        my $deps = $cpan_prereqs{$var};
        next unless defined $deps;

        foreach my ( $module, $info ) ( $deps->%* ) {
            my ( $dist, $version, $failed ) = $info->@{ qw< dist version failed > };

            $self->_pdump( '$var',    \$var,    '' );
            $self->_pdump( '$module', \$module, '' );

            if ( $module eq 'perl' ) {
                # Convert perl version to an Arch perl package version.
                $version = version->parse($version)->to_dotted_decimal =~ s{\Av}{}r
                  if $version ne '0';

                # Skip duplicated perl in makedepends, but get the lesser version.
                if ( $var eq 'makedepends' && exists $prereqs{depends}{perl} ) {
                    $self->_pdbg("perl already in depends\n");

                    my $ret = $self->_comp_vers( $version, $prereqs{depends}{perl}{version}, '<=' );
                    return 1 if defined $ret && $ret == 1;

                    $prereqs{depends}{perl}{version} = $version
                      if defined $ret && $ret == 0;

                    next;
                }

                $prereqs{$var}{perl} = {
                    version   => $version,
                    flag_date => _fmt_date( $perl->{flag_date}, 'official' ),
                };

                $self->_pdbg("\n\n");
                next;
            }
            # Core module
            elsif ( exists $core_modules->{$module} ) {
                $self->_pdbg("$module is a core module\n");

                if ( defined $failed ) {
                    $prereqs{$var}{$module} = {
                        failed  => true,
                        version => $version,
                    };

                    $self->_pdbg("failed module\n");
                    $self->_pdbg("\n\n");

                    next;
                }

                $self->_pdump( '$dist', \$dist, '' );

                if ( $dist eq 'perl' ) {
                    $self->_pdbg("\n\n");
                    next;
                }

                # Dual-life dist
                $self->_pdbg("$dist is dual lifed\n");

                my $pkg = lc "perl-$dist";

                # Skip duplicated variable distros but get the lesser version.
                if ( exists $prereqs{$var}{$pkg} ) {
                    $self->_pdbg("found var dist dupe; skip\n");

                    my $ret = $self->_comp_vers( $version, $prereqs{$var}{$pkg}{version}, '<=' );
                    return 1 if defined $ret && $ret == 1;

                    $prereqs{$var}{$pkg}{version} = $version
                      if defined $ret && $ret == 0;

                    next;
                }

                # Skip duplicated package in makedepends, but get the lesser version.
                if ( $var eq 'makedepends' && exists $prereqs{depends}{$pkg} ) {
                    $self->_pdbg("$pkg already in depends\n");

                    my $ret = $self->_comp_vers( $version, $prereqs{depends}{$pkg}{version}, '<=' );
                    return 1 if defined $ret && $ret == 1;

                    $prereqs{depends}{$pkg}{version} = $version
                      if defined $ret && $ret == 0;

                    next;
                }

                if ( exists $seen_pkgs{$pkg} ) {
                    $prereqs{$var}{$pkg}{version} = $version;
                    $prereqs{$var}{$pkg}{module}  = $module if $var eq 'optdepends';

                    $self->_pdbg("found pkg provides dupe; skip\n");
                    $self->_pdbg("\n\n");

                    next;
                }

                # Dist exists in the perl package provides array.
                if ( any { /\A \Q$pkg\E (?> = [0-9._]+ )?\z/x } $perl->{provides}->@* ) {
                    $prereqs{$var}{$pkg}{version} = $version;
                    $prereqs{$var}{$pkg}{module}  = $module if $var eq 'optdepends';
                    $seen_pkgs{$pkg}              = {};

                    $self->_pdbg("found $pkg in provides\n");
                }

                $self->_pdbg("\n\n");
                next;
            }
            # Non-core CPAN module
            else {
                my $mod = $module;

                $self->_pdbg("$mod is NOT a core module\n");

                if ( defined $failed ) {
                    $prereqs{$var}{$module} = {
                        failed  => true,
                        version => $version,
                    };

                    $self->_pdbg("failed module\n");
                    $self->_pdbg("\n\n");

                    next;
                }

                $self->_pdump( '$dist', \$dist, '' );

                # Some packages incorrectly use the module name as package name,
                # (e.g. perl-term-readkey) so search for module names in addition
                # to dist names.
                my @pkgs;
                {
                    $dist = lc $dist;
                    $mod  = lc $mod =~ s{::}{-}gr;

                    @pkgs = build_pkgnames($dist);
                    push @pkgs, build_pkgnames($mod) if $mod ne $dist;

                    # Hardcode packages that use their own convention, as last resort.
                    my %ODD_PKGS = (
                        'libwww-perl' => 'perl-libwww',
                        cairo         => 'cairo-perl',
                        glib          => 'glib-perl',
                        gtk2          => 'gtk2-perl',
                        pango         => 'pango-perl',
                    );
                    push @pkgs, $ODD_PKGS{$dist} if exists $ODD_PKGS{$dist};

                    @pkgs = uniq @pkgs;
                }

                my $prereq_pkg_dupe = false;

                # Dedupe packages.
                foreach my $pkg (@pkgs) {
                    # Skip duplicated variable packages, but get the lesser version.
                    if ( exists $prereqs{$var}{$pkg} ) {
                        $prereq_pkg_dupe = true;

                        $self->_pdbg("found var pkg dupe; skip\n");
                        $self->_pdump( '$pkg', \$pkg, '' );

                        my $ret = $self->_comp_vers( $version, $prereqs{$var}{$pkg}{version}, '<=' );
                        return 1 if defined $ret && $ret == 1;

                        $prereqs{$var}{$pkg}{version} = $version
                          if defined $ret && $ret == 0;

                        last;
                    }
                    # Skip duplicated package in makedepends, but get the lesser version.
                    elsif ( $var eq 'makedepends' && exists $prereqs{depends}{$pkg} ) {
                        $prereq_pkg_dupe = true;

                        $self->_pdbg("$pkg already in depends\n");

                        my $ret = $self->_comp_vers( $version, $prereqs{depends}{$pkg}{version}, '<=' );
                        return 1 if defined $ret && $ret == 1;

                        $prereqs{depends}{$pkg}{version} = $version
                          if defined $ret && $ret == 0;

                        next;
                    }
                }
                next if $prereq_pkg_dupe;

                my $repo_pkg_dupe = false;

                # Skip packages already found in Official/AUR repos or missing.
                foreach my $pkg (@pkgs) {
                    if ( exists $seen_pkgs{$pkg} ) {
                        $repo_pkg_dupe = true;

                        $prereqs{$var}{$pkg} = {
                            missing   => $seen_pkgs{$pkg}{missing},
                            version   => $version,
                            flag_date => $seen_pkgs{$pkg}{flag_date},
                        };
                        $prereqs{$var}{$pkg}{module} = $module if $var eq 'optdepends';

                        $self->_pdbg("found repo pkg dupe; skip\n");
                        $self->_pdbg("\n\n");

                        last;
                    }
                }
                next if $repo_pkg_dupe;

                # Whether to search for a single package or multiple packages with regex.
                my $pkg_single;
                my $pkg_rx;
                {
                    # Bulk search only covers perl-* packages.
                    my @bulk_pkgs = grep { /\Aperl-/ } @pkgs;

                    if ( scalar @bulk_pkgs == 1 ) {
                        $pkg_single = $bulk_pkgs[0];
                    }
                    # Only build a regex on multiple packages.
                    else {
                        # Longest matches must be matched first in regex alternations.
                        @bulk_pkgs = reverse sort { length $a <=> length $b } @bulk_pkgs;

                        my $pat = join '|', map { "\Q$_\E" } @bulk_pkgs;
                        $pkg_rx = qr{\A(?'pkg' $pat)\z}x;
                    }

                    $self->_pdump( '@pkgs',       \@pkgs,       '' );
                    $self->_pdump( '$pkg_single', \$pkg_single, '' );
                    $self->_pdump( '$pkg_rx',     \$pkg_rx,     "\n" );
                }

                # Try to find the package in Official repositories.

                my $found = false;

                # Bulk search
                {
                    my $pkg;

                    foreach my $res ( $pkgs{official}->@* ) {
                        if ( defined $pkg_single && $res->{pkgname} eq $pkg_single ) {
                            $pkg = $pkg_single;
                        }
                        elsif ( defined $pkg_rx && $res->{pkgname} =~ $pkg_rx ) {
                            $pkg = $+{pkg};
                        }

                        if ( defined $pkg ) {
                            $found = true;
                            $found = is_official_pkg($res) if $pkg !~ /\Aperl-/;

                            if ($found) {
                                # Strip leading 'v' from version if package does not use it.
                                $version =~ s{\Av}{} if $version =~ /\Av/ && $res->{pkgver} !~ /\Av/;

                                my $date = _fmt_date( $res->{flag_date}, 'official' );

                                $prereqs{$var}{$pkg} = {
                                    version   => $version,
                                    flag_date => $date,
                                };
                                $prereqs{$var}{$pkg}{module} = $module if $var eq 'optdepends';

                                $seen_pkgs{$pkg} = { flag_date => $date };

                                $self->_pdbg("found $pkg in official repos (bulk)\n");
                                $self->_pdbg("\n\n");

                                last;
                            }
                        }
                    }
                }
                next if $found;

                # Try an individual search.

                # perl-* pkgs were already searched in bulk.
                my @exact_pkgs = grep { !/\Aperl-/ } @pkgs;

                # Exact pkgname search
                foreach my $pkg (@exact_pkgs) {
                    my $query = "https://archlinux.org/packages/search/json/?name=$pkg&repo=Core&repo=Extra";

                    my $json = $self->_get_json($query);
                    return 1 if $json == 1;
                    next     unless scalar $json->{results}->@*;

                    my $res = $json->{results}[0];

                    if ( $res->{pkgname} eq $pkg ) {
                        $found = true;
                        $found = is_official_pkg($res) if $pkg !~ /\Aperl-/;

                        if ($found) {
                            $version =~ s{\Av}{} if $version =~ /\Av/ && $res->{pkgver} !~ /\Av/;
                            my $date = _fmt_date( $res->{flag_date}, 'official' );

                            $prereqs{$var}{$pkg} = {
                                version   => $version,
                                flag_date => $date,
                            };
                            $prereqs{$var}{$pkg}{module} = $module if $var eq 'optdepends';

                            $seen_pkgs{$pkg} = { flag_date => $date };

                            $self->_pdbg("found $pkg in official repos (individual)\n");
                            $self->_pdbg("\n\n");

                            last;
                        }
                    }
                }
                next if $found;

                # Try to find the package in the AUR.
                #
                # NOTE:
                #   There are currently ~2000 perl packages in AUR but the Aurweb
                #   API is limited to 5k results, so the archives could be used
                #   when needed.

                # Bulk search
                {
                    my $pkg;

                    foreach my $res ( $pkgs{aur}->@* ) {
                        if ( defined $pkg_single && $res->{PackageBase} eq $pkg_single ) {
                            $pkg = $pkg_single;
                        }
                        elsif ( defined $pkg_rx && $res->{PackageBase} =~ $pkg_rx ) {
                            $pkg = $+{pkg};
                        }

                        if ( defined $pkg ) {
                            $found = true;
                            $found = is_aur_pkg($res) if $pkg !~ /\Aperl-/;

                            if ($found) {
                                $version =~ s{\Av}{} if $version =~ /\Av/ && $res->{Version} !~ /\A(?> [0-9]+:)?v/x;
                                my $date = _fmt_date( $res->{OutOfDate}, 'aur' );

                                $prereqs{$var}{$pkg} = {
                                    version   => $version,
                                    flag_date => $date,
                                };
                                $prereqs{$var}{$pkg}{module} = $module if $var eq 'optdepends';

                                $seen_pkgs{$pkg} = { flag_date => $date };

                                $self->_pdbg("found $pkg in AUR repos (bulk)\n");
                                $self->_pdbg("\n\n");

                                last;
                            }
                        }
                    }
                }
                next if $found;

                # Exact PackageBase search
                {
                    my $query = 'https://aur.archlinux.org/rpc/v5/info?';

                    # Construct multiple arg packages in a single query.
                    foreach my ( $idx, $pkg ) ( indexed @exact_pkgs ) {
                        my $arg = "arg[]=$pkg";
                        $arg = "&$arg" unless $idx == 0;

                        $query .= $arg;
                    }

                    my $json = $self->_get_json($query);
                    return 1 if $json == 1;
                    last     unless scalar $json->{results}->@*;

                    foreach my $res ( $json->{results}->@* ) {
                        my $pkg = $res->{PackageBase};

                        $found = true;
                        $found = is_aur_pkg($res) if $pkg !~ /\Aperl-/;

                        if ($found) {
                            $version =~ s{\Av}{} if $version =~ /\Av/ && $res->{Version} !~ /\A(?> [0-9]+:)?v/x;
                            my $date = _fmt_date( $res->{OutOfDate}, 'aur' );

                            $prereqs{$var}{$pkg} = {
                                version   => $version,
                                flag_date => $date,
                            };
                            $prereqs{$var}{$pkg}{module} = $module if $var eq 'optdepends';

                            $seen_pkgs{$pkg} = { flag_date => $date };

                            $self->_pdbg("found $pkg in AUR repos (individual)\n");
                            $self->_pdbg("\n\n");

                            last;
                        }
                    }
                }
                next if $found;

                # Package was not found in the Official/AUR repos.
                {
                    my $pkg = "perl-$dist";

                    $prereqs{$var}{$pkg} = {
                        missing => $module,
                        version => $version,
                    };
                    $prereqs{$var}{$pkg}{module} = $module if $var eq 'optdepends';

                    $seen_pkgs{$pkg} = { missing => $module };

                    $self->_pdbg("$pkg does not exist in Arch's official/AUR repos\n");
                }
            }

            $self->_pdbg("\n\n");
        }
    }

    $self->_pdump( '%prereqs',   \%prereqs,   "\n" );
    $self->_pdump( '%seen_pkgs', \%seen_pkgs, "\n" );

    return \%prereqs;
}

# Post-process prerequisites into its final data for PKGBUILD generation.
method _postproc_prereqs (%prereqs)
{
    $self->_psub;

    my %opts = $self->opts;
    my %post_prereqs;

    foreach my ( $var, $deps ) (%prereqs) {
        foreach my ( $pkg, $info ) ( $deps->%* ) {
            my ( $flag_date, $failed, $missing, $version ) = $info->@{ qw< flag_date failed missing version > };
            my $vertype = reftype $version // '';

            # Do not require a version in Test::Simple because several dists have
            # been merged into it, e.g. Test::More, Test2::*. A Test2 dependency
            # with a minimum version requirement older than the merge will resolve
            # to perl-test-simple with that version, which may not exist in the
            # Test-Simple dist.
            $version = 0 if $pkg eq 'perl-test-simple';

            # Skip version requirement for 0 versions and failed.
            $pkg =
                $version eq '0' || defined $failed
              ? $pkg
              : "$pkg>=$version";

            my sub push_pkg ($p)
            {
                # Flagged/Failed/Missing/Existing package
                push $post_prereqs{$var}->@*,
                    defined $flag_date ? { $p => { flag_date => $flag_date } }
                  : defined $failed    ? { $p => { failed => $failed, version => $version } }
                  : defined $missing   ? { $p => { missing => $missing } }
                  :                      $p;
            }

            # Add optdepends descriptions.
            if ( $var eq 'optdepends' && !defined $failed ) {
                my %optionals = $self->optionals;
                my $module    = $info->{module};

                if ( exists $optionals{$module} ) {
                    foreach my $desc ( $optionals{$module}->@* ) {
                        # Massage desc
                        # https://man.archlinux.org/man/alpm-package-relation.7.en#Optional_dependency:~:text=Note
                        $desc = trim($desc)
                          =~ s{\v}{; }gr
                          =~ s{'}{\\'}gr;

                        my $opt = "$pkg: $desc";
                        push_pkg($opt);
                    }
                    next;
                }
            }

            push_pkg($pkg);
        }
    }

    $self->_pdump( '%post_prereqs', \%post_prereqs, "\n" );

    # Sort the variable dependencies with Schwartzian transform since they may
    # contain mixed elements (scalars and hashrefs).
    {
        foreach my ( $var, $deps ) (%post_prereqs) {
            push $_arch_prereqs{$var}->@*,
              map  { $_->[0] }
              sort { $a->[1] cmp $b->[1] }
              map  { [ $_, defined reftype $_ && reftype $_ eq 'HASH' ? keys $_->%* : $_ ] } $deps->@*;
        }

        $self->_pdump( '%_arch_prereqs', \%_arch_prereqs, "\n" );
    }

    return $self;
}

method _init_mua_arch ()
{
    $self->_psub;

    $_mua_arch = $self->_get_mua('arch');

    return $self;
}

method _get_json ($url)
{
    $self->_psub;

    my $prog = $self->prog;

    # Request JSON
    my $res;
    {
        my $OK      = 200;
        my $get_err = "$prog: failed to request $url\n";

        $res = do {
            try {
                my %env = $self->env;
                local $ENV{MUAC_NOCACHE} = true if $env{cache_ignore};

                $_mua_arch->get($url)->result;
            }
            catch ($e) {
                warn $e;
                undef;
            }
        };

        if ( !defined $res ) {
            warn $get_err;
            return 1;
        }

        if ( $res->code != $OK ) {
            warn $res->body;
            warn $get_err;

            return 1;
        }
    }

    # Decode JSON
    my $json = do {
        try {
            $res->json;
        }
        catch ($e) {
            warn $e;
            undef;
        }
    };

    if ( !defined $json ) {
        warn "$prog: failed to decode $url\n";
        return 1;
    }

    $self->_pdbg("\n");

    return $json;
}

# Get a list of core modules from specific Perl version.
method _get_corelist ($ver)
{
    $self->_psub;

    my $prog = $self->prog;

    # NOTE:
    #   Ideally, M::CoreList should always support the current perl pkg version,
    #   but its min required version would have to be kept updated, so just fallback
    #   to the current perl version if perl pkg version is not found in M::CoreList.
    #   This might lead to the generated PKGBUILD miss core modules (Arch users
    #   will have latest perl anyways).
    require Module::CoreList;

    my $perl_pkg_ver = do {
        try {
            version->parse($ver)->numify;
        }
        catch ($e) {
            warn $e;
            warn "$prog: failed to parse $ver version\n";

            return 1;
        }
    };

    my $perl_cur_ver = $];

    if ( $perl_pkg_ver > $perl_cur_ver ) {
        $self->_pdbg("perl package version ($perl_pkg_ver) is newer than the current perl version ($perl_cur_ver)\n");
    }

    my $core_modules = Module::CoreList->find_version($perl_pkg_ver);

    # Fallback
    $core_modules = Module::CoreList->find_version($perl_cur_ver)
      unless defined $core_modules;

    #$self->_pdump('$core_modules', $core_modules, "\n");

    if ( !defined $core_modules ) {
        warn "$prog: failed to get Perl core modules list\n";
        return 1;
    }

    # Exclude core libs that MetaCPAN API cannot fetch.
    {
        my @EXCLUDED = (
            qw<
                Unicode
                unicore::Name
                meta_notation
            >
        );

        delete $core_modules->{$_} foreach (@EXCLUDED);
    }

    return $core_modules;
}

# Format/convert datetime to YYYY-MMM-DD.
sub _fmt_date ( $date, $repo )
{
    return undef unless defined $date;

    require Time::Piece;

    return $repo eq 'official'
      ? $date =~ s{T.+\z}{}r
      : $repo eq 'aur' ? Time::Piece::localtime($date)->ymd  # Epoch
      :                  undef;
}

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

App::cpan2arch::CheckPackages - check existence of Arch Linux packages

=head1 SYNOPSIS

  use App::cpan2arch;

  my $cpan2arch = App::cpan2arch->new;

  ...

=head1 DESCRIPTION

This role handles analysis of whether prerequisite distributions exist as packages
in the Arch Linux Official/AUR repositories, checks flagged out-of-date packages,
and builds C<PKGBUILD> data.

=head1 METHODS

=head2 check_packages

  $cpan2arch->check_packages;

Takes no arguments and returns C<0> on success.

=head1 BUGS

Report bugs at L<https://github.com/ryoskzypu/App-cpan2arch/issues>.

=head1 AUTHOR

ryoskzypu <ryoskzypu@proton.me>

=head1 SEE ALSO

=over 4

=item *

L<https://wiki.archlinux.org/title/Official_repositories_web_interface>

=item *

L<https://wiki.archlinux.org/title/Aurweb_RPC_interface>

=back

=head1 COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.

=cut
