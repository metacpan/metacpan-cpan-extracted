package Claude::Agent::Error;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'message!' => Str;

=head1 NAME

Claude::Agent::Error - Exception classes for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Error;
    use Try::Tiny;

    try {
        # ... code that might fail ...
    }
    catch {
        if ($_->isa('Claude::Agent::Error::CLINotFound')) {
            die "Please install Claude CLI first";
        }
    };

=head1 DESCRIPTION

This module provides exception classes for error handling in the
Claude Agent SDK.

=head1 ERROR CLASSES

=over 4

=item * L<Claude::Agent::Error::CLINotFound> - CLI not found

=item * L<Claude::Agent::Error::ProcessError> - Process execution failed

=item * L<Claude::Agent::Error::JSONDecodeError> - JSON parsing failed

=item * L<Claude::Agent::Error::TimeoutError> - Operation timed out

=item * L<Claude::Agent::Error::PermissionDenied> - Permission denied

=item * L<Claude::Agent::Error::HookError> - Hook execution failed

=back

=cut

sub throw {
    my ($class, %args) = @_;
    die $class->new(%args);
}

sub to_string {
    my ($self) = @_;
    # Use short error type for cleaner output
    my $type = ref($self);
    $type =~ s/^Claude::Agent::Error:://;
    $type ||= 'Error';
    return "$type: " . $self->message;
}

use overload
    '""' => sub { shift->to_string },
    fallback => 1;

# Load subclasses
use Claude::Agent::Error::CLINotFound;
use Claude::Agent::Error::ProcessError;
use Claude::Agent::Error::JSONDecodeError;
use Claude::Agent::Error::TimeoutError;
use Claude::Agent::Error::PermissionDenied;
use Claude::Agent::Error::HookError;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
