package Claude::Agent::Error;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::Error',
        'message:Str:required',
    );
}

use overload
    '""' => sub { shift->to_string },
    fallback => 1;

sub throw {
    my ($class, %args) = @_;
    die $class->new(%args);
}

sub to_string {
    my ($self) = @_;
    my $type = ref($self);
    $type =~ s/^Claude::Agent::Error:://;
    $type ||= 'Error';
    return "$type: " . $self->message;
}

use Claude::Agent::Error::CLINotFound;
use Claude::Agent::Error::ProcessError;
use Claude::Agent::Error::JSONDecodeError;
use Claude::Agent::Error::TimeoutError;
use Claude::Agent::Error::PermissionDenied;
use Claude::Agent::Error::HookError;

1;

__END__

=head1 NAME

Claude::Agent::Error - Exception classes for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Error;

    eval {
        ...
    };
    if (my $err = $@) {
        if (ref $err && $err->isa('Claude::Agent::Error::CLINotFound')) {
            die "Please install Claude CLI first";
        }
        die $err;
    }

=head1 DESCRIPTION

This module provides the exception classes thrown by the Claude Agent SDK.
Every error stringifies to C<Type: message>, where the type is the class
name without the C<Claude::Agent::Error::> prefix.

Loading this module loads every subclass listed below.

=head1 ERROR CLASSES

=over 4

=item * L<Claude::Agent::Error::CLINotFound> - CLI not found

=item * L<Claude::Agent::Error::ProcessError> - Process execution failed

=item * L<Claude::Agent::Error::JSONDecodeError> - JSON parsing failed

=item * L<Claude::Agent::Error::TimeoutError> - Operation timed out

=item * L<Claude::Agent::Error::PermissionDenied> - Permission denied

=item * L<Claude::Agent::Error::HookError> - Hook execution failed

=back

=head1 ATTRIBUTES

=head2 message

The error description. Required.

=head1 METHODS

=head2 new

    my $err = Claude::Agent::Error->new(message => 'something failed');

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 throw

    Claude::Agent::Error->throw(message => 'something failed');

Constructs the error and dies with it.

=head2 to_string

    my $text = $err->to_string;

Returns C<Type: message>. The C<""> operator is overloaded to call it.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
