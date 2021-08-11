package DNS::Unbound::AsyncQuery::AnyEventXSPromises;

use strict;
use warnings;

# This leaks; don’t use it.

use AnyEvent::XSPromises ();

our @ISA;

use parent 'DNS::Unbound::AsyncQuery';

BEGIN {
    push @ISA, 'AnyEvent::XSPromises::PromisePtr';
}

use constant _DEFERRED_CR => \&AnyEvent::XSPromises::deferred;

my ($new, $class);

sub _dns_unbound_then {

    # This hackery is here because AE::XSP doesn’t accept subclassing.

    $class = ref $_[0];

    bless $_[0], 'AnyEvent::XSPromises::PromisePtr';

    $new = bless( $_[0]->then(@_[1, 2]), $class );

    bless $_[0], $class;

    return $new;
}

1;
