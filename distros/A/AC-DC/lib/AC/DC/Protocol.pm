# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Sep-10 13:37 (EDT)
# Function: 
#
# $Id$

package AC::DC::Protocol;
use Carp qw(croak confess);
use Digest::SHA1;
use Fcntl;
use POSIX;
use Socket;
use Time::HiRes 'time';
use strict;

# header:
#	 proto version(32)
#	 message type(32)
#	 auth length(32)
#	 data length(32)
#	 content length(32)
#	 msgidno(32)
#	 flags(32):	is-reply(0), want-reply(1), is-error(2), data-encrypted(3), content-encrypted(4)
#
# followed by:
#       Auth PB(auth-length)
#	Data PB(data-length)
#       Content(content-length)


my $VERSION = 0x41433032;
my $BUFSIZ  = 65536;

my %MSGTYPE;
my %MSGREV;
#  status		=> { num => 0, reqc => '', 			resc => 'ACPStdReply' },


sub header_size { return 28 }

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub add_msg {
    my $class = shift;
    my $name  = shift;
    my $num   = shift;
    my $reqc  = shift;
    my $resc  = shift;

    my $d = {
        name	=> $name,
        num	=> $num,
        reqc	=> $reqc,
        resc	=> $resc,
    };

    $MSGTYPE{$name} = $d;
    $MSGREV{$num}   = $name;

}

################################################################

sub encode_header {
    my $me = shift;
    my %p = @_;
    # type, auth_length, data_length, content_length, msgidno,
    # is_reply, want_reply, is_error

    my $mt = $MSGTYPE{ $p{type} };
    confess "unknown message type $p{type}\n" unless defined $mt;

    my $flags = ( $p{is_reply}         ? 1 : 0 )
	     | ( $p{want_reply}        ? 2 : 0 )
	     | ( $p{is_error}          ? 4 : 0 )
             | ( $p{data_encrypted}    ? 8 : 0 )
             | ( $p{content_encrypted} ? 16 : 0 );

    return pack( "NNNNNNN",
		 $VERSION, $mt->{num}, $p{auth_length}, $p{data_length}, $p{content_length}, $p{msgidno}, $flags );

}

sub decode_header {
    my $me    = shift;
    my $headr = shift;

    my( $ver, $mt, $al, $dl, $cl, $id, $fl )
	= unpack("NNNNNNN", $headr);

    my %p = (
        auth_length	=> $al,
	data_length	=> $dl,
	content_length	=> $cl,
	msgidno		=> $id,
	type		=> $MSGREV{$mt},
    );

    confess "unknown protocol version $ver\n" unless $ver == $VERSION;
    confess "unknown protocol message $mt\n"  unless $p{type};

    $p{is_reply}   = ($fl & 1) ? 1 : 0;
    $p{want_reply} = ($fl & 2) ? 1 : 0;
    $p{is_error}   = ($fl & 4) ? 1 : 0;
    $p{data_encrypted} = ($fl & 8) ? 1 : 0;
    $p{content_encrypted} = ($fl & 16) ? 1 : 0;

    return \%p;
}

sub encrypt {
    my $me = shift;
    # NYI - placeholder
}

sub decrypt {
    my $me   = shift;
    my $auth = shift;
    my $buf  = shift;
    # NYI - placeholder
}

sub _encode_common {
    my $me    = shift;
    my $how   = shift;
    my $proto = shift;
    my $data  = shift;
    my $cont  = shift;	# reference
    my $auth  = shift;	# NYI

    my $mt = $MSGTYPE{ $proto->{type} };
    confess "unknown message type $proto->{type}\n" unless defined $mt;

    my $apb = $auth ? ACPAuth->encode( $auth ) : '';
    my $gpb = $data ? $mt->{$how}->encode( $data ) : '';

    if( $proto->{data_encrypted} && $gpb ){
        $gpb = $me->encrypt( $auth, $gpb );
    }

    my $hdr = $me->encode_header(
        type		  => $proto->{type},
        want_reply	  => $proto->{want_reply},
        is_reply	  => $proto->{is_reply},
        msgidno		  => $proto->{msgidno},
        data_encrypted	  => $proto->{data_encrypted},
        content_encrypted => $proto->{content_encrypted},
        auth_length	  => length($apb),
        data_length	  => length($gpb),
        content_length 	  => ($cont ? length($$cont) : 0),
       );

    # caller needs to add content. (to avoid large copy)
    return $hdr . $apb . $gpb;

}

sub _decode_common {
    my $me    = shift;
    my $how   = shift;
    my $reply = shift;
    my $data  = shift;

    my $mt = $MSGTYPE{ $reply->{type} };
    confess "unknown message type $reply->{type}\n" unless defined $mt;

    return unless $data || $reply->{data};
    my $res = $mt->{$how}->decode( $data || $reply->{data} || '' );
    return $res;
}

sub encode_request {
    my $me = shift;

    return $me->_encode_common( 'reqc', @_ );
}
sub encode_reply {
    my $me = shift;

    return $me->_encode_common( 'resc', @_ );
}

sub decode_request {
    my $me    = shift;

    return $me->_decode_common( 'reqc', @_ );
}

sub decode_reply {
    my $me    = shift;

    return $me->_decode_common( 'resc', @_ );
}

################################################################

sub _try_to_connect {
    my $s  = shift;
    my $sa = shift;
    my $to = shift;

    my $fn = fileno($s);
    my $wfd = "\0\0\0\0";
    vec($wfd, $fn, 1) = 1;

    my $i = connect($s, $sa);
    return 1 if $i;	# connected
    return unless $! == EISCONN || $! == EALREADY || $! == EINPROGRESS;

    # wait until connected or timeout
    my $is = select(undef, $wfd, undef, $to);
    return if $is == -1;
    return 1 if vec($wfd, $fn, 1);
    return;
}

