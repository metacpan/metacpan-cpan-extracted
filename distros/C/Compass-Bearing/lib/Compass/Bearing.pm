package Compass::Bearing;
use strict;
use warnings;
use base qw{Package::New};
use Geo::Functions qw{deg_rad round};

our $VERSION='0.07';

=head1 NAME

Compass::Bearing - Convert angle to text bearing (aka heading)

=head1 SYNOPSIS

  use Compass::Bearing;
  my $cb    = Compass::Bearing->new(3);
  my $angle = 12;
  printf "Bearing: %s deg => %s\n", $angle, $cb->bearing($angle); #prints NNE

=head1 DESCRIPTION

Convert angle to text bearing (aka heading)

=head1 CONSTRUCTOR

=head2 new

The new() constructor may be called with any parameter that is appropriate to the set method.

  my $obj = Compass::Bearing->new();

=head1 METHODS

=cut

sub initialize {
  my $self  = shift;
  my $param = shift || 3;
  $self->set($param);
}

=head2 bearing

Method returns a text string based on bearing

  my $bearing=$obj->bearing($degrees_from_north);

=cut

sub bearing {
  my $self  = shift;
  my $angle = shift || 0; #degrees
  $angle+=360 while ($angle < 0);
  my @data  = $self->data;
  return $data[round($angle/360 * @data) % @data];
}

=head2 bearing_rad

Method returns a text string based on bearing

  my $bearing=$obj->bearing_rad($radians_from_north);

=cut

sub bearing_rad {
  my $self=shift;
  my $angle=deg_rad(shift()||0); #degrees
  return $self->bearing($angle);
}

=head2 set

Method sets and returns key for the bearing text data structure.

  my $key=$self->set;
  my $key=$self->set(1);
  my $key=$self->set(2);
  my $key=$self->set(3); #default value

=cut

sub set {
  my $self=shift;
  my $param=shift;
  if (defined $param) {
    my %data=$self->_dataraw;
    my @keys=sort keys %data;
    if (exists $data{$param}) {
      $self->{'set'}=$param;
    } else {
      die(qq{Error: "$param" is not a valid parameter to the set method.  Try }. join(", ", map {qq{"$_"}} @keys). ".\n")
    }
  }
  return $self->{'set'};
}

=head2 data

Method returns an array of text values.

  my $data=$self->data;

=cut

sub data {
  my $self=shift;
  my $data=$self->_dataraw;
  my $return=$data->{$self->set};
  return wantarray ? @{$return} : $return;
}

sub _dataraw {
  my %data=(1=>[qw{N E S W}],
            2=>[qw{N NE E SE S SW W NW}],
            3=>[qw{N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW}]);
  return wantarray ? %data : \%data;
}

=head1 BUGS

Please send to the geo-perl email list.

=head1 AUTHOR

Michael R. Davis qw/perl michaelrdavis com/

=head1 LICENSE

Copyright (c) 2012 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
