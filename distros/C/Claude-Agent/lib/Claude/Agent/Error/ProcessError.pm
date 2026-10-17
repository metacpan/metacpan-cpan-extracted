package Claude::Agent::Error::ProcessError;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Error;

BEGIN {
    Object::Proto::define('Claude::Agent::Error::ProcessError',
        extends => 'Claude::Agent::Error',
        'exit_code:Int:predicate',
        'stderr:Str:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Error::ProcessError - Process execution exception

=head1 DESCRIPTION

Thrown when the Claude CLI process fails.
Stringifies as C<ProcessError: message>.

=head1 ATTRIBUTES

=head2 message

The error description. Required.

=head2 exit_code

Process exit code. Optional; C<has_exit_code> reports whether it was given.

=head2 stderr

Standard error output. Optional; C<has_stderr> reports whether it was given.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
