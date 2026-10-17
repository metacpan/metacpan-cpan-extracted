package Claude::Agent::Error::HookError;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Error;

BEGIN {
    Object::Proto::define('Claude::Agent::Error::HookError',
        extends => 'Claude::Agent::Error',
        'hook_event:Str:predicate',
        'original_error:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Error::HookError - Hook execution exception

=head1 DESCRIPTION

Thrown when a hook callback fails.
Stringifies as C<HookError: message>.

=head1 ATTRIBUTES

=head2 message

The error description. Required.

=head2 hook_event

The event that triggered the hook. Optional; C<has_hook_event> reports whether it was given.

=head2 original_error

The original error from the hook callback. Optional; C<has_original_error> reports whether it was given.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
