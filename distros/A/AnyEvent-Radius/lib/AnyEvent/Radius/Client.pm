package AnyEvent::Radius::Client;
# AnyEvent-based radius client
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle::UDP;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(
                handler packer send_cache
                queue_cv write_cv read_cv
                sent_cnt reply_cnt queue_cnt
                last_request_id
            ));

use Data::Radius v1.2.8;
use Data::Radius::Constants qw(%RADIUS_PACKET_TYPES);
use Data::Radius::Dictionary ();
use Data::Radius::Packet ();

use constant {
    READ_TIMEOUT_SEC => 5,
    WRITE_TIMEOUT_SEC => 5,
    RADIUS_PORT => 1812,
    MAX_REQUEST_ID => 0xFF,
};

# deprecated?
use constant MAX_QUEUE => MAX_REQUEST_ID() + 1;

# new 'NAS'
# args:
#   ip
#   port
#   secret
#   dictionary
#   read_timeout
#   write_timeout
#   bind_ip
#   initial_last_request_id - random by default
#- callbacks:
#    on_read
#    on_read_raw
#    on_read_timeout
#    on_write_timeout
#    on_error
sub new {
    my ($class, %h) = @_;

    my $obj = bless {}, $class;

    # either pre-created packer object, or need radius secret to create new one
    # dictionary is optional
    if ( defined $h{packer} ) {
        $obj->packer( $h{packer} );
    } elsif ( defined $h{secret} ) {
        $obj->packer( Data::Radius::Packet->new(dict => $h{dictionary}, secret => $h{secret}) );
    } else {
        die "No radius secret";
    }

    my %udp_handle_args = (
        rtimeout => $h{read_timeout} // READ_TIMEOUT_SEC,
        wtimeout => $h{write_timeout} // WRITE_TIMEOUT_SEC,
    );

    die "No IP argument" if ! exists $h{ip};
    $udp_handle_args{connect} = [ $h{ip}, $h{port} // RADIUS_PORT ];
    $udp_handle_args{bind} = [$h{bind_ip}, 0] if exists $h{bind_ip};

    $udp_handle_args{on_recv} = sub {
        my ($data, $handle, $from) = @_;
        $obj->read_cv->end;
        $obj->reply_cnt($obj->reply_cnt + 1);

        if ($h{on_read_raw}) {
            # dump raw data
            $h{on_read_raw}->($obj, $data, $from);
        }

        # using authenticator from request to verify reply
        my $request_id = $obj->packer()->request_id($data);
        # FIXME how to react on unknown request_id ?
        my $send_info = delete $obj->send_cache()->{ $request_id };
        if (! $send_info ) {
            # got unknown reply (with wrong request id?)
            if ($h{on_error}) {
                $h{on_error}->($obj, 'Unknown reply');
            }
            else {
                warn "Error: unknown reply";
            }
        }
        else {
            my $on_read = $h{on_read};
            my $req_callback = $send_info->{callback};
            if ( $on_read || $req_callback ) {
                # how to decode $from
                # my($port, $host) = AnyEvent::Socket::unpack_sockaddr($from);
                # my $ip = format_ipv4($host);

                my ($type, $req_id, $auth, $av_list) = $obj->packer()->parse($data, $send_info->{authenticator});

                $on_read->($obj, {
                            type => $type,
                            request_id => $req_id,
                            av_list => $av_list,
                            # from is sockaddr binary data
                            from => $from,
                            authenticator => $auth,
                        }) if $on_read;
                $req_callback->($type, $av_list) if $req_callback;
            }
        }

        $obj->queue_cv->end;
    };

    $udp_handle_args{on_rtimeout} = sub {
        my $handle = shift;
        if(! $obj->read_cv->ready) {
            if($h{on_read_timeout}) {
                $h{on_read_timeout}->($obj, $handle);
            }
            $obj->clear_send_cache();
            # stop queue
            $obj->queue_cv->send;
        }
        $handle->clear_rtimeout();
    };

    $udp_handle_args{on_wtimeout}  = sub {
        my $handle = shift;
        if(! $obj->write_cv->ready) {
            if($h{on_write_timeout}) {
                $h{on_write_timeout}->($obj, $handle);
            }
            $obj->clear_send_cache();
            # stop queue
            $obj->queue_cv->send;
        }
        $handle->clear_wtimeout();
    };

    # low-level socket errors
    $udp_handle_args{on_error} = sub {
        my ($handle, $fatal, $error) = @_;
        # abort all
        $handle->clear_wtimeout();
        $handle->clear_rtimeout();
        $obj->clear_send_cache();
        $obj->queue_cv->send;
        if ($h{on_error}) {
            $h{on_error}->($obj, $error);
        }
        else {
            warn "Error occured: $error";
        }
        # the handle::udp self destroys right after calling the on_error_handler
        # so the client have to do the same
        $obj->destroy() if $fatal;
    };

    $obj->handler( AnyEvent::Handle::UDP->new(%udp_handle_args) );

    $obj->init($h{initial_last_request_id});

    return $obj;
}

sub clear_send_cache {
    my $self = shift;
    my $send_cache = $self->send_cache();
    $self->send_cache({});
    if ($send_cache) {
        my @ordered_reqids = sort { $send_cache->{$a}{time_cached} <=> $send_cache->{$b}{time_cached} } keys %$send_cache;
        foreach my $request_id (@ordered_reqids) {
            if (my $cb = $send_cache->{$request_id}{callback}) {
                $cb->();
            }
        }
    }
}

sub _send_packet {
    my ($self, $packet) = @_;

    # +1
    $self->queue_cv()->begin;
    $self->write_cv()->begin;
    $self->read_cv()->begin;

    my $cv = AnyEvent->condvar;

    $cv->cb(sub {
        $self->sent_cnt($self->sent_cnt() + 1);
        # -1
        $self->write_cv()->end;
    });

    # cv->send is called by Handle::UDP when packet is sent
    $self->handler()->push_send($packet, undef, $cv);
}

# wait for Handle to send all queued packets (or timeout)
# object is not usable after it - call init()
sub wait {
    my $self = shift;

    $self->queue_cv()->recv();
}

# reset vars - need to be called after wait() or on_ready()
sub init {
    my ($self, $initial_last_request_id) = @_;
    $initial_last_request_id //= int rand (MAX_REQUEST_ID + 1);
    $self->read_cv(AnyEvent->condvar);
    $self->write_cv(AnyEvent->condvar);
    $self->queue_cv(AnyEvent->condvar);
    $self->sent_cnt(0);
    $self->reply_cnt(0);
    $self->queue_cnt(0);
    $self->send_cache({});
    $self->last_request_id( $initial_last_request_id & MAX_REQUEST_ID() );
}

# close open socket, object is unusable after it was called
sub destroy {
    my $self = shift;
    $self->handler()->destroy();
    $self->handler(undef);
}

my $_IN_GLOBAL_DESTRUCTION = 0;
END {
    $_IN_GLOBAL_DESTRUCTION = 1;
}

sub DESTROY {
    my $self = shift;
    if (defined ${^GLOBAL_PHASE}) {
        # >= 5.14
        return if (${^GLOBAL_PHASE} eq 'DESTRUCT');
    }
    else {
        # before 5.14, see also Devel::GlobalDestruction
        return if $_IN_GLOBAL_DESTRUCTION;
    }

    return if (! $self->handler());
    $self->handler()->destroy();
}

# group wait
# cv is AnyEvent condition var passed outside
#
# Example:
#  my $cv = AnyEvent->condvar;
#  $nas1->on_ready($cv);
#  $nas2->on_ready($cv);
#  $nas3->on_ready($cv);
#  $cv->recv;
#
sub on_ready {
    my ($self, $cv) = @_;

    $cv->begin();
    $self->queue_cv()->cb(sub { $cv->end });
}

sub load_dictionary {
    my ($class, $path) = @_;
    my $dict = Data::Radius::Dictionary->load_file($path);

    if(ref($class)) {
        $class->packer()->dict($dict);
    }

    return $dict;
}

sub next_request_id {
    my $self = shift;
    return undef if $self->queue_cnt() > MAX_REQUEST_ID();
    my $last_request_id = $self->last_request_id();
    my $new_request_id = ($last_request_id + 1) & MAX_REQUEST_ID();
    my $send_cache = $self->send_cache();
    while (exists $send_cache->{$new_request_id}) {
        $new_request_id = ($new_request_id + 1) & MAX_REQUEST_ID();
        return undef if $new_request_id == $last_request_id; # send cache full ??
    }
    $self->last_request_id($new_request_id);
    return $new_request_id;
}

# add packet to the queue
# type - radius request packet type code or its text alias
# av_list - list of attributes in {Name => ... Value => ... } form
# cb - optional callback to be called on result:
#      - when received response as $cb->($resp_type, $resp_av_list)
#      - when failed (eg time out, invalid or non matching response)
#        with empty parameter list cb->();
sub send_packet {
    my ($self, $type, $av_list, $cb) = @_;

    my $request_id = $self->next_request_id();
    if ( !defined $request_id ) {
        return;
    }

    $type = $RADIUS_PACKET_TYPES{$type} if exists $RADIUS_PACKET_TYPES{$type};

    my ($packet, $req_id, $auth) = $self->packer()->build(
                        type => $type,
                        av_list => $av_list,
                        request_id => $request_id,
                    );

    # required to verify reply
    $self->send_cache()->{ $req_id } = {
        authenticator => $auth,
        type => $type,
        callback => $cb,
        time_cached => AE::now(),
    };
    $self->queue_cnt($self->queue_cnt() + 1);

    $self->_send_packet($packet);

    return wantarray() ? ($req_id, $auth) : $req_id;
}

# shortcut methods:

sub send_auth {
    my $self = shift;
    return $self->send_packet(AUTH => @_);
}

sub send_acct {
    my $self = shift;
    return $self->send_packet(ACCT => @_);
}

sub send_pod {
    my $self = shift;
    return $self->send_packet(POD => @_);
}

sub send_coa {
    my $self = shift;
    return $self->send_packet(COA => @_);
}

1;

__END__

=head1 NAME

AnyEvent::Radius::Client - module to implement AnyEvent based RADIUS client

=head1 SYNOPSYS

    use AnyEvent;
    use AnyEvent::Radius::Client;

    my $dict = AnyEvent::Radius::Client->load_dictionary('path-to-radius-dictionary');

    sub read_reply_callback {
        # $h is HASH-REF {type, request_id, av_list, from, authenticator}
        my ($self, $h) = @_;
        ...
    }

    my $client = AnyEvent::Radius::Client->new(
                        ip => $ip,
                        port => $port,
                        on_read => \&read_reply_callback,
                        dictionary => $dict,
                        secret => $secret,
                    );
    $client->send_auth(AV_LIST1);
    $client->send_auth(AV_LIST2);
    ...
    $client->wait;
    ...
    $client->destroy;

=head1 DESCRIPTION

The L<AnyEvent::Radius::Client> module allows to send multiple RADIUS requests in non-blocking way,
and then wait for responses.


=head1 CONSTRUCTOR

=over

=item new ( ..options hash )

=over

=item ip

=item port - where to connect

=item secret - RADIUS secret string for remote server

=item dictionary - optional, dictionary loaded by L<load_dictionary()> method

=item bind_ip - optional, the local ip address to bind client to

=item read_timeout

=item write_timeout - network I/O timeouts (default is 5 second)

=item initial_last_request_id - explicit radius id initialization, the next request will use it+1

=item Callbacks:

=over

=item on_read - called when reply received, arguments is hash-ref with {request_id, type, av_list, authenticator} keys

=item on_read_raw - called when reply received, raw data packet is provided as argument

=item on_read_timeout - timeout waiting for reply from server. Aborts the waiting state

=item on_write_timeout - timeout sending request

=item on_error - invalid packet received, or low-level socket error

=back

=back

=back

=head1 METHODS

=over

=item load_dictionary ($dictionary-file)

Class method to load dictionary - returns the object to be passed to constructor

=item send_packet ( $type, $av_list, $cb )

Builds RADIUS packet using L<Data::Radius::Packet> and store it to outgoing queue.

The type can be either the direct RFC packet type id, or one of its aliases,
like COA, DM, POD, ACCT, AUTH ... see C<Data::Radius::Constants>

Passing the optional callback $cb to be called upon receiving response to this request in form

  $cb->($resp_type, $resp_av_list)

or with empty parameters in case of missing response - eg. being timed out or unmatched authenticator

  $cb->()

Returns request id.
Note that it's not possible to schedule more than 255 requests - trying to add more will return undef

=item send_auth ($av_list, $cb)

=item send_acct ($av_list, $cb)

=item send_pod ($av_list, $cb)

=item send_coa ($av_list, $cb)

Alias methods to send RADIUS request of required type by L<send_packet()>

=item wait()

Blocks until all requests are received or read timeout reached,
new requests can't be sent afterwards until next call to C<init>

=item init( $initial_last_request_id )

Re-initilize the queue with optional last used request id

=item on_ready ( $cond_var )

Used to coordinate multiple clients instead of L<wait()>

Example:

    my $cv = AnyEvent->condvar;
    $client1->on_ready($cv);
    $client2->on_ready($cv);
    $client3->on_ready($cv);
    $cv->recv;

Will be blocked until all clients finish their queue.

=item destroy()

Destroy the internal socket handle. Must be called when object is no longer required.
When called from callback, it is recommended to wrap this call into AnyEvent::postpone { ... } block.

=back

=head1 SEE ALSO

L<Authen::Radius>, L<AnyEvent::Radius::Server>, L<Data::Radius>

=head1 AUTHOR

Sergey Leschenko <sergle.ua at gmail.com>

PortaOne Development Team <perl-radius at portaone.com> is the current module's maintainer at CPAN.

=cut
