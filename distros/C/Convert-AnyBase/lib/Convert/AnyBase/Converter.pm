package Convert::AnyBase::Converter;

use Moose;
use Convert::AnyBase::Carp;

use Scalar::Util qw/looks_like_number/;

has set => qw/is ro required 1 isa Str/;
has base => qw/is ro lazy_build 1/, init_arg => undef;
sub _build_base {
    return length shift->set;
}
has normalize => qw/is ro isa CodeRef/;

sub encode {
    my $self = shift;
    my $number = shift;

    croak "Can't encode \"$number\"" unless looks_like_number $number;

    my $set = $self->set;
    my $base = $self->base;

    my ( $done, @string );

    while ( ! $done ) {
        my $quotient = int( $number / $base );
        my $remainder;
        if ( $quotient != 0 ) {
            $remainder = $number % $base;
            $number = $quotient;
        }
        else {
            $remainder = $number;
            $done = 1;
        }

        push @string, substr $set, $remainder, 1;
    }

    return join '', reverse @string;
}

sub decode {
    my $self = shift;
    my $string = shift;

    my $set = $self->set;
    my $base = $self->base;
    my $normalize = $self->normalize;

    if ( $normalize ) {
        local $_ = $string;
        $string = $normalize->();
    }

    my $number = 0;
    my $offset = 1;
    my @string = reverse split m//, $string;

    for ( @string ) {
        my $value = index $set, $_;
        croak "Unknown character $_ in input \"$string\"\n" if -1 == $value;
        $number += ( $value * $offset );
        $offset *= $base;
    }

    return $number;
}

1;
