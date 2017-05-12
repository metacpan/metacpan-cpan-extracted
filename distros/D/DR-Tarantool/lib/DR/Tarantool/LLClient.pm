use utf8;
use strict;
use warnings;

=head1 NAME

DR::Tarantool::LLClient - a low level async client
for L<Tarantool|http://tarantool.org>

=head1 SYNOPSIS

    DR::Tarantool::LLClient->connect(
        host => '127.0.0.1',
        port => '33033',
        cb   => {
            my ($tnt) = @_;
            ...
        }
    );

    $tnt->ping( sub { .. } );
    $tnt->insert(0, [ 1, 2, 3 ], sub { ... });
    $tnt->select(1, 0, [ [ 1, 2 ], [ 3, 4 ] ], sub { ... });
    $tnt->update(0, [ 1 ], [ [ 1 => add pack 'L<', 1 ] ], sub { ... });
    $tnt->call_lua( 'box.select', [ 0, 1, 2 ], sub { ... });


=head1 DESCRIPTION

This module provides a low-level interface to
L<Tarantool|http://tarantool.org>.

=head1 METHODS

All methods receive B<callback> as the last argument. The callback receives
B<HASHREF> value with the following fields:

=over

=item status

Done status:

=over

=item fatal

A fatal error occurred. The server closed the connection or returned a
broken package.

=item buffer

An internal driver error.

=item error

The request wasn't executed: the server returned an error.

=item ok

Request was executed OK.

=back

=item errstr

If an error occurred, contains error description.

=item code

Contains reply code.

=item req_id

Contains request id.
(see
L<protocol documentation|https://github.com/mailru/tarantool/blob/master/doc/box-protocol.txt>)

=item type

Contains request type
(see
L<protocol documentation|https://github.com/mailru/tarantool/blob/master/doc/box-protocol.txt>)

=item count

Contains the count of returned tuples.

=item tuples

Returned tuples (B<ARRAYREF> of B<ARRAYREF>).

=back

If you use B<NUM> or B<NUM64> field types, values
for these fields need to be packed before they are sent to the
server, and unpacked when received in a response.
This is a low-level driver :)

=cut


package DR::Tarantool::LLClient;
use base qw(DR::Tarantool::AEConnection);
use AnyEvent;
use AnyEvent::Socket;
use Carp;
use Devel::GlobalDestruction;
use File::Spec::Functions 'catfile';
$Carp::Internal{ (__PACKAGE__) }++;

use Scalar::Util 'weaken';
require DR::Tarantool;
use Data::Dumper;
use Time::HiRes ();

my $LE = $] > 5.01 ? '<' : '';


=head2 connect

Creates a connection to L<Tarantool| http://tarantool.org>

    DR::Tarantool::LLClient->connect(
        host => '127.0.0.1',
        port => '33033',
        cb   => {
            my ($tnt) = @_;
            ...
        }
    );

=head3 Arguments

=over

=item host & port

Host and port to connect to.

=item reconnect_period

An interval to wait before trying to reconnect after a fatal error or
unsuccessful connect. If the field is defined and is greater than 0, the
driver tries to reconnect to the server after this interval.

B<Important>: the driver does not reconnect after B<the first>
unsuccessful connection. It calls B<callback> instead.

=item reconnect_always

Try to reconnect even after the first unsuccessful connection.

=item cb

Done callback. The callback receives a connection handle
connected to the server or an error string.

=back

=cut

