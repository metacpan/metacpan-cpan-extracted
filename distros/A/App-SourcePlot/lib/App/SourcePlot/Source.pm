package App::SourcePlot::Source;

=head1 NAME

App::SourcePlot::Source - Create a observation source

=head1 SYNOPSIS

    use App::SourcePlot::Source;
    $src = App::SourcePlot::Source->new;

=head1 DESCRIPTION

This class will create Source objects that will hold essential
information for any single source.

It is essentially a wrapper around an Astro::Coords object to add
the additional information used to display a source in this
application.

=cut

use 5.004;
use Carp;
use strict;

use Astro::Coords;
use Math::Trig qw/pi/;
use DateTime;
use DateTime::Format::Strptime;

our $VERSION = '1.32';

my $locateBug = 0;

=head1 METHODS

=head2 Constructor

=over 4

=item new

Create a new Source object.

    $obs = App::SourcePlot::Source->new($planet);
    $obs = App::SourcePlot::Source->new($name, $RA, $DEC, $Epoc);

Or using an Astro::Coords object.

    $coords = Astro::Coords->new(...);
    $obs = App::SourcePlot::Source->new($coords);

=cut

sub new {
    print "Creating a new observation Source object\n" if $locateBug;

    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};  # Anon hash

    bless($self, $class);
    print "New observation Source object has been blessed: $self\n" if $locateBug;

    $self->configure(@_);

    $self->active(1);

    print "Object created\n" if $locateBug;

    return $self;
}


sub configure {
    my $self = shift;

    # Special case: empty source object.
    unless (@_) {
        $self->coords(Astro::Coords->new());
        return;
    }

    my $name = shift;

    if (UNIVERSAL::isa($name, 'Astro::Coords')) {
        $self->coords($name);
    }
    elsif (@_) {
        print "Passed in paramaters are being entered\n" if $locateBug;
        my ($ra, $dec, $epoc, undef) = @_;

        # Prevent Astro::Coords guessing between radians and degrees.
        my $unit = ($ra =~ /:/ or $dec =~ /:/)
            ? 'sexagesimal'
            : 'degrees';

        if ($epoc eq 'RJ') {
            $self->coords(Astro::Coords->new(
                name => $name,
                ra => ($unit eq 'degrees') ? ($ra * 15) : $ra,
                dec => $dec,
                type => 'J2000',
                units => $unit,
            ));
        }
        elsif ($epoc eq 'RB') {
            $self->coords(Astro::Coords->new(
                name => $name,
                ra => ($unit eq 'degrees') ? ($ra * 15) : $ra,
                dec => $dec,
                type => 'B1950',
                units => $unit,
            ));
        }
        elsif ($epoc eq 'GA') {
            $self->coords(Astro::Coords->new(
                name => $name,
                long => $ra,
                lat => $dec,
                type => 'galactic',
                units => $unit,
            ));
        }
        elsif ($epoc eq 'AZ') {
            $self->coords(Astro::Coords->new(
                name => $name,
                az => $ra,
                el => $dec,
                units => $unit,
            ));
        }
        else {
            die "App::SourcePlot::Source unknown epoc " . $epoc
                . " for source " . $name;
        }
    }
    else {
        $self->coords(Astro::Coords->new(
            planet => $name,
        ));
    }
}

=back

=head2 Common data manipulation functions

=over 4

=item name

Returns and sets the name of the source.

    $name = $obs->name();
    $obs->name('Mars');

=cut

sub name {
    my $self = shift;
    return $self->coords()->name(@_);
}

=item coords

Set or return the corresponding Astro::Coords object.

=cut

sub coords {
    my ($self, $coords, undef) = @_;
    if (defined $coords) {
        die unless UNIVERSAL::isa($coords, 'Astro::Coords');
        $self->{'COORDS'} = $coords;
    }
    return $self->{'COORDS'};
}

=item active

Returns and sets whether the source is active.

    $on = $obs->active();
    $obs->active(0);

=cut

sub active {
    my $self = shift;
    $self->{ACTIVE} = shift if @_;
    return $self->{ACTIVE} if defined $self->{ACTIVE};
    return '';
}

