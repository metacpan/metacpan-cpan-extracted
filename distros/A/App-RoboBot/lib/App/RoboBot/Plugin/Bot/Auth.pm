package App::RoboBot::Plugin::Bot::Auth;
$App::RoboBot::Plugin::Bot::Auth::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use App::RoboBot::Nick;

extends 'App::RoboBot::Plugin';

=head1 bot.auth

Provides functions for managing authorization lists, denying and allowing
access to specific functions for specific users.

=cut

has '+name' => (
    default => 'Bot::Auth',
);

has '+description' => (
    default => 'Provides functions for managing authorization lists, denying and allowing access to specific functions for specific users.',
);

=head2 auth-default

=head3 Description

Sets the default permission mode for a function on the current network.

=head3 Usage

<function name> <"allow" | "deny">

=head3 Examples

    (auth-default set-alarm deny)

=head2 auth-allow

=head3 Description

Grants permission for a user to call the specified function.

=head3 Usage

<function name> <nick>

=head3 Examples

    (auth-allow set-alarm Beauford)

=head2 auth-deny

=head3 Description

Revokes permission for a user to the specified function.

=head3 Usage

<function name> <nick>

=head3 Examples

    (auth-allow set-alarm Beauford)

=cut

has '+commands' => (
    default => sub {{
        'auth-default' => { method      => 'auth_default',
                            description => 'Sets the default permission mode for a function. All functions are assumed to be in "allow" mode unless set otherwise.',
                            usage       => '<function name> <allow | deny>' },

        'auth-allow' => { method      => 'auth_modify',
                          description => 'Marks the given nick as explicitly permitted to call the named function, even if the function is by default denied to all users.',
                          usage       => '<function name> <nick>' },

        'auth-deny' => { method      => 'auth_modify',
                         description => 'Explicitly blocks the given nick from calling the named function.',
                         usage       => '<function name> <nick>' },
    }},
);

sub auth_default {
    my ($self, $message, $command, $rpl, $function_name, $mode) = @_;

    unless (defined $function_name && defined $mode) {
        $message->response->raise('Must provide a function name and permission mode.');
        return;
    }

    $mode = lc($mode);

    unless ($mode eq 'allow' or $mode eq 'deny') {
        $message->response->raise('Only valid permission modes are "allow" and "deny".');
        return;
    }

    unless (exists $self->bot->commands->{lc($function_name)}) {
        $message->response->raise('The function "%s" is not known.', $function_name);
        return;
    }

    my $res = $self->bot->config->db->do(q{
        update auth_permissions
        set ???
        where network_id = ? and lower(command) = lower(?)
    }, { state => $mode, granted_by => $message->sender->id }, $message->network->id, $function_name);

    unless ($res && $res->count > 0) {
        $res = $self->bot->config->db->do(q{
            insert into auth_permissions ???
        }, {
            network_id => $message->network->id,
            command    => lc($function_name),
            state      => $mode,
            granted_by => $message->sender->id,
        });
    }

    $message->response->push(sprintf('Default permission for function "%s" have been set to: %s.', $function_name, $mode));
    return;
}

sub auth_modify {
    my ($self, $message, $command, $rpl, $function_name, $nick_name) = @_;

    my $mode = $command eq 'auth-allow' ? 'allow' : 'deny';

    unless (defined $function_name && defined $nick_name) {
        $message->response->raise('Must provide both a function name and a nick to %s permissions.', $mode);
        return;
    }

    unless (exists $self->bot->commands->{lc($function_name)}) {
        $message->response->raise('The function "%s" is not known.', $function_name);
        return;
    }

    my $nick = App::RoboBot::Nick->new( config => $self->bot->config, name => "$nick_name" );

    unless ($nick->has_id) {
        $message->response->raise('The nick %s is unfamiliar to me. I cannot modify permissions for them yet.', $nick_name);
        return;
    }

    my $res = $self->bot->config->db->do(q{
        update auth_permissions
        set ???
        where network_id = ? and nick_id = ? and lower(command) = lower(?)
    }, { state => $mode, granted_by => $message->sender->id }, $message->network->id, $nick->id, $function_name);

    unless ($res && $res->count > 0) {
        $res = $self->bot->config->db->do(q{
            insert into auth_permissions ???
        }, {
            network_id  => $message->network->id,
            nick_id    => $nick->id,
            command    => lc($function_name),
            state      => $mode,
            granted_by => $message->sender->id,
        });
    }

    $message->response->push(sprintf('The nick %s is now %s permission to run the function %s.', $nick->name, ($mode eq 'allow' ? 'allowed' : 'denied'), $function_name));
    return;
}

__PACKAGE__->meta->make_immutable;

1;