sub connect {
    my $class = shift;

    my (%opts, $cb);

    if (@_ % 2) {
        $cb = pop;
        %opts = @_;
    } else {
        %opts = @_;
        $cb = delete $opts{cb};
    }

    $cb ||= sub {  };

    $class->_check_cb( $cb );

    return $class->SUPER::connect if ref $class;


    my $host = $opts{host} || 'localhost';
    my $port = $opts{port} or croak "port is undefined";

    my $reconnect_period    = $opts{reconnect_period} || 0;
    my $reconnect_always    = $opts{reconnect_always} || 0;

    my $self = $class->SUPER::new(
        host                => $host,
        port                => $port,
        reconnect_period    => $reconnect_period,
        reconnect_always    => $reconnect_always,
    );

    $self->on(connected => sub {
        my ($self) = @_;
        $self->on(connected => $self->on_connected);
        $self->on_connected->($self);
        $cb->($self);
    });

    $self->on(connfail => sub {
        my ($self) = @_;
        $self->on(connfail => undef);
        unless($self->reconnect_always) {
            $self->on(connected => undef);
            $cb->($self->error);
        }
    });

    $self->on(error => sub {
        my ($self) = @_;
        $self->_fatal_error($self->error);
    });

    $self->SUPER::connect;

    unless (defined wantarray) {
        my $cbb = $cb;
        $cb = sub {
            &$cbb;
            undef $self;
        };
        return;
    }

    return $self;
}

sub _reconnected {
}


sub on_connected {
    sub {
        my ($self) = @_;
        $self->_reconnected;
        $self->{guard}{read} = AE::io $self->fh, 0, $self->on_read;
    }
}


sub disconnect {
    my ($self, $cb) = @_;
    $cb ||= sub {  };
    $self->_check_cb( $cb );

    $self->SUPER::disconnect;
    $cb->( 'ok' );
}

sub DESTROY {
    return if in_global_destruction;
    my ($self) = @_;
    $self->disconnect;
}

=head2 is_connected

B<True> if this connection is established.

=cut

sub is_connected {
    my ($self) = @_;
    $self->state eq 'connected';
}

=head2 connection_status

Contains a string with the status of connection. Return value can be:

=over

=item ok

Connection is established.

=item not_connected

Connection isn't established yet, or was lost.

=item connecting

The driver is connecting to the server.

=item fatal

An attempt to connect was made, but ended up with an error. 
If the event loop is running, and B<reconnect_period> option
is set, the driver continues to try to reconnect and update its status.

=back

=cut

sub connection_status {
    my ($self) = @_;
    return 'ok'         if $self->state eq 'connected';
    return 'connecting' if $self->state eq 'connecting';
    return 'fatal'      if $self->state eq 'error';
    return 'not_connected';
}


=head2 ping

Ping the server.

    $tnt->ping( sub { .. } );

=head3 Arguments

=over

=item a callback

=back

=cut

sub ping :method {
    my ($self, $cb) = @_;
    my $id = $self->_req_id;
    $self->_check_cb( $cb );
    my $pkt = DR::Tarantool::_pkt_ping( $id );

    if ($self->is_connected) {
        $self->_request( $id, $pkt, $cb );
        return;
    }
    
    unless($self->reconnect_period) {
        $cb->({
                status  => 'fatal',
                req_id  => $id,
                errstr  => "Connection isn't established (yet)"
            }
        );
        return;
    }

    my $this = $self;
    weaken $this;

    my $tmr;
    $tmr = AE::timer $self->reconnect_period, 0, sub {
        undef $tmr;
        if ($this and $this->is_connected) {
            $this->_request( $id, $pkt, $cb );
            return;
        }
        $cb->({
                status  => 'fatal',
                req_id  => $id,
                errstr  => "Connection isn't established (yet)"
            }
        );
    };
}


=head2 insert

Insert a tuple.

    $tnt->insert(0, [ 1, 2, 3 ], sub { ... });
    $tnt->insert(0, [ 4, 5, 6 ], $flags, sub { .. });

=head3 Arguments

=over

=item space

=item tuple

=item flags (optional)

=item callback

=back

=cut