=item color

Returns and sets the source color.

    $col = $obs->color();
    $obs->color('black');

=cut

sub color {
    my $self = shift;
    $self->{COLOR} = shift if @_;
    return $self->{COLOR} if defined $self->{COLOR};
    return '';
}

=item lineWidth

Returns and sets the sources thickness.

    $LW = $obs->lineWidth();
    $obs->lineWidth(2);

=cut

sub lineWidth {
    my $self = shift;
    $self->{LINEWIDTH} = shift if @_;
    return $self->{LINEWIDTH} if defined $self->{LINEWIDTH};
    return 1;
}

=item index

Returns and sets the sources window index.

    $index = $obs->index();
    $obs->index(1234);

=cut

sub index {
    my $self = shift;
    $self->{INDEX} = shift if @_;
    return $self->{INDEX} if defined $self->{INDEX};
    return -1;
}

=item ra

Returns the RA of the source, or other coordinate type
in systems other than RJ / RB.

    $ra = $obs->ra();

=cut

sub ra {
    my $self = shift;
    if (@_) {
        die 'App::SourcePlot::Source cannot change ra';
    }
    my $native_method = $self->coords()->native();
    my ($ra, undef) = $self->coords()->$native_method();
    return sprintf('%.4f', $ra->degrees()) if $self->epoc() eq 'GA';
    return $ra->in_format('sexagesimal');
}

=item dec

Returns the declination of the source, or other coordinate
type in systems other than RJ / RB.

    $dec = $obs->dec();

=cut

sub dec {
    my $self = shift;
    if (@_) {
        die 'App::SourcePlot::Source cannot change dec';
    }
    my $native_method = $self->coords()->native();
    my (undef, $dec) = $self->coords()->$native_method();
    return sprintf('% .4f', $dec->degrees()) if $self->epoc() eq 'GA';
    return $dec->in_format('sexagesimal');
}

=item ra2000

Returns the ra of the source in J2000 in radians.

    $ra2000 = $obs->ra2000();

=cut

sub ra2000 {
    my $self = shift;
    if (@_) {
        die 'App::SourcePlot::Source cannot change ra2000';
    }
    return $self->coords()->ra(format => 'r');
}

=item dec2000

Returns dec of the source in J2000 in radians.

    $dec2000 = $obs->dec2000();

=cut

sub dec2000 {
    my $self = shift;
    if (@_) {
        die 'App::SourcePlot::Source cannot change dec';
    }
    return $self->coords()->dec(format => 'r');
}

=item epoc

Returns the epoch of the source.

    $epoc = $obs->epoc();

=cut

sub epoc {
    my $self = shift;
    my $native_method = $self->coords()->native;

    return 'RJ' if $native_method eq 'radec';
    return 'RB' if $native_method eq 'radec1950';
    return 'GA' if $native_method eq 'glonglat';
    return 'AZ' if $native_method eq 'azel';
    return '??';
}

=item elevation

Returns the current elevation of the source at the ut time
in degrees.

    $ele = $obs->elevation();

=cut

sub elevation {
    my $self = shift;
    if (@_) {
        die 'App::SourcePlot::Source cannot set elevation';
    }
    return $self->coords()->el(format => 'd');
}

=item is_blank

Returns true if the source information is "blank".  This is the
default state for an object constructed with no arguments,
and is represented by the Astro::Coords default type -- a
Calibration object.

=cut

sub is_blank {
    my $self = shift;

    return $self->coords()->type() eq 'CAL';
}

=item NameX

Returns and sets the current x position of name label.

    $x = $obs->NameX();
    $obs->NameX(6.5);

=cut

sub NameX {
    my $self = shift;
    $self->{NAMEX} = shift if @_;
    return $self->{NAMEX} if defined $self->{NAMEX};
    return '';
}

=item NameY

Returns and sets the current y position of name label.

    $y = $obs->NameY();
    $obs->NameY(6.5);

=cut

