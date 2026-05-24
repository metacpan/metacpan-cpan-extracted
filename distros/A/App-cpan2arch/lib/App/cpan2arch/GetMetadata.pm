use v5.42.0;

use strict;
use warnings;
no source::encoding;  # Avoid dying on v5.42.0 (non-ASCII char in POD).

use Object::Pad 0.825;

package App::cpan2arch::GetMetadata;  # For toolchain compatibility.
role App::cpan2arch::GetMetadata;

use File::Spec::Functions qw< catdir splitdir >;
use Scalar::Util          qw< looks_like_number >;

our $VERSION = 'v1.1.1';

field $_mua_mcpan    :reader;
field $_mod_endpoint :reader :writer = 'https://fastapi.metacpan.org/v1/module/';
field $_rel_endpoint :reader :writer = 'https://fastapi.metacpan.org/v1/release/';
field %_optionals    :reader;
field %_meta         :reader :writer;

# Get CPAN metadata from MetaCPAN's API.
#
# References:
#   https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md
method get_metadata ()
{
    $self->_psub;

    $self->_init_mua_mcpan;

    # Get the module/distribution and its release.
    my $dist;
    my $rel;
    {
        my %args    = $self->args;
        my $module  = $args{module};
        my $version = $args{version};
        my $mod;

        # Only request for a module if it does not look like a dist and no version
        # argument is passed, otherwise treat it as dist.
        if ( $module !~ /-/ && !defined $version ) {
            $mod = $self->_get_module($module);
            $self->_pdbg("found module\n\n") if defined $mod;
        }

        # Since modules and dists names can be ambiguous, e.g. Reply, do not exit
        # if a module request fails, but fallback as dist.
        $dist = defined $mod ? $mod->{distribution} : $module;

        $self->_pdbg("Dist\n");
        $self->_pdump( '$dist', \$dist, "\n" );

        $rel = $self->_get_release($dist);
        return 1 if $rel == 1;

        $self->_pdbg("Release\n");
        $self->_pdump( '$rel', \$rel, "\n" );
    }

    # Find Module::Install, license, and XS files in the dist.
    my $ret = $self->_find_files( $dist, $rel->{download_url} );
    return 1 if looks_like_number($ret) && $ret == 1;
    my %files = $ret->%*;

    # Get 'optionals_features' descriptions (will be added to the optdepends array).
    # See https://metacpan.org/pod/CPAN::Meta::Spec#optional_features.
    {
        foreach my ( $feature, $feat_info ) ( $rel->{metadata}{optional_features}->%* ) {

            foreach my ( $phase, $phase_info ) ( $feat_info->{prereqs}->%* ) {

                foreach my ( $relation, $rel_info ) ( $phase_info->%* ) {

                    foreach my ( $module, $version ) ( $rel_info->%* ) {
                        push $_optionals{$module}->@*, $feat_info->{description};
                    }
                }
            }
        }

        $self->_pdump( '%_optionals', \%_optionals, "\n" );
    }

    %_meta = (
        author             => $rel->{author},
        name               => $rel->{name},
        dist               => $rel->{distribution},
        version            => $rel->{version},
        abstract           => $rel->{abstract},
        license            => $rel->{license},
        spdx_expression    => $rel->{metadata}{x_spdx_expression},
        dependency         => $rel->{dependency},
        download_url       => $rel->{download_url},
        checksum           => $rel->{checksum_sha256},
        has_module_install => $files{mi},
        has_license        => $files{license},
        has_multi_licenses => $files{has_multi_licenses},
        has_xs             => $files{xs},
    );
    $self->_pdump( '%_meta', \%_meta, "\n" );

    return 0;
}

method _init_mua_mcpan ()
{
    $self->_psub;

    $_mua_mcpan = $self->_get_mua('mcpan');

    return $self;
}

