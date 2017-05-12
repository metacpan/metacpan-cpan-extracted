# $eof = nb_io($sock, $in, $out);
# Doing I/O on non-blocking $sock.
# Readed data appended to $in.
# Written data deleted from $out.
# Return true on EOF.
# Throw exception on I/O error.
sub nb_io {
    my ($sock, $in, $out) = @_;
    my $n;
    if (length $out) {
        $n = syswrite($sock, $out);
        die "syswrite: $!" if !defined $n && !$!{EAGAIN};
        substr($out, 0, $n, q{});
    }
    do {
        $n = sysread($sock, my $buf=q{}, 1024);
        die "sysread: $!" if !defined $n && !$!{EAGAIN};
        $in .= $buf;
    } while $n;
    my $eof = defined $n && !$n;
    @_[1 .. $#_] = ($in, $out);
    return $eof; 
}

# $err = ssl_io($ssl, $in, $out, $appIn, $appOut, $handshakeIsComplete);
# Doing matrixSslEncode() and matrixSslDecode() on $ssl.
# $in and $out is socket buffers.
# Decoded SSL packets deleted from $in.
# Encoded SSL packets (internal or encoded $appOut) appended to $out.
# Decoded (from $in) application data appended to $appIn.
# Encoded application data deleted from $appOut.
# Flag $handshakeIsComplete is internal and shouldn't be changed by user!
# Return empty string if no error happens;
#   error message text if matrixSslDecode() return $SSL_ERROR or $SSL_ALERT.
# Throw exceptions on MatrixSSL internal error.
sub ssl_io {
    my ($ssl, $in, $out, $appIn, $appOut, $handshakeIsComplete) = @_;
    $err = undef;
    while (length $in) {
        my ($error, $alertLevel, $alertDescription);
        my $rc = matrixSslDecode2($ssl, $in, $out, $appIn,
            $error, $alertLevel, $alertDescription);
        if ($rc == $SSL_SUCCESS || $rc == $SSL_SEND_RESPONSE) {
            $handshakeIsComplete ||= matrixSslHandshakeIsComplete($ssl);
        }
        elsif ($rc == $SSL_ERROR) {
            $err = sprintf
                "matrixSslDecode\n".
                "\terror: (%d) %s\n",
                $error, $SSL_alertDescription{ $error };
            last;
        }
        elsif ($rc == $SSL_ALERT) {
            $err = sprintf
                "matrixSslDecode\n".
                "\talertLevel: (%d) %s\n".
                "\talertDescription: (%d) %s\n",
                $alertLevel, $SSL_alertLevel{ $alertLevel },
                $alertDescription, $SSL_alertDescription{ $alertDescription };
            last;
        }
        elsif ($rc == $SSL_PARTIAL) {
            last;
        }
        elsif ($rc == $SSL_PROCESS_DATA) {
        }
        else {
            die "matrixSslDecode: unexpected return code ($rc)\n";
        }
    }
    if ($handshakeIsComplete && !$err) {
        while (length $appOut) {
            my $s = substr($appOut, 0, $SSL_MAX_PLAINTEXT_LEN, q{});
            matrixSslEncode($ssl, $s, $out)
                >= 0 or die 'matrixSslEncode';
        }
    }
    @_[1 .. $#_] = ($in, $out, $appIn, $appOut, $handshakeIsComplete);
    return $err;
}

# Wrapper for matrixSslDecode() to separate two kind of output buffers -
# SSL packets which should be sent to other side and decoded application data:
#   $out param will contain SSL packets.
#   $data param will contain decoded application data.
# TODO  Realize this in XS?
sub matrixSslDecode2 {
    my ($ssl, $in, $out, $data, $error, $alertLevel, $alertDescription) = @_;
    my $rc = matrixSslDecode($ssl, $in, my $tmp=q{},
        $error, $alertLevel, $alertDescription);
    ($rc == $SSL_PROCESS_DATA ? $data : $out) .= $tmp;
    @_[1 .. $#_] = ($in, $out, $data, $error, $alertLevel, $alertDescription);
    return $rc;
}

1;
