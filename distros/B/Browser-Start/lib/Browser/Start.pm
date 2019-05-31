package Browser::Start;

use strict;
use warnings;
use 5.008001;
use URI;
use URI::file;
use File::chdir;
use File::Which qw( which );
use base qw( Exporter );

our @EXPORT = qw( open_url );

# ABSTRACT: Open a URL in a web browser
our $VERSION = '0.01'; # VERSION


sub _url ($)
{
  URI->new_abs(shift, URI::file->new("$CWD"))->as_string;
}

sub open_url ($)
{
  my $url = _url shift;

  if($^O eq 'darwin')
  {
    if(-x "/usr/bin/open")
    {
      system '/usr/bin/open', $url;
      return;
    }
  }
  elsif($^O eq 'MSWin32')
  {
    system 'start', $url;
    return;
  }
  elsif($^O eq 'cygwin')
  {
    if(-x '/usr/bin/cygstart')
    {
      system '/usr/bin/cygstart', $url;
      return;
    }
  }
  elsif($^O =~ /^msys2?/)
  {
    # TODO
  }
  else
  {
    my $xdg_open = which('xdg-open');
    if($xdg_open)
    {
      system $xdg_open, $url;
      return;
    }
  }

  die "system not supported";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Browser::Start - Open a URL in a web browser

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Browser::Start;
 
 open_url 'http://metacpan.org';

=head1 DESCRIPTION

Simple interface for opening a URL in a browser appropriate for the system
and user configuration.

=head1 FUNCTIONS

=head2 open_url

 open_url $url;

Opens the given URL in a browser.  If this module doesn't know how to open
a URL in your configuration or if this module can determine that the
URL didn't open correctly then an exception will be thrown.

This function is fire-and-forget, that is it won't interrupt your script.
The browser should open the URL in a separate windows, or tab of an existing
window.

=head1 CAVEATS

There is a lot of variability in environments, so doing this correctly everywhere
is a huge challenge.  The distribution for this module will do what it can to fail
loudly when it knows it won't work, rather than silently fail, so you may at least
to some extent rely on this module if it installed correctly.

Some environments may be configured to use non-browsers for some URL times.  An
FTP or sftp URL might open in some sort of file transfer client.

=head1 SEE ALSO

=over 4

=item L<Browser::Open>

This module provides a similar functionality.

It doesn't support some platforms like OpenBSD and NetBSD which honestly should be
treated similar to Linux and FreeBSD.

It is more aggressive than I think it should be about choosing specific browsers
that may or may not have been configured by users or normal system defaults.

It may open URLs using console browsers like C<lynx> which can muck up your Perl
script.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
