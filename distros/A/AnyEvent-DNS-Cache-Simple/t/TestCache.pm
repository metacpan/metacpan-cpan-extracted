package t::TestCache;

use strict;
use warnings;
use base qw/Cache::Memory::Simple/;

our %HIT;
sub get {
    my ($self, $key) = @_;
    my $ret = $self->SUPER::get($key);
    if ( defined $ret ) {
        $HIT{$key}++;
    }
    return $ret;
}

1;
