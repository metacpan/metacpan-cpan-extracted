use utf8;
use strict;
use warnings;

package DR::Tnt::FullCb;
use Mouse;

require DR::Tnt::LowLevel;
use File::Spec::Functions 'catfile', 'rel2abs';
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use DR::Tnt::Dumper;
with 'DR::Tnt::Role::Logging';
use Scalar::Util;
use feature 'state';

use constant SPACE_space        => 281;     # _vspace
use constant SPACE_index        => 289;     # _vindex
use constant ER_TNT_PERMISSIONS => 0x8037;
use constant ER_TNT_SCHEMA      => 0x806D;


use Mouse::Util::TypeConstraints;

    enum DriverType     => [ 'sync', 'async' ];
    enum FullCbState    => [
        'init',
        'connecting',
        'schema',
        'ready',
        'pause',
    ];

no Mouse::Util::TypeConstraints;

has logger              => is => 'ro', isa => 'Maybe[CodeRef]';
has host                => is => 'ro', isa => 'Str', required => 1;
has port                => is => 'ro', isa => 'Str', required => 1;
has user                => is => 'ro', isa => 'Maybe[Str]';
has password            => is => 'ro', isa => 'Maybe[Str]';
has driver              => is => 'ro', isa => 'DriverType', required => 1;
has reconnect_interval  => is => 'ro', isa => 'Maybe[Num]';
has hashify_tuples      => is => 'ro', isa => 'Bool', default => 0;
has utf8                => is => 'ro', isa => 'Bool', default => 1;
has lua_dir =>
    is          => 'ro',
    isa         => 'Maybe[Str]',
    writer      => '_set_lua_dir'
;
has last_error =>
    is          => 'ro',
    isa         => 'Maybe[ArrayRef]',
    writer      => '_set_last_error'
;
has state =>
    is          => 'ro',
    isa         => 'FullCbState',
    default     => 'init',
    writer      => '_set_state',
    trigger     => sub {
        my ($self, undef, $old_state) = @_;
        $self->_state_changed($self->_now);

        $self->_reconnector->event($self->state, $old_state);
        $self->_log(info => 'Connector is in state: %s',  $self->state);
    };
;

has _state_changed  => is => 'rw', isa => 'Maybe[Num]';


has last_schema =>
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    writer  => '_set_last_schema'
;


has _reconnector    =>
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;

        goto $self->driver;

        sync:
            require DR::Tnt::FullCb::Reconnector::Sync;
            return DR::Tnt::FullCb::Reconnector::Sync->new(fcb => $self);

        async:
            require DR::Tnt::FullCb::Reconnector::AE;
            return DR::Tnt::FullCb::Reconnector::AE->new(fcb => $self);

    }
;



has _unsent_lua     => is => 'rw', isa => 'ArrayRef', default => sub {[]};

sub _preeval_lua {
    my ($self, $cb) = @_;

    $self->_unsent_lua([]);

    if ($self->lua_dir) {
        my @lua = sort glob catfile $self->lua_dir, '*.lua';
        $self->_unsent_lua(\@lua);
    }

    $self->_preeval_unsent_lua($cb);
    return;
}

sub _preeval_unsent_lua {
    my ($self, $cb) = @_;

    unless (@{ $self->_unsent_lua  }) {
        $self->_invalid_schema($cb);
        return;
    }

    my $lua = shift @{ $self->_unsent_lua };

    $self->_log(debug => 'Eval "%s" after connection', $lua);

    if (open my $fh, '<:raw', $lua) {
        local $/;
        my $body = <$fh>;
        $self->_reconnector->ll->send_request(eval_lua => undef, $body, sub {
            my ($state, $message, $sync) = @_;
            unless ($state eq 'OK') {
                $self->_set_last_error([ $state, $message ]);
                $self->_set_state('pause');
                $cb->($state => $message);
                return;
            }

            $self->_reconnector->ll->wait_response($sync, sub {
                my ($state, $message, $resp) = @_;
                unless ($state eq 'OK') {
                    $self->_set_last_error([ $state, $message ]);
                    $self->_set_state('pause');
                    $cb->($state => $message);
                    return;
                }
                unless ($resp->{CODE} == 0) {
                    $cb->(ER_INIT_LUA =>
                        sprintf "lua (%s) error: %s",
                        $lua, $resp->{ERROR} // 'Unknown error'
                    );
                    return;
                }
                $self->_preeval_unsent_lua($cb);
            });
        });

    } else {
        $self->_set_last_error(ER_OPEN_FILE => "$lua: $!");
        $self->_set_state('pause');
        $cb->(@{ $self->last_error });
        return;
    }
}


has _sch            => is => 'rw', isa => 'HashRef';
has _spaces         => is => 'rw', isa => 'ArrayRef', default => sub {[]};
has _indexes        => is => 'rw', isa => 'ArrayRef', default => sub {[]};

