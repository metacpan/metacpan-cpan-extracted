package Claude::Agent::Hook::Result;

use 5.020;
use strict;
use warnings;

use Types::Common -types;

=head1 NAME

Claude::Agent::Hook::Result - Hook result factory for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Hook::Result;

    # In a hook callback:
    return Claude::Agent::Hook::Result->proceed();

    return Claude::Agent::Hook::Result->allow(
        updated_input => { command => 'safe command' },
        reason => 'Modified for safety',
    );

    return Claude::Agent::Hook::Result->deny(
        reason => 'Operation not permitted',
    );

=head1 DESCRIPTION

Factory methods for creating hook results.

=head1 METHODS

=head2 proceed

    my $result = Claude::Agent::Hook::Result->proceed();

Continue (proceed) without modification.

=cut

sub proceed {
    return { decision => 'continue' };
}

=head2 allow

    my $result = Claude::Agent::Hook::Result->allow(
        updated_input => \%new_input,
        reason => 'reason string',
    );

Allow the operation, optionally with modified input.

=cut

sub allow {
    my ($class, %args) = @_;
    return {
        decision      => 'allow',
        updated_input => $args{updated_input},
        reason        => $args{reason},
    };
}

=head2 deny

    my $result = Claude::Agent::Hook::Result->deny(
        reason => 'reason string',
    );

Deny the operation.

=cut

sub deny {
    my ($class, %args) = @_;
    return {
        decision => 'deny',
        reason   => $args{reason},
    };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