sub NameY {
    my $self = shift;
    $self->{NAMEY} = shift if @_;
    return $self->{NAMEY} if defined $self->{NAMEY};
    return '';
}

=item AzElOffsets

Returns the amount in the current system to offset to draw the
Elevation and Azimuth axes.

    ($elex, $eley, $azx, $azy) = $obs->AzElOffsets();
    $obs->AzElOffsets(.5, 4, .3, 2);

=cut

sub AzElOffsets {
    my $self = shift;
    if (@_) {
        $self->{ELEX} = shift;
        $self->{ELEY} = shift;
        $self->{AZX} = shift;
        $self->{AZY} = shift;
    }
    return ($self->{ELEX}, $self->{ELEY}, $self->{AZX}, $self->{AZY})
        if defined $self->{ELEX};
    return (undef, undef, undef, undef);
}

=item timeDotX

Returns and sets the current position of the time dot on
the x axis.

    $x = $obs->timeDotX();
    $obs->timeDotX('15.122');

=cut

sub timeDotX {
    my $self = shift;
    $self->{TIMEDOTX} = shift if @_;
    return $self->{TIMEDOTX} if defined $self->{TIMEDOTX};
    return '';
}

=item timeDotY

Returns and sets the current position of the time dot on
the y axis.

    $y = $obs->timeDotY();
    $obs->timeDotY('15.122');

=cut

sub timeDotY {
    my $self = shift;
    $self->{TIMEDOTY} = shift if @_;
    return $self->{TIMEDOTY} if defined $self->{TIMEDOTY};
    return '';
}

=item time_ele_points

These functions return an array of comparative points for different
characteristics of this source.  The avaliable comparisons are:

    time_ele_points     - time vs elevation
    time_az_points      - time vs azimuth
    time_pa_points      - time vs parallactic angle
    ele_time_points     - elevation vs time
    ele_az_points       - elevation vs azimuth
    ele_pa_points       - elevation vs parallactic angle
    az_time_points      - azimuth vs time
    az_ele_points       - azimuth vs azimuth
    az_pa_points        - azimuth vs parallactic angle
    pa_time_points      - parallactic angle vs time
    pa_ele_points       - parallactic angle vs elevation
    pa_az_points        - parallactic angle vs azimuth

    Example syntax:

    @time_ele_points = $obs->time_ele_points();

=cut

sub time_ele_points {
    my $self = shift;
    return @{$self->{TIME_ELE_POINTS}} if defined $self->{TIME_ELE_POINTS};
    return ();
}

sub time_az_points {
    my $self = shift;
    return @{$self->{TIME_AZ_POINTS}} if defined $self->{TIME_AZ_POINTS};
    return ();
}

sub time_pa_points {
    my $self = shift;
    return @{$self->{TIME_PA_POINTS}} if defined $self->{TIME_PA_POINTS};
    return ();
}

sub ele_time_points {
    my $self = shift;
    return @{$self->{ELE_TIME_POINTS}} if defined $self->{ELE_TIME_POINTS};
    return ();
}

sub ele_az_points {
    my $self = shift;
    return @{$self->{ELE_AZ_POINTS}} if defined $self->{ELE_AZ_POINTS};
    return ();
}

sub ele_pa_points {
    my $self = shift;
    return @{$self->{ELE_PA_POINTS}} if defined $self->{ELE_PA_POINTS};
    return ();
}

sub az_time_points {
    my $self = shift;
    return @{$self->{AZ_TIME_POINTS}} if defined $self->{AZ_TIME_POINTS};
    return ();
}

sub az_ele_points {
    my $self = shift;
    return @{$self->{AZ_ELE_POINTS}} if defined $self->{AZ_ELE_POINTS};
    return ();
}

sub az_pa_points {
    my $self = shift;
    return @{$self->{AZ_PA_POINTS}} if defined $self->{AZ_PA_POINTS};
    return ();
}

sub pa_time_points {
    my $self = shift;
    return @{$self->{PA_TIME_POINTS}} if defined $self->{PA_TIME_POINTS};
    return ();
}

sub pa_ele_points {
    my $self = shift;
    return @{$self->{PA_ELE_POINTS}} if defined $self->{PA_ELE_POINTS};
    return ();
}