# Create a Mojo::UserAgent instance.
method _get_mua ($type)
{
    return undef if $type ne 'mcpan' && $type ne 'arch';

    # Caching support
    my $has_muac = do {
        try {
            require Mojo::UserAgent::Cached;
            Mojo::UserAgent::Cached->VERSION('1.25');
        }
        catch ($e) {
            # Use Mojo::UA as fallback.
            require Mojo::UserAgent;

            $self->_pdbg("Mojo::UserAgent::Cached is not installed\n\n");
            undef;
        }
    };
    my $has_chi = do {
        if ( defined $has_muac ) {
            try {
                require CHI;
                CHI->VERSION('0.61');
            }
            catch ($e) {
                $self->_pdbg("CHI is not installed\n\n");
                undef;
            }
        }
    };

    my %env  = $self->env;
    my %opts = $self->opts;
    my $mua;

    if ( defined $has_muac && defined $has_chi ) {
        require Mojo::Log;

        # Silence logger
        my $logger;
        $logger = Mojo::Log->new( path => '/dev/null' ) unless $env{debug};

        $mua = Mojo::UserAgent::Cached->new(
            $env{debug}
            ? ()
            : ( logger => $logger ),
        );
        $mua->transactor->name( $env{user_agent} );

        # Use CHI as the cache backend.
        {
            my $path =
                $type eq 'mcpan'
              ? $env{cache_mcpan_path}
              : $env{cache_arch_path};

            my $chi;

            $chi = CHI->new(
                driver     => 'File',
                root_dir   => $path,
                expires_in => $env{cache_expiration},
            ) unless $env{cache_ignore};

            if ( defined $chi ) {
                $chi->clear
                  if defined $opts{clear}
                  || ( $type eq 'mcpan' && defined $opts{clear_mcpan} )
                  || ( $type eq 'arch'  && defined $opts{clear_arch} );
            }

            $mua->cache_agent($chi) unless $env{cache_ignore};
        }
    }
    else {
        $mua = Mojo::UserAgent->new;
        $mua->transactor->name( $env{user_agent} );
    }

    return $mua;
}

method _get_module ($module)
{
    $self->_psub;

    my $prog = $self->prog;
    my $url  = $_mod_endpoint . "$module?fields=distribution";
    my $json;

    my $res = do {
        try {
            my %env = $self->env;
            local $ENV{MUAC_NOCACHE} = true if $env{cache_ignore};

            $_mua_mcpan->get($url)->result;
        }
        catch ($e) {
            warn $e;
            undef;
        }
    };

    if ( defined $res && $res->is_success ) {
        $self->_pdbg("\n");
        $json = $res->json;
    }

    if ( !defined $json ) {
        warn "$prog: failed to fetch $module module\n";
        $self->_pdbg("\n");

        return undef;
    }

    return $json;
}

# References:
#   https://blogs.perl.org/users/neilb/2016/12/working-with-the-metacpan-api.html.
method _get_release ($dist)
{
    $self->_psub;

    my %args    = $self->args;
    my $version = $args{version};
    my $prog    = $self->prog;

    my $query = "distribution:$dist%20AND%20";
    $query
      .= defined $version
      ? "version:$version"
      : 'status:latest';

    my $url = $_rel_endpoint . "_search?q=$query";

    my $res = do {
        try {
            my %env = $self->env;
            local $ENV{MUAC_NOCACHE} = true if $env{cache_ignore};

            $_mua_mcpan->get($url)->result;
        }
        catch ($e) {
            warn $e;
            undef;
        }
    };

    my $json;
    my $rel;

    if ( defined $res && $res->is_success ) {
        $self->_pdbg("\n");

        $json = $res->json;
        $rel  = $json->{hits}{hits}[0]{_source}
          if defined $json && scalar $json->{hits}{hits}->@*;
    }

    if ( !defined $json || !defined $rel ) {
        warn "$prog: failed to fetch $dist dist release\n";
        return 1;
    }

    return $rel;
}

