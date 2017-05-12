use utf8;
use strict;
use warnings;

package DR::Tarantool::LLSyncClient;
use Carp;
use IO::Socket::UNIX;
use IO::Socket::INET;
require DR::Tarantool;

my $LE = $] > 5.01 ? '<' : '';

$Carp::Internal{ (__PACKAGE__) }++;

sub connect {
    my ($class, %opts) = @_;

    my $host = $opts{host} || 'localhost';
    my $port = $opts{port} or croak 'port is undefined';

    my $reconnect_period = $opts{reconnect_period} || 0;
    my $reconnect_always = $opts{reconnect_always} || 0;


    my $raise_error = 1;
    if (exists $opts{raise_error}) {
        $raise_error = $opts{raise_error} ? 1 : 0;
    }

    my $self = bless {
        host                => $host,
        port                => $port,
        raise_error         => $raise_error,
        reconnect_period    => $reconnect_period,
        id                  => 0,
    } => ref ($class) || $class;

    unless ($self->_connect()) {
        unless ($reconnect_always) {
            return undef unless $self->{raise_error};
            croak "Can't connect to $self->{host}:$self->{port}: $@";
        }
        unless ($reconnect_period) {
            return undef unless $self->{raise_error};
            croak "Can't connect to $self->{host}:$self->{port}: $@";
        }
    }
    return $self;
}


sub _connect {
    my ($self) = @_;

    if ($self->{host} eq 'unix/' or $self->{port} =~ /\D/) {
        return $self->{fh} = IO::Socket::UNIX->new(Peer => $self->{port});
    } else {
        return $self->{fh} = IO::Socket::INET->new(
            PeerHost    => $self->{host},
            PeerPort    => $self->{port},
            Proto       => 'tcp',
        );
    }
}

sub _req_id {
    my ($self) = @_;
    return $self->{id}++ if $self->{id} < 0x7FFF_FFFE;
    return $self->{id} = 0;
}

sub _request {
    my ($self, $id, $pkt ) = @_;
    until($self->{fh}) {
        unless ($self->{reconnect_period}) {
            $self->{last_error_string} = "Connection isn't established";
            croak $self->{last_error_string} if $self->{raise_error};
            return undef;
        }
        next if $self->_connect;
        sleep $self->{reconnect_period};
    }

    my $len = length $pkt;

    # send request
    while($len > 0) {
        no warnings; # closed socket
        my $slen = syswrite $self->{fh}, $pkt;
        unless(defined $slen) {
            next if $!{EINTR};
            goto SOCKET_ERROR;
        }
        $len -= $slen;
        substr $pkt, 0, $slen, '';
    }

    $pkt = '';
    while(12 > length $pkt) {
        no warnings; # closed socket
        my $rl = sysread $self->{fh}, $pkt, 12 - length $pkt, length $pkt;
        unless (defined $rl) {
            next if $!{EINTR};
            goto SOCKET_ERROR;
        }
    }

    my (undef, $blen) = unpack "L$LE L$LE", $pkt;

    while(12 + $blen > length $pkt) {
        no warnings; # closed socket
        my $rl = sysread $self->{fh},
            $pkt, 12 + $blen - length $pkt, length $pkt;
        unless (defined $rl) {
            next if $!{EINTR};
            goto SOCKET_ERROR;
        }
    }

    my $res = DR::Tarantool::_pkt_parse_response( $pkt );
    if ($res->{status} ne 'ok') {
        $self->{last_error_string} = $res->{errstr};
        $self->{last_code} = $res->{code};
        # disconnect
        delete $self->{fh} if $res->{status} =~ /^(fatal|buffer)$/;
        croak $self->{last_error_string} if $self->{raise_error};
        return undef;
    }

    $self->{last_error_string} = $res->{errstr} || '';
    $self->{last_code} = $res->{code};
    return $res;


    SOCKET_ERROR:
        delete $self->{fh};
        $self->{last_error_string} = $!;
        $self->{last_code} = undef;
        croak $self->{last_error_string} if $self->{raise_error};
        return undef;
}

sub ping :method {
    my ($self) = @_;
    unless ($self->{fh}) {
        $self->_connect;
        $self->{last_code} = -1;
        $self->{last_error_string} = "Connection isn't established";
        return 0 unless $self->{fh};
    }
    my $id = $self->_req_id;
    my $pkt = DR::Tarantool::_pkt_ping( $id );
    my $res = eval { $self->_request( $id, $pkt ); };
    return 0 unless $res and $res->{status} eq 'ok';
    return 1;
}


sub call_lua :method {

    my $self = shift;
    my $proc = shift;
    my $tuple = shift;
    $self->_check_tuple( $tuple );
    my $flags = pop || 0;

    my $id = $self->_req_id;
    my $pkt = DR::Tarantool::_pkt_call_lua($id, $flags, $proc, $tuple);
    return $self->_request( $id, $pkt );
}

sub select :method {
    my $self = shift;
    $self->_check_number(       my $ns = shift                  );
    $self->_check_number(       my $idx = shift                 );
    $self->_check_tuple_list(   my $keys = shift                );
    $self->_check_number(       my $limit = shift || 0x7FFFFFFF );
    $self->_check_number(       my $offset = shift || 0         );

    my $id = $self->_req_id;
    my $pkt =
        DR::Tarantool::_pkt_select($id, $ns, $idx, $offset, $limit, $keys);
    return $self->_request( $id, $pkt );
}

sub insert :method {

    my $self = shift;
    $self->_check_number(   my $space = shift       );
    $self->_check_tuple(    my $tuple = shift       );
    $self->_check_number(   my $flags = pop || 0    );
    croak "insert: tuple must be ARRAYREF" unless ref $tuple eq 'ARRAY';
    $flags ||= 0;
    
    my $id = $self->_req_id;
    my $pkt = DR::Tarantool::_pkt_insert( $id, $space, $flags, $tuple );
    return $self->_request( $id, $pkt );
}

sub update :method {

    my $self = shift;
    $self->_check_number(           my $ns = shift          );
    $self->_check_tuple(            my $key = shift         );
    $self->_check_operations(       my $operations = shift  );
    $self->_check_number(           my $flags = pop || 0    );

    my $id = $self->_req_id;
    my $pkt = DR::Tarantool::_pkt_update($id, $ns, $flags, $key, $operations);
    return $self->_request( $id, $pkt );
}


sub delete :method {
    my $self = shift;
    my $ns = shift;
    my $key = shift;
    $self->_check_tuple( $key );
    my $flags = pop || 0;

    my $id = $self->_req_id;
    my $pkt = DR::Tarantool::_pkt_delete($id, $ns, $flags, $key);
    return $self->_request( $id, $pkt );
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


sub last_error_string {
    return $_[0]->{last_error_string};
}

sub last_code {
    return $_[0]->{last_code};
}

sub raise_error {
    return $_[0]->{raise_error};
}

1;