sub pa_az_points {
    my $self = shift;
    return @{$self->{PA_AZ_POINTS}} if defined $self->{PA_AZ_POINTS};
    return ();
}

=back

=head2 Additional Methods

=over 4

=item dispLine

Returns the line to display - presentation use.

    $line = $obs->dispLine();

=cut

sub dispLine {
    my $self = shift;
    my $line;
    unless (UNIVERSAL::isa($self->coords(), 'Astro::Coords::Planet')) {
        $line = sprintf
            ' %-4d  %-16s  %-12s  %-13s  %-4s',
            ($self->index() + 1),
            $self->name(), $self->ra(), $self->dec(), $self->epoc();
    }
    else {
        $line = sprintf
            ' %-4d  %-16s  Planet',
            ($self->index() + 1),
            ucfirst($self->name());
    }
    return $line;
}

=item copy

Returns a copy of this object.

    $cp = $obs->copy();

=cut

sub copy {
    my $self = shift;
    my $source = $self->new($self->coords());
    return $source;
}

=item calcPoints

Calculations the Elevation, Azimeth, etc. points
$MW is the main window widget.  Required for
progress bar

    $obs->calcPoints($date, $time, $num_points, $MW, $tel);

=cut

sub calcPoints {
    my $self = shift;
    my $DATE = shift;
    my $TIME = shift;
    my $numPoints = shift;
    my $MW = shift;
    my $tel = shift;
    my $timeBug = 0;

    my $coords = $self->coords();
    $coords->telescope($tel);
    my $dt_save = $coords->datetime();

    my $strp = DateTime::Format::Strptime->new(
        pattern => '%Y/%m/%d %H:%M:%S',
        time_zone => 'UTC',
        on_error => 'croak');

    my $dt = $strp->parse_datetime($DATE . ' ' . $TIME);

    my $dt_running = $dt->clone();

    my $tlen = @{$self->{TIME_ELE_POINTS}} if defined $self->{TIME_ELE_POINTS};
    if (defined $tlen && $tlen > 0) {
        return;
    }

    $dt_running->subtract(hours => 2);
    my $lst_prev = undef;

    for (my $h = 0; $h < $numPoints; $h ++) {
        $MW->update;
        my ($lst, $ele, $az, $pa, undef) = $self->_calcPoint($dt_running);

        if (defined $lst_prev and $lst < $lst_prev) {
            $lst += 2 * pi;

            # Allow a second wrap around in case LST is just under 2 pi at the
            # start (eg on March 5th at JCMT with (default) 1:30:00 center time.
            # This is necessary because we generate points over a full day,
            # and then convert to LST so there is always one wrap-around, with
            # a potential for a second for certain date / location /center time
            # configurations!
            if ($lst < $lst_prev) {
                $lst += 2 * pi;
            }
        }

        $lst_prev = $lst;

        push @{$self->{TIME_ELE_POINTS}}, $lst;
        push @{$self->{TIME_ELE_POINTS}}, $ele;

        push @{$self->{TIME_AZ_POINTS}}, $lst;
        push @{$self->{TIME_AZ_POINTS}}, $az;

        push @{$self->{TIME_PA_POINTS}}, $lst;
        push @{$self->{TIME_PA_POINTS}}, $pa;

        push @{$self->{ELE_TIME_POINTS}}, $ele;
        push @{$self->{ELE_TIME_POINTS}}, $lst;

        push @{$self->{ELE_AZ_POINTS}}, $ele;
        push @{$self->{ELE_AZ_POINTS}}, $az;

        push @{$self->{ELE_PA_POINTS}}, $ele;
        push @{$self->{ELE_PA_POINTS}}, $pa;

        push @{$self->{AZ_TIME_POINTS}}, $az;
        push @{$self->{AZ_TIME_POINTS}}, $lst;

        push @{$self->{AZ_ELE_POINTS}}, $az;
        push @{$self->{AZ_ELE_POINTS}}, $ele;

        push @{$self->{AZ_PA_POINTS}}, $az;
        push @{$self->{AZ_PA_POINTS}}, $pa;

        push @{$self->{PA_TIME_POINTS}}, $pa;
        push @{$self->{PA_TIME_POINTS}}, $lst;

        push @{$self->{PA_ELE_POINTS}}, $pa;
        push @{$self->{PA_ELE_POINTS}}, $ele;

        push @{$self->{PA_AZ_POINTS}}, $pa;
        push @{$self->{PA_AZ_POINTS}}, $az;

        $dt_running->add(seconds => 24 * 3600 / ($numPoints - 1));
    }

    $coords->datetime($dt_save);
}

