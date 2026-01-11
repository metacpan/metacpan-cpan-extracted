package Claude::Agent::Permission;

use 5.020;
use strict;
use warnings;

use Exporter qw(import);
use Types::Common -types;

# Load subclasses
use Claude::Agent::Permission::Result;
use Claude::Agent::Permission::Result::Allow;
use Claude::Agent::Permission::Result::Deny;
use Claude::Agent::Permission::Context;

=head1 NAME

Claude::Agent::Permission - Permission handling for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Permission;

    # In a can_use_tool callback:
    my $options = Claude::Agent::Options->new(
        can_use_tool => sub {
            my ($tool_name, $input, $context) = @_;

            if ($tool_name eq 'Bash' && $input->{command} =~ /rm/) {
                return Claude::Agent::Permission->deny(
                    message => "Delete commands not allowed"
                );
            }

            return Claude::Agent::Permission->allow(
                updated_input => $input
            );
        },
    );

=head1 DESCRIPTION

This module provides permission handling utilities for the Claude Agent SDK,
including factory methods for creating permission responses.

=head1 PERMISSION MODES

=over 4

=item * default - Normal permission behavior

=item * acceptEdits - Auto-accept file edits

=item * bypassPermissions - Bypass all permission checks

=item * dontAsk - Auto-deny unless explicitly allowed

=back

=head1 PERMISSION CLASSES

=over 4

=item * L<Claude::Agent::Permission::Result> - Base result class

=item * L<Claude::Agent::Permission::Result::Allow> - Allow result

=item * L<Claude::Agent::Permission::Result::Deny> - Deny result

=item * L<Claude::Agent::Permission::Context> - Callback context

=back

=cut

# Permission mode constants
use Const::XS qw(const);
const our $MODE_DEFAULT     => 'default';
const our $MODE_ACCEPT_EDIT => 'acceptEdits';
const our $MODE_BYPASS      => 'bypassPermissions';
const our $MODE_DONT_ASK    => 'dontAsk';

our @EXPORT_OK = qw(
    $MODE_DEFAULT $MODE_ACCEPT_EDIT $MODE_BYPASS $MODE_DONT_ASK
);

=head1 CLASS METHODS

=head2 allow

    my $result = Claude::Agent::Permission->allow(
        updated_input => $input,
    );

Create an "allow" permission result.

=head3 Arguments

=over 4

=item * updated_input - The (optionally modified) input to pass to the tool

=item * updated_permissions - Optional permissions update

=back

=cut

sub allow {
    my ($class, %args) = @_;

    return Claude::Agent::Permission::Result::Allow->new(
        updated_input       => $args{updated_input},
        updated_permissions => $args{updated_permissions},
    );
}

=head2 deny

    my $result = Claude::Agent::Permission->deny(
        message => "Not allowed",
    );

Create a "deny" permission result.

=head3 Arguments

=over 4

=item * message - Reason for denial (shown to Claude)

=item * interrupt - Optional, if true interrupts the entire query

=back

=cut

sub deny {
    my ($class, %args) = @_;

    return Claude::Agent::Permission::Result::Deny->new(
        message   => $args{message},
        interrupt => $args{interrupt},
    );
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
