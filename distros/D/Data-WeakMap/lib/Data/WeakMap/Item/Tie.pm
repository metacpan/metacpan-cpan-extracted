package Data::WeakMap::Item::Tie;

use strict;
use warnings;

use Scalar::Util 'weaken';

sub TIESCALAR {
    my ($class, $ref_c, $hash, $value) = @_;

    my $thing = {
        ref_c => $ref_c,
        key   => "$$ref_c",
        value => $value,
    };
    weaken($thing->{hash} = $hash);

    bless $thing, $class;
}

sub STORE {
    my ($self, $value) = @_;

    my $hash = $self->{hash} // return; # is 'return' needed? the test still fails sometimes
    delete $hash->{ $self->{key} };
}

sub FETCH {
    my ($self) = @_;

    return ${ $self->{ref_c} };
}

sub DESTROY {
    # avoid random error of type: "Can't call method "STORE" on an undefined value during global destruction."
    if (${^GLOBAL_PHASE} eq 'DESTRUCT') {
        untie ${ shift()->{ref_c} };
    }
}

1;