sub connect_to_server {
    my $me    = shift;
    my $ipn   = shift;
    my $port  = shift;
    my $timeo = shift;

    my $s;
    socket($s, PF_INET, SOCK_STREAM, 6) || confess "cannot create socket: $!\n";
    setsockopt($s, Socket::IPPROTO_TCP(), Socket::TCP_NODELAY(), 1);

    # set non-blocking
    my $fl = fcntl($s, F_GETFL, 0);
    fcntl($s, F_SETFL, O_NDELAY);

    my $sa  = sockaddr_in($port, $ipn);
    my $to  = $timeo ? $timeo / 2 : 0.25;

    # try connecting up to 3 times
    for (1..3){
        # print STDERR "connecting\n";
        my $ok = _try_to_connect($s, $sa, $to);

        if( $ok ){
            # reset non-blocking
            fcntl($s, F_SETFL, $fl);
            return $s;
        }
    }

    my $ipa = inet_ntoa($ipn);
    confess "connect failed to $ipa:$port\n";
}

sub write_request {
    my $me    = shift;
    my $s     = shift;
    my $req   = shift;
    my $timeo = shift;

    $timeo ||= 1;

    # set non-blocking
    my $fl = fcntl($s, F_GETFL, 0);
    fcntl($s, F_SETFL, O_NDELAY);
    my $fn = fileno($s);

    my $tlen = length($req);
    my $slen = 0;

    while($tlen){
        my $wfd = "\0\0\0\0";
        vec($wfd, $fn, 1) = 1;
        my $to = $timeo;

        my $si = select(undef, $wfd, undef, $to);
        confess "write data failed: $!\n" if $si == -1;
        confess "write timeout\n" unless vec($wfd, $fn, 1);

        my $l = $tlen > $BUFSIZ ? $BUFSIZ : $tlen;
        my $i = syswrite($s, $req, $l, $slen);
        confess "write failed $!\n" unless $i >= 1;
        $tlen -= $i;
        $slen += $i;
    }

    fcntl($s, F_SETFL, $fl);
    return $slen;

}

sub read_data {
    my $me    = shift;
    my $s     = shift;
    my $size  = shift;
    my $timeo = shift;

    $timeo ||= 1;

    # set non-blocking
    my $fl = fcntl($s, F_GETFL, 0);
    fcntl($s, F_SETFL, O_NDELAY);
    my $fn = fileno($s);

    my $data;
    my $start = time();
    while( my $len = $size - length($data) ){
        $len = $BUFSIZ if $len > $BUFSIZ;
        my $rfd = "\0\0\0\0";
        vec($rfd, $fn, 1) = 1;
        my $to = $start + $timeo - time();
        my $t0 = time();

        my $si = select($rfd, undef, undef, $to);
        next if $si == -1 && $! == EINTR;
        confess "read data failed: $!\n" if $si == -1;
        confess "read timeout " . (time() - $t0) . "\n" unless vec($rfd, $fn, 1);

        my $i = sysread($s, $data, $len, length($data));
        next if !defined($i) && $! == EINTR;
        confess "read failed: connection closed (read " . length($data) . " of $len)\n" if $i == 0;
    }

    fcntl($s, F_SETFL, $fl);
    return $data;
}

################################################################

# stream fd to other fd
# return hash
sub sendfile {
    my $me    = shift;
    my $out   = shift;
    my $in    = shift;
    my $size  = shift;
    my $timeo = shift;

    # NB: sendfile(2) only supports file=>socket + file=>file
    #     not socket=>file, ...
    # RSN - elastic buffering?

    my $sha1 = Digest::SHA1->new();

    while($size){
        my $len = $size > $BUFSIZ ? $BUFSIZ : $size;
        my $buf = $me->read_data($in, $len, $timeo);
        my $i = length $buf;
        confess "read failed: $!\n" unless $i > 0;
        my $w = $me->write_request($out, $buf, $timeo);
        $size -= $i;
        $sha1->add($buf);
    }

    return $sha1->b64digest();
}

sub send_request {
    my $me    = shift;
    my $ipn   = shift;
    my $port  = shift;
    my $req   = shift;
    my $debug = shift;
    my $timeo = shift;

    $debug ||= sub {};
    $timeo ||= 0.5;
    local $SIG{ALRM} = sub{ $debug->("timeout") };

    my $s = $me->connect_to_server($ipn, $port, $timeo);

    # send request
    $debug->("sending request");
    $me->write_request($s, $req, $timeo);

    # get response or timeout
    $debug->("reading header");
    my $buf = $me->read_data($s, header_size(), $timeo);

    my $p = $me->decode_header($buf);

    # get auth
    if( $p->{auth_length} ){
	# read gpb
	$debug->("reading auth $p->{auth_length}");
        my $data = $me->read_data($s, $p->{auth_length}, $timeo);
	$p->{auth} = $data;
    }

    # get data
    if( $p->{data_length} ){
	# read gpb
	$debug->("reading data $p->{data_length}");
        my $data = $me->read_data($s, $p->{data_length}, $timeo);
	$p->{data} = $data;
    }

    # get content
    if( $p->{content_length} ){
	$debug->("reading content $p->{content_length}");
        my $data = $me->read_data($s, $p->{content_length}, $timeo);
	$p->{content} = $data;
    }

    return $p;
}

1;
