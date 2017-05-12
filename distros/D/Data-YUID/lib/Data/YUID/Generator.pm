# $Id$

package Data::YUID::Generator;
use strict;
use warnings;
no warnings qw(deprecated); # for fields

use vars qw{$VERSION};
$VERSION = "0.01";
use Carp;
use Config;

use fields qw(host_id start_time current_time min_id max_id ids make_id);

use constant EPOCH_OFFSET => 946684800; # Sat, Jan 1 2000 00:00 GMT

## |             timestamp             |   serial   |      host     |
## |              36 bits              |     12     |       16      |
use constant HOST_ID_BITS => 16;
use constant TIME_BITS => 36;
use constant SERIAL_BITS => 64 - HOST_ID_BITS - TIME_BITS;

use constant HOST_SHIFT => HOST_ID_BITS;
use constant TIME_SHIFT => HOST_ID_BITS + SERIAL_BITS;
use constant SERIAL_SHIFT => HOST_ID_BITS;

use constant SERIAL_INCREMENT => 1 << SERIAL_SHIFT;

use constant HOST_ID_MAX => (1 << HOST_ID_BITS) - 1;
use constant TIME_MAX => (1 << TIME_BITS) - 1;
use constant TIME_MAX_SHIFTED => TIME_MAX << TIME_SHIFT;
use constant SERIAL_MAX => (1 << SERIAL_BITS) - 1;
use constant SERIAL_MAX_SHIFTED => SERIAL_MAX << SERIAL_SHIFT;

use constant HOST_MAX => (1 << HOST_ID_BITS) - 1;
BEGIN {
    use Config;
    unless ($Config{use64bitint}) {
        eval "use Math::BigInt; 1;"
            or croak "Please install Math::BigInt";
    }
};

sub new {
    my Data::YUID::Generator $self = shift;
    $self = fields::new( $self ) unless ref $self;

    my $host_id = shift;
    if( !$host_id ) {
        $host_id = int( rand( HOST_ID_MAX ) );
    } elsif( $host_id < 0 || $host_id > HOST_ID_MAX ) {
        warn __PACKAGE__ . ": host ID $host_id is not in range of [0," . HOST_ID_MAX . "]\n";
        return undef;
    }

    $self->{ host_id } = $host_id;
    $self->{ start_time } = time;
    $self->{ current_time } = 0;
    $self->{ ids } = {};
    if ($Config{use64bitint}) {
        $self->{make_id} = sub { $self->_make_id_64bits(@_) };
    }
    else {
        $self->{make_id} = sub { $self->_make_id_32bits(@_) };
    }

    $self->_sync();

    return $self;
}


sub _sync {
    my $self = shift;
    my $key = shift;
    my $time = time;
    return if( $self->{ current_time } == $time ); # FIXME: check for clock skew
    $self->{ current_time } = $time;
    $self->{ min_id } = $self->{make_id}->( 0 );
    $self->{ max_id } = $self->{make_id}->( SERIAL_MAX );
    delete $self->{ ids }->{ $key } if $key; ## reset current timestamp
}


sub _make_id_64bits ($) {
    my $self = shift;
    my $serial = shift || 0;
    return (($self->{ current_time } - EPOCH_OFFSET) << TIME_SHIFT) |
        ($serial << SERIAL_SHIFT) | $self->{ host_id };
}

sub _make_id_32bits ($) {
    my $self = shift;
    my $serial = shift || 0;
    my $id = Math::BigInt->new($self->{ current_time } - EPOCH_OFFSET);
    return $id->blsft(TIME_SHIFT)
              ->bior(Math::BigInt->new($serial)->blsft(SERIAL_SHIFT))
              ->bior($self->{ host_id });
}

sub get_id ($) {
    my $self = shift;
    my $key = shift || "_";
    $self->_sync($key);

    if( !exists $self->{ ids }->{ $key } ) {
        $self->{ ids }->{ $key } = $self->{ min_id };
        return $self->{ ids }->{ $key };
    }

    return undef
        if( $self->{ ids }->{ $key } >= $self->{ max_id } );

    $self->{ ids }->{ $key } += SERIAL_INCREMENT;
    return $self->{ ids }->{ $key };
}

## deconstruct an id in its composing part, using id order:
## (ts, serial, host)
sub decompose {
    my $class = shift;
    my $id = shift;
    my $ts     =   $id >> TIME_SHIFT;
    my $serial = ( $id >> HOST_SHIFT ) & SERIAL_MAX;
    my $host   =   $id  & HOST_MAX;
    return ($ts, $serial, $host);
}

1;
