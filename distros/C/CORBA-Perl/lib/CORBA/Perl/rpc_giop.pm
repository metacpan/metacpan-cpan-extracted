use strict;
use warnings;

use CORBA::Perl::CORBA;
use CORBA::Perl::IOP;
use CORBA::Perl::GIOP;
use CORBA::Perl::MIOP;

package CORBA::Perl::GIOP;

use Carp;
use IO::Socket;

our $TRACE;

sub BEGIN {
    $TRACE = 1;
}

my $request_id = 0;

sub GetRequestId {
    $request_id ++;
    return $request_id;
}

sub RequestOneWay {
    my ($sock, $request_header, $request_body) = @_;
    if ($sock->getsockopt(SOL_SOCKET, SO_TYPE) == SOCK_DGRAM) {
        return CORBA::Perl::DIOP::RequestOneWay($sock, $request_header, $request_body);
    }
    else {
        return _RequestOneWay($sock, $request_header, $request_body);
    }
}

sub _RequestOneWay {
    my ($sock, $request_header, $request_body) = @_;
    $request_header->{request_id} = GetRequestId();
    my $request = q{};
    CORBA::Perl::GIOP::RequestHeader_1_2__marshal(\$request, $request_header);
    $request .= $request_body;
    my $buffer = q{};
    CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$buffer, {
            magic           => [ 'G', 'I', 'O', 'P' ],
            GIOP_version    => {
                    major           => 1,
                    minor           => 2,
            },
            flags           => 0x01,    # flags : little endian
            message_type    => 0,       # Request
            message_size    => length $request
        }
    );
    $buffer .= $request;
    my $rc = $sock->send($buffer);
    croak "send error with $sock ($!).\n"
            unless (defined $rc);
}

sub RequestReply {
    my ($sock, $request_header, $request_body) = @_;
    if ($sock->getsockopt(SOL_SOCKET, SO_TYPE) == SOCK_DGRAM) {
        return CORBA::Perl::DIOP::RequestReply($sock, $request_header, $request_body);
    }
    else {
        return _RequestReply($sock, $request_header, $request_body);
    }
}

sub _RequestReply {
    my ($sock, $request_header, $request_body) = @_;
    $request_header->{request_id} = GetRequestId();
#   print "request id $request_id\n";
    my $request = q{};
    CORBA::Perl::GIOP::RequestHeader_1_2__marshal(\$request, $request_header);
    $request .= $request_body;
    my $buffer = q{};
    CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$buffer, {
            magic           => [ 'G', 'I', 'O', 'P' ],
            GIOP_version    => {
                    major           => 1,
                    minor           => 2,
            },
            flags           => 0x01,    # flags : little endian
            message_type    => 0,       # Request
            message_size    => length $request
        }
    );
    $buffer .= $request;
    my $rc = $sock->send($buffer);
    croak "send error with $sock ($!).\n"
            unless (defined $rc);
    my $header;
RETRY:
    $rc = $sock->recv($header, 12);
    croak "header: recv error with $sock ($!).\n"
            unless (defined $rc);
    my $endian = 0;
    my $offset = 0;
    my $magic = q{};
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$header, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$header, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$header, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$header, \$offset, $endian);
    my $GIOP_version = CORBA::Perl::GIOP::Version__demarshal(\$header, \$offset, $endian);
    my $flags = CORBA::Perl::CORBA::octet__demarshal(\$header, \$offset, $endian);
    $endian = $flags & 0x01;            # now, endian is known
    my $message_type  = CORBA::Perl::CORBA::octet__demarshal(\$header, \$offset, $endian);
    my $message_size  = CORBA::Perl::CORBA::unsigned_long__demarshal(\$header, \$offset, $endian);

    if (        $magic eq 'GIOP'
            and $GIOP_version->{major} == 1
            and $GIOP_version->{minor} == 2
            and $message_type == 1 ) {
        my $reply = q{};
        while ($message_size > 0) {
            my $reply_i;
            $rc = $sock->recv($reply_i, $message_size);
            croak "reply: recv error with $sock ($!).\n"
                    unless (defined $rc);
            $reply .= $reply_i;
            $message_size -= length $reply_i;
        }
        $offset = 0;
        my $reply_header = CORBA::Perl::GIOP::ReplyHeader_1_2__demarshal(\$reply, \$offset, $endian);
        my $reply_body = substr $reply, $offset;
        if ($request_header->{request_id} == $reply_header->{request_id}) {
#           print "reply id $reply_header->{request_id}\n";
            return ($reply_header->{reply_status}, $reply_header->{service_context}, $reply_body, $endian);
        }
        elsif ($request_id > $reply_header->{request_id}) {
            warn "bad request id $reply_header->{request_id} (waiting $request_header->{request_id}).\n";
            goto RETRY;
        }
        else {
            croak "bad request id $reply_header->{request_id} (waiting $request_header->{request_id}).\n";
        }
    }
    else {
        croak "bad header.\n";
    }
}

