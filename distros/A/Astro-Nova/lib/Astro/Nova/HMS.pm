package Astro::Nova::HMS;

use 5.008;
use strict;
use warnings;

use Astro::Nova;

# basic stuff is in Astro::Nova's XS!

sub members {
  return qw/hours minutes seconds/
}

sub as_ascii {
  my $self = shift;
  my $template = <<'HERE';
Hours:      %d
Minutes:    %d
Seconds:    %f
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

sub to_degrees {
  Astro::Nova::hms_to_deg(shift)
}

sub to_radians {
  Astro::Nova::hms_to_rad(shift)
}

sub to_dms {
  Astro::Nova::deg_to_dms(Astro::Nova::hms_to_deg(shift))
}

sub from_degrees {
  my $class = shift;
  my $obj = Astro::Nova::deg_to_hms(shift);
  return $obj if not ref $class;
  $class->set_all($obj->get_all());
  return $class;
}

sub from_radians {
  my $class = shift;
  my $obj = Astro::Nova::rad_to_hms(shift);
  return $obj if not ref $class;
  $class->set_all($obj->get_all());
  return $class;
}

sub from_dms {
  my $class = shift;
  my $obj = shift->to_hms();
  return $obj if not ref $class;
  $class->set_all($obj->get_all());
  return $class;
}


1;
__END__

=head1 NAME

Astro::Nova::HMS - Perl representation of a libnova ln_hms (hours, minutes, seconds)

=head1 SYNOPSIS

  use Astro::Nova qw(functions ...);
  my $date = Astro::Nova::HMS->new();
  $date->set_year(...);
  # ...
  print $date->as_ascii(), "\n";
  my @members = $date->get_all();

=head1 DESCRIPTION

This class represents a libnova C<ln_hms> struct. The struct has the following layout:

  ln_hms {
    unsigned short  hours
    unsigned short  minutes
    double          seconds
  }

=head1 METHODS

=head2 new

Constructor returns a new C<Astro::Nova::HMS>.
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

=head2 to_degrees / to_radians / to_dms

Convert to degrees or radians (returns a number).

C<to_dms> Converts to L<Astro::Nova::DMS> (degrees, minutes, seconds).

=head2 from_degrees / from_radians / from_dms

When called as a class method, creates a new C<Astro::Nova::HMS> object from the
given degrees/radians value or C<Astro::Nova::DMS> object.

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
