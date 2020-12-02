package Database::Async::Engine::PostgreSQL;
# ABSTRACT: PostgreSQL support for Database::Async

use strict;
use warnings;

our $VERSION = '0.009';

use parent qw(Database::Async::Engine);

=head1 NAME

Database::Async::Engine::PostgreSQL - support for PostgreSQL databases in L<Database::Async>

=head1 DESCRIPTION

Provide a C<postgresql://> URI when instantiating L<Database::Async> to use this engine.

 $loop->add(
  my $dbh = Database::Async->new(
   uri => 'postgresql://localhost'
  )
 );

Connection can also be made using a service definition, as described in L<https://www.postgresql.org/docs/current/libpq-pgservice.html>.

 $loop->add(
  my $dbh = Database::Async->new(
   type => 'postgresql',
   engine => {
    service => 'example',
   }
  )
 );

If neither URI nor service are provided, the C<PGSERVICE> environment variable is attempted, and will fall back
to localhost (similar to C<psql -h localhost> behaviour).

 $loop->add(
  my $dbh = Database::Async->new(
   type => 'postgresql',
  )
 );


=cut

no indirect;
use Ryu::Async;
use Ryu::Observable;
use curry;
use Scalar::Util ();
use URI::postgres;
use URI::QueryParam;
use Future::AsyncAwait;
use Database::Async::Query;
use File::HomeDir;
use Config::Tiny;

use Protocol::Database::PostgreSQL::Client qw(0.008);
use Protocol::Database::PostgreSQL::Constants qw(:v1);

use Log::Any qw($log);

use overload
    '""' => sub { ref(shift) },
    bool => sub { 1 },
    fallback => 1;

Database::Async::Engine->register_class(
    postgresql => __PACKAGE__
);

=head1 METHODS

=head2 connection

Returns a L<Future> representing the database connection,
and will attempt to connect if we are not already connected.

=cut

sub connection {
    my ($self) = @_;
    $self->{connection} //= $self->connect;
}

=head2 ssl

Whether to try SSL or not, expected to be one of the following
values from L<Protocol::Database::PostgreSQL::Constants>:

=over 4

=item * C<SSL_REQUIRE>

=item * C<SSL_PREFER>

=item * C<SSL_DISABLE>

=back

=cut

sub ssl { shift->{ssl} }

=head2 read_len

Buffer read length. Higher values mean we will attempt to read more
data for each I/O loop iteration.

Defaults to 2 megabytes.

=cut