package CORBA::Perl::GIOP::NB;

use Carp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{callback} = {};
    return $self;
}

sub Collect {
    my $self = shift;
    my $collection = q{};
    my $idx = 1;
    my $nb = scalar(@_) / 3;
    while (@_) {
        my $message = q{};
        my $request_header = shift;
        my $request_body = shift;
        my $callback = shift;
        $request_header->{request_id} = CORBA::Perl::GIOP::GetRequestId();
        $self->{callback}->{$request_header->{request_id}} = $callback;
        my $request = q{};
        CORBA::Perl::GIOP::RequestHeader_1_2__marshal(\$request, $request_header);
        $request .= $request_body;
        CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$message, {
                magic           => [ 'G', 'I', 'O', 'P' ],
                GIOP_version    => {
                        major           => 1,
                        minor           => 2,
                },
                flags               => 0x01     # little endian
                                     | (($idx != $nb) ? 0x80 : 0x00),
                message_type    => 0,       # Request
                message_size    => length $request
            }
        );
        $message .= $request;
        $collection .= $message;
        $idx ++;
    }
    return $collection;
}

sub Dispatch {
    my $self = shift;
    my ($message) = @_;

    my $endian = 0;
    my $more;
    while (1) {
        my $offset = 0;
        my $magic = q{};
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        my $GIOP_version = CORBA::Perl::GIOP::Version__demarshal(\$message, \$offset, $endian);
        my $flags = CORBA::Perl::CORBA::octet__demarshal(\$message, \$offset, $endian);
        $endian = $flags & 0x01;            # now, endian is known
        $more = $flags & 0x80;
        my $message_type = CORBA::Perl::CORBA::octet__demarshal(\$message, \$offset, $endian);
        my $message_size = CORBA::Perl::CORBA::unsigned_long__demarshal(\$message, \$offset, $endian);

        if (        $magic eq 'GIOP'
                and $GIOP_version->{major} == 1
                and $GIOP_version->{minor} == 2
                and $message_type == 1 ) {

            my $reply_header = CORBA::Perl::GIOP::ReplyHeader_1_2__demarshal(\$message, \$offset, $endian);
            my $request_id = $reply_header->{request_id};
            if (exists $self->{callback}->{$request_id}) {
                my $callback = $self->{callback}->{$request_id};
                ${$callback}[0](${$callback}[1], $reply_header->{reply_status}, $reply_header->{service_context}, \$message, \$offset, $endian);
                delete $self->{callback}->{$request_id};
            }
            $message = substr $message, 12+$message_size;
        }
        last unless ($more);
    }
}

package CORBA::Perl::GIOP::Servant;

use Carp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{itf} = {};
    $self->{all_reply} = q{};
    return $self;
}

sub Register {
    my $self = shift;
    my ($interface, $classname) = @_;

    $self->{itf}->{$interface} = $classname;
}

