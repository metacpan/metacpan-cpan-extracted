package Alien::Build::Plugin::Fetch::Rewrite;

use strict;
use warnings;
use 5.008001;
use URI;
use Alien::Build;
use Alien::Build::Plugin;
use Alien::Build::Plugin::Fetch::LWP;
use Alien::Build::Plugin::Decode::HTML;

# ABSTRACT: Alien::Build plugin to rewrite network requests to local resources
our $VERSION = '0.02'; # VERSION


sub init
{
  my($self, $meta) = @_;

  unless($meta->prop->{start_url})
  {
    Alien::Build->log("sorry! this plugin requires a default url to function");
    Alien::Build->log("no rewrites will be possible");
    return;
  }

  Alien::Build::Plugin::Fetch::LWP->new->init($meta);
  Alien::Build::Plugin::Decode::HTML->new->init($meta);

  $meta->around_hook(fetch => sub {
    my($f, $build, $url) = @_;

    $url ||= $build->meta_prop->{start_url};

    if(Alien::Build::rc->can('rewrite'))
    {
      my $orig = URI->new($url);
      my $copy = $orig->clone;
      Alien::Build::rc::rewrite($build, $copy);
      if("$copy" ne "$orig")
      {
        $build->log("rewriting $orig as $copy");
        $url = "$copy";
      }
    }
    
    return $f->($build, $url);
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Fetch::Rewrite - Alien::Build plugin to rewrite network requests to local resources

=head1 VERSION

version 0.02

=head1 SYNOPSIS

In your ~/.alienbuild/rc.pl:

 postload 'Fetch::Rewrite';
 
 sub rewrite {
   my($build, $uri) = @_;
   
   # $build isa Alien::Build
   # $uri isa URI
   
   if($uri->host eq 'ftp.gnu.org')
   {
     # if we see a request to ftp.gnu.org (either ftp or http)
     # we redirect it to the local mirror at
     # http://mirror.example.com/ftp.gnu.org
     $uri->scheme('http');
     $uri->host('mirror.example.com');
     $uri->host('/ftp.gnu.org' . $uri->path);
   }
 }
 
 1;

=head1 DESCRIPTION

This plugin allows you to rewrite the URLs for remote networked resources
to local resources.  This is useful if you are building CPAN modules that
rely on L<Alien> distributions where you do not have system packages.  It
may also seem useful if you do not trust the remote resources, although
please keep in mind that like a C<Makefile.PL> or C<Build.PL>, an L<alienfile>
is arbitrary Perl code, and should be appropriately vetted before being
used in an environment with security requirements.

=head1 CAVEATS

This plugin is only able to rewrite URLs that are fetched through the standard
L<Alien::Build> URL fetching interface, and only URLs that are supported by
L<LWP::UserAgent> and L<URI>.

=head1 SEE ALSO

=over 4

=item L<Alien::Build>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
