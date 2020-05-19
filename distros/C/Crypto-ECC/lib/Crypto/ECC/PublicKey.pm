package Crypto::ECC::PublicKey;
$Crypto::ECC::PublicKey::VERSION = '0.004';
use Moo;
use Crypto::ECC::Point;

with "Object::GMP";

has generator => ( is => 'ro' );
has point     => ( is => 'ro' );

my $Point = 'Crypto::ECC::Point';

sub BUILD {
    my ($self) = @_;

    my $n = $self->generator->order
      or die 'Generator Must have order.';

    my $p = $self->point;

    if ( $Point->cmp( $Point->mul( $n, $p ), $Point->infinity ) != 0 ) {
        die "Generator Point order is bad.";
    }

    if (   ( $p->x <=> 0 ) < 0
        || ( $n <=> $p->x ) <= 0
        || ( $p->y <=> 0 ) < 0
        || ( $n <=> $p->y ) <= 0 )
    {
        die "Generator Point has x and y out of range.";
    }
}

sub verifies {
    my ( $self, $hash, $signature ) = @_;

    my $_g = $self->generator;
    my $n  = $_g->order;

    my $r = $signature->r;
    my $s = $signature->s;

    if ( ( $r <=> 1 ) < 0 || ( $r <=> ( $n - 1 ) ) > 0 ) {
        return 0;
    }

    if ( ( $s <=> 1 ) < 0 || ( $s <=> ( $n - 1 ) ) > 0 ) {
        return 0;
    }

    my $c  = $s->copy->bmodinv($n);
    my $u1 = ( $hash * $c ) % $n;
    my $u2 = ( $r * $c ) % $n;
    my $xy =
      $Point->add( $Point->mul( $u1, $_g ), $Point->mul( $u2, $self->point ) );
    my $v = $xy->x % $n;

    return $v == $r;
}

sub hashref {
    my ( $self, %options ) = @_;
    my %hash = map { ; $_ => $self->$_->hashref(%options) } keys %$self;
    return \%hash;
}

1;
