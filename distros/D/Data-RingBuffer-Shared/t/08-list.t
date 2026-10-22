use strict;
use warnings;
use Test::More;
use Data::RingBuffer::Shared;

for my $variant (qw(Int F64)) {
    my $class = "AdvancingRing::$variant";
    my $base = "Data::RingBuffer::Shared::$variant";
    no strict 'refs';
    @{"${class}::ISA"} = ($base);
    for my $method (qw(latest read_seq)) {
        my $read = $base->can($method);
        *{"${class}::$method"} = sub {
            my $self = shift;
            my $value = $read->($self, @_);
            $self->write($self->head);
            return $value;
        };
    }
    my $r = $class->new(undef, 8);
    is_deeply [$r->to_list], [], "$variant: empty list";
    $r->write($_) for 0..7;
    is_deeply [$r->to_list], [0..7], "$variant: list stays within its initial window as writes advance";
}

done_testing;
