use strict;
use warnings;
package Data::GUID::URLSafe;
{
  $Data::GUID::URLSafe::VERSION = '0.006';
}
# ABSTRACT: url-safe base64-encoded GUIDs


use Data::GUID ();
use Sub::Exporter -setup => {
  into    => 'Data::GUID',
  exports => [ qw(as_base64_urlsafe from_base64_urlsafe) ],
  groups  => [ default => [ -all ] ],
};


sub as_base64_urlsafe {
  my ($self) = @_;
  my $base64 = $self->as_base64;
  $base64 =~ tr{+/=}{-_}d;

  return $base64;
}


sub from_base64_urlsafe {
  my ($self, $string) = @_;

  # +/ should not be handled, so convert them to invalid chars
  # also, remove spaces (\t..\r and SP) so as to calc padding len
  $string =~ tr{-_\t-\x0d }{+/}d;
  if (my $mod4 = length($string) % 4) {
    $string .= substr('====', $mod4);
  }

  return $self->from_base64($string);
}

1;

__END__

=pod

=head1 NAME

Data::GUID::URLSafe - url-safe base64-encoded GUIDs

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Data::GUID::URLSafe;

  my $guid = Data::GUID->new;

  my $string = $guid->as_base64_urlsafe;

  my $same_guid = Data::GUID->from_base64_urlsafe;

This module provides methods for L<Data::GUID|Data::GUID> that provide for
URL-safe base64 encoded GUIDs, as described by
L<MIME::Base64::URLSafe|MIME::Base64::URLSafe>.

These strings are also safer for email addresses.  While the forward slash is
legal in email addresses, some broken email address validators reject it.
(Also, without the trailing equals signs, these strings will be shorter.)

When Data::GUID::URLSafe is C<use>'d, it installs methods into Data::GUID using
L<Sub::Exporter|Sub::Exporter>.

=head1 METHODS

=head2 as_base64_urlsafe

  my $string = $guid->as_base64_urlsafe;

This method returns the URL-safe base64 encoded representation of the GUID.

=head2 from_base64_urlsafe

  my $guid = Data::GUID->from_base64_urlsafe($string);

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
