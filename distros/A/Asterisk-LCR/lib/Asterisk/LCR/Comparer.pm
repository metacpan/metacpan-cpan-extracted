=head1 NAME

Asterisk::LCR::Comparer - Generic Route Comparer for Asterisk::LCR


=head1 SUMMARY

This is a generic class for any Comparer object. Asterisk::LCR::Comparer
objects must implement the sortme() method for it to function properly.


=head1 ATTRIBUTES

none.


=head1 METHODS


=cut
package Asterisk::LCR::Comparer;
use base qw /Asterisk::LCR::Object/;
use Config::Mini;
use warnings;
use strict;


=head2 $self->normalize ($rate);

Turns $rate into a 1/1, base currency rate.

=cut
sub normalize
{
    my $self = shift;
    my $rate = shift;
    $rate->{first_increment} = 1;
    $rate->{connection_fee}  = 0;
    $rate->{increment}       = 1;
    $rate->{currency}        = Config::Mini::get ('comparer')->currency();
}


=head2 $self->sortme ($object1, $object2);

This method needs to be implemented by subclasses.

Should:

=over 4

=item return +1 if $object1 is greater than $object2

=item return -1 if $object1 is smaller than $object2

=item return 0 if $object1 is equal to $object2

=back

=cut
sub sortme 
{
    die "Asterisk::LCR::Comparer::sortme() is a virtual method";
}


=head2 $self->eq ($object1, $object2);

Returns 1 if both objects are equal, 0 otherwise.

=cut
sub eq
{
    my $self = shift;
    return $self->sortme (@_) == 0;
}


=head2 $self->ne ($object1, $object2);

Returns 1 if both objects are not equal, 0 otherwise.

=cut
sub ne
{
    my $self = shift;
    return not $self->eq (@_);
}


=head2 $self->gt ($object1, $object2);

Returns 1 if $object1 is strictly greater than $object2, 0 otherwise.

=cut
sub gt
{
    my $self = shift;
    return $self->sortme (@_) > 0;
}


=head2 $self->ge ($object1, $object2);

Returns 1 if $object1 is greater or equals than $object2, 0 otherwise.

=cut
sub ge
{
    my $self = shift;
    return $self->gt (@_) or $self->eq (@_);
}


=head2 $self->lt ($object1, $object2);

Returns 1 if $object1 is strictly smaller than $object2, 0 otherwise.

=cut
sub lt
{
    my $self = shift;
    return $self->sortme (@_) < 0;
}


=head2 $self->ge ($object1, $object2);

Returns 1 if $object1 is smaller or equals than $object2, 0 otherwise.

=cut
sub le
{
    my $self = shift;
    return $self->lt (@_) or $self->eq (@_);
}


1;


__END__