=item calcPoint

Returns the time in decimal, elevation, azimuth, and parallactic angle
for a given source at a particular time and date.

    ($lst, $ele, $az, $pa) = $obs->calcPoint($date, $time, $tel);

=cut

sub calcPoint {
    my $self = shift;
    my $DATE = shift;
    my $TIME = shift;
    my $tel = shift;

    my $strp = DateTime::Format::Strptime->new(
        pattern => '%Y/%m/%d %H:%M:%S',
        time_zone => 'UTC',
        on_error => 'croak');

    my $dt = $strp->parse_datetime($DATE . ' ' . $TIME);

    $dt->add(hours => 10);

    return $self->_calcPoint($dt, $tel);
}

sub _calcPoint {
    my $self = shift;
    my $dt = shift;
    my $tel = shift;

    # PAL (and so Astro::Coords) can not handle seconds > 59 (used in the case
    # of leap seconds), so replace with 59 seconds when this happens.
    $dt->set_second(59) if $dt->second() > 59;

    my $coords = $self->coords();
    $coords->datetime($dt) if defined $dt;
    $coords->telescope($tel) if defined $tel;

    my $pa = $coords->pa(format => 'r');
    my ($elex, $eley) = _axis_direction($pa, 0, 30);
    my ($azx, $azy) = _axis_direction($pa, 30, 0);

    return (
        $coords->_lst()->radians(),
        $coords->el(format => 'd'),
        $coords->az(format => 'd'),
        $coords->pa(format => 'd'),
        $elex, $eley, $azx, $azy,
    );
}

# Based on the AzToRa function from the old
# Astro::Instrument::SCUBA::Array module
# by Casey Best (University of Victoria).
sub _axis_direction {
    my $pa = shift;
    my $daz = shift;
    my $del = shift;

    my $x = -$daz * cos($pa) + $del * sin($pa);
    my $y = $daz * sin($pa) + $del * cos($pa);
    return ($x, $y);
}


=item erasePoints

Erases all of the plotting points.  Needed when new coords put in.

    $obs->erasePoints();

=cut

sub erasePoints {
    my $self = shift;
    $self->{TIME_ELE_POINTS} = ();
    $self->{TIME_AZ_POINTS} = ();
    $self->{TIME_PA_POINTS} = ();
    $self->{ELE_TIME_POINTS} = ();
    $self->{ELE_AZ_POINTS} = ();
    $self->{ELE_PA_POINTS} = ();
    $self->{AZ_TIME_POINTS} = ();
    $self->{AZ_ELE_POINTS} = ();
    $self->{AZ_PA_POINTS} = ();
    $self->{PA_TIME_POINTS} = ();
    $self->{PA_ELE_POINTS} = ();
    $self->{PA_AZ_POINTS} = ();
    $self->{TIMEDOTX} = undef;
    $self->{TIMEDOTY} = undef;
}

=item eraseTimeDot

Erases the time dot coordinates

    $obs->eraseTimeDot();

=cut

sub eraseTimeDot {
    my $self = shift;
    $self->{TIMEDOTX} = undef;
    $self->{TIMEDOTY} = undef;
}

1;

__END__

=back

=head1 AUTHOR

Casey Best

=head1 COPYRIGHT

Copyright (C) 2018 East Asian Observatory.
Copyright (C) 2012-2014 Science and Technology Facilities Council.
Copyright (C) 1998, 1999 Particle Physics and Astronomy Research
Council. All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
