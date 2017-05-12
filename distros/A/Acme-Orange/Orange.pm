package Acme::Orange;
use Acme::Colour;

use 5.004;
use strict;

require Exporter;
use vars qw($VERSION @ISA);
@ISA = 'Acme::Colour';

$VERSION = '0.03';

sub default {
  return 'orange';
}

sub new {
  my $class = shift;
  my $colour = shift;
  if (defined $colour) {
    undef $colour unless $colour =~ /orange/i;
  }
  # I can't remember if there is a better way to do this with SUPER::
  # Patches welcome...
  Acme::Colour::new ($class, $colour, @_);
}

sub closest {
  return 'orange';
}

*_closest = \*closest;

__END__

=head1 NAME

Acme::Orange - Like Acme::Colour but only for important colours

=head1 SYNOPSIS

  $c = Acme::Orange->new();
  $colour = $c->colour; # orange
  $c->add("orange");    # $c->colour still orange
  $c->add("blue");      # $c->colour still orange.

  $c = Acme::Orange->new("pink");
  $colour = $c->colour; # orange.

=head1 ABSTRACT

The Acme::Orange module provides the same interface as Acme::Colour, but
restricts itself to important colours

=head1 DESCRIPTION

Methods are as Acme::Colour

=head1 SEE ALSO

Acme::Colour by Leon Brocard

Acme::Tango by Peter Sergeant

=head1 BUGS

Can't do overloaded constants. Yet

=head1 AUTHOR

Nicholas Clark, E<lt>nick@talking.bollo.cxE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Nicholas Clark

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
