use utf8;
use strict;
use warnings;

package DR::Tnt::LowLevel::Connector;
use Mouse;
use DR::Tnt::Proto;
use List::MoreUtils 'any';
use feature 'state';
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use Data::Dumper;
use feature 'switch';
use Time::HiRes ();
use DR::Tnt::Dumper;
use Mouse::Util::TypeConstraints;
enum LLConnectorState => [
    'init',
    'connecting',
    'connected',
    'ready',
    'error'
];
no Mouse::Util::TypeConstraints;

has host        => is => 'ro', isa => 'Str', required => 1;
has port        => is => 'ro', isa => 'Str', required => 1;
has user        => is => 'ro', isa => 'Maybe[Str]';
has password    => is => 'ro', isa => 'Maybe[Str]';
has utf8        => is => 'ro', isa => 'Bool', default => 1;

has state =>
    is => 'rw',
    isa => 'LLConnectorState',
    default => 'init',
    trigger => sub {
        my ($self) = @_;
        goto $self->state;

        init:
            $self->last_error(undef);
            die 1;

        connecting: {
            $self->last_error(undef);
            $self->_clean_fh;
            $self->_active_sync({});
            $self->_watcher({});
            return;
        }

        connected:
            $self->last_error(undef);
            return;

        ready:
            $self->last_error(undef);
            return;

        error: {
            $self->_clean_fh;

            confess "Can't set state 'error' without last_error"
                unless $self->last_error;
           
            # on_handshake erorrs
            my $list = $self->_on_handshake;
            $self->_on_handshake([]);
            $_->(@{ $self->last_error }) for @$list;
           
            # waiter errors
            $list = $self->_watcher;
            $self->_watcher({});
            $_->(@{ $self->last_error }) for map { @$_ } values %$list;

            # unsent errors
            $list = $self->_unsent;
            $self->_unsent([]);
            $_->[-1](@{ $self->last_error }) for @$list;
            return;
        }
    };

has fh =>
    is      => 'ro',
    isa     => 'Maybe[Any]',
    clearer => '_clean_fh',
    writer  => '_set_fh';

has last_error_time => is => 'rw', isa => 'Num', default => 0;
has last_error      =>
    is      => 'rw',
    isa     => 'Maybe[ArrayRef]',
    trigger => sub { $_[0]->last_error_time(Time::HiRes::time) }
;

has greeting        => is => 'rw', isa => 'Maybe[HashRef]';
has rbuf            => is => 'rw', isa => 'Str', default => '';

has _unsent         => is => 'rw', isa => 'ArrayRef', default => sub {[]};
has _last_sync      => is => 'rw', isa => 'Int', default => 0;
has _active_sync    => is => 'rw', isa => 'HashRef', default => sub {{}};
has _watcher        => is => 'rw', isa => 'HashRef', default => sub {{}};
has _on_handshake   => is => 'rw', isa => 'ArrayRef', default => sub {[]};

sub next_sync {
    my ($self) = @_;

    for (my $sync = $self->_last_sync + 1;; $sync++) {
        $sync = 1 if $sync > 0x7FFF_FFFF;
        next if exists $self->_active_sync->{ $sync };
        $self->_last_sync($sync);
        $self->_active_sync->{ $sync } = 1;
        return $sync;
    }
}

