=head1 NAME

DateTimeX::AATW - DateTime All Around The World

=head1 SYNOPSIS

  use DateTime;
  use DateTimeX::AATW;

  my $dt = DateTime->now();
  my $aatw = DateTimeX::AATW->new($dt);

  ### Return names of all time zones that are in hour '2' of the day
  my $zone_names_for_hour_2_ref = $aatw->zone_names_for_hour(2);
  my @zone_names_for_hour_2_ary = $aatw->zone_names_for_hour(2);

  ### Return DateTime::TimeZone objects of all time zones that are
  ### in hour '2' of the day
  my $zones_for_hour_2_ref = $aatw->zones_for_hour(2);
  my @zones_for_hour_2_ary = $aatw->zones_for_hour(2);

  ### Return names of all time zones that are in hours '2' and '5'
  ### of the day
  my $zone_names_for_hours_2and5_ref = $aatw->zone_names_for_hours(2,5);
  my @zone_names_for_hours_2and5_ary = $aatw->zone_names_for_hours(2,5);

  ### Return DateTime::TimeZone objets of all time zones that are in
  ### hours '2' and '5' of the day
  my $zones_for_hours_2and5_ref = $aatw->zones_for_hours(2,5);
  my @zones_for_hours_2and5_ary = $aatw->zones_for_hours(2,5);

  ### Return a DateTime object for a specific time zone
  my $dt_for_NewYork = $aatw->dt_for_zone('America/New_York');
  my $dt_for_Paris   = $aatw->dt_for_zone('Europe/Paris');

  ### Return a HASH mapping an hour in the day to an ARRAYREF
  ### of DateTime::TimeZone objects that are part of that hour.
  my $hour_zones_map = $aatw->hour_zones_map();
  my $hour_zones_map = $aatw->hour_zones_map(0,4,8,12,16);

  ### Return a HASH mapping an hour in the day to an ARRAYREF
  ### of time zone names that are part of that hour.
  my $hour_zone_names_map = $aatw->hour_zones_map();
  my $hour_zone_names_map = $aatw->hour_zones_map(0,4,8,12,16);

  ### Return a HASH mapping a DateTime string to an ARRAYREF
  ### of DateTime::TimeZone objects.
  my $dt_zones_map = $aatw->dt_zones_map();
  my $dt_zones_map = $aatw->dt_zones_map(0,4,8,12,16);

  ### Return a HASH mapping a DateTime string to an ARRAYREF
  ### of time zone names.
  my $dt_zones_map = $aatw->dt_zones_map();
  my $dt_zones_map = $aatw->dt_zones_map(0,4,8,12,16);

  ### Return a HASH mapping a zone name to it's current DateTime
  ### objct
  my $zone_name_dt_map = $aatw->zone_name_dt_map();
  my $zone_name_dt_map = $aatw->zone_name_dt_map(
                                 'America/New_York',
                                 'Europe/Paris', 
                                 'Asia/Tokyo');


=head1 DESCRIPTION

This module intends to make it easy to find what time or hour it is
for every time zone known to L<DateTime::TimeZone::Catalog> and provide
easy lookup functions for that data based on a single L<DateTime> object.

The inital reason for creating this module grew from a need to run
scheduled tasks on servers around the world from a single monitoring /
administration server.  Some information for example, needed to be
collected on the 0,4,8,12,16,20 hours within that servers time zone.
The script on the monitoring server could be kicked off every hour,
calculate which time zones needed to be collected from, then collect
information form servres only in those time zones.  

Combining this module with L<DateTime::Event::Cron> helps figure out
which time zones need be operated on at a specific time and schedule. 


=cut

package DateTimeX::AATW;
use strict;

use DateTime;
use DateTime::TimeZone;

our $VERSION = '0.04';


=head1 CONSTRUCTOR

=over 4

=item B<new($datetime_object)>

Returns a DateTimeX::AATW object.  A vaild L<DateTime> object must be passed.

=back

=cut


sub new {
    my $class = shift;
    my $dt = shift;

    die "Must pass a DateTime object." unless UNIVERSAL::isa( $dt, "DateTime" );

    my $self = {
        '_dt' => $dt->clone,
    };

    bless $self, $class;

    $self->_build_lookups();
  
    return $self;
}


=head1 OBJECT METHODS

=over 4

=cut






=item B<zones_for_hour(SCALAR | ARRAY | ARRAYREF)>

Returns an ARRAY or ARRAYREF depending on context of L<DateTime::TimeZone> objects for the requests hour(s).  
The requested hour(s) must be integers between 0 and 23.

=over 4

If you create a DateTimeX::AATW object with a L<DateTime> object based on UTC and call $aatw->zones_for_hour(2),
the function will return all time zones that are in the second hour of the day based on that L<DateTime> object. 

