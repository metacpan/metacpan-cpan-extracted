use v5.42.0;

use strict;
use warnings;
no source::encoding;  # Avoid dying on v5.42.0 (non-ASCII char in POD).

use Object::Pad 0.825;

package App::cpan2arch::MergePrereqs;  # For toolchain compatibility.
role App::cpan2arch::MergePrereqs;

use Scalar::Util qw< looks_like_number >;
use List::Util   qw< any >;

our $VERSION = 'v1.1.0';

field $_dl_endpoint  :reader :writer = 'https://fastapi.metacpan.org/v1/download_url/';
field %_cpan_prereqs :reader :writer;
field @_fetch_errors :reader;
field @_prereq_dists;

# Merge CPAN prerequisites to PKGBUILD dependencies.
#
# References:
#   https://blogs.perl.org/users/neilb/2017/04/an-introduction-to-distribution-metadata.html
#   https://blogs.perl.org/users/neilb/2017/04/dependency-phases-in-cpan-distribution-metadata.html
#   https://blogs.perl.org/users/neilb/2017/04/specifying-the-type-of-your-cpan-dependencies.html
#   https://blogs.perl.org/users/neilb/2017/05/specifying-dependencies-for-your-cpan-distribution.html
#   https://neilb.org/2015/09/25/dependencies-model.html
#   https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/cpan-packaging.md
#   https://metacpan.org/pod/CPAN::Meta::Spec#PREREQUISITES
#   https://wiki.archlinux.org/title/PKGBUILD#Dependencies
#   https://metacpan.org/pod/CPAN::Meta::Spec#Version-Ranges
#   https://man.archlinux.org/man/core/pacman/PKGBUILD.5.en#:~:text=depends%20(array
#   https://man.archlinux.org/man/alpm-package-relation.7
#   https://man.archlinux.org/man/alpm-comparison.7
method merge_prereqs ()
{
    $self->_psub;

    my %meta = $self->meta;

    %_cpan_prereqs = (
        depends      => undef,
        makedepends  => undef,
        checkdepends => undef,
        optdepends   => undef,
    );

    my $prereqs = $self->_get_dists;
    return 1 if looks_like_number($prereqs) && $prereqs == 1;
    $self->_pdump( '$prereqs', $prereqs, "\n" );

    foreach my $dep ( $prereqs->@* ) {
        my $module       = $dep->{module};
        my $dist         = $dep->{dist};
        my $phase        = $dep->{phase};
        my $relationship = $dep->{relationship};
        my $version      = $dep->{version};
        my $failed       = $dep->{failed};

        my $variable =
            $relationship eq 'recommends' || $relationship eq 'suggests' ? 'optdepends'
          : $phase eq 'configure' || $phase eq 'build'                   ? 'makedepends'
          : $phase eq 'runtime'                                          ? 'depends'
          : $phase eq 'test'                                             ? 'checkdepends'
          :                                                                ();

        $self->_pdump( '$module',  \$module,  '' );
        $self->_pdump( '$version', \$version, '' );

        # Version ranges are unsupported because no dist use it for its prereqs,
        # and some operators are inconsistent with PKGBUILD operators, e.g. ==, !=.
        my $is_version = do {
            try {
                version->parse($version);
            }
            catch ($e) {
                $self->_pdbg("version range is unsupported\n");
                undef;
            }
        };

        if ( !defined $is_version ) {
            $_cpan_prereqs{$variable}{$module}{dist}    = $dist if defined $dist;
            $_cpan_prereqs{$variable}{$module}{failed}  = true  if defined $failed;
            $_cpan_prereqs{$variable}{$module}{version} = 0;
        }
        # Numeric version
        else {
            # Skip duplicated distros but get the lesser version.
            if ( exists $_cpan_prereqs{$variable}{$module} ) {
                $self->_pdbg("found dupe\n");

                my $ret = $self->_comp_vers( $version, $_cpan_prereqs{$variable}{$module}{version}, '>=' );

                return 1 if defined $ret && $ret == 1;
                next     if defined $ret && $ret == 0;
            }

            $_cpan_prereqs{$variable}{$module}{dist}    = $dist if defined $dist;
            $_cpan_prereqs{$variable}{$module}{failed}  = true  if defined $failed;
            $_cpan_prereqs{$variable}{$module}{version} = $version;
        }

        $self->_pdbg("\n");
    }

    # Optionals must not exist in other variable phases.
    foreach my $opt ( keys $_cpan_prereqs{optdepends}->%* ) {
        foreach my ( $var, $deps ) (%_cpan_prereqs) {
            next if $var eq 'optdepends';

            if ( exists $_cpan_prereqs{$var}{$opt} ) {
                delete $_cpan_prereqs{optdepends}{$opt};
                $self->_pdbg("$opt exists outside of optdepends\n\n");
            }
        }
    }

    # Ensure perl package is in 'depends'.
    if ( !exists $_cpan_prereqs{depends}{perl} ) {
        if ( exists $_cpan_prereqs{makedepends}{perl} ) {
            $_cpan_prereqs{depends}{perl} = delete $_cpan_prereqs{makedepends}{perl};
        }
        else {
            $_cpan_prereqs{depends}{perl}{version} = 0;
        }
    }

    # Ensure Module::Install is in makedepends if dist uses it.
    if ( $meta{has_module_install} && !exists $_cpan_prereqs{makedepends}{'Module::Install'} ) {
        $_cpan_prereqs{makedepends}{'Module::Install'} = {
            dist    => 'Module-Install',
            version => 0,
        };
    }

    $self->_pdump( '%_cpan_prereqs', \%_cpan_prereqs, "\n" );

    return 0;
}