has _wait_ready    => is => 'rw', isa => 'ArrayRef', default => sub { [] };

sub _invalid_schema {
    my ($self, $cb) = @_;

    goto $self->state;

    init:
    pause:
        confess "Internal error: _invalid_schema in state " . $self->state;

    schema:
    connecting:
    ready:
        $self->_set_state('schema');
        $self->_reconnector->ll->send_request(select =>
                                undef, SPACE_space, 0, [], undef, undef, 'ALL', sub {
            my ($state, $message, $sync) = @_;
            $self->_log(debug => 'Loading spaces');
            unless ($state eq 'OK') {
                $self->_set_last_error([ $state, $message ]);
                $self->_set_state('pause');
                $cb->($state => $message);
                return;
            }

            $self->_reconnector->ll->wait_response($sync, sub {
                my ($state, $message, $resp) = @_;
                unless ($state eq 'OK') {
                    $self->_set_last_error([ $state, $message ]);
                    $self->_set_state('pause');
                    $cb->($state => $message);
                    return;
                }


                # have no permissions
                if ($resp->{CODE} == ER_TNT_PERMISSIONS) {
                    $self->_spaces([]);
                } elsif ($resp->{CODE}) {
                    $self->_set_last_error([ ER_REQUEST =>
                        'Can not load tarantool schema', $resp->{CODE} ]);
                    $self->_set_state('pause');
                    $cb->(@{ $self->last_error });
                    return;
                } else {
                    $self->_spaces($resp->{DATA});
                }

                $self->_log(debug => 'Loading indexes');
                $self->_reconnector->ll->send_request(select =>
                    $resp->{SCHEMA_ID}, SPACE_index, 0, [], undef, undef, 'ALL', sub {

                    my ($state, $message, $sync) = @_;
                    unless ($state eq 'OK') {
                        $self->_set_last_error([ $state, $message ]);
                        $self->_set_state('pause');
                        $cb->($state => $message);
                        return;
                    }


                    $self->_reconnector->ll->wait_response($sync, sub {
                        my ($state, $message, $resp) = @_;
                        unless ($state eq 'OK') {
                            $self->_set_last_error([ $state, $message ]);
                            $self->_set_state('pause');
                            $cb->($state => $message);
                            return;
                        }

                        if ($resp->{CODE} == ER_TNT_PERMISSIONS) {
                            $self->_indexes([]);
                        } elsif ($resp->{CODE} == ER_TNT_SCHEMA) {
                            # collision again!
                            $self->_invalid_schema($cb);
                            return;

                        } elsif ($resp->{CODE}) {
                            $self->_set_last_error([ ER_REQUEST =>
                                'Can not load tarantool schema', $resp->{CODE} ]);
                            $self->_set_state('pause');
                            $cb->(@{ $self->last_error });
                            return;

                        } else {
                            $self->_indexes($resp->{DATA});
                        }

                        $self->_set_schema($resp->{SCHEMA_ID});
                        $self->_set_state('ready');

                        $cb->('OK', 'Connected, schema loaded');
                        $self->request;
                    });
                });
            });
        });
}

sub _set_schema {
    my ($self, $schema_id) = @_;

    my %sch;

    for (@{ $self->_spaces }) {
        my $space = $sch{ $_->[0] } = $sch{ $_->[2] } = {
            id      => $_->[0],
            name    => $_->[2],
            engine  => $_->[3],
            flags   => $_->[5],
            fields  => $_->[6],
            indexes => {  }
        };

        for (@{ $self->_indexes }) {
            next unless $_->[0] == $space->{id};

            $space->{indexes}{ $_->[2] } =
            $space->{indexes}{ $_->[1] } = {
                id      => $_->[1],
                name    => $_->[2],
                type    => $_->[3],
                flags   => $_->[4],
                fields  => [
                    map {
                        'HASH' eq ref $_ ?
                                { type => $_->{type},   no => $_->{field} }
                            :   { type => $_->[1],      no => $_->[0] }
                    }
                    
                    @{ $_->[5] }
                ]
            }
        }
    }

    $self->_set_last_schema($schema_id);
    $self->_sch(\%sch);
    $self->_indexes([]);
    $self->_spaces([]);
}

