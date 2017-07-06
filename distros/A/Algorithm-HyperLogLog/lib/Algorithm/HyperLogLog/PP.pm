package Algorithm::HyperLogLog::PP;
use strict;
use warnings;
use 5.008008;
use Carp ();
use Digest::MurmurHash3::PurePerl qw(murmur32);
use constant {
    HLL_HASH_SEED => 313,
    TWO_32        => 4294967296.0,
    NEG_TWO_32    => -4294967296.0,
};

our $VERSION = "0.24";

require Algorithm::HyperLogLog;

{

    package Algorithm::HyperLogLog;
    our @ISA = qw(Algorithm::HyperLogLog::PP);
}

sub new {
    my ( $class, $k ) = @_;

    if ( $k < 4 || $k > 16 ) {
        Carp::croak "Number of ragisters must be in the range [4,16]";
    }

    my $m         = 1 << $k;
    my $registers = [ (0) x $m ];
    my $alpha     = 0;
    if ( $m == 16 ) {
        $alpha = 0.673;
    }
    elsif ( $m == 32 ) {
        $alpha = 0.697;
    }
    elsif ( $m == 64 ) {
        $alpha = 0.709;
    }
    else {
        $alpha = 0.7213 / ( 1.0 + 1.079 / $m );
    }

    my $self = {
        k         => $k,
        m         => $m,
        registers => $registers,
        alphaMM   => $alpha * $m * $m,
    };
    bless $self, $class;
    return $self;
}

sub _new_from_dump {
    my ( $class, $k, $data ) = @_;
    my $self = $class->new($k);
    $self->{registers} = $data;
    return $self;
}

sub _dump_register {
    my $self = shift;
    return $self->{registers};
}

sub register_size {
    my $self = shift;
    return $self->{m};
}

sub add {
    my ( $self, @data_list ) = @_;
    for my $data (@data_list) {
        my $hash = murmur32( $data, HLL_HASH_SEED );
        my $index = ( $hash >> ( 32 - $self->{'k'} ) );
        my $rank = _rho( ( $hash << $self->{k} ), 32 - $self->{k} );
        if ( $rank > $self->{registers}[$index] ) {
            $self->{registers}[$index] = $rank;
        }
    }
}

sub estimate {
    my $self = shift;
    my $m    = $self->{m};

    my $rank = 0;
    my $sum  = 0.0;
    for my $i ( 0 .. ( $m - 1 ) ) {
        $rank = $self->{registers}[$i];
        $sum += 1.0 / ( 2.0**$rank );
    }

    my $estimate = $self->{alphaMM} * ( 1.0 / $sum );    # E in the original paper
    if ( $estimate <= 2.5 * $m ) {
        my $v = 0;
        for my $i ( 0 .. ( $m - 1 ) ) {
            if ( $self->{registers}[$i] == 0 ) {
                $v++;
            }
        }

        if ( $v != 0 ) {
            $estimate = $m * log( $m / $v );
        }
    }
    elsif ( $estimate > ( 1.0 / 30.0 ) * TWO_32 ) {
        $estimate = NEG_TWO_32 * log( 1.0 - ( $estimate / TWO_32 ) );
    }
    return $estimate;
}

sub merge {
    my ($self, $other) = @_;
    my $m    = $self->{m};

    die "hll size misatch" if $self->{m} != $other->{m};

    for (my $i=0; $i<$m; $i++) {
        if ($self->{registers}[$i] < $other->{registers}[$i]) {
            $self->{registers}[$i] = $other->{registers}[$i];
        }
    }
}

sub XS {
    0;
}

sub _rho {
    my ( $x, $b ) = @_;
    my $v = 1;
    while ( $v <= $b && !( $x & 0x80000000 ) ) {
        $v++;
        $x <<= 1;
    }
    return $v;
}

1;
__END__
