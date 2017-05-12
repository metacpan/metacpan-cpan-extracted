package App::RoboBot::Nick;
$App::RoboBot::Nick::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::ClassAttribute;
use MooseX::SetOnce;

has 'id' => (
    is        => 'rw',
    isa       => 'Int',
    traits    => [qw( SetOnce )],
    predicate => 'has_id',
);

has 'name' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_name',
);

has 'extradata' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'denied_functions' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    writer  => '_set_denied_functions',
);

has 'config' => (
    is       => 'ro',
    isa      => 'App::RoboBot::Config',
    required => 1,
);

has 'network' => (
    is        => 'ro',
    isa       => 'App::RoboBot::Network',
    predicate => 'has_network',
);

class_has 'log' => (
    is        => 'rw',
    predicate => 'has_logger',
);

sub BUILD {
    my ($self) = @_;

    $self->log($self->config->bot->logger('core.nick')) unless $self->has_logger;

    $self->log->debug('Nick object construction requested.');

    unless ($self->has_id) {
        die $self->log->fatal('Invalid nick object creation (missing both ID and name).') unless $self->has_name;

        my $res = $self->config->db->do(q{
            select id
            from nicks
            where lower(name) = lower(?)
        }, $self->name);

        if ($res && $res->next) {
            $self->log->debug(sprintf('Nick object creation for %s located existing ID (%d).', $self->name, $res->{'id'}));

            $self->id($res->{'id'});
        } else {
            $res = $self->config->db->do(q{
                insert into nicks ??? returning id
            }, { name => $self->name });

            if ($res && $res->next) {
                $self->log->debug(sprintf('New nick record created for %s with ID %d.', $self->name, $res->{'id'}));

                $self->id($res->{'id'});
            }
        }

        die $self->log->fatal('Could not generate nick ID.') unless $self->has_id;
    }

    # TODO basic normalization of nicks (removing trailing underscores and single
    # digits from automatic nick renames for dupe connections)

    $self->update_permissions;
}

sub update_permissions {
    my ($self) = @_;

    $self->log->debug(sprintf('Permissions update request for nick %s.', $self->name));

    # TODO: Restore old functionality of per-server permissions. Pre-AnyEvent
    #       the information to do so was missing, but now we have it back.

    $self->log->debug('Collecting default permissions.');

    my %denied;

    my $res = $self->config->db->do(q{
        select command, granted_by
        from auth_permissions
        where nick_id is null and state = 'deny'
    });

    if ($res) {
        while ($res->next) {
            $denied{$res->{'command'}} = $res->{'granted_by'};
        }
    }

    $self->log->debug('Collecting nick-specific permissions.');

    $res = $self->config->db->do(q{
        select command, granted_by, state
        from auth_permissions
        where nick_id = ?
    }, $self->id);

    if ($res) {
        while ($res->next) {
            if ($res->{'state'} eq 'allow') {
                delete $denied{$res->{'command'}} if exists $denied{$res->{'command'}};
            } else {
                $denied{$res->{'command'}} = $res->{'granted_by'};
            }
        }
    }

    if (scalar(keys(%denied)) > 0) {
        $self->log->debug(sprintf('Setting denied functions for %s to: %s', $self->name, (join(', ', sort keys %denied))));
    } else {
        $self->log->debug(sprintf('Nick %s has no defined functions.', $self->name));
    }

    $self->_set_denied_functions(\%denied);
}

__PACKAGE__->meta->make_immutable;

1;
