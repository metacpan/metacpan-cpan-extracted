use warnings;
use strict;
use blib;
use Crypt::MatrixSSL3 qw( :all );

# $eof = nb_io($sock, $in, $out);
# Doing I/O on non-blocking $sock.
# Read data appended to $in.
# Written data deleted from $out.
# Return true on EOF.
# Throw exception on I/O error.
sub nb_io {
    my ($sock, $in, $out) = @_;
    my $n;
    if (length $out) {
        $n = syswrite $sock, $out;
        die "syswrite: $!" if !defined $n && !$!{EAGAIN} && !$!{EWOULDBLOCK};
        substr $out, 0, $n, q{};
    }
    do {
        $n = sysread $sock, my $buf=q{}, 1024;
        die "sysread: $!" if !defined $n && !$!{EAGAIN} && !$!{EWOULDBLOCK};
        $in .= $buf;
    } while $n;
    my $eof = defined $n && !$n;
    @_[1 .. $#_] = ($in, $out);
    return $eof;
}

# $err = ssl_io($ssl, $in, $out, $appIn, $appOut, $handshakeIsComplete);
# $in and $out is socket buffers.
# Decoded SSL packets deleted from $in.
# Encoded SSL packets (internal or encoded $appOut) appended to $out.
# Decoded (from $in) application data appended to $appIn.
# Encoded application data deleted from $appOut.
# Flag $handshakeIsComplete is internal and shouldn't be changed by user!
# Return empty string if no error happens;
#   error message text if matrixSsl*() return error.
sub ssl_io {
    my ($ssl, $in, $out, $appIn, $appOut, $handshakeIsComplete) = @_;
    # This function is called when some I/O has successfully completed, so
    # we've either sent some data, received, or both.
    # At first we should process received data (if any) because this may
    # produce new outgoing data to be sent as result.
    # After that we should try to send outgoing data (if any).
    my $err = q{};

    # SSL data buffer
    my $buf;

RECV:
    # Fill MatrixSSL's read buffer with received data. Repeat until all
    # received data will be moved from our buffer to MatrixSSL.
    while (length $in) {
        # Process (part of) received data:
        my $rc = $ssl->received_data($in, $buf);
RC:
        # - "Success. This return code will be returned if $n is 0 and
        #   there is no remaining internal data to process. This could
        #   be useful as a polling mechanism to confirm the internal
        #   buffer is empty. One real life use-case for this method of
        #   invocation is when dealing with a Google Chrome browser
        #   that uses False Start."
        if ($rc == PS_SUCCESS) {
            last;
        }
        # - "Success. More data must be received and this function
        #   must be called again."
        elsif ($rc == MATRIXSSL_REQUEST_RECV) {
            next;
        }
        # - "Success. The processing of the received data resulted in
        #   an SSL response message that needs to be sent to the peer."
        # - NOTE: I believe we don't have to call $ssl->get_outdata()
        #   immediately and can try to continue processing received data.
        elsif ($rc == MATRIXSSL_REQUEST_SEND) {
            next;
        }
        # - "Success. The SSL handshake is complete. This return code
        #   is returned to client side implementation during a full
        #   handshake after parsing the FINISHED message from the
        #   server. It is possible for a server to receive this value
        #   if a resumed handshake is being performed where the client
        #   sends the final FINISHED message."
        # - "If this code is returned, there are not any additional
        #   full SSL records in the buffer available to parse,
        #   although there may be a partial record remaining. If
        #   there were a full SSL record available, for example an
        #   application data record, it would be parsed and
        #   MATRIXSSL_APP_DATA would be returned instead."
        elsif ($rc == MATRIXSSL_HANDSHAKE_COMPLETE) {
            $handshakeIsComplete = 1;
            next;
        }
        # - "Success. The data that was processed was an SSL alert
        #   message. In this case, the $buf will be two bytes in which
        #   the first byte will be the alert level and the second byte
        #   will be the alert description. After examining the alert,
        #   the user must call $ssl->processed_data($buf) to indicate
        #   the alert was processed and the data may be internally
        #   discarded."
        elsif ($rc == MATRIXSSL_RECEIVED_ALERT) {
            my ($level, $descr) = get_ssl_alert($buf);
            if ($level == SSL_ALERT_LEVEL_FATAL) {
                # Ignore returned $rc and $buf because after fatal alert
                # there should be no data on this connection.
                $ssl->processed_data($buf);

                $err = alert($level, $descr);
                last;
            }
            else {
                # Do whatever you like, process like fatal alert or just:
                warn alert($level, $descr);
            }
        }
        # - "Success. The data that was processed was application data
        #   that the user should process. In this return code case the
        #   $buf will be valid. After handling the data the user must
        #   call $ssl->processed_data($buf) to indicate the plain text
        #   data may be internally discarded."
        # - "If application data has been appended to a handshake
        #   FINISHED message it is possible the MATRIXSSL_APP_DATA
        #   return code can be received without ever having received
        #   the MATRIXSSL_HANDSHAKE_COMPLETE return code. In this
        #   case, it is implied the handshake completed successfully
        #   because application data is being received."
        elsif ($rc == MATRIXSSL_APP_DATA) {
            $handshakeIsComplete = 1;
            $appIn .= $buf;
        }
        # - "Success. The application data that is returned needs to
        #   be inflated with zlib before being processed. This return
        #   code is only possible if the USE_ZLIB_COMPRESSION define
        #   has been enabled and the peer has agreed to compression.
        #   Compression is not advised due to TLS attacks."
        elsif ($rc == MATRIXSSL_APP_DATA_COMPRESSED) {
            $handshakeIsComplete = 1;
            $appIn .= uncompress($buf);
        }
        # - "Failure."
        else {
            $err = error($rc);
            last;
        }
        # Indicate previous $buf was processed and try to process
        # next (part of) received data in MatrixSSL's read buffer:
        $rc = $ssl->processed_data($buf);
        goto RC;
    }
    goto RET if $err;

SEND:
    # Get pending encoded data that should be sent (if any).
    # New pending encoded data will become available (and so you must
    # process it with $ssl->get_outdata()) after:
    # - Crypt::MatrixSSL3::Client->new()
    # - $ssl->encode_rehandshake()
    # - $ssl->received_data() returns MATRIXSSL_REQUEST_SEND
    # - $ssl->processed_data() returns MATRIXSSL_REQUEST_SEND
    # - $ssl->encode_to_outdata()
    # - $ssl->encode_closure_alert()
    while (my $n = $ssl->get_outdata($out)) {
        # "After sending the returned $out to the peer, the user must
        # always follow with a call to $ssl->sent_data() to update the
        # number of bytes that have been sent from the returned buf.
        # Depending on how much data was sent, there may still be data to
        # send within the internal outdata, and $ssl->get_outdata() should
        # be called again to ensure 0 bytes remain."
        # NOTE: You don't have to actually send that data to the peer
        # before calling $ssl->send_data(), you have to make sure these $n
        # bytes from $out won't be lost and you'll send them eventually.
        # Also in this case you should be prepared to handle
        # MATRIXSSL_REQUEST_CLOSE by closing connection when that data
        # will be actually sent.
        my $rc = $ssl->sent_data($n);
        # - "Success. No pending data remaining."
        if ($rc == PS_SUCCESS) {
            last;
        }
        # - "Success. Call $ssl->get_outdata() again and send more data to
        #   the peer. Indicates the number of bytes sent was not the full
        #   amount of pending data."
        elsif ($rc == MATRIXSSL_REQUEST_SEND) {
            next;
        }
        # - "Success. Will be returned to the peer if this is the final
        #   FINISHED message that is being sent to complete the handshake."
        # - "This is an indication that this peer is sending the final
        #   FINISHED message of the SSL handshake. If a client receives
        #   this return code, a resumed handshake has just completed."
        elsif ($rc == MATRIXSSL_HANDSHAKE_COMPLETE) {
            $handshakeIsComplete = 1;

            # Sometimes clients use the "false start" technique - they send
            # the first application data packet immediately after sending the
            # handshake "Finished" message without waiting for the server's own
            # handshake "Finished" message. This saves a rountrip and speeds the
            # data transfer in some cases by 33%

            my $rc2 = $ssl->false_start_received_data($buf);

            # all the codes are already explained in this function
            while (1) {
                if ($rc2 == MATRIXSSL_APP_DATA) {
                    $appIn .= $buf;
                }
                elsif ($rc2 == MATRIXSSL_RECEIVED_ALERT) {
                    my ($level, $descr) = get_ssl_alert($buf);
                    if ($level == SSL_ALERT_LEVEL_FATAL) {
                        $ssl->processed_data($buf);
                        $err = alert($level, $descr);
                        last;
                    } else {
                        warn alert($level, $descr);
                    }
                }
                elsif (($rc2 == MATRIXSSL_SUCCESS) || ($rc2 == MATRIXSSL_REQUEST_SEND) || ($rc2 == MATRIXSSL_REQUEST_RECV)) {
                    last;
                }
                else {
                    $err = error($rc);
                    last;
                }

                $rc2 = $ssl->processed_data($buf);
            }

            next;
        }
        # - "Success. This indicates the message that was sent to the peer
        #   was an alert and the caller should close the session."
        # - "This will be the case if the data being sent is a closure
        #   alert (or fatal alert)."
        elsif ($rc == MATRIXSSL_REQUEST_CLOSE) {
            $err = 'close';
            last;
        }
        # - "Failure."
        # - NOTE: This error should never happens.
        else {
            $err = error($rc);
            last;
        }
    }
    goto RET if $err;

    if ($handshakeIsComplete && length $appOut) {
        my $s = substr $appOut, 0, SSL_MAX_PLAINTEXT_LEN, q{};
        my $rc = $ssl->encode_to_outdata($s);
        goto SEND if $rc > 0;
        $err = error($rc);
    }

RET:
    @_[1 .. $#_] = ($in, $out, $appIn, $appOut, $handshakeIsComplete);
    return $err;
}

sub error {
    my $rc = get_ssl_error(shift);
    return sprintf "MatrixSSL error %d: %s\n", $rc, $rc;
}

sub alert {
    my ($level, $descr) = @_;
    return sprintf "MatrixSSL alert %s: %s\n", $level, $descr;
}

sub uncompress {
    die 'not implemented because USE_ZLIB_COMPRESSION should not be enabled';
}


1;