sub connect {
    my ($self, $cb) = @_;

    if (any { $_ eq $self->state } 'init', 'error', 'ready') {
        $self->_clean_fh;
        $self->state('connecting');
        $self->_connect(sub {
            my ($state, $message) = @_;
            if ($state eq 'OK') {
                $self->state('connected');
            } else {
                # TODO connection error
                $self->last_error([$state, $message // "Can't connect to remote host"]);
                $self->state('error');
            }
            goto &$cb;
        });
        return;
    }
    $cb->(fatal => 'can not connect in state: ' . $self->state);
    return;
}

sub socket_error {
    my ($self, $message) = @_;
    $self->last_error([ER_SOCKET => $message // 'Socket error']);
    $self->state('error');
}

sub handshake {
    my ($self, $cb) = @_;

    goto $self->state;

    ready:
        $cb->(OK => 'Handshake was received', $self->greeting);
        return;

    init:
    connecting:
    connected:
        push @{ $self->_on_handshake } => $cb;
        return;

    error:
        $cb->(@{ $self->last_error });
        return;
}


sub send_request {
    my $cb = pop;
    my ($self, $name, @args) = @_;


    goto $self->state;


    error: {
        $cb->(@{ $self->last_error });
        return;
    }


    ready: {
        state $r = {
            select      => \&DR::Tnt::Proto::select,
            update      => \&DR::Tnt::Proto::update,
            insert      => \&DR::Tnt::Proto::insert,
            replace     => \&DR::Tnt::Proto::replace,
            delete      => \&DR::Tnt::Proto::del,
            call_lua    => \&DR::Tnt::Proto::call_lua,
            eval_lua    => \&DR::Tnt::Proto::eval_lua,
            ping        => \&DR::Tnt::Proto::ping,
            auth        => \&DR::Tnt::Proto::auth,
        };

        croak "unknown method $name" unless exists $r->{$name};

        state $ra = {
            auth    => sub {
                my ($self, $schema_id, $user, $password) = @_;
                return (
                    $schema_id,
                    $user // $self->user,
                    $password // $self->password,
                    $self->greeting->{salt},
                );
            }
        };
        
        @args = $ra->{$name}->($self, @args) if exists $ra->{$name};
        
        my $sync = $self->next_sync;
        my $pkt = $r->{$name}->($sync, @args);

        if ($ENV{DR_SEND_DUMP}) {
            warn pkt_dump($name, $pkt);
        }


        $self->send_pkt($pkt, sub {
            my ($state, $message) = @_;
            unless ($state eq 'OK') {
                $self->last_error([$state, $message]);
                $self->state('error');
                $self->fh(undef);
                goto &$cb;
            }
            $cb->(OK => sprintf("packet '%s' sent", $name), $sync);
        });

        return;
    }

    init:
    connected:
    connecting:
    {
        push @{ $self->_unsent } => [ $name, @args, $cb ];
        return;
    }
}

sub wait_response {
    my ($self, $sync, $cb) = @_;
    unless (exists $self->_active_sync->{$sync}) {
        $cb->(ER_FATAL => "Request $sync was not sent");
        return;
    }
    if (ref $self->_active_sync->{$sync}) {
        my $resp = delete $self->_active_sync->{$sync};
        $cb->(OK => 'Request was read', $resp);
        return;
    }
    push @{ $self->_watcher->{$sync} } => $cb;
    return;
}

sub check_rbuf {
    my ($self) = @_;
   
    my $found = 0;

    # handshake
    goto $self->state;

    ready: {
        while (length $self->rbuf) {
            my ($res, $tail) = DR::Tnt::Proto::response($self->rbuf, $self->utf8);
            return $found unless defined $res;
            
            $found++;

            $self->rbuf($tail);

            my $sync = $res->{SYNC};
            if (exists $self->_watcher->{$sync}) {
                my $list = delete $self->_watcher->{$sync};
                delete $self->_active_sync->{$sync};
                for my $cb (@$list) {
                    $cb->(OK => 'Response received', $res);
                }
                next;
            }

            unless (exists $self->_active_sync->{$sync}) {
                warn "Unexpected tarantool reply $sync";
                next;
            }

            $self->_active_sync->{$sync} = $res;
        };
        return $found;
    }

    connected: {
        return $found if 128 > length $self->rbuf;
        my $handshake = substr $self->rbuf, 0, 128;
        $self->rbuf(substr $self->rbuf, 128);

        my $greeting = DR::Tnt::Proto::parse_greeting($handshake);
        unless ($greeting and $greeting->{salt}) {
            $self->fh(undef);
            $self->last_error([ER_HANDSHAKE => 'Broken handshake']);
            $self->state('error');
            return $found;
        }
        
        $self->greeting($greeting);
        $self->state('ready');
        
        for (my $list = $self->_on_handshake) {
            $self->_on_handshake([]);
            $_->(OK => 'Handshake received', $self->greeting) for @$list;
            $found++;
        }
        
        for (my $list = $self->_unsent) {
            $self->_unsent([]);
            $self->send_request(@$_) for @$list;
        }
        goto ready;
    }
}
__PACKAGE__->meta->make_immutable;