sub Servant {
    my $self = shift;
    my ($message) = @_;

    my $endian = 0;
    my $offset = 0;
    my $magic = q{};
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
    my $GIOP_version = CORBA::Perl::GIOP::Version__demarshal(\$message, \$offset, $endian);
    my $flags = CORBA::Perl::CORBA::octet__demarshal(\$message, \$offset, $endian);
    $endian = $flags & 0x01;            # now, endian is known
    my $message_type  = CORBA::Perl::CORBA::octet__demarshal(\$message, \$offset, $endian);
    my $message_size  = CORBA::Perl::CORBA::unsigned_long__demarshal(\$message, \$offset, $endian);

    if (        $magic eq 'GIOP'
            and $GIOP_version->{major} == 1
            and $GIOP_version->{minor} == 2
            and $message_type == 0 ) {

        my ($reply_status, $reply_body);
        my $request_header = CORBA::Perl::GIOP::RequestHeader_1_2__demarshal(\$message, \$offset, $endian);
        my $interface = ${$request_header->{target}}[1];
        if (!exists $self->{itf}->{$interface}) {
            warn "unknown interface '$interface'.\n";
            $reply_status = CORBA::Perl::CORBA::SYSTEM_EXCEPTION;
            $reply_body = q{};
            CORBA::Perl::CORBA::string__marshal(\$reply_body, "IDL:CORBA/NO_IMPLEMENT:1.0");
            CORBA::Perl::CORBA::unsigned_long__marshal(\$reply_body, 11);
            CORBA::Perl::CORBA::completion_status__marshal(\$reply_body, CORBA::COMPLETED_NO());
        }
        else {
            my $classname = $self->{itf}->{$interface};
            my $op = $request_header->{operation};
            if (! $classname->can($op)) {
                warn "unknown operation '$request_header->{operation}'.\n";
                $reply_status = CORBA::Perl::CORBA::SYSTEM_EXCEPTION;
                $reply_body = q{};
                CORBA::Perl::CORBA::string__marshal(\$reply_body, "IDL:CORBA/BAD_OPERATION:1.0");
                CORBA::Perl::CORBA::unsigned_long__marshal(\$reply_body, 13);
                CORBA::Perl::CORBA::completion_status__marshal(\$reply_body, CORBA::COMPLETED_NO());
            }
            else {
                my $srv_op = 'srv_' . $op;
                ($reply_status, $reply_body) = $classname->$srv_op(\$message, \$offset, $endian);
                return undef unless ($reply_status);    # oneway
            }
        }
        my $reply = q{};
        CORBA::Perl::GIOP::ReplyHeader_1_2__marshal(\$reply, {
                request_id      => $request_header->{request_id},
                reply_status    => $reply_status,
                service_context => [],
            }
        );
        $reply .= $reply_body;
        my $buffer = q{};
        CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$buffer, {
                magic           => [ 'G', 'I', 'O', 'P' ],
                GIOP_version    => {
                        major           => 1,
                        minor           => 2,
                },
                flags           => 0x01,    # flags : little endian
                message_type    => 1,       # Reply
                message_size    => length $reply
            }
        );
        $buffer .= $reply;
        return $buffer
    }
}

sub ServantNB {
    my $self = shift;
    my ($message) = @_;

    my $endian = 0;
    my $more;
    while (1) {
        return undef unless (length($message));
        my $offset = 0;
        my $magic = q{};
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        my $GIOP_version = CORBA::Perl::GIOP::Version__demarshal(\$message, \$offset, $endian);
        my $flags = CORBA::Perl::CORBA::octet__demarshal(\$message, \$offset, $endian);
        $endian = $flags & 0x01;            # now, endian is known
        $more = $flags & 0x80;
        my $message_type = CORBA::Perl::CORBA::octet__demarshal(\$message, \$offset, $endian);
        my $message_size = CORBA::Perl::CORBA::unsigned_long__demarshal(\$message, \$offset, $endian);

        if (        $magic eq 'GIOP'
                and $GIOP_version->{major} == 1
                and $GIOP_version->{minor} == 2
                and $message_type == 0 ) {

            my ($reply_status, $reply_body);
            my $request_header = CORBA::Perl::GIOP::RequestHeader_1_2__demarshal(\$message, \$offset, $endian);
            my $interface = ${$request_header->{target}}[1];
            if (!exists $self->{itf}->{$interface}) {
                warn "unknown interface '$interface'.\n";
                $reply_status = CORBA::Perl::CORBA::SYSTEM_EXCEPTION;
                $reply_body = q{};
                CORBA::Perl::CORBA::string__marshal(\$reply_body, "IDL:CORBA/NO_IMPLEMENT:1.0");
                CORBA::Perl::CORBA::unsigned_long__marshal(\$reply_body, 11);
                CORBA::Perl::CORBA::completion_status__marshal(\$reply_body, CORBA::COMPLETED_NO());
            }
            else {
                my $classname = $self->{itf}->{$interface};
                my $op = $request_header->{operation};
                if (! $classname->can($op)) {
                    warn "unknown operation '$request_header->{operation}'.\n";
                    $reply_status = CORBA::Perl::CORBA::SYSTEM_EXCEPTION;
                    $reply_body = q{};
                    CORBA::Perl::CORBA::string__marshal(\$reply_body, "IDL:CORBA/BAD_OPERATION:1.0");
                    CORBA::Perl::CORBA::unsigned_long__marshal(\$reply_body, 13);
                    CORBA::Perl::CORBA::completion_status__marshal(\$reply_body, CORBA::COMPLETED_NO());
                }
                else {
                    my $srv_op = 'srv_' . $op;
                    ($reply_status, $reply_body) = $classname->$srv_op(\$message, \$offset, $endian);
                }
            }
            if (defined $reply_status) {        # !oneway
                my $msg = q{};
                my $reply = q{};
                CORBA::Perl::GIOP::ReplyHeader_1_2__marshal(\$reply, {
                        request_id      => $request_header->{request_id},
                        reply_status    => $reply_status,
                        service_context => [],
                    }
                );
                $reply .= $reply_body;
                CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$msg, {
                        magic           => [ 'G', 'I', 'O', 'P' ],
                        GIOP_version    => {
                                major           => 1,
                                minor           => 2,
                        },
                        flags           => $flags,
                        message_type    => 1,       # Reply
                        message_size    => length $reply
                    }
                );
                $msg .= $reply;
                $self->{all_reply} .= $msg;
            }
            $message = substr $message, 12+$message_size;
        }
        last unless ($more);
    }
    my $all_reply = $self->{all_reply};
    $self->{all_reply} = q{};
    return $all_reply;
}

