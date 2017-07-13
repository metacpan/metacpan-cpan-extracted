package Alien::Build::Plugin::Fetch::Cache;

use strict;
use warnings;
use 5.010;
use Alien::Build::Plugin;
use File::HomeDir 1.00;
use URI 1.71;
use Path::Tiny 0.100 ();
use Sereal 3.015 qw( encode_sereal decode_sereal );
use Digest::MD5;

# ABSTRACT: Alien::Build plugin to cache files downloaded from the internet
our $VERSION = '0.02'; # VERSION


sub _local_file
{
  my($uri) = @_;

  Path::Tiny
    ->new(File::HomeDir->my_home)
    ->child('.alienbuild/plugin_fetch_cache')
    ->child($uri->scheme)
    ->child($uri->host)
    ->child($uri->path)
    ->child('meta');
}

sub init
{
  my($self, $meta) = @_;
  
  $meta->around_hook(
    fetch => sub {
      my($orig, $build, $url) = @_;
      my $local_file;
      
      my $cache_url = $url // $build->meta_prop->{plugin_download_negotiate_default_url};
      
      if($cache_url && $cache_url !~ m!^/!  && $cache_url !~ m!^file:!)
      {
        my $uri = URI->new($cache_url);
        $local_file = _local_file($uri);
        if(-r $local_file)
        {
          $build->log("using cached response for $uri");
          return decode_sereal($local_file->slurp_raw);
        }
      }
      my $res = $orig->($build, $url);
      
      if(defined $local_file)
      {
        $local_file->parent->mkpath;
        if($res->{type} eq 'file')
        {
          my $md5 = Digest::MD5->new;
          
          if($res->{content})
          {
            $md5->add($res->{content});
          }
          else
          {
            open my $fh, '<', $res->{path};
            $md5->addfile($fh);
            close $fh;
          }
          
          my $data = Path::Tiny->new(File::HomeDir->my_home)
                     ->child('.alienbuild/plugin_fetch_cache/payload')
                     ->child($md5->hexdigest)
                     ->child($res->{filename});
          $data->parent->mkpath;

          my $res2 = {
            type     => 'file',
            filename => $res->{filename},
            path     => $data->stringify,
          };
          if($res->{content})
          {
            $data->spew_raw($res->{content});
          }
          elsif($res->{path})
          {
            Path::Tiny->new($res->{path})->copy($data);
          }
          else
          {
            die "got a file without contant or path";
          }
          $local_file->spew_raw( encode_sereal $res2 );
        }
        elsif($res->{type} =~ /^(list|html|dir_listing)$/)
        {
          $local_file->spew_raw( encode_sereal $res );
        }
      }
      
      $res;
    }
  );

  if($ENV{ALIEN_BUILD_PLUGIN_FETCH_CACHE_PRECACHE})
  {
    $meta->around_hook(
      prefer => sub {
        my($orig, $build, @rest) = @_;
        my $ret = $orig->($build, @rest);
      
        if($ret->{type} eq 'list')
        {
          foreach my $file (@{ $ret->{list} })
          {
            my $url = $file->{url};
            if($url && $url !~ m!^/!  && $url !~ m!^file:!)
            {
              my $local_file = _local_file(URI->new($url));
              next if -f $local_file;
              $build->log("precacheing $url");
              $build->fetch($url);
            }
          }
        }
        $ret;
      },
    );
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Fetch::Cache - Alien::Build plugin to cache files downloaded from the internet

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 export ALIEN_BUILD_PRELOAD=Fetch::Cache

=head1 DESCRIPTION

This is a L<Alien::Build> plugin that caches the files that you download from
the internet, so that you only have to download them once.  Handy when doing
development of an L<Alien> distribution.  Not a particularly smart cache.
Doesn't ignore or expire old entries.  You have to remove them yourself.
They are stored in C<~/.alienbuild/plugin_fetch_cache>.

=head1 CAVEATS

As mentioned, not a sophisticated cache.  Patches welcome to make it smarter.
There are probably lots of corner cases that this plugin doesn't take into
account, but it is probably good enough for most Alien usage.

=head1 ENVIRONMENT

=over 4

=item ALIEN_BUILD_PLUGIN_FETCH_CACHE_PRECACHE

If set to a true value, then this plugin will precache all files that match the appropriate pattern in the L<alienfile>.

This can be helpful if you are developing a prefer plugin or filter and will be off-line for the development.

Be careful, if no pattern is specified you could end up downloading the entire internet!

=back

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Base>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
