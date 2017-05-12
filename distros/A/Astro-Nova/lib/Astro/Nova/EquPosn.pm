package Astro::Nova::EquPosn;

use 5.008;
use strict;
use warnings;

use Astro::Nova;

# basic stuff is in Astro::Nova's XS!

sub members {
  return qw/ra dec/;
}

sub as_ascii {
  my $self = shift;
  my $template = <<'HERE';
Right Ascension:  %f
Declination:      %f
HERE
  return sprintf($template, $self->get_all());
}

sub get_all {
  my $self = shift;
  return(map $self->$_(), map "get_$_", $self->members());
}

sub set_all {
  my $self = shift;
  foreach my $member (map "set_$_", $self->members) {
    last if not @_;
    my $value = shift @_;
    next if not defined $value;
    $self->$member($value);
  }
  return 1;
}

sub from_galactic_B1950 {
  my $class = shift;
  my $obj = shift->to_equatorial_B1950();
  return $obj if not ref $class;
  $class->set_all($obj->get_all());
  return $class;
}

sub from_galactic_J2000 {
  my $class = shift;
  my $obj = shift->to_equatorial_J2000();
  return $obj if not ref $class;
  $class->set_all($obj->get_all());
  return $class;
}

sub to_galactic_B1950 {
  return Astro::Nova::get_gal_from_equ(shift);
}

sub to_galactic_J2000 {
  return Astro::Nova::get_gal_from_equ2000(shift);
}


1;
__END__

=head1 NAME

Astro::Nova::EquPosn - Perl representation of a libnova ln_equ_posn

=head1 SYNOPSIS

  use Astro::Nova qw(functions ...);
  my $date = Astro::Nova::EquPosn->new();
  $date->set_year(...);
  # ...
  print $date->as_ascii(), "\n";
  my @members = $date->get_all();

=head1 DESCRIPTION

This class represents a libnova C<ln_equ_posn> struct. The struct has the following layout:

  ln_equ_posn {
    double  ra  # right ascension
    double  dec # declination
  }

=head1 METHODS

=head2 new

Constructor returns a new C<Astro::Nova::EquPosn>.
Optionally takes key/value pairs for setting the struct members.
Extra arguments are ignored. Uninitialized struct members are set to zero.

=head2 get_... / set_...

Get or set any of the class attributes. (See list above)

=head2 get_all

Returns all members as a list.

=head2 set_all

Sets all members. Takes a list of values which must be in the order shown above.
Any missing values are ignored, undefs are skipped.

=head2 as_ascii

Returns a human-readable ASCII table of the date information.

=head2 members

Returns a list of all members in order.

=head2 to_galactic_B1950 / to_galactic_J2000

Convert to galactic coordinates with respect to the B1950 or J2000
epochs (returns an L<Astro::Nova::GalPosn> object).

=head2 from_galactic_B1950 / from_galactic_J2000

When called as a class method, creates a new C<Astro::Nova::EquPosn> object from the
given C<Astro::Nova::GalPosn> object. Uses the B1950/J2000 epochs according to
the method name.

When called as an object method, sets the current object's state instead.

=head1 SEE ALSO

L<Astro::Nova>

libnova website: L<http://libnova.sourceforge.net/>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The Astro::Nova wrapper of libnova is copyright (C) 2009-2010 by Steffen Mueller.

The wrapper code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

libnova is maintained by Liam Girdwood and Petr Kubanek.

libnova is released under the GNU LGPL. This may limit the licensing
terms of the wrapper code. If in doubt, ask a lawyer.

=cut
