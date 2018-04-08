package Astro::Units;

use strict;
use warnings;

use Carp;

use bignum;
use Math::BigFloat;

Math::BigFloat->config({
    div_scale => 0,
    accuracy => undef,
});

our $VERSION = '1.10';
use constant {
    ONE_LIGHT_YEAR   => Math::BigFloat->new('9_460_730_472_580.8'),
    ONE_LIGHT_WEEK   => Math::BigFloat->new('181_314_478_598.399_9'),
    ONE_LIGHT_DAY    => Math::BigFloat->new('25_902_068_371.199_997'),
    ONE_LIGHT_HOUR   => Math::BigFloat->new('1_079_252_848.8'),
    ONE_LIGHT_MINUTE => Math::BigFloat->new('17_987_547.48'),
    ONE_LIGHT_SECOND => Math::BigFloat->new('299_792.458'),
    ONE_AU           => Math::BigFloat->new('149_597_870.7'),
    ONE_PARSEC       => Math::BigFloat->new('30_856_775_814_914.218_05'),
    ONE_MILE         => Math::BigFloat->new('1.609_344'),
};

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};
    if (exists $args{unit} && defined $args{unit}) {
        my $u = lc (substr($args{unit},0,1) );
        croak("Invalid unit use Either (Miles or Kilometers) or (mi or km) Default is Kilometers\n")
        unless ( $u =~ /^(m|k)/i);
       $self->{unit} = $u;
    } else {
        $self->{unit} = 'k';
    }
    return bless($self, $class);
}

sub _clean  {
    my $raw_string = shift;
    $raw_string =~ s/([a-zA-Z\s_,\s])//g;
    return $raw_string;
}

#atrological units to km/mi
sub get_astronomical_units { return _calculate(@_, ONE_AU) }

sub get_light_years { return _calculate( @_, ONE_LIGHT_YEAR) }

sub get_light_week { return _calculate( @_, ONE_LIGHT_WEEK) }

sub get_light_days { return _calculate( @_, ONE_LIGHT_DAY) }

sub get_light_hours { return _calculate( @_, ONE_LIGHT_HOUR) }

sub get_light_minutes { return _calculate( @_, ONE_LIGHT_MINUTE)}

sub get_light_seconds { return _calculate( @_, ONE_LIGHT_SECOND) }

sub get_light_parsecs { return _calculate( @_, ONE_PARSEC) }

#reverse function km/mi to astro
sub convert_to_astronomical_units { return _reverse_calculate(@_, ONE_AU) }

sub convert_to_light_years { return _reverse_calculate( @_, ONE_LIGHT_YEAR) }

sub convert_to_light_weeks { return _reverse_calculate( @_, ONE_LIGHT_WEEK) }

sub convert_to_light_days { return _reverse_calculate( @_, ONE_LIGHT_DAY) }

sub convert_to_light_hours { return _reverse_calculate( @_, ONE_LIGHT_HOUR) }

sub convert_to_light_minutes { return _reverse_calculate( @_, ONE_LIGHT_MINUTE)}

sub convert_to_light_seconds { return _reverse_calculate( @_, ONE_LIGHT_SECOND) }

sub convert_to_light_parsec { return _reverse_calculate( @_, ONE_PARSEC) }

#Asu to light units miles/kilometers not applicable

sub au_to_light_years { return _au_to_light(@_, ONE_LIGHT_YEAR) }

sub au_to_light_weeks { return _au_to_light( @_, ONE_LIGHT_WEEK) }

sub au_to_light_days { return _au_to_light( @_, ONE_LIGHT_DAY) }

sub au_to_light_hours { return _au_to_light( @_, ONE_LIGHT_HOUR) }

sub au_to_light_minutes { return _au_to_light( @_, ONE_LIGHT_MINUTE) }

sub au_to_light_seconds { return _au_to_light( @_, ONE_LIGHT_SECOND)}

sub au_to_light_parsecs { return _au_to_light( @_, ONE_PARSEC) }

#light units to astronomical units miles/kilometers not applicable

sub light_years_to_au { return _light_to_au(@_, ONE_LIGHT_YEAR) }

sub light_weeks_to_au { return _light_to_au( @_, ONE_LIGHT_WEEK) }

