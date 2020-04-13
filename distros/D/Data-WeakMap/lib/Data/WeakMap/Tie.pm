package Data::WeakMap::Tie;

use strict;
use warnings;

require Tie::Hash;
our @ISA = 'Tie::StdHash';

use Data::WeakMap::Item::Tie;

use Carp 'croak';
use Scalar::Util 'weaken';

sub TIEHASH {
    bless {}, shift;
}

sub STORE {
    my ($self, $key, $value) = @_;

    croak 'key is not a reference,' unless ref $key ne '';

    weaken(my $c = $key);
    my $c_tie = tie $c, 'Data::WeakMap::Item::Tie', \$c, $self, $value;

    $self->{$key} = $c_tie;
}

sub FETCH {
    my ($self, $key) = @_;

    if (my $c_tie = $self->{$key}) {
        return $c_tie->{value};
    } else {
        return undef;
    }
}

sub FIRSTKEY {
    my ($self) = @_;

    my $z = keys %$self;

    my $self_key = each %$self;

    return defined $self_key ? ${ $self->{$self_key}{ref_c} } : undef;
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;

    my $self_key = each %$self;

    if (! defined $self_key) {
        weaken(${ $_->{ref_c} }) foreach values %$self;
        return undef;
    }
    return ${ $self->{$self_key}{ref_c} };
}

1;
