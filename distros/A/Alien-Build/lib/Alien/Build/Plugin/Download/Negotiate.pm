package Alien::Build::Plugin::Download::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
use Module::Load ();
use Carp ();

# ABSTRACT: Download negotiation plugin
our $VERSION = '1.10'; # VERSION


has '+url' => sub { Carp::croak "url is a required property" };


has 'filter'  => undef;


has 'version' => undef;


has 'ssl'     => 0;


has 'passive' => 0;

has 'scheme'  => undef;


sub pick
{
  my($self) = @_;
  
  $self->scheme(
    $self->url !~ m!(ftps?|https?|file):!i
      ? 'file'
      : $self->url =~ m!^([a-z]+):!i
  ) unless defined $self->scheme;
  
  if($self->scheme =~ /^https?$/)
  {
    return ('Fetch::HTTPTiny', 'Decode::HTML');
  }
  elsif($self->scheme eq 'ftp')
  {
    if($ENV{ftp_proxy} || $ENV{all_proxy})
    {
      return $self->scheme =~ /^ftps?/
        ? ('Fetch::LWP', 'Decode::DirListing', 'Decode::HTML')
        : ('Fetch::LWP', 'Decode::HTML');
    }
    else
    {
      return ('Fetch::NetFTP');
    }
  }
  elsif($self->scheme eq 'file')
  {
    return ('Fetch::Local');
  }
  else
  {
    die "do not know how to handle scheme @{[ $self->scheme ]} for @{[ $self->url ]}";
  }
}

sub init
{
  my($self, $meta) = @_;
  
  $meta->add_requires('share' => 'Alien::Build::Plugin::Download::Negotiate' => '0.61')
    if $self->passive;

  $meta->prop->{plugin_download_negotiate_default_url} = $self->url;

  my($fetch, @decoders) = $self->pick;
  
  $self->subplugin($fetch,
    url     => $self->url,
    ssl     => $self->ssl,
    ($fetch eq 'Fetch::NetFTP' ? (passive => $self->passive) : ()),
  )->init($meta);
  
  if($self->version)
  {
    $self->subplugin($_)->init($meta) for @decoders;
    $self->subplugin('Prefer::SortVersions', 
      (defined $self->filter ? (filter => $self->filter) : ()),
      version => $self->version,
    )->init($meta);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Download::Negotiate - Download negotiation plugin

=head1 VERSION

version 1.10

=head1 SYNOPSIS

 use alienfile;
 plugin 'Download' => (
   url => 'http://ftp.gnu.org/gnu/make',
   filter => qr/^make-.*\.tar.\gz$/,
   version => qr/([0-9\.]+)/,
 );

=head1 DESCRIPTION

This is a negotiator plugin for downloading packages from the internet.  This
plugin picks the best Fetch, Decode and Prefer plugins to do the actual work.
Which plugins are picked depend on the properties you specify, your platform
and environment.  It is usually preferable to use a negotiator plugin rather
than the Fetch, Decode and Prefer plugins directly from your L<alienfile>.

=head1 PROPERTIES

=head2 url

The Initial URL for your package.  This may be a directory listing (either in
HTML or ftp listing format) or the final tarball intended to be downloaded.

=head2 filter

This is a regular expression that lets you filter out files that you do not
want to consider downloading.  For example, if the directory listing contained
tarballs and readme files like this:

 foo-1.0.0.tar.gz
 foo-1.0.0.readme

You could specify a filter of C<qr/\.tar\.gz$/> to make sure only tarballs are
considered for download.

=head2 version

Regular expression to parse out the version from a filename.  The regular expression
should store the result in C<$1>.

=head2 ssl

If your initial URL does not need SSL, but you know ahead of time that a subsequent
request will need it (for example, if your directory listing is on C<http>, but includes
links to C<https> URLs), then you can set this property to true, and the appropriate
Perl SSL modules will be loaded.

=head2 passive

If using FTP, attempt a passive mode transfer first, before trying an active mode transfer.

=head1 METHODS

=head2 pick

 my($fetch, @decoders) = $plugin->pick;

Returns the fetch plugin and any optional decoders that should be used.

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey

Ilya Pavlov

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Zaki Mughal (zmughal)

mohawk (mohawk2, ETJ)

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Juan Julián Merelo Guervós (JJ)

Joel Berger (JBERGER)

Petr Pisar (ppisar)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