sub light_days_to_au { return _light_to_au( @_, ONE_LIGHT_DAY) }

sub light_hours_to_au { return _light_to_au( @_, ONE_LIGHT_HOUR) }

sub light_minutes_to_au { return _light_to_au( @_, ONE_LIGHT_MINUTE) }

sub light_seconds_to_au { return _light_to_au( @_, ONE_LIGHT_SECOND)}

sub light_parsecs_to_au { return _light_to_au( @_, ONE_PARSEC) }

sub _calculate {
    my ($self,$raw_inp,$multiplier) = @_;
    my $inp = Math::BigFloat->new(_clean($raw_inp));
    my $res = $inp->bmul($multiplier);
    return $self->{unit} eq 'm' ? $res->bdiv(ONE_MILE) : $res;
}

sub _reverse_calculate {
    my ($self,$raw_inp,$divisor) = @_;
    my $inp = Math::BigFloat->new(_clean($raw_inp));
    $inp = $inp->bmul(ONE_MILE) if ($self->{unit} eq 'm');
    my $res = $inp->bdiv($divisor);
    return $res;
}

sub _au_to_light {
    my ($self,$raw_inp,$divisor) = @_;
    my $inp = Math::BigFloat->new(_clean($raw_inp));
    my $au_km = $inp->bmul(ONE_AU);
    my $res = $au_km->bdiv($divisor);
    return $res;
}