=back

=cut

sub zones_for_hour {
    my $self = shift;
    my @hours;
    if (ref $_[0] eq 'ARRAY') {
        @hours = @{$_};
    } else {
        @hours = @_;
    }


    my @zones = ();

    foreach my $hour (@hours) {
        if ($hour >= 0 && $hour <= 23) {
            push @zones, @{$self->{_hour_zone_map}->{$hour}->{zones}};
        } else {
            #warn "Hour must be an integer from 0 to 23";
            return undef;
        }
    }

    wantarray ? @zones : \@zones;

}



=item B<zones_for_hours(SCALAR | ARRAY | ARRAYREF)>

Alias for L<zones_for_hour|/zones_for_hour>

=back

=cut

sub zones_for_hours {
    my $self = shift;
    $self->zones_for_hour(@_);
}




=item B<zone_names_for_hour(SCALAR | ARRAY | ARRAYREF)>

Returns an ARRAY or ARRAYREF depending on context of time zone names for the requests hour(s).
The requested hour(s) must be integers between 0 and 23.

=cut

sub zone_names_for_hour {
    my $self = shift;

    my $zone_names = undef;
    my $zones = $self->zones_for_hour(@_);

    if ($zones) {
        $zone_names = [];
        push @$zone_names,  map {$_->name } @$zones;
    } else {
        return undef;
    }

    wantarray ? @$zone_names : $zone_names;
}



=item B<zone_names_for_hours(SCALAR | ARRAY | ARRAYREF)>

Alias for L<zone_names_for_hour|/zone_names_for_hour>

=back

=cut

sub zone_names_for_hours {
    my $self = shift;
    $self->zone_names_for_hour(@_);
}




=item B<hour_zones_map(SCALAR | ARRAY | ARRAYREF)>

Returns a HASHREF that maps an hour of the day to an ARRAYREF 
of L<DateTime::TimeZone> objects.  Hour(s) passed must be integers between 0 and 23.

With no parameters a map of all hours between 0 and 23 will be returned.

=cut


sub hour_zones_map {
    my $self = shift;
    my @hours;
    if (ref $_[0] eq 'ARRAY') {
        @hours = @{$_};
    } else {
        @hours = @_;
    }

    my $hour_zones_map = {};
    if (@hours > 0) {
        foreach my $hour (@hours) {
            if ($hour >= 0 && $hour <= 23) {
                $hour_zones_map->{$hour} = $self->{_hour_zone_map}->{$hour}->{zones};
            } else {
                return undef;
            }
        }
    } else {
        map {$hour_zones_map->{$_} = $self->{_hour_zone_map}->{$_}->{zones}} keys %{$self->{_hour_zone_map}};
    }

    return $hour_zones_map;

}



=item B<hour_zone_names_map(SCALAR | ARRAY | ARRAYREF)>

Returns a HASHREF that maps an hour of the day to an ARRAYREF
of time zone names.  Hour(s) passed must be integers between 0 and 23.

With no parameters a map of all hours between 0 and 23 will be returned.

=cut


### Got Lazy copied from hour_zone_map, look to make generic _build_map function in the future
sub hour_zone_names_map {
    my $self = shift;
    my @hours;
    if (ref $_[0] eq 'ARRAY') {
        @hours = @{$_};
    } else {
        @hours = @_;
    }

    my $hour_zones_map = {};
    if (@hours > 0) {
        foreach my $hour (@hours) {
            if ($hour >= 0 && $hour <= 23) {
                $hour_zones_map->{$hour} = $self->{_hour_zone_map}->{$hour}->{zone_names};
            } else {
                return undef;
            }
        }
    } else {
        map {$hour_zones_map->{$_} = $self->{_hour_zone_map}->{$_}->{zone_names}} keys %{$self->{_hour_zone_map}};
    }

    return $hour_zones_map;

}



=item B<dt_zones_map(SCALAR | ARRAY | ARRAYREF)>

Returns a HASHREF that maps a L<DateTime> string to an ARRAYREF
of L<DateTime::TimeZone> objects.  

Parameters must be valid L<DateTime> objects

With no parameters a map of all L<DateTime> strings will be returned.

=cut

sub dt_zones_map {
    my $self = shift;
    my @datetimes;
    if (ref $_[0] eq 'ARRAY') {
        @datetimes = @{$_};
    } else {
        @datetimes = @_;
    }

    my $dt_zones_map = {};
    if (@datetimes > 0) {
        foreach my $dt (@datetimes) {
            if (UNIVERSAL::isa( $dt, "DateTime" )) {
                $dt_zones_map->{$dt} = $self->{_time_zone_map}->{$dt}->{zones};
            } else {
                return undef;
            }
        }
    } else {
        map {$dt_zones_map->{$_} = $self->{_time_zone_map}->{$_}->{zones}} keys %{$self->{_time_zone_map}};
    }

    return $dt_zones_map;
}


