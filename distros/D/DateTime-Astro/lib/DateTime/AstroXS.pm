package DateTime::Astro;
use strict;
use Carp 'confess';

sub dynamical_moment_from_dt {
    return dynamical_moment( moment( $_[0] ) );
}

sub julian_centuries {
    return julian_centuries_from_moment( dynamical_moment_from_dt( $_[0] ) );
}

sub lunar_phase {
    return lunar_phase_from_moment( moment($_[0]) );
}

sub solar_longitude {
    return solar_longitude_from_moment( moment($_[0]) );
}
    
sub lunar_longitude {
    return lunar_longitude_from_moment( moment($_[0]) );
}

sub new_moon_after {
    return dt_from_moment( new_moon_after_from_moment( moment( $_[0] ) ) );
}

sub new_moon_before {
    return dt_from_moment( new_moon_before_from_moment( moment( $_[0] ) ) );
}

sub solar_longitude_before {
    return dt_from_moment( solar_longitude_before_from_moment( moment( $_[0] ), $_[1] ) );
}

sub solar_longitude_after {
    return dt_from_moment( solar_longitude_after_from_moment( moment( $_[0] ), $_[1] ) );
}

BEGIN {
    _init_global_cache();
}

END {
    _clear_global_cache();
}

1;
