package Claude::Agent::Permission;

use 5.020;
use strict;
use warnings;

use Exporter qw(import);
use Scalar::Util qw(blessed);
use Const::XS qw(const);
use Claude::Agent::Types;
use Claude::Agent::Permission::Result;
use Claude::Agent::Permission::Result::Allow;
use Claude::Agent::Permission::Result::Deny;
use Claude::Agent::Permission::Context;

const our $MODE_DEFAULT     => 'default';
const our $MODE_ACCEPT_EDIT => 'acceptEdits';
const our $MODE_BYPASS      => 'bypassPermissions';
const our $MODE_DONT_ASK    => 'dontAsk';
const our $MODE_PLAN        => 'plan';
const our $MODE_AUTO        => 'auto';
const our $MODE_MANUAL      => 'manual';

our @EXPORT_OK = qw(
    $MODE_DEFAULT $MODE_ACCEPT_EDIT $MODE_BYPASS $MODE_DONT_ASK
    $MODE_PLAN $MODE_AUTO $MODE_MANUAL
);

sub allow {
    my ($class, %args) = @_;
    return Claude::Agent::Permission::Result::Allow->new(
        Claude::Agent::Types::defined_args(
            updated_input       => $args{updated_input},
            updated_permissions => $args{updated_permissions},
        )
    );
}

sub deny {
    my ($class, %args) = @_;
    return Claude::Agent::Permission::Result::Deny->new(
        Claude::Agent::Types::defined_args(
            message   => $args{message},
            interrupt => $args{interrupt},
        )
    );
}

sub coerce {
    my ($class, $thing) = @_;
    return $thing if blessed($thing) && $thing->isa('Claude::Agent::Permission::Result');
    return unless ref $thing eq 'HASH';
    my $behavior = $thing->{behavior} // '';
    if ($behavior eq 'allow') {
        return $class->allow(
            updated_input       => $thing->{updated_input} // $thing->{updatedInput},
            updated_permissions => $thing->{updated_permissions} // $thing->{updatedPermissions},
        );
    }
    if ($behavior eq 'deny') {
        return $class->deny(
            message   => $thing->{message},
            interrupt => $thing->{interrupt},
        );
    }
    return;
}

1;

__END__

=head1 NAME

Claude::Agent::Permission - Permission handling for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Permission;

    my $options = Claude::Agent::Options->new(
        can_use_tool => sub {
            my ($tool_name, $input, $context) = @_;
            if ($tool_name eq 'Bash' && $input->{command} =~ /rm/) {
                return Claude::Agent::Permission->deny(
                    message => "Delete commands not allowed"
                );
            }
            return Claude::Agent::Permission->allow;
        },
    );

=head1 DESCRIPTION

The CLI asks the C<can_use_tool> callback whenever it would otherwise
prompt a person for permission: a tool that no rule, mode or
C<allowed_tools> entry already allows. Hooks run first, so a PreToolUse
hook that allows or denies the tool pre-empts the callback. This module
provides the factories for the callback's answers and the constants for
the permission modes.

=head1 PERMISSION MODES

=over 4

=item * default - Normal permission behavior

=item * acceptEdits - Auto-accept file edits

=item * bypassPermissions - Bypass all permission checks

=item * dontAsk - Deny anything that would prompt

=item * plan - Read-only planning

=item * auto - Let the CLI's classifier decide

=item * manual - Ask for everything

=back

Exported on request as C<$MODE_DEFAULT>, C<$MODE_ACCEPT_EDIT>,
C<$MODE_BYPASS>, C<$MODE_DONT_ASK>, C<$MODE_PLAN>, C<$MODE_AUTO> and
C<$MODE_MANUAL>. The same list is C<@Claude::Agent::Types::PERMISSION_MODES>,
which the C<permission_mode> option is validated against.

=head1 PERMISSION CLASSES

=over 4

=item * L<Claude::Agent::Permission::Result> - Base result class

=item * L<Claude::Agent::Permission::Result::Allow> - Allow result

=item * L<Claude::Agent::Permission::Result::Deny> - Deny result

=item * L<Claude::Agent::Permission::Context> - Callback context

=back

=head1 CLASS METHODS

=head2 allow

    my $result = Claude::Agent::Permission->allow(
        updated_input       => $input,
        updated_permissions => \@updates,
    );

Create an allow result. Both arguments are optional; when
C<updated_input> is not given the tool runs with the input it asked about.

=head2 deny

    my $result = Claude::Agent::Permission->deny(
        message   => "Not allowed",
        interrupt => 1,
    );

Create a deny result. C<message> is shown to the model; C<interrupt> ends
the turn. Both are optional.

=head2 coerce

    my $result = Claude::Agent::Permission->coerce($thing);

Returns C<$thing> when it is already a result object, builds one from a
hashref with a C<behavior> key of C<allow> or C<deny> (taking
C<updated_input>/C<updatedInput>, C<updated_permissions>/C<updatedPermissions>,
C<message> and C<interrupt>), and returns undef for anything else.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