package CORBA::Perl::MIOP;

use Carp;

sub Collect {
    my (@msg_giop) = @_;

    my $collection = q{};
    my $idx = 0;
    my $nb = scalar(@msg_giop);
    foreach my $msg (@msg_giop) {
        CORBA::Perl::MIOP::PacketHeader_1_0__marshal(\$collection, {
                magic               => [ 'M', 'I', 'O', 'P' ],
                hdr_version         => 0x10,    # version 1.0
                flags               => 0x01     # little endian
                                     | (($idx == $nb -1) ? 0x02 : 0x00),
                packet_length       => 2048,    # MTU
                packet_number       => $idx,
                number_of_packets   => 0,       # optional
                id                  => q{}      # empty sequence of octet
        }
        );
        $collection .= $msg;
        $idx ++;
    }
    return $collection;
}

package CORBA::Perl::MIOP::Servant;

use Carp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{itf} = {};
    return $self;
}

sub Register {
    my $self = shift;
    my ($interface, $classname) = @_;

    $self->{itf}->{$interface} = $classname;
}

sub Servant {
    my $self = shift;
    my ($collection) = @_;

    my $endian = 0;
    my $offset = 0;
    my $last_packet;
    my @list_reply;
    while (1) {
        my $magic = q{};
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$collection, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$collection, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$collection, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$collection, \$offset, $endian);
        my $version_hdr = CORBA::Perl::CORBA::octet__demarshal(\$collection, \$offset, $endian);
        my $flags = CORBA::Perl::CORBA::octet__demarshal(\$collection, \$offset, $endian);
        $endian = $flags & 0x01;            # now, endian is known
        $last_packet = $flags & 0x02;
        my $packet_length = CORBA::Perl::CORBA::unsigned_short__demarshal(\$collection, \$offset, $endian);
        my $packet_number = CORBA::Perl::CORBA::unsigned_long__demarshal(\$collection, \$offset, $endian);
        my $number_of_packets = CORBA::Perl::CORBA::unsigned_short__demarshal(\$collection, \$offset, $endian);
        my $id = CORBA::Perl::MIOP::UniqueId__demarshal(\$collection, \$offset, $endian);

        if (        $magic eq 'MIOP'
                and $version_hdr == 0x10 ) {
            my $message_header = CORBA::Perl::GIOP::MessageHeader_1_2__demarshal(\$collection, \$offset, $endian);
            my $GIOP_magic = join q{}, @{$message_header->{magic}};

            if (        $GIOP_magic eq 'GIOP'
                    and $message_header->{GIOP_version}->{major} == 1
                    and $message_header->{GIOP_version}->{minor} == 2 ) {
                if ( $message_header->{message_type}  != 0 ) {
                    warn "no request messsage ($message_header->{type})";
                    $offset += $message_header->{message_size};
                }
                else {
                    my $request_header = CORBA::Perl::GIOP::RequestHeader_1_2__demarshal(\$collection, \$offset, $endian);
                    my $interface = ${$request_header->{target}}[1];
                    if (!exists $self->{itf}->{$interface}) {
                        warn "unknown interface '$interface'.\n";
                        $offset += $message_header->{message_size};
                    }
                    else {
                        my $classname = $self->{itf}->{$interface};
                        my $op = $request_header->{operation};
                        if (! $classname->can($op)) {
                            warn "unknown operation '$request_header->{operation}'.\n";
                            $offset += $message_header->{message_size};
                        }
                        else {
                            my $demarshal_body = $op . '__demarshal_body';
                            my @args = $classname->$demarshal_body(\$collection, \$offset, $endian);
                            my $reply = $classname->$op(@args);
                            push @list_reply, $reply if ($reply);
                        }
                    }
                }
            }
        }
        last if ($last_packet);
    }
    return CORBA::Perl::MIOP::Collect(@list_reply);
}