sub read_len { shift->{read_len} //= 2 * 1024 * 1024 }

=head2 write_len

Buffer write length. Higher values mean we will attempt to write more
data for each I/O loop iteration.

Defaults to 2 megabytes.

=cut

sub write_len { shift->{write_len} //= 2 * 1024 * 1024 }

=head2 connect

Establish a connection to the server.

Returns a L<Future> which resolves to the L<IO::Async::Stream>
once ready.

=cut

async sub connect {
    my ($self) = @_;
    my $loop = $self->loop;

    # Initial connection is made directly through the URI
    # parameters. Eventually we also want to support UNIX
    # socket and other types.
    $self->{uri} ||= $self->uri_for_service($self->service) if $self->service;
    my $uri = $self->uri;
    die 'bad URI' unless ref $uri;
    $log->tracef('URI for connection is %s', "$uri");
    my $endpoint = join ':', $uri->host, $uri->port;
    $log->tracef('Will connect to %s', $endpoint);
    $self->{ssl} = do {
        my $mode = $uri->query_param('sslmode') // 'prefer';
        $Protocol::Database::PostgreSQL::Constants::SSL_NAME_MAP{$mode} // die 'unknown SSL mode ' . $mode;
    };

    my $sock = await $loop->connect(
        service     => $uri->port,
        host        => $uri->host,
        socktype    => 'stream',
    );

    my $local  = join ':', $sock->sockhost_service(1);
    my $remote = join ':', $sock->peerhost_service(1);
    $log->tracef('Connected to %s as %s from %s', $endpoint, $remote, $local);

    # We start with a null handler for read, because our behaviour varies depending on
    # whether we want to go through the SSL dance or not.
    $self->add_child(
        my $stream = IO::Async::Stream->new(
            handle   => $sock,
            on_read  => sub { 0 }
        )
    );

    # SSL is conveniently simple: a prefix exchange before the real session starts,
    # and the user can decide whether SSL is mandatory or optional.
    $stream = await $self->negotiate_ssl(
        stream => $stream,
    );

    Scalar::Util::weaken($self->{stream} = $stream);
    $self->outgoing->each(sub {
        $log->tracef('Write bytes [%v02x]', $_);
        $self->ready_for_query->set_string('');
        $self->stream->write("$_");
        return;
    });
    $stream->configure(
        on_read   => $self->curry::weak::on_read,
        read_len  => $self->read_len,
        write_len => $self->write_len,
        autoflush => 0,
    );

    $log->tracef('Send initial request with user %s', $uri->user);
    my %qp = $uri->query_params;
    delete $qp{sslmode};
    $qp{application_name} //= $self->application_name;
    $self->protocol->send_startup_request(
        database         => $self->database_name,
        user             => $self->database_user,
        %qp
    );
    return $stream;
}

=head2 service_conf_path

Return the expected location for the pg_service.conf file.

=cut

sub service_conf_path {
    my ($class) = @_;
    return $ENV{PGSERVICEFILE} if exists $ENV{PGSERVICEFILE};
    return $ENV{PGSYSCONFDIR} . '/pg_service.conf' if exists $ENV{PGSYSCONFDIR};
    my $path = File::HomeDir->my_home . '/.pg_service.conf';
    return $path if -r $path;
    return '/etc/pg_service.conf';
}

sub service_parse {
    my ($class, $path) = @_;
    return Config::Tiny->read($path, 'encoding(UTF-8)');
}

sub find_service {
    my ($class, $srv) = @_;
    my $data = $class->service_parse(
        $class->service_conf_path
    );
    die 'service ' . $srv . ' not found in config' unless $data->{$srv};
    return $data->{$srv};
}

sub service { shift->{service} //= $ENV{PGSERVICE} }

sub database_name {
    my $uri = shift->uri;
    return $uri->dbname // $uri->user // 'postgres'
}

sub database_user {
    my $uri = shift->uri;
    return $uri->user // 'postgres'
}

=head2 negotiate_ssl

Apply SSL negotiation.

=cut

async sub negotiate_ssl {
    my ($self, %args) = @_;
    my $stream = delete $args{stream};

    # If SSL is disabled entirely, just return the same stream as-is
    my $ssl = $self->ssl
        or return $stream;

    require IO::Async::SSL;
    require IO::Socket::SSL;

    $log->tracef('Attempting to negotiate SSL');
    await $stream->write($self->protocol->ssl_request);

    $log->tracef('Waiting for response');
    my ($resp, $eof) = await $stream->read_exactly(1);

    $log->tracef('Read %v02x from server for SSL response (EOF is %s)', $resp, $eof ? 'true' : 'false');
    die 'Server closed connection' if $eof;

    if($resp eq 'S') {
        # S for SSL...
        $log->tracef('This is SSL, let us upgrade');
        $stream = await $self->loop->SSL_upgrade(
            handle          => $stream,
            # SSL defaults...
            SSL_server      => 0,
            SSL_hostname    => $self->uri->host,
            SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE(),
            # Pass through anything SSL-related unchanged, the user knows
            # better than we do
            (map {; $_ => $self->{$_} } grep { /^SSL_/ } keys %$self)
        );
        $log->tracef('Upgrade complete');
    } elsif($resp eq 'N') {
        # N for "no SSL"...
        $log->tracef('No to SSL');
        die 'Server does not support SSL' if $self->ssl == SSL_REQUIRE;
    } else {
        # anything else is unexpected
        die 'Unknown response to SSL request';
    }
    return $stream;
}

sub is_replication { shift->{is_replication} //= 0 }
sub application_name { shift->{application_name} //= 'perl' }

=head2 uri_for_dsn

Returns a L<URI> corresponding to the given L<database source name|https://en.wikipedia.org/wiki/Data_source_name>.

May throw an exception if we don't have a valid string.

=cut

sub uri_for_dsn {
    my ($class, $dsn) = @_;
    die 'invalid DSN, expecting DBI:Pg:...' unless $dsn =~ s/^DBI:Pg://i;
    my %args = split /[=;]/, $dsn;
    my $uri = URI->new('postgresql://postgres@localhost/postgres');
    $uri->$_(delete $args{$_}) for grep exists $args{$_}, qw(host port user password dbname);
    $uri
}

sub uri_for_service {
    my ($class, $service) = @_;
    my $cfg = $class->find_service($service);
    my $uri = URI->new('postgresql://postgres@localhost/postgres');
    $uri->$_(delete $cfg->{$_}) for grep exists $cfg->{$_}, qw(host port user password dbname);
    $uri->host(delete $cfg->{hostaddr}) if exists $cfg->{hostaddr};
    $uri->query_param($_ => delete $cfg->{$_}) for grep exists $cfg->{$_}, qw(
        application_name
        fallback_application_name
        keepalives
        options
        sslmode
        replication
    );
    $uri
}

=head2 stream

The L<IO::Async::Stream> representing the database connection.

=cut

sub stream { shift->{stream} }

=head2 on_read

Process incoming database packets.

Expects the following parameters:

=over 4

=item * C<$stream> - the L<IO::Async::Stream> we are receiving data on

=item * C<$buffref> - a scalar reference to the current input data buffer

=item * C<$eof> - true if we have reached the end of input

=back

=cut

sub on_read {
    my ($self, $stream, $buffref, $eof) = @_;

    $log->tracef('Have server message of length %d', length $$buffref);
    while(my $msg = $self->protocol->extract_message($buffref)) {
        $log->tracef('Message: %s', $msg);
        $self->incoming->emit($msg);
    }
    return 0;
}

=head2 ryu

Provides a L<Ryu::Async> instance.

=cut

sub ryu {
    my ($self) = @_;
    $self->{ryu} //= do {
        $self->add_child(
            my $ryu = Ryu::Async->new
        );
        $ryu
    }
}

=head2 outgoing

L<Ryu::Source> representing outgoing packets for the current database connection.

=cut

sub outgoing {
    my ($self) = @_;
    $self->{outgoing} //= $self->ryu->source;
}

=head2 incoming

L<Ryu::Source> representing incoming packets for the current database connection.

=cut

sub incoming {
    my ($self) = @_;
    $self->{incoming} //= $self->ryu->source;
}

=head2 authenticated

Resolves once database authentication is complete.

=cut

sub authenticated {
    my ($self) = @_;
    $self->{authenticated} //= $self->loop->new_future;
}

# Handlers for authentication messages from backend.
our %AUTH_HANDLER = (
    AuthenticationOk => sub {
        my ($self, $msg) = @_;
        $self->authenticated->done;
    },
    AuthenticationKerberosV5 => sub {
        my ($self, $msg) = @_;
        die "Not yet implemented";
    },
    AuthenticationCleartextPassword => sub {
        my ($self, $msg) = @_;
        $self->protocol->send_message(
            'PasswordMessage',
            user          => $self->uri->user,
            password_type => 'plain',
            password      => $self->uri->password,
        );
    },
    AuthenticationMD5Password => sub {
        my ($self, $msg) = @_;
        $self->protocol->send_message(
            'PasswordMessage',
            user          => $self->uri->user,
            password_type => 'md5',
            password_salt => $msg->password_salt,
            password      => $self->uri->password,
        );
    },
    AuthenticationSCMCredential => sub {
        my ($self, $msg) = @_;
        die "Not yet implemented";
    },
    AuthenticationGSS => sub {
        my ($self, $msg) = @_;
        die "Not yet implemented";
    },
    AuthenticationSSPI => sub {
        my ($self, $msg) = @_;
        die "Not yet implemented";
    },
    AuthenticationGSSContinue => sub {
        my ($self, $msg) = @_;
        die "Not yet implemented";
    }
);

=head2 protocol

Returns the L<Protocol::Database::PostgreSQL> instance, creating it
and setting up event handlers if necessary.

=cut

sub protocol {
    my ($self) = @_;
    $self->{protocol} //= do {
        my $pg = Protocol::Database::PostgreSQL::Client->new(
            database => $self->database_name,
            outgoing => $self->outgoing,
        );
        $self->incoming
            ->switch_str(
                sub { $_->type },
                authentication_request => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Auth request received: %s', $msg);
                    my $code = $AUTH_HANDLER{$msg->auth_type}
                        or $log->errorf('unknown auth type %s', $msg->auth_type);
                    $self->$code($msg);
                }),
                password => $self->$curry::weak(sub {
                    my ($self, %args) = @_;
                    $log->tracef('Auth request received: %s', \%args);
                    $self->protocol->{user} = $self->uri->user;
                    $self->protocol->send_message('PasswordMessage', password => $self->uri->password);
                }),
                parameter_status => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Parameter received: %s', $msg);
                    $self->set_parameter($msg->key => $msg->value);
                }),
                row_description => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Row description %s', $msg);
                    $log->errorf('No active query?') unless my $q = $self->active_query;
                    $q->row_description($msg->description);
                }),
                data_row => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Have row data %s', $msg);
                    $self->active_query->row([ $msg->fields ]);
                }),
                command_complete => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    my $query = delete $self->{active_query} or do {
                        $log->warnf('Command complete but no query');
                        return;
                    };
                    $log->tracef('Completed query %s with result %s', $query, $msg->result);
                    $query->done unless $query->completed->is_ready;
                }),
                no_data => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Completed query %s with no data', $self->active_query);
                    # my $query = delete $self->{active_query};
                    # $query->done if $query;
                }),
                send_request => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Send request for %s', $msg);
                    $self->stream->write($msg);
                }),
                ready_for_query => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Ready for query, state is %s', $msg->state);
                    $self->ready_for_query->set_string($msg->state);
                    $self->db->engine_ready($self) if $self->db;
                }),
                backend_key_data => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Backend key data: pid %d, key 0x%08x', $msg->pid, $msg->key);
                }),
                parse_complete => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Parsing complete for query %s', $self->active_query);
                }),
                bind_complete => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Bind complete for query %s', $self->active_query);
                }),
                close_complete => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Close complete for query %s', $self->active_query);
                }),
                empty_query_response => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Query returned no results for %s', $self->active_query);
                }),
                error_response => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    my $query = $self->active_query;
                    $log->warnf('Query returned error %s for %s', $msg->error, $self->active_query);
                    my $f = $query->completed;
                    $f->fail($msg->error) unless $f->is_ready;
                }),
                copy_in_response => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    my $query = $self->active_query;
                    $log->tracef('Ready to copy data for %s', $query);
                    my $proto = $self->protocol;
                    {
                        my $src = $query->streaming_input;
                        $src->completed
                            ->on_ready(sub {
                                my ($f) = @_;
                                $log->tracef('Sending copy done notification, stream status was %s', $f->state);
                                $proto->send_message(
                                    'CopyDone',
                                    data => '',
                                );
                                $proto->send_message(
                                    'Close',
                                    portal    => '',
                                    statement => '',
                                );
                                $proto->send_message(
                                    'Sync',
                                    portal    => '',
                                    statement => '',
                                );
                            });
                            $src->each(sub {
                                $log->tracef('Sending %s', $_);
                                $proto->send_copy_data($_);
                            });
                    }
                    $query->ready_to_stream->done unless $query->ready_to_stream->is_ready;
                }),
                copy_out_response => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('copy out starts %s', $msg);
                    # $self->active_query->row([ $msg->fields ]);
                }),
                copy_data => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Have copy data %s', $msg);
                    my $query = $self->active_query or do {
                        $log->warnf('No active query for copy data');
                        return;
                    };
                    $query->row($_) for $msg->rows;
                }),
                copy_done => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    $log->tracef('Copy done - %s', $msg);
                }),
                notification_response => $self->$curry::weak(sub {
                    my ($self, $msg) = @_;
                    my ($chan, $data) = @{$msg}{qw(channel data)};
                    $log->tracef('Notification on channel %s containing %s', $chan, $data);
                    $self->db->notification($self, $chan, $data);
                }),
                sub { $log->errorf('Unknown message %s (type %s)', $_, $_->type) }
            );
        $pg
    }
}