=item B<dt_zone_names_map(SCALAR | ARRAY | ARRAYREF)>

Returns a HASHREF that maps a L<DateTime> string to an ARRAYREF
of time zone names.

Parameters must be valid L<DateTime> objects

With no parameters a map of all L<DateTime> strings will be returned.

=cut


### Got Lazy copied from dt_zone_map, look to make generic _build_map function in the future
sub dt_zone_names_map {
    my $self = shift;
    my @datetimes;
    if (ref $_[0] eq 'ARRAY') {
        @datetimes = @{$_};
    } else {
        @datetimes = @_;
    }

    my $dt_zones_map = {};
    if (@datetimes > 0) {
        foreach my $dt (@datetimes) {
            if (UNIVERSAL::isa( $dt, "DateTime::TimeZone" )) {
                $dt_zones_map->{$dt} = $self->{_time_zone_map}->{$dt}->{zone_names};
            } else {
                return undef;
            }
        }
    } else {
        map {$dt_zones_map->{$_} = $self->{_time_zone_map}->{$_}->{zone_names}} keys %{$self->{_time_zone_map}};
    }

    return $dt_zones_map;

}


=item B<dt_for_zone(SCALAR | DateTime::TimeZone)>

Returns a L<DateTime> object.

Parameters must be a valid L<DateTime::TimeZone> string or a valid L<DateTime::TimeZone> object.

=cut

sub dt_for_zone {
    my $self = shift;
    my $zone = shift;

    if (UNIVERSAL::isa( $zone, "DateTime::TimeZone" )) {
        return $self->{_zone_time_map}->{$zone->name}->{dt};
    } elsif (DateTime::TimeZone->is_valid_name($zone)) {
        return $self->{_zone_time_map}->{$zone}->{dt};
    }

    return undef;

}


=item B<zone_name_dt_map(SCALAR | ARRAY | ARRAYREF)>

Returns a HASHREF that maps a zone name to a L<DateTime> object.  

Parameters must be valid L<DateTime::TimeZone> string(s) or a valid L<DateTime::TimeZone> object(s).

With no parameters a map of all zone names is returned.

=cut


sub zone_name_dt_map {
    my $self = shift;
    my @zones;
    if (ref $_[0] eq 'ARRAY') {
        @zones = @{$_};
    } else {  
        @zones = @_;
    }

    my $zone_dt_map = {};
    if (@zones > 0) {
        foreach my $zone (@zones) {
            if (UNIVERSAL::isa( $zone, "DateTime::TimeZone" )) {
                $zone_dt_map->{$zone->name} = $self->{_zone_time_map}->{$zone->name}->{dt};
            } elsif (DateTime::TimeZone->is_valid_name($zone)) {
                $zone_dt_map->{$zone} = $self->{_zone_time_map}->{$zone}->{dt};
            } else {
                return undef;
            }
        }
    } else {
        map { $zone_dt_map->{$_} = $self->{_zone_time_map}->{$_}->{dt} } keys %{$self->{_zone_time_map}};
    }

    return $zone_dt_map;
}




sub _build_lookups {
    my $self = shift;

    my $dt = $self->{_dt}->clone;

    my $time_zone_map = {};
    my $zone_time_map = {};
    my $hour_zone_map = {};

    foreach my $name (DateTime::TimeZone->all_names) {
        $dt->set_time_zone($name);
        my $new_dt = $dt->clone;
        my $tz = $new_dt->time_zone;
        my $tz_name = $tz->name;

        $zone_time_map->{$name}->{dt} = $new_dt;
        
        $time_zone_map->{$new_dt}->{dt} = $new_dt unless $time_zone_map->{$new_dt}->{dt};
        push @{$time_zone_map->{$new_dt}->{zones}}, $tz;
        push @{$time_zone_map->{$new_dt}->{zone_names}}, $tz_name;

        $hour_zone_map->{int($new_dt->hour)}->{dt} = $new_dt unless $hour_zone_map->{int($new_dt->hour)}->{dt};
        push @{$hour_zone_map->{int($new_dt->hour)}->{zones}}, $tz;
        push @{$hour_zone_map->{int($new_dt->hour)}->{zone_names}}, $tz_name;

    }

    $self->{_time_zone_map} = $time_zone_map;
    $self->{_zone_time_map} = $zone_time_map;
    $self->{_hour_zone_map} = $hour_zone_map;
 
    return 1;
}



1;


=back


=head1 AUTHOR

    Kevin C. McGrath
    CPAN ID: KMCGRATH
    kmcgrath@baknet.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

# The preceding line will help the module return a true value

