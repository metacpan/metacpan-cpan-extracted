package Geo::Coordinates;

use strict;
use warnings;


our $VERSION = '0.01';

=head1 NAME

Geo::Coordinates - Basic class for geographical coordinates

=head1 SYNOPSIS

  use Geo::Coordinates;
  my $place = new Geo::Coordinates;
  $place->latitude(59.78);
  $place->longitude(10.12);

=head1 DESCRIPTION

B<IT IS A BAD IDEA TO USE THIS CLASS> in its present form! The Geo stuff is undergoing some elaborate revision, see http://wiki.bluedevbox.com/newgeo/new.htm
but there was some demand for L<Astro::SolarParallax>, so I needed to get it out the door. Anyway...:

This is a simple Object Oriented implementation of geographical coordinates, latitude and longitude. It is meant to be just a basic class, and won't do a lot on it's own. Basically, it is just a convenient container and abstraction layer. Hey, it's OO! 

=over

=item new()

The constructor of this class. Nothing special. 

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {
	       LAT  => undef,
	       LONG => undef,
	      };
  bless ($self, $class);
  return $self;
}


=item C<latitude()>

A method to set or retrieve the latitude. To set the latitude, supply a decimal degree argument. 

=cut

sub latitude {
  my $self = shift;
  if (@_) { $self->{LAT} = shift }
  return $self->{LAT};
}

=item C<longitude()>

As C<latitude()>, but instead sets or retrieves the longitude. 

=cut

sub longitude {
  my $self = shift;
  if (@_) { $self->{LONG} = shift }
  return $self->{LONG};
}

1;
__END__

=back

=head1 SEE ALSO

L<Geo::Distance>, L<Geo::Coordinates::DecimalDegrees>, L<Geo::Coordinates::UTM> and L<DateTime::Util::Astro::Common>, http://wiki.bluedevbox.com/newgeo/new.htm


=head1 BUGS/TODO

This could be a dead end, so it may not be a lot to do, and it is so simple there shouldn't be any bugs either... But, as previously said, B<don't use it>.


=head1 AUTHOR

Kjetil Kjernsmo, kjetilk@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Kjetil Kjernsmo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
