package DateTime::Calendar::Mayan;

use strict;

use vars qw( $VERSION );
$VERSION = '0.0601';

use DateTime;
use Params::Validate qw( validate SCALAR OBJECT );

use constant MAYAN_EPOCH => -1137142;
use constant MAYAN_HAAB_EPOCH => MAYAN_EPOCH - 348;
use constant MAYAN_HAAB_MONTH => qw( Pop Uo Zip Zotz Tzec Xul Yaxkin Mol Chen
    Yax Zac Ceh Mac Kankin Muan Pax Kayab Cumku Uayeb );
use constant MAYAN_TZOLKIN_EPOCH => MAYAN_EPOCH - 159;
use constant MAYAN_TZOLKIN_NAME => qw( Imix Ik Akbal Kan Chicchan Cimi Manik
    Lamat Muluc Oc Chuen Eb Ben Ix Men Cib Caban Etznab Cauac Ahau );

sub new {
    my( $class ) = shift;

    my %args = validate( @_,
        {
            baktun  => { type => SCALAR, default => 0 },
            katun   => { type => SCALAR, default => 0 },
            tun     => { type => SCALAR, default => 0 },
            uinal   => { type => SCALAR, default => 0 },
            kin     => { type => SCALAR, default => 0 },
            epoch   => {
                type        => OBJECT,
                can         => 'utc_rd_values',
                optional    => 1,
            },
        }
    );

    $class = ref( $class ) || $class;

    my $alt_epoch;
    if ( exists $args{ epoch } ) {
        my $object = $args{ epoch };
        delete $args{ epoch };
        $object = $object->clone->set_time_zone( 'floating' )
            if $object->can( 'set_time_zone' );

        $alt_epoch = ( $object->utc_rd_values )[ 0 ];
    }

    my $self = {
        epoch       => $alt_epoch || MAYAN_EPOCH,
        rd_secs     => 0,
        rd_nanos    => 0,
    };

    $self->{ rd } = _long_count2rd( $self, \%args );

    return( bless( $self, $class ) );
}

sub now {
    my( $class ) = shift;

    $class = ref( $class ) || $class;

    my $dt = DateTime->now;
    my $dtcm = $class->from_object( object => $dt );

    return( $dtcm );
}

sub today {
    my( $class ) = shift;

    $class = ref( $class ) || $class;

    my $dt = DateTime->today;
    my $dtcm = $class->from_object( object => $dt );

    return( $dtcm );
}

# lifted from DateTime
sub clone { bless { %{ $_[0] } }, ref $_[0] }

sub _long_count2rd {
    my( $self, $lc ) = @_;

    my $rd = $self->{ epoch }
    + $lc->{ baktun } * 144000
    + $lc->{ katun }  * 7200
    + $lc->{ tun }    * 360
    + $lc->{ uinal }  * 20
    + $lc->{ kin };

    return( $rd );
}

sub _rd2long_count {
    my( $self ) = shift;

    my %lc;
    my $long_count  = $self->{ rd } - $self->{ epoch };
    $lc{ baktun }   = _floor( $long_count / 144000 );
    my $day_baktun  = $long_count % 144000;
    $lc{ katun }    = _floor( $day_baktun / 7200 );
    my $day_katun   = $day_baktun % 7200;
    $lc{ tun }      = _floor( $day_katun / 360 );
    my $day_tun     = $day_katun % 360;
    $lc{ uinal }    = _floor( $day_tun / 20 );
    $lc{ kin }      = _floor( $day_tun % 20 );

    return( \%lc );
}

sub  _rd2haab {
    my( $self ) = shift;

    my %haab;
    my $count = ( $self->{ rd } - MAYAN_HAAB_EPOCH ) % 365;
    $haab{ day }    = $count % 20;
    $haab{ month }  = _floor( $count / 20 ) + 1;

    return( \%haab );
}

sub _haab2rd {
    my( $month, $day ) = @_;
    
    return( ( $month - 1 ) * 20 + $day );
}

sub _rd2tzolkin {
    my( $self ) = shift;

    my %tzolkin;
    my $count = $self->{ rd } - MAYAN_TZOLKIN_EPOCH + 1;
    $tzolkin{ number }  = _amod( $count, 13 );
    $tzolkin{ name }    = _amod( $count, 20 );

    return( \%tzolkin );
}

sub _tzolkin2rd {
    my( $number, $name ) = shift;

    return( ( $number - 1 + 39 x ( $number - $name ) ) % 260 );
}

