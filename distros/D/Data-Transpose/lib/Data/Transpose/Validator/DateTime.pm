package Data::Transpose::Validator::DateTime;
use strict;
use warnings;

use base 'Data::Transpose::Validator::Base';
use DateTime::Format::ISO8601;
use Try::Tiny;

=head1 NAME

Data::Transpose::Validator::DateTime - Validator for DateTime

=head1 SYNOPSIS

    my $dt = Data::Transpose::Validator::DateTime->new;
    $dt->is_valid($date);

=head2 DESCRIPTION

This module uses optional module L<DateTime::Format::ISO8601>
to validate DateTime format.

=head2 is_valid($date)

The validator. Returns a true value if the input is in a valid
DateTime format.

=cut

sub is_valid {
    my ($self, $arg) = @_;
    $self->reset_errors;
    $self->error(["undefined", "Not defined"]) unless defined $arg;
    my $dt = try {
        DateTime::Format::ISO8601->parse_datetime( $arg );
    };
    $self->error(["notdatetime", "Not a valid DateTime format"]) unless $dt;
    $self->error ? return 0 : return 1;
}

1;
