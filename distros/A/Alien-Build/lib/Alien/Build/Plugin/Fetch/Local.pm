package Alien::Build::Plugin::Fetch::Local;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::chdir;
use Path::Tiny ();

# ABSTRACT: Local file plugin for fetching files
our $VERSION = '0.45'; # VERSION


has url => 'patch';


has root => undef;


has ssl => 0;

sub init
{
  my($self, $meta) = @_;
    
  if($self->url =~ /^file:/)
  {
    $meta->add_requires('share' => 'URI' => 0 );
    $meta->add_requires('share' => 'URI::file' => 0 );
  }

  {
    my $root = $self->root;
    if(defined $root)
    {
      $root = Path::Tiny->new($root)->absolute->stringify;
    }
    else
    {
      $root = "$CWD";
    }
    $self->root($root);
  }
  
  $meta->register_hook( fetch => sub {
    my(undef, $path) = @_;
    
    $path ||= $self->url;
    
    if($path =~ /^file:/)
    {
      my $root = URI::file->new($self->root);
      my $url = URI->new_abs($path, $root);
      $path = $url->path;
      $path =~ s{^/([a-z]:)}{$1}i if $^O eq 'MSWin32';
    }
    
    $path = Path::Tiny->new($path)->absolute($self->root);
    
    if(-d $path)
    {
      return {
        type => 'list',
        list => [
          map { { filename => $_->basename, url => $_->stringify } } 
          sort { $a->basename cmp $b->basename } $path->children,
        ],
      };
    }
    elsif(-f $path)
    {
      return {
        type     => 'file',
        filename => $path->basename,
        path     => $path->stringify,
      };
    }
    else
    {
      die "no such file or directory $path";
    }
    
    
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Fetch::Local - Local file plugin for fetching files

=head1 VERSION

version 0.45

=head1 SYNOPSIS

 use alienfile;
 plugin 'Fetch::Local' => (
   url => 'patch/libfoo-1.00.tar.gz',
 );

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This fetch plugin fetches files from the local file system.  It is mostly useful if you
intend to bundle packages with your Alien.

=head1 PROPERTIES

=head2 url

The initial URL to fetch.  This may be a C<file://> style URL, or just the path on the
local system.

=head2 root

The directory from which the URL should be relative.  The default is usually reasonable.

=head2 ssl

This property is for compatibility with other fetch plugins, but is not used.

=head1 SEE ALSO

L<Alien::Build::Plugin::Download::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
