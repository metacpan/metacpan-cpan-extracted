package Command::Interactive::Interaction;

use strict;
use warnings;

our $VERSION = 1.1;

use Moose;

=head1 NAME

Command::Interactive::Interaction - Models a result that may occur during an
interactive command invoked by Command::Interactive.

=head1 SYNOPSIS

This module is used to describe a single expected result (a string or a regex)
that can appear in the output of a system command invoked by
Command::Interactive. Optionally this class can model the string to be sent in response to the expected string (e.g., a password in response to a password prompt).

    use Command::Interactive::Interaction;
    my $password_prompt = Command::Interactive->new({
        expected_string => 'password:',
        response        => 'secret',
    });

    my $result = Command::Interactive->new({
        interactions => [ $password_prompt ],
    })-run("ssh user@somehost");

=head1 FIELDS

=head2 expected_string (REQUIRED)

The string (or regular expression) that Command::Interactive should look for in the output of the invoked command. To specify a regular expression, also set C<is_regex> to a true value.

=cut

has expected_string => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

=head2 response

Optionally, a response that can be sent after the expected_string is found in the command output. This string will include a newline if C<send_newline_with_response> is true.

=cut

has response => (
    is  => 'rw',
    isa => 'Str',
);

=head2 expected_string_is_regex (DEFAULT: FALSE)

Whether the C<expected_string> should be treated as a Perl regular expression. 

=cut

has expected_string_is_regex => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 send_newline_with_response (DEFAULT: TRUE)

Whether to send a newline at the end of the C<response> string when expected_string is discovered.

=cut

has send_newline_with_response => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

=head2 is_error (DEFAULT: FALSE)

Whether expected_string should be considered the indication of an error. If
is_error is set to true and Command::Interactive encounters
<expected_string>, processing of the invoked command will cease and
Command::Interactive will return an error result indicating the discovered value of <expected_string> that was understood to indicate an error.

=cut

has is_error => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 is_required (DEFAULT: FALSE)

Whether the C<expected_string> must be seen prior to the termination of the
command invoked by Command::Interactive. If this field is set to true and
C<expected_string> is not encountered prior to the end of the command output,
Command::Interactive will return an error result indicating that the command was not successful due to the fact that C<expected_string> was not found.

=cut

has is_required => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 max_allowed_occurrences (DEFAULT: 1)

The number of times that C<expected_string> can be found before
Command::Interactive returns an error. This field exists to prevent infinite loops in which (e.g.) a password is requested over and over. To disable this checking altogether, set C<max_allowed_occurrences> to 0. You may also set it to a higher value if you actually expect the same string to appear more than once.

=cut

has max_allowed_occurrences => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

=head1 METHODS

=head2 actual_response_to_send

Returns the actual string to send in response to discovering C<expected_string>, including any newlines that might be added to the end of the string.

=cut 

sub actual_response_to_send {
    my $self = shift;
    return $self->response
      ? $self->response . ($self->send_newline_with_response ? "\n" : '')
      : undef;
}

=head2 type

Returns 'string' or 'regex' based on C<is_regex>. Useful in routines internal to
Command::Interactive ewhich create human-readable explanations of failure conditions.

=cut

sub type {
    my $self = shift;
    return $self->expected_string_is_regex ? 'regex' : 'string';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Binary.com, <perl@binary.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