sub from_object {
    my( $class ) = shift;
    my %args = validate( @_,
        {
            object => {
                type    => OBJECT,
                can     => 'utc_rd_values',
            },
        },
    );

    $class = ref( $class ) || $class;

    my $object = $args{ object };
    $object = $object->clone->set_time_zone( 'floating' )
            if $object->can( 'set_time_zone' );

    my( $rd, $rd_secs, $rd_nanos ) = $object->utc_rd_values();

    my $dtcm_epoch = $object->mayan_epoch
            if $object->can( 'mayan_epoch' );

    my $self = {
        rd          => $rd,
        rd_secs     => $rd_secs,
        rd_nanos    => $rd_nanos || 0,
        epoch       => $dtcm_epoch->{ rd } || MAYAN_EPOCH,
    };

    return( bless( $self, $class ) );
}

sub utc_rd_values {
    my( $self ) = shift;

    # days utc, seconds utc,
    return( $self->{ rd }, $self->{ rd_secs }, $self->{ rd_nanos } || 0 );
}

sub from_epoch {
    my( $class ) = shift;
    my %args = validate( @_,
        {
            epoch => { type => SCALAR },
        }
    );

    $class = ref( $class ) || $class;

    my $dt = DateTime->from_epoch( epoch => $args{ epoch } );

    my $self = $class->from_object( object => $dt );

    return( $self );
}

sub epoch {
    my( $self ) = shift;

    my $dt = DateTime->from_object( object => $self );

    return( $dt->epoch );
}

sub set_mayan_epoch {
    my( $self ) = shift;

    my %args = validate( @_,
        {
            object => {
                type    => OBJECT,
                can     => 'utc_rd_values',
            },
        },
    );

    my $object = $args{ object };
    $object = $object->clone->set_time_zone( 'floating' )
            if $object->can( 'set_time_zone' );

    # this can not handle rd values larger then a Mayan year
    # $self->{ rd } = _long_count2rd( $self, _rd2long_count( $self ) );

    $self->{ epoch } = ( $object->utc_rd_values )[ 0 ];
    if ( $self->{ epoch } > MAYAN_EPOCH ) {
        $self->{ rd } += abs( $self->{ epoch } - MAYAN_EPOCH );
    } else {
        $self->{ rd } -= abs( $self->{ epoch } - MAYAN_EPOCH );
    }

    return( $self );
}

sub mayan_epoch {
    my( $self ) = shift;

    my $new_self = $self->clone();

    $new_self->{ rd }       = $self->{ epoch };
    $new_self->{ rd_secs }  = 0;
    $new_self->{ epoch }    = MAYAN_EPOCH;

    # calling from_object causes a method loop

    my $class = ref( $self );
    my $dtcm = bless( $new_self, $class );

    return( $dtcm );
}

sub set {
    my( $self ) = shift;

    my %args = validate( @_,
        {
            baktun  => { type => SCALAR, optional => 1 },
            katun   => { type => SCALAR, optional => 1 },
            tun     => { type => SCALAR, optional => 1 },
            uinal   => { type => SCALAR, optional => 1 },
            kin     => { type => SCALAR, optional => 1 },
        }
    );

    my $lc = _rd2long_count( $self );

    $lc->{ baktun } = $args{ baktun } if defined $args{ baktun };
    $lc->{ katun }  = $args{ katun } if defined $args{ katun };
    $lc->{ tun }    = $args{ tun } if defined $args{ tun };
    $lc->{ uinal }  = $args{ uinal } if defined $args{ uinal };
    $lc->{ kin }    = $args{ kin } if defined $args{ kin };

    $self->{ rd } = _long_count2rd( $self, $lc ); 

    return( $self );
}

sub add {
    my( $self ) = shift;

    my %args = validate( @_,
        {
            baktun  => { type => SCALAR, optional => 1 },
            katun   => { type => SCALAR, optional => 1 },
            tun     => { type => SCALAR, optional => 1 },
            uinal   => { type => SCALAR, optional => 1 },
            kin     => { type => SCALAR, optional => 1 },
        }
    );

    my $lc = _rd2long_count( $self );

    $lc->{ baktun } += $args{ baktun } if defined $args{ baktun };
    $lc->{ katun }  += $args{ katun } if defined $args{ katun };
    $lc->{ tun }    += $args{ tun } if defined $args{ tun };
    $lc->{ uinal }  += $args{ uinal } if defined $args{ uinal };
    $lc->{ kin }    += $args{ kin } if defined $args{ kin };

    $self->{ rd } = _long_count2rd( $self, $lc ); 
    
    return( $self );
}

