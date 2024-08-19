package Data::WeakMap::Key::Tie;
use 5.014;
use warnings FATAL => 'all';

use Scalar::Util 'weaken';
use Carp 'croak';

our $VERSION = "v0.0.4";

sub TIESCALAR {
    my ($class, $weakmap, $key) = @_;

    my $self = { weakmap => $weakmap, prop => "$key", key => $key };
    weaken($self->{$_}) foreach qw/ weakmap key /;

    bless $self, $class;
}

sub FETCH {
    my ($self) = @_;

    return $self->{key};
}

sub STORE {
    my ($self) = @_;

    delete $self->{weakmap}{$self->{prop}};
}

1;
