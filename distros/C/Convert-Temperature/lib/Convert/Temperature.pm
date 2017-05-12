package Convert::Temperature;

use strict;
use warnings;

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my $self= bless {},$class;

    return $self;
}

sub from_fahr_to_cel {
    my $self = shift;
    my $fahr = shift;

    $self->{'res_celsius'} = ($fahr -32) /1.8;

    return $self->{'res_celsius'};
}

sub from_cel_to_fahr {
    my $self = shift;
    my $cel = shift;

    $self->{'res_fahrenheit'} =  $cel * 1.8 + 32;

    return $self->{'res_fahrenheit'};
}

sub from_fahr_to_kelvin{
    my $self = shift;
    my $fahr = shift;

    $self->{'res_kelvin'} = ($fahr + 459.67) / 1.8;

    return $self->{'res_kelvin'};
}

sub from_kelvin_to_fahr {
    my $self = shift;
    my $kelvin = shift;

    $self->{'res_kelvin'} = $kelvin * 1.8 - 459.67;

    return $self->{'res_kelvin'};
}

sub from_fahr_to_rankine {
    my $self = shift;
    my $fahr = shift;

    $self->{'res_rankine'} = $fahr + 459.67;

    return $self->{'res_rankine'};
}

sub from_rankine_to_fahr {
    my $self = shift;
    my $rankine = shift;

    $self->{'res_rak_fahr'} = $rankine - 459.67;

    return $self->{'res_rak_fahr'};
}

sub from_fahr_to_reaumur {
    my $self = shift;
    my $fahr = shift;

    $self->{'res_fahr_reamur'} = ($fahr - 32) / 2.25;

    return  $self->{'res_fahr_reamur'};
}

sub from_reaumur_to_fahr {
    my $self = shift;
    my $reaumur = shift;

    $self->{'res_reaumur_fahr'} = $reaumur * 2.25 +32;

    return $self->{'res_reaumur_fahr'};
}

sub extra {
    my $self = shift;
    my $extra = "To my Mom. Maria Luisa Mesquista (1954 - 2007)";

    $self->{'extra'} = $extra;
    return $self->{'extra'};
}

1;

__END__


=head1 NAME

Convert::Temperature - Convert Temperatures

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

  use Convert::Temperature;
  
  my $c = new Convert::Temperature();

  my $res = $c->from_fahr_to_cel('59'); => result in Celsius
  ...

=head1 FUNCTIONS

=head2 new 

Creates a new Temperature::Convert object.

    my $c = new Convert::Temperature();

=head2 from_fahr_to_cel

Convert from Fahrenheit to Celsius

    my $res = $c->from_fahr_to_cel('59');

=head2 from_cel_to_fahr

Convert from Celsius to Fahrenheit

    my $res = $c->from_cel_to_fahr('31');

=head2 from_fahr_to_kelvin

Convert from Fahrenheit to Kelvin

    my $res = $c->from_fahr_to_kelvin('59');

=head2 from_kelvin_to_fahr

Convert from Kelvin to Fahrenheit

    my $res = $c->from_kelvin_to_fahr('215');

=head2 from_fahr_to_rankine

Convert from Fahrenheit to Rankine

    my $res = $c->from_fahr_to_rankine('59');

=head2 from_rankine_to_fahr

Convert from Rankine to Fahrenheit

    my $res = $c->from_rankine_to_fahr('518');

=head2 from_fahr_to_reaumur

Convert from Fahrenheit to Reaumur

    my $res = $c->from_fahr_to_reaumur('59');

=head2 from_reaumur_to_fahr

Convert from Reaumur to Fahrenheit

    my $res = $c->from_reaumur_to_fahr('12');

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Convert::Temperature

=head1 AUTHOR

Filipe Dutra, E<lt>mopy@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Filipe Dutra

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
