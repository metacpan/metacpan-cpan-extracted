#
# Copyright (c) 2011-2015 T.v.Dein <tlinden |AT| cpan.org>.
#
# Licensed under the terms of the Artistic License 2.0
# see: http://www.perlfoundation.org/artistic_license_2_0
#
# helper class to provide SHA-256 to HMAC class

package Crypt::PWSafe3::SHA256;

$Crypt::PWSafe3::SHA256::VERSION = '1.03';

use Digest::SHA;

sub new {
  my($this) = @_;
  my $class = ref($this) || $this;
  my $self = { };
  bless($self, $class);
  my $sha = Digest::SHA->new('SHA-256');
  return $sha;
}

=head1 NAME

Crypt::PWSafe3::SHA256 - HMAC Helper Class

=head1 DESCRIPTION

This is a small helper class used to work with
SHA256 in Digest::HMAC module. This is because the
Digest::HMAC module requires a module as parameter
for the algorithm but Digest::SHA256 doesn't exist
as a module.

This module here is just a wrapper, it doesn't return
an instance of its own but an instance of Digest::SHA('SHA-256')
instead.

=head1 AUTHOR

T.v.Dein <tlinden@cpan.org>

=head1 SEE ALSO

L<Crypt::PWSafe3>
L<Digest::SHA>
L<Digest::HMAC>

=head1 COPYRIGHT

Copyright (c) 2011-2015 by T.v.Dein <tlinden@cpan.org>.

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms of the Artistic
License 2.0, see: L<http://www.perlfoundation.org/artistic_license_2_0>

=cut




1;
