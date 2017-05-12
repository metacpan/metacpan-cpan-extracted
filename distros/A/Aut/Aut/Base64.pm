package Aut::Base64;

# $Id: Base64.pm,v 1.2 2004/04/08 16:55:13 cvs Exp $

use strict;
use MIME::Base64;

sub new {
  my $class=shift;
  my $self;

  $self->{"base64"}=1;
  bless $self,$class;

return $self;
}

sub encode {
  my $self=shift;
  my $text=shift;
  $text=encode_base64($text);
  chomp $text;
return $text;
}

sub decode {
  my $self=shift;
  my $text=shift;
return decode_base64($text);
}

1;
__END__

=pod

=head1 NAME

Aut::Base64 -- Base64 encoding/decoding for Aut.

=head1 ABSTRACT

This module encapsulates MIME::Base64. It sees to it that encoded strings
that terminate with a newline ('\n') are chomped. This has been done to
facilitate Aut Backends that loose trailing newlines (like L<Config::Inifiles|Config::IniFiles>).

If trailing newlines (whitespace) is lost, hashing algorithms start to behave
different for strings that appear the same. 

=head1 DESCRIPTION

=head2 C<new() --E<gt> Aut::Base64>

=over 1

Instantiates a new Aut::Base64 object.

=back

=head2 C<encode(text) --E<gt> base64 string>

=over 1

Encodes text into a base64 string using MIME::Base64's C<encode_base64()> 
function and chomps it.

=back

=head2 C<decode(base64 string)) --E<gt> string>

=over 1

Decodes base64 text using MIME::Base64's C<decode_base64()>.

=back

=head1 AUTHOR

Hans Oesterholt-Dijkema E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

(c)2004 Hans Oesterholt-Dijkema, This module is distributed
under Artistic license.

=cut

