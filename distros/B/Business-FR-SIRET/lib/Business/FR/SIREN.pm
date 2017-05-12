package Business::FR::SIREN;

use strict;
use warnings;
use Algorithm::LUHN;
use base qw(Business::FR::SIRET);
our $VERSION = '0.01';

1;

__END__

=head1 NAME

Business::FR::SIREN - Verify French Companies SIREN

=head1 SYNOPSIS

  use Business::FR::SIREN;
  $c = Business::FR::SIREN->new('000111222');
  print $c->siren()." looks good\n" if $c->is_valid();

  $c = Business::FR::SIRET->new();
  $c->siren('000111222');
  print "looks good\n" if $c->is_valid();

  print "looks good\n" if $c->is_valid('000111222');

=head1 DESCRIPTION

This module verifies SIRENs, which are french companies identification.
This module cannot tell if a SIREN references a real company, but it 
can tell you if the given SIREN is properly formatted.

See Business::FR::SIRET for more documentation.

=head1 COPYRIGHT

Copyright 2004

Fabien Potencier, fabpot@cpan.org

This software may be freely copied and distributed under the same
terms and conditions as Perl.

=head1 SEE ALSO

perl(1), Business::FR::SIRET.

=cut
