package Data::Transpose::Validator::String;

use strict;
use warnings;
use base 'Data::Transpose::Validator::Base';

=head1 NAME

Data::Transpose::Validator::String Validator for strings

=cut

=head2 is_valid

Check with C<ref> if the argument is a string. Return true on success
(the length of the string). It fails on the empty string.

=cut

sub is_valid {
    my ($self, $string) = @_;
    $self->reset_errors;
    unless (defined $string) {
        $self->error(["undefined", "String is undefined"]);
        return 0;
    }
    unless (ref($string) eq '') {
        $self->error(["hash", "Not a string"]);
        return 0;
    }
    my $length = length($string);
    $self->error(["empty", "Empty string"]) unless $length;
    $self->error ? return 0 : return $length;
}

1;