package CORBA::Perl::DIOP;

use Carp;

our $TRACE;

sub BEGIN {
    $TRACE = 1;
}

sub GetRequestId {
    $CORBA::Perl::GIOP::request_id ++;
    return $CORBA::Perl::GIOP::request_id;
}

sub SendAckReply {
    my ($sock, $rep_id) = @_;
    my $buffer = q{};
    CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$buffer, {
            magic           => [ 'G', 'I', 'O', 'P' ],
            GIOP_version    => {
                    major           => 1,
                    minor           => 2,
            },
            flags           => 0x01,    # flags : little endian
            message_type    => 1 + 128, # Reply | Ack
            message_size    => 4
        }
    );
    CORBA::Perl::CORBA::unsigned_long__marshal(\$buffer, $rep_id);
    my $rc = $sock->send($buffer);
    croak "send error with $sock ($!).\n"
            unless (defined $rc);
#   print "send ack $rep_id\n";
}

sub SendRequest {
    my ($sock, $request, $req_id) = @_;
REWRITE:
    my $rc = $sock->send($request);
    croak "send error with $sock ($!).\n"
            unless (defined $rc);
#   print "send request $req_id\n";
    my $ack;
REREAD:
    $rc = $sock->recv($ack, 1024);
    croak "header: recv error with $sock ($!).\n"
            unless (defined $rc);
    my $endian = 0;
    my $offset = 0;
    my $magic = q{};
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$ack, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$ack, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$ack, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$ack, \$offset, $endian);
    my $GIOP_version = CORBA::Perl::GIOP::Version__demarshal(\$ack, \$offset, $endian);
    my $flags = CORBA::Perl::CORBA::octet__demarshal(\$ack, \$offset, $endian);
    $endian = $flags & 0x01;            # now, endian is known
    my $message_type = CORBA::Perl::CORBA::octet__demarshal(\$ack, \$offset, $endian);
    my $message_size = CORBA::Perl::CORBA::unsigned_long__demarshal(\$ack, \$offset, $endian);

    if (        $magic eq 'GIOP'
            and $GIOP_version->{major} == 1
            and $GIOP_version->{minor} == 2 ) {
        if ($message_type != 0 + 128) { # Request | Ack
            goto REREAD;
        }
        my $ack_id = CORBA::Perl::CORBA::unsigned_long__demarshal(\$ack, \$offset, $endian);
#       print "recv ack $ack_id\n";
        if ($ack_id != $req_id) {
            goto REWRITE;
        }
    }
    else {
        croak "bad header.\n";
    }
}

sub RequestOneWay {
    my($sock, $request_header, $request_body) = @_;
    $request_header->{request_id} = GetRequestId();
    my $request = q{};
    CORBA::Perl::GIOP::RequestHeader_1_2__marshal(\$request, $request_header);
    $request .= $request_body;
    my $buffer = q{};
    CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$buffer, {
            magic           => [ 'G', 'I', 'O', 'P' ],
            GIOP_version    => {
                    major           => 1,
                    minor           => 2,
            },
            flags           => 0x01,    # flags : little endian
            message_type    => 0,       # Request
            message_size    => length $request
        }
    );
    $buffer .= $request;
    SendRequest($sock, $buffer, $request_header->{request_id});
}

