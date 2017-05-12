use warnings;
use strict;
use Test::More;
use Test::Exception;

use Crypt::MatrixSSL3 qw(:all);

Crypt::MatrixSSL3::Open();

my $certFile            = 't/cert/server.crt';
my $privFile            = 't/cert/server.key';
my $privPass            = undef;
my $trustedCAcertFiles  = 't/cert/testCA.crt';
my $trustedCAbundle     = $Crypt::MatrixSSL3::CA_CERTIFICATES;

my ($Server_Keys, $Client_Keys);
my ($Server_SSL, $Client_SSL);

my @Alert;

my ($client2server, $server2client) = (q{}, q{});

is MATRIXSSL_SUCCESS, Crypt::MatrixSSL3::set_cipher_suite_enabled_status(TLS_RSA_WITH_AES_128_CBC_SHA, PS_FALSE),
    'disable TLS_RSA_WITH_AES_128_CBC_SHA';

new($trustedCAcertFiles, undef);
handshake();
io();
is $Client_SSL->encode_rehandshake(undef, undef, SSL_OPTION_FULL_HANDSHAKE, [SSL_RSA_WITH_RC4_128_MD5]), PS_UNSUPPORTED_FAIL,
    '--- Rehandshake: unsupported cipher';
io();
fin();

new($trustedCAcertFiles, undef);
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake(undef, undef, 0, undef),
    '--- Rehandshake: change nothing';
handshake();
io();
fin();

new($trustedCAcertFiles, undef);
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake(undef, undef, SSL_OPTION_FULL_HANDSHAKE, undef),
    '--- Rehandshake: change nothing (full rehandshake)';
handshake();
io();
fin();

new($trustedCAcertFiles, undef);
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake($Client_Keys, undef, 0, undef),
    '--- Rehandshake: change nothing (same keys)';
handshake();
io();
fin();

new($trustedCAcertFiles, undef);
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake(undef, undef, SSL_OPTION_FULL_HANDSHAKE, [TLS_RSA_WITH_AES_256_CBC_SHA]),
    '--- Rehandshake: change cipher to TLS_RSA_WITH_AES_256_CBC_SHA';
handshake();
io();
fin();

=for not allowed anymore

new($trustedCAcertFiles, undef);
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake(undef, undef, SSL_OPTION_FULL_HANDSHAKE, [SSL_NULL_WITH_NULL_NULL]),
    '--- Rehandshake: change cipher to SSL_NULL_WITH_NULL_NULL';
handshake();
io(1);
fin();

new($trustedCAcertFiles, undef);
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake(undef, undef, SSL_OPTION_FULL_HANDSHAKE, [SSL_RSA_WITH_NULL_SHA]),
    '--- Rehandshake: change cipher to SSL_RSA_WITH_NULL_SHA';
handshake();
io(1);
fin();

new($trustedCAcertFiles, undef);
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake(undef, undef, 0, [SSL_RSA_WITH_NULL_SHA]),
    '--- Rehandshake: change cipher to SSL_RSA_WITH_NULL_SHA (without FULL_HANDSHAKE)';
handshake();
io(1);
fin();

=cut

new($trustedCAcertFiles, sub{0});
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake(undef, undef, 0, undef),
    '--- Rehandshake: change nothing';
handshake();
io();
fin();

# TODO crash 3.3.0
# new($trustedCAcertFiles, sub{0});
# handshake();
# io();
# is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake($Client_Keys, undef, 0, 0),
#     '--- Rehandshake: change nothing (same keys)';
# handshake();
# io();
# fin();

new($trustedCAcertFiles, sub{0});
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake(undef, sub{0}, 0, undef),
    '--- Rehandshake: change nothing (same callback)';
handshake();
io();
fin();

new($trustedCAcertFiles, sub{0});
handshake();
io();
is MATRIXSSL_SUCCESS, $Client_SSL->encode_rehandshake($Client_Keys, sub{0}, 0, undef),
    '--- Rehandshake: change nothing (same keys and callback)';
handshake();
io();
fin();


# diag "ALERTS: @Alert";

done_testing();


sub new {
    my ($trustedCA, $cb) = @_;

    lives_ok { $Server_Keys = Crypt::MatrixSSL3::Keys->new() }
        'Keys->new (server)';
    is PS_SUCCESS, $Server_Keys->load_rsa($certFile, $privFile, $privPass, undef),
        '$Server_Keys->load_rsa';
    lives_ok { $Server_SSL = Crypt::MatrixSSL3::Server->new($Server_Keys, undef) }
        'Server->new';

    lives_ok { $Client_Keys = Crypt::MatrixSSL3::Keys->new() }
        'Keys->new (client)';
    is PS_SUCCESS, $Client_Keys->load_rsa(undef, undef, undef, $trustedCA),
        '$Client_Keys->load_rsa';
    lives_ok { $Client_SSL = Crypt::MatrixSSL3::Client->new($Client_Keys, undef, undef, $cb, undef, undef, undef) }
        'Client->new';

    ($client2server, $server2client) = (q{}, q{});
    return;
}

sub handshake {
    my ($client_rc, $server_rc);
    while (1) {
        $server_rc = _decode($Server_SSL, $client2server, $server2client);
        $client_rc = _decode($Client_SSL, $server2client, $client2server);
        last if $client_rc || $server_rc;
    }
    $server_rc = _decode($Server_SSL, $client2server, $server2client) if !defined $server_rc;
    is 1, $server_rc, 'handshake complete (server)';
    is 1, $client_rc, 'handshake complete (client)';
    ok !length $client2server, 'client outbuf empty after handshake';
    ok !length $server2client, 'server outbuf empty after handshake';
}

sub io {
    my ($plaintext) = (!!$_[0]);
    my $s   = "Hello MatrixSSL!\0\n";
    my $tmp = $s;
    my $buf;

    ok $Client_SSL->encode_to_outdata($s) > 0,
        'encode_to_outdata (client)';
    is $tmp, $s,
        q{encode_to_outdata doesn't destroy input string};
    is undef, _decode($Client_SSL, $server2client, $client2server);
    ok length $client2server,
        'got some outbuf (client)';

    my $is_plaintext = $client2server =~ /\Q$s\E/;
    is $is_plaintext, $plaintext,
        'ssl'.($plaintext ? ' NOT ' : ' ').'encrypted';

    is undef, _decode($Server_SSL, $client2server, $server2client, $buf);
    is $buf, $s,
        'decoded ok (server)';
    ok !length $client2server,
        'outbuf empty (client)';
    ok !length $server2client,
        'outbuf empty (server)';
}

sub fin {
    undef $Server_SSL;
    undef $Client_SSL;
    undef $Server_Keys;
    undef $Client_Keys;
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
    push @Alert, sprintf "MatrixSSL alert: level %d: %s, desc %d: %s", $level, $level, $descr, $descr;
    return;
}

Crypt::MatrixSSL3::Close();