sub insert :method {

    my $self = shift;
    $self->_check_number(   my $space = shift       );
    $self->_check_tuple(    my $tuple = shift       );
    $self->_check_cb(       my $cb = pop            );
    $self->_check_number(   my $flags = pop || 0    );
    croak "insert: tuple must be ARRAYREF" unless ref $tuple eq 'ARRAY';
    $flags ||= 0;

    my $id = $self->_req_id;
    my $pkt = DR::Tarantool::_pkt_insert( $id, $space, $flags, $tuple );
    $self->_request( $id, $pkt, $cb );
    return;
}

=head2 select

Select a tuple or tuples.

    $tnt->select(1, 0, [ [ 1, 2 ], [ 3, 4 ] ], sub { ... });
    $tnt->select(1, 0, [ [ 1, 2 ], [ 3, 4 ] ], 1, sub { ... });
    $tnt->select(1, 0, [ [ 1, 2 ], [ 3, 4 ] ], 1, 2, sub { ... });

=head3 Arguments

=over

=item space

=item index

=item tuple_keys

=item limit (optional)

If the limit isn't set or is zero, select extracts all records without
a limit.

=item offset (optional)

Default value is B<0>.

=item callback for results

=back

=cut

sub select :method {

    my $self = shift;
    $self->_check_number(       my $ns = shift                  );
    $self->_check_number(       my $idx = shift                 );
    $self->_check_tuple_list(   my $keys = shift                );
    $self->_check_cb(           my $cb = pop                    );
    $self->_check_number(       my $limit = shift || 0x7FFFFFFF );
    $self->_check_number(       my $offset = shift || 0         );

    my $id = $self->_req_id;
    my $pkt =
        DR::Tarantool::_pkt_select($id, $ns, $idx, $offset, $limit, $keys);
    $self->_request( $id, $pkt, $cb );
    return;
}

=head2 update

