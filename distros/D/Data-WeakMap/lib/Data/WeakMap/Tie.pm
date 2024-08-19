package Data::WeakMap::Tie;
use 5.014;
use warnings FATAL => 'all';

use Scalar::Util 'weaken';
use Carp 'croak';

our $VERSION = "v0.0.4";

sub TIEHASH {
    my ($class, $mbp) = @_;

    my $self = [$mbp];
    weaken($self->[0]);

    bless $self, $class;
}

sub STORE {
    my ($self, $key, $value) = @_;

    croak 'key argument is not a ref' if ref $key eq '';

    my $struct = ${ $_[0][0] };

    weaken($struct->{tied_keys}{$key} = $key);
    $struct->{values}{$key} = $value;

    require Data::WeakMap::Key::Tie;
    tie $struct->{tied_keys}{$key}, 'Data::WeakMap::Key::Tie', $struct->{dummy}, $key;

    return $self;
}

sub FETCH {
    my ($self, $key) = @_;

    croak 'key argument is not a ref' if ref $key eq '';

    my $struct = ${ $_[0][0] };

    return $struct->{values}{$key};
}

sub DELETE {
    my ($self, $key) = @_;

    croak 'key argument is not a ref' if ref $key eq '' and caller ne 'Data::WeakMap::Key::Tie';

    my $struct = ${ $_[0][0] };

    my $ret = delete $struct->{values}{$key};
    delete $struct->{tied_keys}{$key};

    return $ret;
}

sub CLEAR {
    my ($self) = @_;

    my $struct = ${ $_[0][0] };

    %{ $struct->{$_} } = () foreach qw/ tied_keys values /;
}

sub EXISTS {
    my ($self, $key) = @_;

    croak 'key argument is not a ref' if ref $key eq '';

    my $struct = ${ $_[0][0] };

    return exists $struct->{tied_keys}{$key};
}

sub FIRSTKEY {
    my ($self) = @_;

    my $struct = ${ $_[0][0] };

    my $z = keys %{ $struct->{tied_keys} };

    return (each %{ $struct->{tied_keys} })[1];
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;

    my $struct = ${ $_[0][0] };

    weaken($struct->{tied_keys}{$lastkey});

    return (each %{ $struct->{tied_keys} })[1];
}

sub SCALAR {
    my ($self) = @_;

    my $struct = ${ $_[0][0] };

    return scalar %{ $struct->{tied_keys} };
}

1;
