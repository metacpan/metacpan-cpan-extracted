package Astro::SolarParallax;

#use 5.008003;
use strict;
use warnings;
use Math::Trig;

our $VERSION = '0.04';


=head1 NAME

Astro::SolarParallax - Find the Solar Parallax from Venus Transit

=head1 SYNOPSIS

  use Astro::SolarParallax::Observer;
  use Astro::SolarParallax;
  use Geo::Coordinates;
  my $obs1 = new Geo::Coordinates;
  my $obs2 = new Geo::Coordinates;
  $obs1->latitude(78.20); # Longyearbyen
  $obs1->longitude(15.82);
  $obs2->latitude(13.7307); # Bangkok
  $obs2->longitude(100.521);
  my $observer1 = Astro::SolarParallax::Observer->new($obs1);
  my $observer2 = Astro::SolarParallax::Observer->new($obs2);
  # Longyearbyen
  $observer1->contacttime(1, "07:17:47");
  $observer1->contacttime(4, "13:21:00");
  # Bangkok
  $observer2->contacttime(1, "07:13:07");
  $observer2->contacttime(4, "13:20:36");
  my $measurement = Astro::SolarParallax->new($observer1, $observer2);
  print $measurement->AU(1,4);


=head1 DESCRIPTION

This module is intended to be used to compute the solar parallax from planetary transits. Specifically, in the current implementation, it makes use of a method developed by F. Mignard, and is limited to the transit of Venus on 2004-06-08.

It has a object oriented interface. 

=over

=item C<new($obs1, $obs2)>

This is the constructor of this class, it takes as argument two observers, that is, two objects of the L<Astro::SolarParallax::Observer> class.

=cut

sub new {
    my $that  = shift;
    my $obs1 = shift;
    my $obs2 = shift;
    my $class = ref($that) || $that;
    my $self = {
	OBS1 => $obs1,
	OBS2 => $obs2,
    };

    bless($self, $class);
    return $self;
}

=item C<AU(@contacts)>

This method will return the distance to the sun in kilometers, based on the measurements done by the two observers given to the constructor. It takes as argument and array containing the number of the contact points, in ascending order.

The constraints in the L<Astro::SolarParallax::Observer> apply.

=cut


sub AU {
    my $self = shift;
    my @contacts = @_;
    my $deltatref = ${$self}{'OBS2'}->deltatref(@contacts) 
                  - ${$self}{'OBS1'}->deltatref(@contacts);
    my $deltatobs = ${$self}{'OBS2'}->deltatobs(@contacts) 
                  - ${$self}{'OBS1'}->deltatobs(@contacts);
  return (149.60 * 1000000 * $deltatref->seconds / $deltatobs->seconds);
}


1;
__END__

=back

=head1 BUGS/TODO

This is the initial release. While it should be considered an alpha, the author do not expect any very substantial non-backwards compatible changes in the API of this class.

It has not been very thorougly tested in this release, specifically, it has not been compared to "known correct answers". It does, however, give answers of the right magnitude, and the intermediate numbers are identical to those of Mignard.

It is somewhat uncertain what happens if the observers come in an unanticipated order, whatever that means...

It currently supports only two observers, and there are many limitations on the data from these two observers. It should be possible to expand its scope, however.

=head1 SEE ALSO

L<Astro::SolarParallax::Observer>.

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