# Get distribution names from prerequisite modules.
method _get_dists ()
{
    $self->_psub;

    my %meta = $self->meta;
    return [] unless scalar $meta{dependency}->@*;

    my $prog = $self->prog;

    # Filter undesired modules.
    my @prereqs;
    my @ignored;
    {
        my @NOT_FOUND = (
            qw<
                Config
                Errno
            >
        );

        foreach my ( $idx, $dep ) ( indexed $meta{dependency}->@* ) {
            # Skip phases like 'develop' and x_Dist_Zilla.
            # Those phases and 'conflicts' relationship (discouraged) are CPAN
            # specific and not relevant to Arch.
            next
              if $dep->{phase} ne 'configure'
              && $dep->{phase} ne 'build'
              && $dep->{phase} ne 'runtime'
              && $dep->{phase} ne 'test';

            next
              if $dep->{relationship} ne 'requires'
              && $dep->{relationship} ne 'recommends'
              && $dep->{relationship} ne 'suggests';

            # MetaCPAN API fails to fetch these core modules for some reason, but it's OK.
            next if any { $dep->{module} eq $_ } @NOT_FOUND;

            # No need to fetch perl interpreter dist.
            if ( $dep->{module} eq 'perl' ) {
                $dep->{dist} = 'perl';
                push @ignored, $dep;

                next;
            }

            push @prereqs, $dep;
        }

        $self->_pdump( '@prereqs', \@prereqs, "\n" );
        $self->_pdump( '@ignored', \@ignored, "\n" );
    }

    # Fetch dists.
    {
        $self->_fetch(@prereqs) if scalar @prereqs;

        $self->_pdbg("\n");
        $self->_pdump( '@_prereq_dists', \@_prereq_dists, "\n" );

        if ( scalar @_fetch_errors ) {
            warn "$prog: failed to fetch distributions\n";
            $self->_pdump( '@_fetch_errors', \@_fetch_errors, "\n" );

            return 1;
        }
    }

    # Include the dists.
    {
        foreach my ( $idx, $dep ) ( indexed @prereqs ) {
            my $dist = $_prereq_dists[$idx];
            my $type = reftype $dist;

            if ( defined $type && $type eq 'HASH' && exists $dist->{failed} ) {
                $dep->{failed} = true;
                next;
            }

            $dep->{dist} = $dist;
        }

        push @prereqs, @ignored;
    }

    return \@prereqs;
}

