package Astro::SolarParallax::Observer;

#use 5.008003;
use strict;
use warnings;
use Math::Trig;
use Time::Piece;
use Time::Seconds;

use Carp;

our $VERSION = '0.01';


=head1 NAME

Astro::SolarParallax::Observer - Class for observer data for Solar Parallax measurements

=head1 SYNOPSIS

  use Astro::SolarParallax::Observer;
  use Geo::Coordinates;
  my $obs1 = new Geo::Coordinates;
  $obs1->latitude(78.20); # Longyearbyen
  $obs1->longitude(15.82);
  my $observer1 = Astro::SolarParallax::Observer->new($obs1);
  # Longyearbyen
  $observer1->contacttime(1, "07:17:47");
  $observer1->contacttime(4, "13:21:00");

=head1 DESCRIPTION

This class is used to set and retrieve data about a single observer of a Transit of Venus. You may use it to set things like the observer's position on Earth and the observed contact times.


=head1 METHODS

=over

=item C<new($coords)>

This is the constructor of this class.

As you use it to create a new observer, you should set the coordinates of observers, by giving it a L<Geo::Coordinates> object. 


=cut

sub new {
    my ($that, $coords) = @_;
    my $class = ref($that) || $that;
    my $self = {
		COORDS => $coords,
		CONTACTS => []
    };
    bless($self, $class);
    return $self;
}


=item C<contacttime($number, [$time, [$format]])>

This method is used to set or retrieve the time of a contact.

The first parameter C<$number> is an integer representing the number of the contact point (first contact, second contact, etc). If only C<$number> is given, the method will return a L<Time::Piece> object with the contact time for this contact.

To set the time of a contact, supply a second parameter C<$time>. It may be a L<Time::Piece> object (preferred), or just a string. If it is a string, you may supply a third C<$format> parameter, which gives the time format of the string. The time format follows the C<strptime> of your Operating System. It defaults to C<%T>, for example "15:09:23". Internally, the time is represented by a L<Time::Piece> object.

If you do not supply a full date and timezone, just make sure you're using the same date and timezone. But then, you might want to supply it all, just to be sure...

=cut


sub contacttime {
  my ($self, $number, $time, $format) = @_;
  return ${$self}{'CONTACTS'}[$number] unless defined($time);
  if (ref($time) eq 'Time::Piece') {
    ${$self}{'CONTACTS'}[$number] = $time;
  } else {
    unless ($format) {
      $format = '%T';
    }
    ${$self}{'CONTACTS'}[$number] = Time::Piece->strptime($time, $format);
  }
  return $self;
}

=item C<deltatobs(@contacts)>

This computes the observed duration from a contact to the other for this observer, given the number of the contact in the array C<@contacts> as the parameter. In Mignard's paper, Eqs. (79) and (80) are examples of this.

In the present implementation, only two contacts can be used, and the array should be in ascending order. 

It will return a L<Time::Seconds> object.

=cut

sub deltatobs {
  my $self = shift;
  my @contacts = @_;
  unless ($#contacts == 1)
    {
      croak "Only exactly two contact points can be used now.";
    }
  return ${$self}{'CONTACTS'}[$contacts[1]] - ${$self}{'CONTACTS'}[$contacts[0]];
}

=item C<deltatref(@contacts)>

Identical to the C<deltatobs>, except it computes the reference duration. In Mignard's paper, Eqs. (76) and (77) are examples of this.

At present, only the combination of contacts 1 and 4, and 2 and 3 are supported.

The following note is of little interest to a user, but a programmer interested in the details of the implementation may note that the constants of Mignard's Table 10 are hardcoded in this method. This is slightly inelegant, and may change if the class is expanded to support more contacts.

=cut



sub deltatref {
  my $self = shift;
  my @contacts = @_;
  unless ($#contacts == 1)
    {
      croak "Only exactly two contact points can be used now.";
    }
  my ($deltatgeo, $A, $B, $C, $out);
  if (($contacts[0] == 1) && ($contacts[1] == 4)) {
      $deltatgeo = Time::Seconds->new(372.4 * 60);
      $A = Time::Seconds->new(-221.6);
      $B = Time::Seconds->new(-235.7);
      $C = Time::Seconds->new(-491.2);
  } elsif (($contacts[0] == 2) && ($contacts[1] == 3)) {
      $deltatgeo = Time::Seconds->new(333.85 * 60);
      $A = Time::Seconds->new(-200.9);
      $B = Time::Seconds->new(-167.4);
      $C = Time::Seconds->new(-548.2);
  } else {
      croak "Not implemented for the combination of contacts $contacts[0] and ($contacts[1] (in that order).";
  }
  return $deltatgeo + Time::Seconds->new($self->_deltat($A, $B, $C));
}

# Internal use only,  Mignard's Eq. (74):

sub _deltat
{
    my ($self, $A, $B, $C) = @_;
    return ($A * cos(deg2rad(${$self}{'COORDS'}->latitude)) 
	       * cos(deg2rad(${$self}{'COORDS'}->longitude))
	  + $B * cos(deg2rad(${$self}{'COORDS'}->latitude)) 
	       * sin(deg2rad(${$self}{'COORDS'}->longitude))
	  + $C * sin(deg2rad(${$self}{'COORDS'}->latitude)))
}


1;
__END__

=back

=head1 BUGS/TODO

This is the initial release. While it should be considered an alpha, the author do not expect any very substantial non-backwards compatible changes in the API of this class. The internals may, however, change significantly.

For now, it only supports the combination of two contact points, and only 1 and 4, and 2 and 3. I'm not sure it is meaningful to change this, but I'll give it a try if it is.

=head1 SEE ALSO

L<Astro::SolarParallax>, L<Time::Piece>, L<strptime>. For the meaning of "contact points", see http://www.astronomy.no/venus080604/contactpoints.html

=head1 REFERENCES 

F. Mignard: I<"The solar parallax with the transit of Venus">, version 3, 2004-02-26. http://www.obs-azur.fr/cerga/mignard/TRANSITS/venus_contact.pdf


=head1 AUTHOR

Kjetil Kjernsmo, kjetilk@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Kjetil Kjernsmo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