# Check if the distribution has some type of files (M::I, license, XS).
method _find_files ( $dist, $download_url )
{
    $self->_psub;

    require Path::Tiny;
    Path::Tiny->VERSION('0.150');

    require Archive::Tar;

    my $prog  = $self->prog;
    my %files = (
        mi                 => false,
        license            => false,
        has_multi_licenses => false,
        xs                 => false,
    );

    my $res = do {
        try {
            my %env = $self->env;
            local $ENV{MUAC_NOCACHE} = true if $env{cache_ignore};

            $_mua_mcpan->get($download_url)->result;
        }
        catch ($e) {
            warn $e;
            undef;
        }
    };

    if ( !defined $res ) {
        warn "$prog: failed to fetch $dist tarball release: $download_url\n";
        return 1;
    }

    if ( $res->is_success ) {
        $self->_pdbg("\n");

        # Read tarball
        my @tar_files;
        {
            # Save tarball to tempdir so Archive::Tar can detect its compress type.
            my ($fname) = $download_url =~ m{/([^/]+)\z};
            my $temp    = Path::Tiny->tempdir;
            my $tarball = $temp->child($fname);

            $res->save_to($tarball);

            my $tar = Archive::Tar->new($tarball);

            if ( !defined $tar ) {
                warn "$prog: failed to read $fname\n";
                return 1;
            }

            @tar_files = $tar->get_files;
            #$self->_pdump( '@tar_files', \@tar_files, "\n" );
        }

        my @licenses;

        foreach my $f (@tar_files) {
            if ( $f->is_file ) {
                my $path =
                  $f->prefix ne ''
                  ? catdir( $f->prefix, $f->name )
                  : $f->name;

                my @dirs = splitdir($path);

                # Only top level license files.
                if ( scalar @dirs == 2 ) {
                    my $license = $dirs[1];

                    if ( $license =~ /\A(?> LICEN[CS]E | COPYRIGHT | COPYING)(?> [-_.][^\n]+ )?\z/x ) {
                        push @licenses, $license;
                        $self->_pdbg("found license: $license\n");
                    }
                }
                elsif ( scalar @dirs == 4 ) {
                    my $mi = catdir( $dirs[0], qw< inc Module Install.pm > );

                    # ../inc/Module/Install.pm
                    if ( $f->name eq $mi ) {
                        $files{mi} = true;
                        $self->_pdbg("found Install.pm\n");
                    }
                }
            }
        }

        $self->_pdbg("\n");

        if ( scalar @licenses ) {
            # Multiple licenses is uncommon in Perl, so just return a single license
            # for simplicity, but flag multiple files.
            @licenses                  = sort @licenses;
            $files{license}            = $licenses[0];
            $files{has_multi_licenses} = true
              if scalar @licenses > 1;

            $self->_pdump( '@licenses', \@licenses, "\n" );
        }

        # XS
        foreach my $f (@tar_files) {
            if ( $f->is_file ) {
                my $path =
                  $f->prefix ne ''
                  ? catdir( $f->prefix, $f->name )
                  : $f->name;

                my @dirs = splitdir($path);

                if ( scalar @dirs ) {
                    # Ignore irrelevant dirs.
                    next if $dirs[1] && $dirs[1] =~ /\A(?> inc | bin | script | eg | examples | share | x?t)\z/x;

                    my $fname = $dirs[-1];

                    if ( $fname eq 'typemap' || $fname =~ /\A[^.]+\.xs\z/ ) {
                        $files{xs} = true;

                        $self->_pdbg("found XS: $fname\n\n");
                        last;
                    }
                }
            }
        }
    }

    $self->_pdump( '%files', \%files, "\n" );

    return \%files;
}

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

App::cpan2arch::GetMetadata - get CPAN metadata from MetaCPAN's API

=head1 SYNOPSIS

  use App::cpan2arch;

  my $cpan2arch = App::cpan2arch->new;

  ...

=head1 DESCRIPTION

This role handles the fetching of module/distribution metadata from
L<MetaCPAN's|https://github.com/metacpan/metacpan-api> API.

=head1 METHODS

=head2 get_metadata

  $cpan2arch->get_metadata;

Takes no arguments and returns C<0> on success.

=head1 BUGS

Report bugs at L<https://github.com/ryoskzypu/App-cpan2arch/issues>.

=head1 AUTHOR

ryoskzypu <ryoskzypu@proton.me>

=head1 SEE ALSO

=over 4

=item *

L<https://blogs.perl.org/users/neilb/2016/12/working-with-the-metacpan-api.html>

=back

=head1 COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.

=cut