# Fetch all modules distributions concurrently.
method _fetch (@prereqs)
{
    $self->_psub;

    require Mojo::Promise;

    my $prog       = $self->prog;
    my $mua_mcpan = $self->mua_mcpan;

    my %env = $self->env;
    local $ENV{MUAC_NOCACHE} = true if $env{cache_ignore};

    # Fetch three dists at a time using the download_url endpoint.
    #
    # References:
    #   https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#download_urlmodule.
    #   https://metacpan.org/release/MIYAGAWA/App-cpanminus-1.7049/source/lib/App/cpanminus/fatscript.pm#L926
    #   https://github.com/metacpan/MetaCPAN-Client/blob/396ba371317f114db04967c90be64bb46fd7fd2c/lib/MetaCPAN/Client.pm#L217
    return Mojo::Promise->map(
        { concurrency => 3 },
        sub ($prereq) {
            my $module  = $prereq->{module};
            my $version = $prereq->{version};
            my $url     = $_dl_endpoint . $module;
            my $query;

            $query  = 'version=' . $version if $version;       # Ignore 0 versions.
            $url   .= '?' . $query          if defined $query;

            $mua_mcpan->get_p($url);
        },
        @prereqs,
      )
      ->then(
          sub (@promises) {
              foreach my $tx (@promises) {
                  my $res = $tx->[0]->result;

                  if ( $res->is_success ) {
                      my $json = $res->json;
                      push @_prereq_dists, $json->{distribution};
                  }
                  # Do not exit but flag if MetaCPAN API fails to fetch a module,
                  # to avoid PKGBUILD not being generated when upstream metadata
                  # has wrong module name.
                  else {
                      my $req = $tx->[0]->req;
                      my $url = $req->url;
                      my $mod = $url->path->parts->[-1];
                      my $ver = $url->query->param('version');
                      my $msg = $res->message;

                      my $err = "$prog: failed to fetch $mod module";
                      $err .= " (query version: $ver)" if defined $ver;

                      warn "Failed to fetch '$url': $msg";
                      warn "$err\n";

                      push @_prereq_dists, {
                          failed  => true,
                          version => $ver,
                      };
                  }
              }
          }
      )
      ->catch(
          sub ($e) {
              warn $e;
              push @_fetch_errors, $e;
          }
      )->wait;
}

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

App::cpan2arch::MergePrereqs - merge CPAN prerequisites to PKGBUILD dependencies

=head1 SYNOPSIS

  use App::cpan2arch;

  my $cpan2arch = App::cpan2arch->new;

  ...

=head1 DESCRIPTION

This role handles the translation of dependencies between
L<CPAN|https://metacpan.org/pod/CPAN::Meta::Spec#PREREQUISITES> and
L<PKGBUILD|https://man.archlinux.org/man/alpm-package-relation.7> for the
module/distribution.

=head1 METHODS

=head2 merge_prereqs

  $cpan2arch->merge_prereqs;

Takes no arguments and returns C<0> on success.

=head1 BUGS

Report bugs at L<https://github.com/ryoskzypu/App-cpan2arch/issues>.

=head1 AUTHOR

ryoskzypu <ryoskzypu@proton.me>

=head1 SEE ALSO

=over 4

=item *

L<https://blogs.perl.org/users/neilb/2017/04/dependency-phases-in-cpan-distribution-metadata.html>

=item *

L<https://blogs.perl.org/users/neilb/2017/04/specifying-the-type-of-your-cpan-dependencies.html>

=item *

L<https://blogs.perl.org/users/neilb/2017/05/specifying-dependencies-for-your-cpan-distribution.html>

=back

=head1 COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.

=cut
