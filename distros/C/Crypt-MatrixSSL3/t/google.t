use warnings;
use strict;
use Test::More;
use Test::Exception;

use IO::Socket;

use Crypt::MatrixSSL3 qw(:all);

Crypt::MatrixSSL3::Open();

my $trustedCAbundle     = $Crypt::MatrixSSL3::CA_CERTIFICATES;
my $target              = 'www.google.com:443';


plan tests => 14;


########
# Init #
########

my ($ssl, $keys);
lives_ok { $keys = Crypt::MatrixSSL3::Keys->new() }
    'Keys->new';
is PS_SUCCESS, $keys->load_rsa(undef, undef, undef, $trustedCAbundle),
    '$keys->load_rsa';
lives_ok { $ssl = Crypt::MatrixSSL3::Client->new($keys, undef, undef, sub { 0 }, undef, undef, undef) }
    'Client->new';

my $sock = IO::Socket::INET->new(PeerAddr=>$target) or die "IO::Socket: $!";

#############
# Handshake #
#############

my ($rc, $inbuf, $outbuf, $appbuf) = (0, q{}, q{}, q{});
until ($rc = _decode($ssl, $inbuf, $outbuf, $appbuf)) {
    if (length $outbuf) {
        my $n = syswrite $sock, $outbuf or die "syswrite: $!";
        substr $outbuf, 0, $n, q{};
    }
    else {
        sysread $sock, $inbuf, 8192, length $inbuf or die "sysread: $!";
    }
}
is 1, $rc, 'handshake complete';
ok !length $inbuf, 'inbuf empty';
ok !length $outbuf, 'outbuf empty';
ok !length $appbuf, 'appbuf empty';

#######
# I/O #
#######

my $s = "GET / HTTP/1.0\r\nAccept: */*\r\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)\r\nHost: $target\r\n\r\n";

ok $ssl->encode_to_outdata($s) > 0,
    'encode_to_outdata';
is undef, _decode($ssl, $inbuf, $outbuf, $appbuf),
    'encode';
is length($outbuf), syswrite($sock,$outbuf),
    'send';

ok sysread($sock, $inbuf, 8192, length $inbuf),
    'recv';
is undef, _decode($ssl, $inbuf, $outbuf, $appbuf),
    'decode';
if ($appbuf eq q{}) {
    diag "one more sysread...";
    sysread($sock, $inbuf, 8192, length $inbuf);
    _decode($ssl, $inbuf, $outbuf, $appbuf);
}
like $appbuf, qr/^(Content-Type:|Location:)/im,
    'got http reply';

#######
# Fin #
#######

undef $ssl;
undef $keys;
ok 1, 'matrixSslClose';


###########
# Helpers #
###########

sub _decode {
    my ($ssl) = @_; # other 3 params must be modified in place
    while (length $_[1]) {
        my $rc = $ssl->received_data($_[1], my $buf);
RC:
        if    ($rc == MATRIXSSL_REQUEST_SEND)       { last          }
        elsif ($rc == MATRIXSSL_REQUEST_RECV)       { next          }
        elsif ($rc == MATRIXSSL_HANDSHAKE_COMPLETE) { return 1      }
        elsif ($rc == MATRIXSSL_RECEIVED_ALERT)     { alert($buf); return -1 }
        elsif ($rc == MATRIXSSL_APP_DATA)           { $_[3].=$buf   }
        elsif ($rc == MATRIXSSL_SUCCESS)            { last          }
        else                                        { die error($rc)}
        $rc = $ssl->processed_data($buf);
        goto RC;
    }
    while (my $n = $ssl->get_outdata($_[2])) {
        my $rc = $ssl->sent_data($n);
        if    ($rc == MATRIXSSL_REQUEST_SEND)       { next          }
        elsif ($rc == MATRIXSSL_SUCCESS)            { last          }
        elsif ($rc == MATRIXSSL_REQUEST_CLOSE)      { return -1     }
        elsif ($rc == MATRIXSSL_HANDSHAKE_COMPLETE) { return 1      }
        else                                        { die error($rc)}
    }
    return;
}

sub error {
    my $rc = get_ssl_error($_[0]);
    return sprintf "MatrixSSL error %d: %s\n", $rc, $rc;
}
sub alert {
    my ($level, $descr) = get_ssl_alert($_[0]);
    diag sprintf "MatrixSSL alert: level %d: %s, desc %d: %s\n", $level, $level, $descr, $descr;
    return;
}

Crypt::MatrixSSL3::Close();