Update a tuple.

    $tnt->update(0, [ 1 ], [ [ 1 => add 1 ] ], sub { ... });
    $tnt->update(
        0,                                      # space
        [ 1 ],                                  # key
        [ [ 1 => add 1 ], [ 2 => add => 1 ],    # operations
        $flags,                                 # flags
        sub { ... }                             # callback
    );
    $tnt->update(0, [ 1 ], [ [ 1 => add 1 ] ], $flags, sub { ... });

=head3 Arguments

=over

=item space

=item tuple_key

=item operations list

=item flags (optional)

=item callback for results

=back

=cut

sub update :method {

    my $self = shift;
    $self->_check_number(           my $ns = shift          );
    $self->_check_tuple(            my $key = shift         );
    $self->_check_operations(       my $operations = shift  );
    $self->_check_cb(               my $cb = pop            );
    $self->_check_number(           my $flags = pop || 0    );

    my $id = $self->_req_id;
    my $pkt = DR::Tarantool::_pkt_update($id, $ns, $flags, $key, $operations);
    $self->_request( $id, $pkt, $cb );
    return;

}

=head2 delete

Delete a tuple.

    $tnt->delete( 0, [ 1 ], sub { ... });
    $tnt->delete( 0, [ 1 ], $flags, sub { ... });

=head3 Arguments

=over

=item space

=item tuple_key

=item flags (optional)

=item callback for results

=back

=cut

sub delete :method {
    my $self = shift;
    my $ns = shift;
    my $key = shift;
    $self->_check_tuple( $key );
    my $cb = pop;
    $self->_check_cb( $cb );
    my $flags = pop || 0;

    my $id = $self->_req_id;
    my $pkt = DR::Tarantool::_pkt_delete($id, $ns, $flags, $key);
    $self->_request( $id, $pkt, $cb );
    return;
}


=head2 call_lua

Calls a lua procedure.

    $tnt->call_lua( 'box.select', [ 0, 1, 2 ], sub { ... });
    $tnt->call_lua( 'box.select', [ 0, 1, 2 ], $flags, sub { ... });

=head3 Arguments

=over

=item name of the procedure

=item tuple_key

=item flags (optional)

=item callback to call when the request is ready

=back

=cut

sub call_lua :method {

    my $self = shift;
    my $proc = shift;
    my $tuple = shift;
    $self->_check_tuple( $tuple );
    my $cb = pop;
    $self->_check_cb( $cb );
    my $flags = pop || 0;

    my $id = $self->_req_id;
    my $pkt = DR::Tarantool::_pkt_call_lua($id, $flags, $proc, $tuple);
    $self->_request( $id, $pkt, $cb );
    return;
}


=head2 last_code

Return code of the last request or B<undef> if there was no
request. 

=cut

sub last_code {
    my ($self) = @_;
    return $self->{last_code} if exists $self->{last_code};
    return undef;
}


=head2 last_error_string

An error string if the last request ended up with an 
error, or B<undef> otherwise.

=cut

sub last_error_string {
    my ($self) = @_;
    return $self->{last_error_string} if exists $self->{last_error_string};
    return undef;
}

=head1 Logging

The module can log requests/responses. Logging can be turned ON by 
setting these environment variables:

=over

=item TNT_LOG_DIR

Instructs LLClient to record all requests/responses into this directory.

=item TNT_LOG_ERRDIR

Instructs LLClient to record all requests/responses which
ended up with an error into this directory.

=back

=cut


sub _log_transaction {
    my ($self, $id, $pkt, $response, $res_pkt) = @_;

    my $logdir = $ENV{TNT_LOG_DIR};
    goto DOLOG if $logdir;
    $logdir = $ENV{TNT_LOG_ERRDIR};
    goto DOLOG if $logdir and $response->{status} ne 'ok';
    return;

    DOLOG:
    eval {
        die "Directory $logdir was not found, transaction wasn't logged\n"
            unless -d $logdir;

        my $now = Time::HiRes::time;

        my $logdirname = catfile $logdir,
            sprintf '%s-%s', $now, $response->{status};

        die "Object $logdirname is already exists, transaction wasn't logged\n"
            if -e $logdirname or -d $logdirname;
        
        die $! unless mkdir $logdirname;
       
        my $rrname = catfile $logdirname, 
            sprintf 'rawrequest-%04d.bin', $id;
        open my $fh, '>:raw', $rrname or die "Can't open $rrname: $!\n";
        print $fh $pkt;
        close $fh;

        my $respname = catfile $logdirname,
            sprintf 'dumpresponse-%04d.txt', $id;

        open $fh, '>:raw', $respname or die "Can't open $respname: $!\n";
        
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Deepcopy = 1;
        local $Data::Dumper::Maxdepth = 0;
        print $fh Dumper($response);
        close $fh;

        if (defined $res_pkt) {
            $respname = catfile $logdirname,
                sprintf 'rawresponse-%04d.bin', $id;
            open $fh, '>:raw', $respname or die "Can't open $respname: $!\n";
            print $fh $res_pkt;
            close $fh;
        }
    };
    warn $@ if $@;
}


sub _request {
    my ($self, $id, $pkt, $cb ) = @_;
#     Scalar::Util::weaken $self;
  
    my $cbres = $cb;
    $cbres = sub { $self->_log_transaction($id, $pkt, @_); &$cb }
        if $ENV{TNT_LOG_ERRDIR} or $ENV{TNT_LOG_DIR};

    $self->{ wait }{ $id } = $cbres;

    $self->push_write($pkt);
}

sub _req_id {
    my ($self) = @_;
    for (my $id = $self->{req_id} || 0;; $id++) {
        $id = 0 unless $id < 0x7FFF_FFFF;
        next if exists $self->{wait}{$id};
        $self->{req_id} = $id + 1;
        return $id;
    }
}

sub _fatal_error {
    my ($self, $msg, $raw) = @_;

    $self->{last_code} ||= -1;
    $self->{last_error_string} ||= $msg;

    delete $self->{fh};
    $self->{wbuf} = '';

    my $wait = delete $self->{wait};
    $self->{wait} = {};
    for (keys %$wait) {
        my $cb = delete $wait->{$_};
        $cb->({ status  => 'fatal',  errstr  => $msg, req_id => $_ }, $raw);
    }

    $self->set_error($msg) if $self->state ne 'error';
}


sub _check_rbuf {{
    my ($self) = @_;
    return unless length $self->{rbuf} >= 12;
    my (undef, $blen) = unpack "L$LE L$LE", $self->{rbuf};
    return unless length $self->{rbuf} >= 12 + $blen;
    

    my $pkt = substr $self->{rbuf}, 0, 12 + $blen, '';

    my $res = DR::Tarantool::_pkt_parse_response( $pkt );

    $self->{last_code} = $res->{code};
    if (exists $res->{errstr}) {
        $self->{last_error_string} = $res->{errstr};
    } else {
        delete $self->{last_error_string};
    }

    if ($res->{status} =~ /^(fatal|buffer)$/) {
        $self->_fatal_error( $res->{errstr}, $pkt );
        return;
    }

    my $id = $res->{req_id};
    my $cb = delete $self->{ wait }{ $id };
    if ('CODE' eq ref $cb) {
        $cb->( $res, $pkt );
    } else {
        warn "Unexpected reply from tarantool with id = $id";
    }
    redo;
}}


sub on_read {
    my $self = shift;
    sub {
        my $rd = sysread $self->fh, my $buf, 4096;
        unless(defined $rd) {
            return if $!{EINTR};
            $self->_fatal_error("Socket error: $!");
            return;
        }

        unless($rd) {
            $self->_fatal_error("Socket error: Server closed connection");
            return;
        }
        $self->{rbuf} .= $buf;
        $self->_check_rbuf;
    }
        # write responses as binfile for tests
#         {
#             my ($type, $blen, $id, $code, $body) =
#                 unpack 'L< L< L< L< A*', $hdr . $data;

#             my $sname = sprintf 't/test-data/%05d-%03d-%s.bin',
#                 $type || 0, $code, $code ? 'fail' : 'ok';
#             open my $fh, '>:raw', $sname;
#             print $fh $hdr;
#             print $fh $data;
#             warn "$sname saved (body length: $blen)";
#         }
}

sub _check_cb {
    my ($self, $cb) = @_;
    croak 'Callback must be CODEREF' unless 'CODE' eq ref $cb;
}

sub _check_tuple {
    my ($self, $tuple) = @_;
    croak 'Tuple must be ARRAYREF' unless 'ARRAY' eq ref $tuple;
}

sub _check_tuple_list {
    my ($self, $list) = @_;
    croak 'Tuplelist must be ARRAYREF of ARRAYREF' unless 'ARRAY' eq ref $list;
    croak 'Tuplelist is empty' unless @$list;
    $self->_check_tuple($_) for @$list;
}

sub _check_number {
    my ($self, $number) = @_;
    croak "argument must be number"
        unless defined $number and $number =~ /^\d+$/;
}


sub _check_operation {
    my ($self, $op) = @_;
    croak 'Operation must be ARRAYREF' unless 'ARRAY' eq ref $op;
    croak 'Wrong update operation: too short arglist' unless @$op >= 2;
    croak "Wrong operation: $op->[1]"
        unless $op->[1] and
            $op->[1] =~ /^(delete|set|insert|add|and|or|xor|substr)$/;
    $self->_check_number($op->[0]);
}

sub _check_operations {
    my ($self, $list) = @_;
    croak 'Operations list must be ARRAYREF of ARRAYREF'
        unless 'ARRAY' eq ref $list;
    croak 'Operations list is empty' unless @$list;
    $self->_check_operation( $_ ) for @$list;
}

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=head1 VCS

The project is placed git repo on github:
L<https://github.com/dr-co/dr-tarantool/>.

=cut

1;
