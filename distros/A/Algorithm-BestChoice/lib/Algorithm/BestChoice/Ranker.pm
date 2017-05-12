package Algorithm::BestChoice::Ranker;

use Moose;

use Scalar::Util qw/looks_like_number/;

sub parse {
    my $class = shift;
    my $ranker = shift;

    return Algorithm::BestChoice::Ranker::Value->new( value => 0 ) unless defined $ranker;

    if (ref $ranker eq '' && looks_like_number $ranker) {
        return Algorithm::BestChoice::Ranker::Value->new( value => $ranker );
    }
    elsif (ref $ranker eq 'CODE') {
        return Algorithm::BestChoice::Ranker::Code->new( code => $ranker );
    }

    die "Don't understand ranker $ranker";
}

sub rank {
    die "Unspecific ranker can't rank";
}

package Algorithm::BestChoice::Ranker::Value;

use Moose;

extends qw/Algorithm::BestChoice::Ranker/;

has value => qw/is ro required 1 isa Num/;

sub rank {
    my $self = shift;
    return $self->value;
}

package Algorithm::BestChoice::Ranker::Code;

use Moose;

extends qw/Algorithm::BestChoice::Ranker/;

has code => qw/is ro required 1 isa CodeRef/;

sub rank {
    my $self = shift;
    my $key = shift;

    return $self->code( $key );
}

1;