sub stream_from {
    my ($self, $src) = @_;
    my $proto = $self->proto;
    $src->each(sub {
        $log->tracef('Sending %s', $_);
        $proto->send_copy_data($_);
    })
}

=head2 set_parameter

Marks a parameter update from the server.

=cut

sub set_parameter {
    my ($self, $k, $v) = @_;
    if(my $param = $self->{parameter}{$k}) {
        $param->set_string($v);
    } else {
        $self->{parameter}{$k} = Ryu::Observable->new($v);
    }
    $self
}

=head2 idle

Resolves when we are idle and ready to process the next request.

=cut

sub idle {
    my ($self) = @_;
    $self->{idle} //= $self->loop->new_future->on_ready(sub {
        delete $self->{idle}
    });
}

sub ready_for_query {
    my ($self) = @_;
    $self->{ready_for_query} //= do {
        Ryu::Observable->new(0)->subscribe($self->$curry::weak(sub {
            my ($self, $v) = @_;
            return unless my $idle = $self->{idle} and $v;
            $idle->done unless $idle->is_ready;
        }))
    }
}

sub simple_query {
    my ($self, $sql) = @_;
    die 'already have active query' if $self->{active_query};
    $self->{active_query} = my $query = Database::Async::Query->new(
        sql      => $sql,
        row_data => my $src = $self->ryu->source
    );
    $self->protocol->simple_query($query->sql);
    return $src;
}

