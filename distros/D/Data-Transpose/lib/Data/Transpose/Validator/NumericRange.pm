package Data::Transpose::Validator::NumericRange;
use strict;
use warnings;

use Moo;
extends 'Data::Transpose::Validator::Base';
use Scalar::Util qw/looks_like_number/;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

=head1 NAME

Data::Transpose::Validator::NumericRange - Validate numbers in a range

=head1 METHODS

=head2 new(min => $min, max => $max, integer => $bool)

Constructor, setting the minimum, the maximum and the C<integer>
option, which will validate only integers.

=cut


has min => (is => 'rw',
            isa => Num,
            required => 1);
has max => (is => 'rw',
            isa => Num,
            required => 1);
has integer => (is => 'rw',
                isa => Bool,
                default => sub { 0 },
               );


=head2 is_valid($number)

The validator. Returns a true value if the number is in the range
passed to the constructor.

=cut


sub is_valid {
    my ($self, $arg) = @_;
    $self->reset_errors;
    $self->error(["undefined", "Not defined"]) unless defined $arg;
    $self->error(["notanumber", "Not a number"]) unless looks_like_number($arg);
    if ($self->integer) {
        $self->error(["notinteger", "Not an integer"]) unless $arg =~ m/^\d+$/;
    }
    return undef if $self->error;
    my $min = $self->min;
    my $max = $self->max;
    if ($arg < $min or $arg > $max) {
        $self->error(["outofrange", "Value is out of range ($min/$max)"])
    }
    $self->error? return 0 : return 1;
}

=head1 INTERNAL ACCESSORS

=head2 min

Return the minimum

=head2 min

Return the maximum

=head2 integer

Return true if we have to validate only integers

=cut


1;