sub _light_to_au {
    my ($self,$raw_inp,$multiplier) = @_;
    my $inp = Math::BigFloat->new(_clean($raw_inp));
    my $lu_km = $inp->bmul($multiplier);
    my $res = $lu_km->bdiv(ONE_AU);
    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Units - Astronomical unit conversion with high precision and large number support

=head1 VERSION

version 1.00

=head1 SYNOPSIS

Astro::Units can capable of converting the astrological units into mile or kilometers 
with the added support of conversion from astrological to light year and vice-versa
   
   # Raw number input will be truncated by Perl hence need to use
   # either bignum in the script or single quotes to pass large number to methods

    use Astro::Units;
    use bignum;
    my $astro =  new Astouniuts();
    print $astro->get_astronomical_units(19999); #use bigint
    
              OR
    
    use Astro::Units;
    my $astro =  new Astouniuts();
    print $astro->get_astronomical_units('19999'); #single quote
    
=head1 DESCRIPTION

C<Astro::Units>, 

Features include:

=over 4

=item * High Precision

=item * Support for very large number range

=item * Fast

=item * Imperial as well as SI unit system support

=back

Astro::Units is useful for performing the astrological conversion and calculation till n'th digit with precision.
Without worrying about result getting truncated.

=head1 IMPORTANT LINKS

=head3 ACKNOWLEDGEMENTS

Conversion Values were taken from 

L<http://www.kylesconverter.com/length/>

L<https://www.calculateme.com/astronomy>

Module internally uses 

L<https://perldoc.perl.org/bignum.html>

L<https://perldoc.perl.org/Math/BigFloat.html>

=over 4

=item * L<https://github.com/spajai/Astro-Units>

Report issue on above link

Frequently asked questions. Make sure you read here FIRST.

=back

=head1 CONSTRUCTOR AND STARTUP

=head2 new()

Creates and returns a new Astro::Units object.

    my $astro = Astro::Units->new()


C<Astro::Units supports unit option>

=head2 new() set metric system

    my $astro = Astro::Units->new(unit => 'mile')
                        or 
    my $astro = Astro::Units->new(unit => 'kilometer')

=head3 supported unit input
    
    Default is Kilometers

    mile
    mi
    m  
    anything starting will m will be considered as miles
    kilometers
    kl
    k
    anything starting will k will be considered as kilometers

=head1 Methods available

    #Astrologocal units to mi/km
    get_astronomical_units
    get_light_years
    get_light_week 
    get_light_days
    get_light_hours
    get_light_minutes
    get_light_seconds
    get_light_parsecs

    #reverse function mi/km to Astrologocal units
    convert_to_astronomical_units
    convert_to_light_years
    convert_to_light_weeks
    convert_to_light_days
    convert_to_light_hours
    convert_to_light_minutes
    convert_to_light_seconds
    convert_to_light_parsec

    #Astrologocal units to light units mi/km not applicable
    au_to_light_years
    au_to_light_weeks
    au_to_light_days
    au_to_light_hours
    au_to_light_minutes
    au_to_light_seconds
    au_to_light_parsecs

    #light units to astronomical units mi/km not applicable
    light_years_to_au
    light_weeks_to_au
    light_days_to_au
    light_hours_to_au
    light_minutes_to_au
    light_seconds_to_au
    light_parsecs_to_au



To convert the user astrological units to kilometers or miles as per the setting in object.

=head2 $astro->get_astronomical_units('1234567899.123456789')

Returns equivalent mi/km for given astronomical_units (au)

=head2 $astro->get_light_years('1234567899.123456789Kilometer')

Returns equivalent mi/km for given light-years (ly)

=head2 $astro->get_light_week('12,34,567,899.123,456,789')

Returns equivalent mi/km for given light-week (lw)

=head2 $astro->get_light_days('12_34_567,899.123,456,789')

Returns equivalent mi/km for given light-days (ld)

=head2 $astro->get_light_hours('12_34_567,899.123,456,789m')

Returns equivalent mi/km for given light-hours (lh)

=head2 $astro->get_light_minutes('12_34_567,899.123,456')

Returns equivalent mi/km for given light-minutes (lm)

=head2 $astro->get_light_seconds(1)

Returns equivalent mi/km for given light-seconds (ls)

=head2 $astro->get_light_parsecs($number)

Returns equivalent mi/km for given parsecs (ps)

=head2 $astro->convert_to_astronomical_units('12_34_567,899.123,456')

Returns equivalent Mi/Km for given astrological-unit

=head2 $astro->convert_to_light_years('12_34_567,899.123,456')

Returns equivalent Mi/Km for given astrological-unit

=head2 $astro->convert_to_light_weeks('12_34_567,899.123,456')

Returns equivalent Mi/Km for given astrological-unit

=head2 $astro->convert_to_light_days('12_34_567,899.123,456')

Returns equivalent Mi/Km for given astrological-unit

=head2 $astro->convert_to_light_hours('12_34_567,899.123,456')

Returns equivalent Mi/Km for given astrological-unit

=head2 $astro->convert_to_light_minutes('12_34_567,899.123,456')

Returns equivalent Mi/Km for given astrological-unit

=head2 $astro->convert_to_light_seconds('12_34_567,899.123,456')

Returns equivalent Mi/Km for given astrological-unit

=head2 $astro->convert_to_light_parsec('12_34_567,899.123,456')

Returns equivalent Mi/Km for given astrological-unit


=head1 Following methods will not follow metric system for obvious reason

=head2 $astro->au_to_light_years()

Returns equivalent light years for given Astronomical units (AU)

=head2 $astro->au_to_light_weeks()

Returns equivalent light weeks for given Astronomical units (AU)

=head2 $astro->au_to_light_days()

Returns equivalent light days for given Astronomical units (AU)

=head2 $astro->au_to_light_hours()

Returns equivalent light hours for given Astronomical units (AU)

=head2 $astro->au_to_light_minutes()

Returns equivalent light minutes for given Astronomical units (AU)

=head2 $astro->au_to_light_seconds()

Returns equivalent light seconds for given Astronomical units (AU)

=head2 $astro->au_to_light_parsecs()

Returns equivelent parsecs for given Astronomical units (AU)

=head1 Following methods will not follow metric system for obvious reason

=head2 $astro->light_years_to_au()

Returns equivalent Atronomical units for given Astrologocal unit

=head2 $astro->light_weeks_to_au()

Returns equivalent Atronomical units for given Astrologocal unit

=head2 $astro->light_days_to_au()

Returns equivalent Atronomical units for given Astrologocal unit

=head2 $astro->light_hours_to_au()

Returns equivalent Atronomical units for given Astrologocal unit

=head2 $astro->light_minutes_to_au()

Returns equivalent Atronomical units for given Astrologocal unit

=head2 $astro->light_seconds_to_au()

Returns equivalent Atronomical units for given Astrologocal unit

=head2 $astro->light_parsecs_to_au()

Returns equivalent Atronomical units for given Astrologocal unit



=head1 AUTHOR

Sushrut Pajai <sushrutpajai at gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Sushrut Pajai 

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language itself.

=cut
