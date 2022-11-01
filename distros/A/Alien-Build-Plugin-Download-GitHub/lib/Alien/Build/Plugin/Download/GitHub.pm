package Alien::Build::Plugin::Download::GitHub;

use strict;
use warnings;
use 5.008001;
use Carp qw( croak );
use Path::Tiny qw( path );
use JSON::PP qw( decode_json );
use URI;
use Alien::Build::Plugin;
use Alien::Build::Plugin::Download::Negotiate;
use Alien::Build::Plugin::Extract::Negotiate;

# ABSTRACT: Alien::Build plugin to download from GitHub
our $VERSION = '0.10'; # VERSION


has github_user => sub { croak("github_user is required") };
has github_repo => sub { croak("github_repo is required") };
has include_assets => 0;
has version => qr/^v?(.*)$/;
has prefer => 0;
has tags_only => 0;


has asset => 0;
has asset_name => qr/\.tar\.gz$/;
has asset_format => 'tar.gz';
has asset_convert_version => 0;

my $once = 1;

sub init
{
  my($self, $meta) = @_;

  croak("Don't set set a start_url with the Download::GitHub plugin") if defined $meta->prop->{start_url};
  croak("cannot use both asset and tag_only") if $self->asset && $self->tags_only;

  if($self->asset)
  {
    $meta->add_requires('configure' => 'Alien::Build::Plugin::Download::GitHub' => '0.09' );
  }
  else
  {
    $meta->add_requires('configure' => 'Alien::Build::Plugin::Download::GitHub' => 0 );
  }

  my $endpoint = $self->tags_only ? 'tags' : 'releases' ;
  $meta->prop->{start_url} ||= "https://api.github.com/repos/@{[ $self->github_user ]}/@{[ $self->github_repo ]}/$endpoint";

  $meta->apply_plugin('Download',
    prefer  => $self->prefer,
    version => $self->version,
  );

  if($self->asset_format ne 'none')
  {
    if($self->asset && $self->asset_format)
    {
      $meta->apply_plugin('Extract',
        format  => $self->asset_format,
      )
    }
    else
    {
      $meta->apply_plugin('Extract',
        format  => 'tar.gz',
      );
    }
  }

  my %gh_fetch_options;
  my $secret;

  foreach my $name (qw( ALIEN_BUILD_GITHUB_TOKEN GITHUB_TOKEN GITHUB_PAT ))
  {
    if(defined $ENV{$name})
    {
      $secret = $ENV{$name};
      push @{ $gh_fetch_options{http_headers} }, Authorization => "token $secret";
      Alien::Build->log("using the GitHub Personal Access Token in $name") if $once;
      $once = 0;
      last;
    }
  }

  $meta->around_hook(
    fetch => sub {
      my $orig = shift;
      my($build, $url, @the_rest) = @_;

      # only do special stuff when talking to GitHub API.  In particular, this
      # avoids leaking the PAT (if specified) to other servers.
      return $orig->($build, $url, @the_rest)
        unless do {
          my $uri = URI->new($url || $build->meta_prop->{start_url});
          $uri->host eq 'api.github.com' && $uri->scheme eq 'https';
        };

      # Temporarily patch the log method so that we don't log the PAT
      my $log = \&Alien::Build::log;
      no warnings 'redefine';
      local *Alien::Build::log = sub {
        if(defined $secret)
        {
          $_[1] =~ s/\Q$secret\E/ '#' x length($secret) /eg;
        }
        goto &$log;
      };
      use warnings;

      my $res = $orig->($build, $url, @the_rest, %gh_fetch_options);
      if($res->{type} eq 'file' && $res->{filename} =~ qr{^(?:releases|tags)$})
      {
        my $rel;
        if($res->{content})
        {
          $rel = decode_json $res->{content};
        }
        elsif($res->{path})
        {
          $rel = decode_json path($res->{path})->slurp_raw;
        }
        else
        {
          croak("malformed response object: no content or path");
        }
        my $version_key = $res->{filename} eq 'releases' ? 'tag_name' : 'name';

        if($ENV{ALIEN_BUILD_PLUGIN_DOWNLOAD_GITHUB_DEBUG})
        {
          require YAML;
          my $url = $url || $meta->prop->{start_url};
          $url = URI->new($url);
          $build->log(YAML::Dump({
            url => $url->path,
            res => $rel,
          }));
        }

        my $res2;

        if($self->asset)
        {
          $res2 = {
            type => 'list',
            list => [],
          };

          foreach my $release (@$rel)
          {
            foreach my $asset (@{ $release->{assets} })
            {
              if($asset->{name} =~ $self->asset_name)
              {
                push @{ $res2->{list} }, {
                  filename => $asset->{name},
                  url      => $asset->{browser_download_url},
                  version  => $self->asset_convert_version ? $self->asset_convert_version->($release->{name}) : $release->{name},
                };
              }
            }
          }
        }
        else
        {
          $res2 = {
            type     => 'list',
            list     => [
              map {
                my $release = $_;
                my($version) = $release->{$version_key} =~ $self->version;
                my @results = ({
                  filename => $release->{$version_key},
                  url      => $release->{tarball_url},
                  defined $version ? (version  => $version) : (),
                });

                if (my $include = $self->include_assets) {
                  my $filter = ref($include) eq 'Regexp' ? 1 : 0;
                  for my $asset(@{$release->{assets} || []}) {
                    push @results, {
                      asset_url => $asset->{url},
                      filename  => $asset->{name},
                      url       => $asset->{browser_download_url},
                      defined $version ? (version  => $version) : (),
                    } if (0 == $filter or $asset->{name} =~ $include);
                  }
                }
                @results;
              } @$rel
            ],
          };
        }

        if($ENV{ALIEN_BUILD_PLUGIN_DOWNLOAD_GITHUB_DEBUG})
        {
          require YAML;
          $build->log(YAML::Dump({
            res2 => $res2,
          }));
        }

        $res2->{protocol} = $res->{protocol} if exists $res->{protocol};
        return $res2;
      }
      else
      {
        return $res;
      }
    },
  );

  unless($self->prefer)
  {
    $meta->default_hook(
      prefer => sub {
        my($build, $res) = @_;
        $res;
      },
    );
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Download::GitHub - Alien::Build plugin to download from GitHub

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use alienfile;

 ...

 share {
 
   plugin 'Download::GitHub' => (
     github_user => 'PerlAlien',
     github_repo => 'dontpanic',
   );
 
 };

=head1 DESCRIPTION

This plugin will download releases from GitHub.  It is generally preferred over
L<Alien::Build::Plugin::Download::Git> for packages that are released on GitHub,
as it has much fewer dependencies and is more reliable.

=head1 PROPERTIES

=head2 github_user

The GitHub user or org that owns the repository.  This property is required.

=head2 github_repo

The GitHub repository name.  This property is required.

=head2 include_assets

[deprecated: use the asset* properties instead]

Defaulting to false, this option designates whether to include the assets of
releases in the list of candidates for download. This should be one of three
types of values:

=over 4

=item true value

The full list of assets will be included in the list of candidates.

=item false value

No assets will be included in the list of candidates.

=item regular expression

If a regular expression is provided, this will include assets that match by
name.

=back

=head2 tags_only

Boolean value for those repositories that do not upgrade their tags to releases.
There are two different endpoints. One for
L<releases|https://developer.github.com/v3/repos/releases/#list-releases-for-a-repository>
and one for simple L<tags|https://developer.github.com/v3/repos/#list-tags>. The
default is to interrogate the former for downloads. Passing a true value for
L</"tags_only"> interrogates the latter for downloads.

=head2 version

Regular expression that can be used to extract a version from a GitHub tag.  The
default ( C<qr/^v?(.*)$/> ) is reasonable for many GitHub repositories.

=head2 prefer

How to sort candidates for selection.  This should be one of three types of values:

=over 4

=item code reference

This will be used as the prefer hook.

=item true value (not code reference)

Use L<Alien::Build::Plugin::Prefer::SortVersions>.

=item false value

Don't set any preference at all.  The order returned from GitHub will be used if
no other prefer plugins are specified.  This may be reasonable for at least some
GitHub repositories.  This is the default.

=back

=head2 asset

Download from assets instead of via tag.  This option is incompatible with
C<tags_only>.

=head2 asset_name

Regular expression which the asset name should match.  The default is C<qr/\.tar\.gz$/>.

=head2 asset_format

The format of the asset.  This is passed to L<Alien::Build::Plugin::Extract::Negotiate>
so any format supported by that is valid.

[version 0.10]

If this is set to C<none> then no extractor will be added.  This allows for you to write
your own extractor code, or use a non-standard one.

=head2 asset_convert_version

This is an optional code reference which can be used to modify the version.  For example,
if the release version is prefixed with a C<v> You could do this:

 plugin 'Download::GitHub' => (
   github_user => 'PerlAlien',
   github_repo => 'dontpanic',
   asset => 1,
   asset_convert_version => sub {
     my $version = shift;
     $version =~ s/^v//;
     $version;
   },
 );

=head1 ENVIRONMENT

=over 4

=item ALIEN_BUILD_GITHUB_TOKEN GITHUB_TOKEN GITHUB_PAT

If one of these environment variables are set, then the GitHub API Personal
Access Token (PAT) will be used when connecting to the GitHub API.

For security reasons, the PAT will be removed from the log.  Some Fetch plugins
(for example the C<curl> plugin) will log HTTP requests headers so this will
make sure that your PAT is not displayed in the log.

=item ALIEN_BUILD_PLUGIN_DOWNLOAD_GITHUB_DEBUG

Setting this to a true value will send additional diagnostics to the log during
the indexing phase of the fetch.

=back

=head1 CAVEATS

This plugin does not support, and will not work if C<ALIEN_DOWNLOAD_RULE> is set to
either C<digest_and_encrypt> or C<digest>.

The GitHub API is rate limited.  Once you've reach that limit, this plugin will be 
inoperative for a period of time until the limits reset.  When using the GitHub
API unauthenticated the limit is especially low.  This is usually not a problem when
used in production where you only need to use the API once for each L<Alien>, but
it can become a problem when testing an L<Alien> that uses this plugin in CI or via
cpantesters.  In this situation you can set the C<ALIEN_BUILD_GITHUB_TOKEN> environment
variable (or commonly used but unofficial C<GITHUB_TOKEN> or C<GITHUB_PAT>), and this
plugin will use that in making API requests.  If you are using GitHub Actions for CI,
then you can use the C<secrets.GITHUB_TOKEN> macro to get a PAT.

If you do this it is recommended that you make some precautions where possible:

=over 4

=item Limit permissions

Create a PAT with the bare minimum access permissions.  Consider creating a
separate GitHub account without access to anything, and use it to generate the PAT.

=item Limit scope of usage

The PAT is only needed (if it is needed at all) during the build stage
of a share install.  If you are doing this in GitHub Actions you can
just set the environment variable for that stage:

 perl Makefile.PL
 env ALIEN_BUILD_GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }} make
 make test

Or if you are using L<Dist::Zilla>

 dzil listdeps --missing | cpanm -n
 env ALIEN_BUILD_GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }} dzil test

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Roy Storey (KIWIROY)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