sub subtract {
    my( $self ) = shift;

    my %args = validate( @_,
        {
            baktun  => { type => SCALAR, optional => 1 },
            katun   => { type => SCALAR, optional => 1 },
            tun     => { type => SCALAR, optional => 1 },
            uinal   => { type => SCALAR, optional => 1 },
            kin     => { type => SCALAR, optional => 1 },
        }
    );

    my $lc = _rd2long_count( $self );

    $lc->{ baktun } -= $args{ baktun } if defined $args{ baktun };
    $lc->{ katun }  -= $args{ katun } if defined $args{ katun };
    $lc->{ tun }    -= $args{ tun } if defined $args{ tun };
    $lc->{ uinal }  -= $args{ uinal } if defined $args{ uinal };
    $lc->{ kin }    -= $args{ kin } if defined $args{ kin };

    $self->{ rd } = _long_count2rd( $self, $lc ); 

    return( $self );
}

sub add_duration {
    my( $self, $duration ) = @_;

    my $dt = DateTime->from_object( object => $self );
    $dt->add_duration( $duration );

    my $new_self = $self->from_object( object => $dt );

    # if there is an alternate epoch defined don't touch it
    $self->{ rd }       = $new_self->{ rd };
    $self->{ rd_secs }  = $new_self->{ rd_secs };

    return( $self );
}

sub subtract_duration {
    my( $self, $duration ) = @_;

    my $dt = DateTime->from_object( object => $self );
    $dt->subtract_duration( $duration );

    my $new_self = $self->from_object( object => $dt );

    # if there is an alternate epoch defined don't touch it
    $self->{ rd }       = $new_self->{ rd };
    $self->{ rd_secs }  = $new_self->{ rd_secs };

    return( $self );
}

sub baktun {
    my( $self, $arg ) = @_;

    my $lc = _rd2long_count( $self );

    if ( defined $arg ) {
        $lc->{ baktun } = $arg;
        $self->{ rd }   = _long_count2rd( $self, $lc ); 

        return( $self );
    }

    # conversion from Date::Maya
    # set baktun to [1-13]
    $lc->{ baktun } %= 13;
    $lc->{ baktun } = 13 if $lc->{ baktun } == 0;

    return( $lc->{ baktun } );
}

*set_baktun = \&baktun;

sub katun {
    my( $self, $arg ) = @_;

    my $lc = _rd2long_count( $self );

    if ( defined $arg ) {
        $lc->{ katun }  = $arg;
        $self->{ rd }   = _long_count2rd( $self, $lc ); 

        return( $self );
    }

    return( $lc->{ katun } );
}

*set_katun= \&katun;

sub tun {
    my( $self, $arg ) = @_;

    my $lc = _rd2long_count( $self );

    if ( defined $arg ) {
        $lc->{ tun }    = $arg;
        $self->{ rd }   = _long_count2rd( $self, $lc ); 

        return( $self );
    }

    return( $lc->{ tun } );
}

*set_tun= \&tun;

sub uinal {
    my( $self, $arg ) = @_;

    my $lc = _rd2long_count( $self );

    if ( defined $arg ) {
        $lc->{ uinal }  = $arg;
        $self->{ rd }   = _long_count2rd( $self, $lc ); 

        return( $self );
    }

    return( $lc->{ uinal } );
}

*set_uinal= \&uinal;

sub kin {
    my( $self, $arg ) = @_;

    my $lc = _rd2long_count( $self );

    if ( defined $arg ) {
        $lc->{ kin }    = $arg;
        $self->{ rd }   = _long_count2rd( $self, $lc ); 

        return( $self );
    }

    return( $lc->{ kin } );
}

*set_kin= \&kin;

sub bktuk {
    my( $self, $sep ) = @_;
    $sep = '.' unless defined $sep;

    my $lc = _rd2long_count( $self ); 

    $lc->{ baktun } %= 13;
    $lc->{ baktun } = 13 if $lc->{ baktun } == 0;

    return(
        $lc->{ baktun } . $sep .
        $lc->{ katun }  . $sep .
        $lc->{ tun }    . $sep .
        $lc->{ uinal }  . $sep .
        $lc->{ kin }
    );
}

*date = \&bktuk;
*long_count = \&bktuk;

sub haab {
    my( $self, $sep ) = @_;
    $sep = ' ' unless defined $sep;

    my $haab = _rd2haab( $self );

    return( $haab->{ day } . $sep . (MAYAN_HAAB_MONTH)[ $haab->{ month } - 1 ] );
}

sub tzolkin {
    my( $self, $sep ) = @_;
    $sep = ' ' unless defined $sep;

    my $tzolkin = _rd2tzolkin( $self );

    return( $tzolkin->{ number } . $sep . (MAYAN_TZOLKIN_NAME )[ $tzolkin->{ name } - 1 ] );
}

# lifted from DateTime::Calendar::Julian;
sub _floor {
    my $x  = shift;
    my $ix = int $x;
    if ($ix <= $x) {
        return $ix;
    } else {
        return $ix - 1;
    }
}

sub _amod {
    my( $x, $y ) = @_;

    return( $y + $x % ( -$y ) );
}

1;

__END__
