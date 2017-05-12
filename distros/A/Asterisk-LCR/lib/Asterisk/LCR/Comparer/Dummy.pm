=head1 NAME

Asterisk::LCR::Comparer::Dummy - Dummy Route Comparer for Asterisk::LCR


=head1 SUMMARY

This is a very dumb comparer for Asterisk::LCR::Route object.


=head1 ATTRIBUTES

none.


=head1 METHODS


=cut
package Asterisk::LCR::Comparer::Dummy;
use base qw /Asterisk::LCR::Comparer/;
use warnings;
use strict;

=head2 $self->sortme ($object1, $object2);

Simply compares $object1->rate() with $object2->rate().

Doesn't care about time increments or even rate currency(!).

Pretty dumb... it would be nice to have better rate comparers
but it's a start and can be overriden...

=cut
sub sortme
{
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    my $rate1 = $arg1->rate();
    my $rate2 = $arg2->rate();

    return +1 if ($rate1 > $rate2);
    return -1 if ($rate2 > $rate1);
    return 0;
}


1;


__END__