sub handle_query {
    my ($self, $query) = @_;
    die 'already have active query' if $self->{active_query};
    $self->{active_query} = $query;
    my $proto = $self->protocol;
    $proto->send_message(
        'Parse',
        sql       => $query->sql,
        statement => '',
    );
    $proto->send_message(
        'Bind',
        portal    => '',
        statement => '',
        param     => [ $query->bind ],
    );
    $proto->send_message(
        'Describe',
        portal    => '',
        statement => '',
    );
    $proto->send_message(
        'Execute',
        portal    => '',
        statement => '',
    );
    if($query->{in}) {
        $query->in
            ->completed
            ->on_done(sub {
                $proto->send_message(
                    'Close',
                    portal    => '',
                    statement => '',
                );
            })
            ->on_ready(sub {
                $proto->send_message(
                    'Sync',
                    portal    => '',
                    statement => '',
                );
            });
    } else {
        $proto->send_message(
            'Close',
            portal    => '',
            statement => '',
        );
        $proto->send_message(
            'Sync',
            portal    => '',
            statement => '',
        );
    }
    Future->done
}

sub query {
    my ($self, $sql, @bind) = @_;
    die 'use handle_query instead';
    die 'already have active query' if $self->{active_query};
    $self->{active_query} = my $query = Database::Async::Query->new(
        sql      => $sql,
        bind     => \@bind,
        row_data => my $src = $self->ryu->source
    );
    return $src;
}

sub active_query { shift->{active_query} }

1;

__END__

=head1 Implementation notes

Query sequence is essentially:

=over 4

=item * receive C<ReadyForQuery>

=item * send C<frontend_query>

=item * Row Description

=item * Data Row

=item * Command Complete

=item * ReadyForQuery

=back

The DB creates an engine.  The engine does whatever connection handling required, and eventually should reach a "ready" state.
Once this happens, it'll notify DB to say "this engine is ready for queries".
If there are any pending queries, the next in the queue is immediately assigned
to this engine.
Otherwise, the engine is pushed into the pool of available engines, awaiting
query requests.

On startup, the pool `min` count of engine instances will be instantiated.
They start in the pending state.

Any of the following:

=over 4

=item * tx

=item * query

=item * copy etc.

=back

is treated as "queue request". It indicates that we're going to send one or
more commands over a connection.

L</next_engine> resolves with an engine instance:

=over 4

=item * check for engines in `available` queue - these are connected and waiting, and can be assigned immediately

=item * next look for engines in `unconnected` - these are instantiated but need
a ->connection first

=back

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.