sub RequestReply {
    my($sock, $request_header, $request_body) = @_;
    $request_header->{request_id} = GetRequestId();
#   print "request id $request_id\n";
    my $request = q{};
    CORBA::Perl::GIOP::RequestHeader_1_2__marshal(\$request, $request_header);
    $request .= $request_body;
    my $buffer = q{};
    CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$buffer, {
            magic           => [ 'G', 'I', 'O', 'P' ],
            GIOP_version    => {
                    major           => 1,
                    minor           => 2,
            },
            flags           => 0x01,    # flags : little endian
            message_type    => 0,       # Request
            message_size    => length $request
        }
    );
    $buffer .= $request;
    SendRequest($sock, $buffer, $request_header->{request_id});
    my $reply;
RETRY:
    my $rc = $sock->recv($reply, 1024);
    croak "header: recv error with $sock ($!).\n"
            unless (defined $rc);
    my $endian = 0;
    my $offset = 0;
    my $magic = q{};
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$reply, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$reply, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$reply, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$reply, \$offset, $endian);
    my $GIOP_version = CORBA::Perl::GIOP::Version__demarshal(\$reply, \$offset, $endian);
    my $flags = CORBA::Perl::CORBA::octet__demarshal(\$reply, \$offset, $endian);
    $endian = $flags & 0x01;            # now, endian is known
    my $message_type = CORBA::Perl::CORBA::octet__demarshal(\$reply, \$offset, $endian);
    my $message_size = CORBA::Perl::CORBA::unsigned_long__demarshal(\$reply, \$offset, $endian);

    if (        $magic eq 'GIOP'
            and $GIOP_version->{major} == 1
            and $GIOP_version->{minor} == 2 ) {
        if ($message_type == 1) {
            my $reply_header = CORBA::Perl::GIOP::ReplyHeader_1_2__demarshal(\$reply, \$offset, $endian);
#           print "recv reply $reply_header->{request_id}\n";
            SendAckReply($sock, $reply_header->{request_id});
            my $reply_body = substr $reply, $offset;
            if ($request_header->{request_id} == $reply_header->{request_id}) {
                return ($reply_header->{reply_status}, $reply_header->{service_context}, $reply_body, $endian);
            }
            elsif ($request_id > $reply_header->{request_id}) {
                warn "bad request id $reply_header->{request_id} (waiting $request_header->{request_id}).\n";
                goto RETRY;
            }
            else {
                croak "bad request id $reply_header->{request_id} (waiting $request_header->{request_id}).\n";
            }
        }
        else {
            goto RETRY;
        }
    }
    else {
        croak "bad header.\n";
    }
}

package CORBA::Perl::DIOP::Servant;

use Carp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{itf} = {};
    return $self;
}

sub Register {
    my $self = shift;
    my ($interface, $classname) = @_;

    $self->{itf}->{$interface} = $classname;
}

sub SendAckRequest {
    my ($sock, $req_id) = @_;
    my $buffer = q{};
    CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$buffer, {
            magic           => [ 'G', 'I', 'O', 'P' ],
            GIOP_version    => {
                    major           => 1,
                    minor           => 2,
            },
            flags           => 0x01,    # flags : little endian
            message_type    => 0 + 128, # Request | Ack
            message_size    => 4
        }
    );
    CORBA::Perl::CORBA::unsigned_long__marshal(\$buffer, $req_id);
    my $rc = $sock->send($buffer);
    croak "send error with $sock ($!).\n"
            unless (defined $rc);
#   print "send ack $req_id\n";
}

sub SendReply {
    my ($sock, $reply, $rep_id) = @_;
REWRITE:
    my $rc = $sock->send($reply);
    croak "send error with $sock ($!).\n"
            unless (defined $rc);
    my $ack;
REREAD:
    $rc = $sock->recv($ack, 1024);
    croak "header: recv error with $sock ($!).\n"
            unless (defined $rc);
#   print "send reply $rep_id\n";
    my $endian = 0;
    my $offset = 0;
    my $magic = q{};
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$ack, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$ack, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$ack, \$offset, $endian);
    $magic .= CORBA::Perl::CORBA::char__demarshal(\$ack, \$offset, $endian);
    my $GIOP_version = CORBA::Perl::GIOP::Version__demarshal(\$ack, \$offset, $endian);
    my $flags = CORBA::Perl::CORBA::octet__demarshal(\$ack, \$offset, $endian);
    $endian = $flags & 0x01;            # now, endian is known
    my $message_type = CORBA::Perl::CORBA::octet__demarshal(\$ack, \$offset, $endian);
    my $message_size = CORBA::Perl::CORBA::unsigned_long__demarshal(\$ack, \$offset, $endian);

    if (        $magic eq 'GIOP'
            and $GIOP_version->{major} == 1
            and $GIOP_version->{minor} == 2 ) {
        if ($message_type != 1 + 128) {     # Reply | Ack
            goto REREAD;
        }
        my $ack_id = CORBA::Perl::CORBA::unsigned_long__demarshal(\$ack, \$offset, $endian);
#       print "recv ack $ack_id\n";
        if ($ack_id != $rep_id) {
            goto REWRITE;
        }
    }
    else {
        croak "bad header.\n";
    }
}

