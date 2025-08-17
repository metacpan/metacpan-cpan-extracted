# ABSTRACT: K-Sortable Unique IDentifiers
package Data::KSUID;

use strict;
use warnings;

our $VERSION = '0.001';

use Exporter 'import';

our @EXPORT_OK = qw(
    create_ksuid
    create_ksuid_string
    is_ksuid
    is_ksuid_string
    ksuid_to_string
    next_ksuid
    payload_of_ksuid
    previous_ksuid
    string_to_ksuid
    time_of_ksuid
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Carp ();
use Crypt::URandom ();
use Scalar::Util ();
use Sub::Util ();

# KSUID's epoch starts more recently so that the 32-bit
# number space gives a significantly higher useful lifetime
# of around 136 years from March 2017. This number (14e8)
# was picked to be easy to remember.
use constant EPOCH => 1_400_000_000;

use constant {
    # For base-62 encoding
    KSUID_BASE  => 4_294_967_296, # 0x100_000_000
    STRING_BASE => 62,

    MAX_TIME    => EPOCH + unpack( 'N', "\xff" x 4 ),
};

# Public constants
# The ones defined above are for internal use only
use constant {
    MAX => "\xff" x 20,
    MIN => "\x00" x 20,

    # Math::BigInt->from_bytes("\xff" x 20)->to_base(62)
    MAX_STRING => 'aWgEPTl1tmebfsQzFP4bxwgy80V',
    MIN_STRING => '000000000000000000000000000',
};

# Trusting private functions

my $safely_printed = Sub::Util::set_subname( safely_printed => sub {
    require B;
    defined $_[0]
        ? B::perlstring($_[0])
        : 'an undefined value';
});

my %value62 = map {
    $_ =~ /[A-Z]/ ? ( $_ => ord($_) - ord('A') + 10 ) :
    $_ =~ /[a-z]/ ? ( $_ => ord($_) - ord('a') + 36 ) :
                    ( $_ =>     $_ );
} 0 .. 9, 'A' .. 'Z', 'a' .. 'z';

my %digit62 = reverse %value62;

my $ksuid_to_string = Sub::Util::set_subname( ksuid_to_string => sub {
    my @parts  = unpack 'N*', $_[0];
    my @digits = (0) x 27;

    for ( 0 .. $#digits ) {
        my @quotient;
        my $remainder = 0;

        for (@parts) {
            my $value  = int($_) + int($remainder) * KSUID_BASE;
            my $digit  = $value / STRING_BASE;
            $remainder = $value % STRING_BASE;

            push @quotient, $digit
                if @quotient || $digit;
        }

        # We push into this in reverse order for convenience
        $digits[$_] = $remainder;

        @parts = @quotient or last;
    }

    join '', @digit62{ reverse @digits };
});

my $string_to_ksuid = Sub::Util::set_subname( string_to_ksuid => sub {
    my @digits = (0) x 20;
    my @parts = @value62{ split //, $_[0] };

    die unless @parts == 27;

    my $n = 0;
    while ( @parts ) {
        my @quotient;
        my $remainder = 0;

        for (@parts) {
            my $value  = int($_) + int($remainder) * STRING_BASE;
            my $digit  = $value / KSUID_BASE;
            $remainder = $value % KSUID_BASE;

            push @quotient, $digit % 256
                if @quotient || $digit;
        }

        $digits[$n++] = ( $remainder       ) % 256;
        $digits[$n++] = ( $remainder >> 8  ) % 256;
        $digits[$n++] = ( $remainder >> 16 ) % 256;
        $digits[$n++] = ( $remainder >> 24 ) % 256;

        @parts = @quotient or last;
        last if $n == @digits;
    }

    pack 'C*', reverse @digits;
});

my $time_of_ksuid = Sub::Util::set_subname( time_of_ksuid => sub {
    EPOCH + unpack 'N', substr( $_[0], 0, 4 );
});

my $payload_of_ksuid = Sub::Util::set_subname( payload_of_ksuid => sub {
    substr $_[0], 4, 20;
});

my $next_ksuid = Sub::Util::set_subname( next_ksuid => sub {
    my $k = shift;

    my $time = $k->$time_of_ksuid;
    my $data = $k->$payload_of_ksuid;

    # Overflow
    return create_ksuid( $time + 1, "\x00" x 16 )
        if $data eq ( "\xff" x 16 );

    my @parts = reverse $data =~ /[\w\W]{4}/g;
    for (@parts) {
        $_ = pack 'N', unpack('N', $_) + 1;
        last unless $_ eq "\x00" x 4;
    }

    create_ksuid( $time, join '', reverse @parts );
});

my $previous_ksuid = Sub::Util::set_subname( previous_ksuid => sub {
    my $k = shift;

    my $time = $k->$time_of_ksuid;
    my $data = $k->$payload_of_ksuid;

    # Overflow
    return create_ksuid( $time - 1, "\xff" x 16 )
        if $data eq ( "\x00" x 16 );

    my @parts = reverse $data =~ /[\w\W]{4}/g;
    for (@parts) {
        $_ = pack 'N', unpack('N', $_) - 1;
        last unless $_ eq "\xff" x 4;
    }

    create_ksuid( $time, join '', reverse @parts );
});

# Distrustful user-facing functions

sub create_ksuid {
    my ( $time, $payload ) = @_;

    if ( $time ) {
        Carp::croak 'Timestamp must be numeric'
            unless Scalar::Util::looks_like_number($time);

        Carp::croak "Timestamp must be between 0 and "
            . MAX_TIME . ", got $time instead"
            if $time < 0 || $time > MAX_TIME;
    }

    if ( $payload ) {
        my $length = length $payload;
        Carp::croak "KSUID payloads must have 16 bytes, got instead $length"
            if $length != 16;
    }

    $time    ||= time;
    $payload ||= Crypt::URandom::urandom(16);

    pack( 'N', $time - EPOCH ) . $payload;
}

sub create_ksuid_string {
    create_ksuid(@_)->$ksuid_to_string
}

sub ksuid_to_string {
    Carp::croak 'Expected a valid KSUID, got instead '
        . $_[0]->$safely_printed
        unless is_ksuid($_[0]);

    goto $ksuid_to_string;
}

sub string_to_ksuid {
    Carp::croak 'Expected a string KSUID, got instead '
        . $_[0]->$safely_printed
        unless is_ksuid_string($_[0]);

    goto $string_to_ksuid;
}

sub time_of_ksuid {
    Carp::croak 'Expected a valid KSUID, got instead '
        . $_[0]->$safely_printed
        unless is_ksuid($_[0]);

    goto $time_of_ksuid;
}

sub payload_of_ksuid {
    Carp::croak 'Expected a valid KSUID, got instead '
        . $_[0]->$safely_printed
        unless is_ksuid($_[0]);

    goto $payload_of_ksuid;
}

sub next_ksuid {
    Carp::croak 'Expected a valid KSUID, got instead '
        . $_[0]->$safely_printed
        unless is_ksuid($_[0]);

    goto $next_ksuid;
}

sub previous_ksuid {
    Carp::croak 'Expected a valid KSUID, got instead '
        . $_[0]->$safely_printed
        unless is_ksuid($_[0]);

    goto $previous_ksuid;
}

sub is_ksuid {
    return defined $_[0]
        && length $_[0] == 20
        && $_[0] ge MIN
        && $_[0] le MAX;
}

sub is_ksuid_string {
    return defined $_[0]
        && length $_[0] == 27
        && $_[0] ge MIN_STRING
        && $_[0] le MAX_STRING
        && $_[0] !~ /[^0-9A-Za-z]/;
}

## OO interface

use overload
    '""'  => \&string,
    'cmp' => Sub::Util::set_subname( cmp => sub {
        $_[0]->bytes cmp $_[1]->bytes
    }),
;

sub new {
    my $class = shift;
    my $self  = create_ksuid(@_);
    bless \$self, $class;
}

sub parse {
    my $class = shift;
    my $self  = string_to_ksuid(@_);
    bless \$self, $class;
}

sub bytes    { ${ $_[0] }                       }
sub payload  { $_[0]->bytes->$payload_of_ksuid  }
sub string   { $_[0]->bytes->$ksuid_to_string   }
sub time     { $_[0]->bytes->$time_of_ksuid     }

sub next {
    my $self = $_[0];
    my $next = $self->bytes->$next_ksuid;
    bless \$next, ref $self;
}

sub previous {
    my $self = $_[0];
    my $prev = $self->bytes->$previous_ksuid;
    bless \$prev, ref $self;
}

# Clean our namespace
delete @Data::KSUID::{qw(
    MAX_TIME
    EPOCH
    KSUID_BASE
    STRING_BASE
)};

1;