sub _tuples {
    my ($self, $resp, $space, $cb) = @_;


    unless (defined $space) {
        $cb->(OK => 'Response received', $resp->{DATA} // []);
        return;
    }

    unless (exists $self->_sch->{ $space }) {
        $cb->(OK => "Space $space not exists in schema", $resp->{DATA} // []);
        return;
    }

    my $res = $resp->{DATA} // [];
    $space = $self->_sch->{ $space };

    if ($self->hashify_tuples) {
        for my $tuple (@$res) {
            next unless 'ARRAY' eq ref $tuple;
            my %t;

            for (0 .. $#{ $space->{fields} }) {
                my $fname = $space->{fields}[$_]{name} // sprintf "field:%02X", $_;
                $t{$fname} = $tuple->[$_];
            }

            if (@{ $space->{fields} } < @$tuple) {
                $t{tail} = [ splice @$tuple, scalar @{ $space->{fields} } ];
            } else {
                $t{tail} = [];
            }
            $tuple = \%t;
        }
    }

    $cb->(OK => 'Response received', $res);
}

sub restart {
    my ($self, $cbc) = @_;

    $cbc ||= sub {  };

    $self->_log(info => 'Starting connection to %s:%s (driver: %s)',
        $self->host, $self->port, $self->driver);

    goto $self->state;

    init:
    connecting:
    schema:
    pause:
    ready:
        $self->_set_state('connecting');
        $self->_reconnector->ll->connect(sub {
            my ($state, $message) = @_;
            unless ($state eq 'OK') {
                $self->_set_last_error([ $state, $message ]);
                $self->_set_state('pause');
                $cbc->(@{ $self->last_error });
                return;
            }

            $self->_reconnector->ll->handshake(sub {
                my ($state, $message) = @_;
                unless ($state eq 'OK') {
                    $self->_set_last_error([ $state, $message ]);
                    $self->_set_state('pause');
                    $cbc->(@{ $self->last_error });
                    return;
                }

                unless ($self->user and $self->password) {
                    return $self->_preeval_lua($cbc);
                }

                $self->_reconnector->ll->send_request(auth => undef, sub {
                    my ($state, $message, $sync) = @_;
                    unless ($state eq 'OK') {
                        $self->_set_last_error([ $state, $message ]);
                        $self->_set_state('pause');
                        $cbc->(@{ $self->last_error });
                        return;
                    }

                    $self->_reconnector->ll->wait_response($sync, sub {
                        my ($state, $message, $resp) = @_;
                        unless ($state eq 'OK') {
                            $self->_set_last_error([ $state, $message ]);
                            $self->_set_state('pause');
                            $cbc->(@{ $self->last_error });
                            return;
                        }

                        unless ($resp->{CODE} == 0) {
                            $self->_log(warning => 'Can not auth: Wrong login or password');
                            $self->_set_last_error([ ER_BROKEN_PASSWORD =>
                                $resp->{ERROR} // 'Wrong password']
                            );
                            $self->_set_state('pause');
                            $cbc->(@{ $self->last_error });
                            return;
                        }
                        $self->_preeval_lua($cbc);
                    });
                });
            });
        });
}

sub request {
    my $self = shift;

    if (@_) {

        unless ('CODE' eq ref $_[-1]) {
            croak 'usage: $connector->request(..., $CALLBACK)';
        }
        state $check = {
            get         => sub {
                croak 'usage: $connector->get(space, index, key)'
                    unless @_ == 5;
            },
            select      => sub {
                croak 'usage: $connector->select(space, index, key[, limit, offset, iterator])'
                    unless @_ >= 5 and @_ <= 8;
            },
            update      => sub { },
            insert      => sub {
                croak 'usage: $connector->insert(space, tuple)'
                    unless @_ == 4 and 'ARRAY' eq ref $_[2];
            },
            replace     => sub {
                croak 'usage: $connector->replace(space, tuple)'
                    unless @_ == 4 and 'ARRAY' eq ref $_[2];
            },
            delete      => sub {
                croak 'usage: $connector->delete(space, key)'
                    unless @_ == 4;
            },
            call_lua    => sub {
                croak 'usage: $connector->call_lua(name[, args])'
                    unless @_ >= 3;
            },
            eval_lua    => sub {
                croak 'usage: $connector->eval_lua(code[, args])'
                    unless @_ >= 3;
            },
            ping        => sub {
            },
            auth        => sub {
                croak 'usage: $connector->auth([user, password])'
                    unless @_ == 3 or @_ == 5;
            },
        };

        unless (exists $check->{ $_[0] // 'undef' }) {
            croak 'unknown request method: ' . $_[0] // 'undef';
        }

        $check->{ $_[0] }(@_);

        push @{ $self->_wait_ready } => \@_;
    }

    restart:
        goto $self->state;


    init:
        $self->_log(info => 'Autoconnect before first request');

    reinit:
        $self->restart(sub {
            return if $self->state eq 'ready';
            unless (defined $self->reconnect_interval) {
                my $list = $self->_wait_ready;
                $self->_wait_ready([]);
                for (@$list) {
                    $_->[-1](@{ $self->last_error });
                }
                return;
            }
        });

        if ($self->driver eq 'sync') {
            goto ready if $self->state eq 'ready';
            goto sync_redo_check;
        }

        return;
    
    sync_redo_check:
        goto no_reconnect_errors unless defined $self->reconnect_interval;
        Time::HiRes::sleep($self->reconnect_interval);
        goto reinit;

    schema:
    connecting:
        return;

    pause:
        if ($self->driver eq 'sync') {
            goto no_reconnect_errors unless defined $self->reconnect_interval;
            my $pause = $self->reconnect_interval -
                ($self->_now - $self->_state_changed);
            Time::HiRes::sleep($pause) if $pause > 0;
            goto reinit;
        }
        goto no_reconnect_errors unless defined $self->reconnect_interval;
        return;
    no_reconnect_errors: {
            my $list = $self->_wait_ready;
            $self->_wait_ready([]);
            for (@$list) {
                $_->[-1](@{ $self->last_error });
            }
            return
    }

    ready:
        while (my $request = shift @{ $self->_wait_ready }) {

            unless ($self->state eq 'ready') {
                unshift @{ $self->_wait_ready  } => $request;
                goto restart;
            };

            my @args = @$request;
            my $name = shift @args;
            my $cb = pop @args;

            my ($space, $index);
            state $space_pos = {
                select      => 'index',
                update      => 'normal',
                insert      => 'normal',
                replace     => 'normal',
                delete      => 'normal',
                call_lua    => 'mayberef',
                eval_lua    => 'mayberef',
                ping        => 'none',
                auth        => 'none',
            };

            croak "unknown method $name" unless exists $space_pos->{$name};

            goto $space_pos->{$name};

            index:
                $space = $args[0];
                unless (exists $self->_sch->{ $space }) {
                    $self->_set_last_error([ER_NOSPACE => "Space $space not found"]);
                    $cb->(@{ $self->last_error });
                    next;
                }
                $args[0] = $self->_sch->{ $space }{id};

                $index = $args[1];
                unless (exists $self->_sch->{ $space }{indexes}{ $index }) {
                    $self->_set_last_error(
                        [ER_NOINDEX => "Index space[$space].$index not found"]
                    );
                    $cb->(@{ $self->last_error });
                    next;
                }

                $index = $args[1] = $self->_sch->{$space}{indexes}{ $index }{id};
                goto do_request;

            normal:
                $space = $args[0];
                unless (exists $self->_sch->{ $space }) {
                    $self->_set_last_error([ER_NOSPACE => "Space $space not found"]);
                    $cb->(@{ $self->last_error });
                    next;
                }
                $space = $args[0] = $self->_sch->{ $space }{id};
                goto do_request;

            mayberef:
                if ('ARRAY' eq ref $args[0]) {
                    ($args[0], $space) = @{ $args[0] };
                }
                goto do_request unless defined $space;
                unless (exists $self->_sch->{ $space }) {
                    $self->_set_last_error([ER_NOSPACE => "Space $space not found"]);
                    $cb->(@{ $self->last_error });
                    next;
                }
                $space = $self->_sch->{ $space }{id};


            none:

            do_request:

                $self->_reconnector->ll->send_request($name, $self->last_schema,
                    @args, sub {
                        my ($state, $message, $sync) = @_;
                        unless ($state eq 'OK') {
                            $self->_set_last_error([ $state => $message ]);
                            $self->_set_state('pause');
                            $cb->(@{ $self->last_error });
                            return;
                        }

                        $self->_reconnector->ll->wait_response($sync, sub {
                            my ($state, $message, $resp) = @_;
                            unless ($state eq 'OK') {
                                $self->_set_last_error([ $state => $message ]);
                                $self->_set_state('pause');
                                $cb->(@{ $self->last_error });
                                return;
                            }

                            # schema collision
                            if ($resp->{CODE} == ER_TNT_SCHEMA) {
                                $self->_log(warning => 'Detected schema collision');
                                $self->_log(info => 'Defer request "%s" until schema loaded', $name);
                                unshift @{ $self->_wait_ready } => $request;
                                $self->_invalid_schema(sub {}) if $self->state eq 'ready';
                                return;
                            }

                            unless ($resp->{CODE} == 0) {
                                $self->_set_last_error(
                                    [ ER_REQUEST => $resp->{ERROR}, $resp->{CODE} ]
                                );
                                $cb->(@{ $self->last_error });
                                return;
                            }

                            if ($resp->{SCHEMA_ID} != $self->last_schema) {
                                $self->_log(info => 'request was changed schema id');
                            }
                            $self->_set_last_error(undef);
                            $self->_tuples($resp, $space, $cb);
                        });
                    });
    }
    return;

}

sub _now {
    my ($self) = @_;
    return Time::HiRes::time() if $self->driver eq 'sync';
    return AnyEvent->now();
}

sub BUILD {
    my ($self) = @_;
    goto $self->driver;

    sync:
        require Time::HiRes;
        return;
    async:
        require AnyEvent;
        return;
}

__PACKAGE__->meta->make_immutable;