sub Run {
    my $self = shift;
    my ($sock) = @_;

    my $message;
    print "waiting first data ...\n";
    while (1) {
        $sock->recv($message, 1024);
        my $endian = 0;
        my $offset = 0;
        my $magic = q{};
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        $magic .= CORBA::Perl::CORBA::char__demarshal(\$message, \$offset, $endian);
        my $GIOP_version = CORBA::Perl::GIOP::Version__demarshal(\$message, \$offset, $endian);
        my $flags = CORBA::Perl::CORBA::octet__demarshal(\$message, \$offset, $endian);
        $endian = $flags & 0x01;            # now, endian is known
        my $message_type  = CORBA::Perl::CORBA::octet__demarshal(\$message, \$offset, $endian);
        my $message_size  = CORBA::Perl::CORBA::unsigned_long__demarshal(\$message, \$offset, $endian);

        if (        $magic eq 'GIOP'
                and $GIOP_version->{major} == 1
                and $GIOP_version->{minor} == 2
                and $message_type  == 0 ) {

            my ($reply_status, $reply_body);
            my $request_header = CORBA::Perl::GIOP::RequestHeader_1_2__demarshal(\$message, \$offset, $endian);
#           print "recv request $request_header->{request_id}\n";
            SendAckRequest($sock, $request_header->{request_id});
            my $interface = ${$request_header->{target}}[1];
            if (!exists $self->{itf}->{$interface}) {
                warn "unknown interface '$interface'.\n";
                $reply_status = CORBA::Perl::CORBA::SYSTEM_EXCEPTION;
                $reply_body = q{};
                CORBA::Perl::CORBA::string__marshal(\$reply_body, "IDL:CORBA/NO_IMPLEMENT:1.0");
                CORBA::Perl::CORBA::unsigned_long__marshal(\$reply_body, 11);
                CORBA::Perl::CORBA::completion_status__marshal(\$reply_body, CORBA::COMPLETED_NO());
            }
            else {
                my $classname = $self->{itf}->{$interface};
                my $op = $request_header->{operation};
                if (! $classname->can($op)) {
                    warn "unknown operation '$request_header->{operation}'.\n";
                    $reply_status = CORBA::Perl::CORBA::SYSTEM_EXCEPTION;
                    $reply_body = q{};
                    CORBA::Perl::CORBA::string__marshal(\$reply_body, "IDL:CORBA/BAD_OPERATION:1.0");
                    CORBA::Perl::CORBA::unsigned_long__marshal(\$reply_body, 13);
                    CORBA::Perl::CORBA::completion_status__marshal(\$reply_body, CORBA::COMPLETED_NO());
                }
                else {
                    my $srv_op = 'srv_' . $op;
                    ($reply_status, $reply_body) = $classname->$srv_op(\$message, \$offset, $endian);
                    return undef unless ($reply_status);    # oneway
                }
            }
            my $reply = q{};
            CORBA::Perl::GIOP::ReplyHeader_1_2__marshal(\$reply, {
                    request_id      => $request_header->{request_id},
                    reply_status    => $reply_status,
                    service_context => [],
                }
            );
            $reply .= $reply_body;
            my $buffer = q{};
            CORBA::Perl::GIOP::MessageHeader_1_2__marshal(\$buffer, {
                    magic           => [ 'G', 'I', 'O', 'P' ],
                    GIOP_version    => {
                            major           => 1,
                            minor           => 2,
                    },
                    flags           => 0x01,    # flags : little endian
                    message_type    => 1,       # Reply
                    message_size    => length $reply
                }
            );
            $buffer .= $reply;
            SendReply($sock, $buffer, $request_header->{request_id});
        }
    }
}

1;

