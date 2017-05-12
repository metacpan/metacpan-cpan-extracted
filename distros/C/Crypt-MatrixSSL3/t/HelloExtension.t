use warnings;
use strict;
use Test::More;
use Test::Exception;

use Socket;
use IO::Socket;

use Crypt::MatrixSSL3 qw(:all);

Crypt::MatrixSSL3::Open();

use constant RFC3546_SERVER_NAME => 0;          # "server_name" extension type
use constant RFC3546_SERVER_NAME_HOST_NAME => 0;# "host_name" host name type

my $trustedCAbundle     = $Crypt::MatrixSSL3::CA_CERTIFICATES;
my $host1               = 'alice.sni.velox.ch';
my $host2               = 'bob.sni.velox.ch';


plan skip_all => '*.sni.velox.ch is not available anymore';
plan skip_all => 'connection to *.sni.velox.ch is unreliable'
    if $ENV{AUTOMATED_TESTING} || $ENV{PERL_CPAN_REPORTER_CONFIG};
plan tests => 45;


is inet_ntoa(scalar gethostbyname $host1), inet_ntoa(scalar gethostbyname $host2),
    "https://$host1/ and https://$host2/ share same IP";
doit($host1);
doit($host2);


sub ext_server_name {
    my ($host) = @_;
    my $servername = pack 'C n/a*', RFC3546_SERVER_NAME_HOST_NAME, $host;
    my $data = pack 'n/a*', $servername;
    return ($data, RFC3546_SERVER_NAME);
}

sub doit {
    my ($target) = @_;
    my ($keys, $extension, $ssl);

    # Init
    lives_ok { $keys = Crypt::MatrixSSL3::Keys->new() }
        'Keys->new';
    is PS_SUCCESS, $keys->load_rsa(undef, undef, undef, $trustedCAbundle),
        '$keys->load_rsa';
    lives_ok { $extension = Crypt::MatrixSSL3::HelloExt->new() }
        'HelloExt->new';
    my ($extData, $extType) = ext_server_name($target);
    is PS_SUCCESS, $extension->load($extData, $extType),
        '$extension->load';
    lives_ok { $ssl = Crypt::MatrixSSL3::Client->new($keys, undef, undef, sub {
            is 0+@_, 2, 'certValidate got 2 params';
            is $_[0]->[0]{subject}{commonName}, $target, "certificate for $target";
            return $_[1];
        }, undef,
        $extension, sub {
            is 0+@_, 2, 'extensionCback got 2 params';
            is $_[0], RFC3546_SERVER_NAME,  '... "server_name" extension type';
            is $_[1], q{},                  '... empty data';
            return 0;
        }) }
        'Client->new';

    my $sock = IO::Socket::INET->new("$target:443") or die "IO::Socket: $!";

    # Handshake
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

    # I/O
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
    like $appbuf, qr/^(Content-Type:|Location:)/im,
        'got http reply';

    while ($appbuf !~ m{</html>}msi) {
        sysread($sock, $inbuf, 8192, length $inbuf) or last;
        !defined _decode($ssl, $inbuf, $outbuf, $appbuf) or last;
    }
    like $appbuf, qr{>\s*TLS\s+SNI\s+Test\s+Site:\s+\Q$target\E\s*<}ms,
        'html content';

    # Fin
    undef $ssl;
    undef $extension;
    undef $keys;
    ok 1, 'matrixSslClose';
}

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
        elsif ($rc == MATRIXSSL_RECEIVED_ALERT)     { return alert($buf); }
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
    return if $descr == SSL_ALERT_CLOSE_NOTIFY;
    diag sprintf "MatrixSSL alert: level %d: %s, desc %d: %s\n", $level, $level, $descr, $descr;
    return -1;
}

Crypt::MatrixSSL3::Close();
