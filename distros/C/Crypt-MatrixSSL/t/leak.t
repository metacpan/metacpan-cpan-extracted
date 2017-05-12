use warnings;
use strict;
use Test::More tests => 13;

use Crypt::MatrixSSL;

my $trustedCAcertFiles  = 't/cert/testca.crt';

my $certFile            = 't/cert/testserver.crt';
my $privFile            = 't/cert/testserver.key';
my $privPass            = undef;

my $trustedCA; if(open(IN,'<',"$trustedCAcertFiles.der")) {local $/; $trustedCA=<IN>; close(IN); }
my $cert; if(open(IN,'<',"$certFile.der")) {local $/; $cert=<IN>; close(IN); }
my $priv; if(open(IN,'<',"$privFile.der")) {local $/; $priv=<IN>; close(IN); }

my $privFile_des3       = $privFile.'.des3';
my $privPass_des3       = 'test';

our ($Server_Keys, $Client_Keys, $All_Keys);

our @VALIDATE = (-1, 0, $SSL_ALLOW_ANON_CONNECTION);

leaktest('open_close');

matrixSslOpen()
    == 0 or die diag sprintf 'matrixSslOpen';
leaktest('read_keys');
# this bug fixed in matrixssl-1-8-open.patch:
our $CA;
# $CA = '/etc/ssl/certs/ca-certificates.crt';
$CA = 'ca-certificates.crt';
leaktest('read_keys_one');
matrixSslClose();

matrixSslOpen()
    == 0 or die diag sprintf 'matrixSslOpen';
matrixSslReadKeys($Server_Keys, $certFile, $privFile, $privPass, undef)
    == 0 or die diag sprintf 'matrixSslReadKeys (server)';
matrixSslReadKeys($Client_Keys, undef, undef, undef, $trustedCAcertFiles)
    == 0 or die diag sprintf 'matrixSslReadKeys (client)';
leaktest('session');
leaktest('handshake');
leaktest('client_server', test=>500);
diag sprintf 'about to matrixSslFreeKeys($Server_Keys);';
matrixSslFreeKeys($Server_Keys);
diag sprintf 'about to matrixSslFreeKeys($Client_Keys);';
matrixSslFreeKeys($Client_Keys);
diag sprintf 'about to matrixSslClose();';
matrixSslClose();
diag sprintf 'All done.';

ok('just to be sure there was no SegFault until this point', 'matrixSslClose');
exit(0);

sub open_close {
    matrixSslOpen()
        == 0 or die diag sprintf 'matrixSslOpen';
    matrixSslClose();
}

sub read_keys {
    matrixSslReadKeys($Server_Keys, $certFile, $privFile, $privPass, undef)
        == 0 or die diag sprintf 'matrixSslReadKeys (server)';
    matrixSslReadKeys($Client_Keys, undef, undef, undef, $trustedCAcertFiles)
        == 0 or die diag sprintf 'matrixSslReadKeys (client)';
    matrixSslReadKeys($All_Keys, $certFile, $privFile, $privPass, $trustedCAcertFiles)
        == 0 or die diag sprintf 'matrixSslReadKeys (all)';
    matrixSslFreeKeys($Server_Keys);
    matrixSslFreeKeys($Client_Keys);
    matrixSslFreeKeys($All_Keys);
    matrixSslReadKeysMem($All_Keys, $cert, $priv, $trustedCA)
        == 0 or die diag sprintf 'matrixSslReadKeysMem';
    matrixSslFreeKeys($All_Keys);
    matrixSslReadKeys($Server_Keys, $certFile, $privFile_des3, $privPass_des3, undef)
        == 0 or die diag sprintf 'matrixSslReadKeys (encrypted)';
    matrixSslFreeKeys($Server_Keys);
}

sub read_keys_one {
    my($rc);
    ($rc=matrixSslReadKeys($Client_Keys, undef, undef, undef, $CA))
        == 0 or diag "matrixSslReadKeys (client,$CA)=" . $rc;
    matrixSslFreeKeys($Client_Keys) unless($rc);
}

sub session {
    my ($Server_SSL, $Client_SSL, $Client_sessionId);
    matrixSslNewSession($Server_SSL, $Server_Keys, undef, $SSL_FLAGS_SERVER)
        == 0 or die diag sprintf 'matrixSslNewSession (server)';
    matrixSslNewSession($Client_SSL, $Client_Keys, $Client_sessionId, 0)
        == 0 or die diag sprintf 'matrixSslNewSession (client)';
    matrixSslDeleteSession($Server_SSL);
    matrixSslDeleteSession($Client_SSL);
}

sub handshake {
    my ($client2server, $server2client) = (q{}, q{});
    
    my ($Server_SSL, $Client_SSL, $Client_sessionId);
    matrixSslNewSession($Server_SSL, $Server_Keys, undef, $SSL_FLAGS_SERVER)
        == 0 or die diag sprintf 'matrixSslNewSession (server)';
    matrixSslNewSession($Client_SSL, $Client_Keys, $Client_sessionId, 0)
        == 0 or die diag sprintf 'matrixSslNewSession (client)';

    matrixSslSetCertValidator($Client_SSL, \&cb_validate, {complex=>['arg']});

    my $cipherSuite         = 0;
    matrixSslEncodeClientHello($Client_SSL, $client2server, $cipherSuite)
        == 0 or die diag sprintf 'matrixSslEncodeClientHello';
    while (matrixSslHandshakeIsComplete($Client_SSL) != 1 and
            (length $client2server or length $server2client)) {
        _decode($Server_SSL, $client2server, $server2client) or last;
        _decode($Client_SSL, $server2client, $client2server) or last;
    }
    matrixSslHandshakeIsComplete($Client_SSL)
        == ($VALIDATE[0]==-1 ? 0 : 1)
        or die diag sprintf 'wrong handshake result';
    
    matrixSslGetAnonStatus($Client_SSL, my $anonArg=0);
    $anonArg
        == ($VALIDATE[0]==$SSL_ALLOW_ANON_CONNECTION ? 1 : 0)
        or die diag sprintf 'wrong certificate validate result';

    matrixSslDeleteSession($Server_SSL);
    matrixSslDeleteSession($Client_SSL);
}

sub cb_validate {
    my ($cert, $arg) = @_;
    push @VALIDATE, shift @VALIDATE;
    return $VALIDATE[0];
}

sub client_server {
    my ($client2server, $server2client) = (q{}, q{});

    my ($Server_SSL, $Client_SSL, $Client_sessionId);
    matrixSslNewSession($Server_SSL, $Server_Keys, undef, $SSL_FLAGS_SERVER)
        == 0 or die diag sprintf 'matrixSslNewSession (server)';
    matrixSslNewSession($Client_SSL, $Client_Keys, $Client_sessionId, 0)
        == 0 or die diag sprintf 'matrixSslNewSession (client)';

    my $cipherSuite = 0;
    matrixSslEncodeClientHello($Client_SSL, $client2server, $cipherSuite)
        == 0 or die diag sprintf 'matrixSslEncodeClientHello';
    while (matrixSslHandshakeIsComplete($Client_SSL) != 1 and
            (length $client2server or length $server2client)) {
        _decode($Server_SSL, $client2server, $server2client) or last;
        _decode($Client_SSL, $server2client, $client2server) or last;
    }
    matrixSslHandshakeIsComplete($Client_SSL)
        == 1 or die diag sprintf 'handshake failed';
    length($client2server)
        == 0 or die diag sprintf 'client2server non-empty after handshake';
    length($server2client)
        == 0 or die diag sprintf 'server2client non-empty after handshake';

    my $s   = "Hello MatrixSSL!\n".("\0" x 16000);

    matrixSslEncode($Client_SSL, $s, $client2server)
        >= 0 or die diag sprintf 'matrixSslEncode (client)';
    matrixSslEncode($Client_SSL, $s, $client2server)
        >= 0 or die diag sprintf 'matrixSslEncode (client)';

    my ($rc, $error, $alertLevel, $alertDescription);
    matrixSslDecode($Server_SSL, $client2server, $server2client,
        $error, $alertLevel, $alertDescription)
        == $SSL_PROCESS_DATA or die diag sprintf 'matrixSslDecode (first)';
    $server2client
        eq $s or die diag sprintf 'first string decoded incorrectly';
    matrixSslDecode($Server_SSL, $client2server, $server2client,
        $error, $alertLevel, $alertDescription)
        == $SSL_PROCESS_DATA or die diag sprintf 'matrixSslDecode (second)';;
    $server2client
        eq $s.$s or die diag sprintf 'second string decoded incorrectly or was not appended to output buffer';
    length($client2server)
        == 0 or die diag sprintf 'client2server non-empty';

    matrixSslDeleteSession($Server_SSL);
    matrixSslGetSessionId($Client_SSL, $Client_sessionId)
        == 0 or die diag sprintf 'matrixSslGetSessionId';
    matrixSslDeleteSession($Client_SSL);
    matrixSslFreeSessionId($Client_sessionId);
}

sub _decode {
    my ($ssl, $in, $out) = @_;
    if (length $in) {
        my ($rc, $error, $alertLevel, $alertDescription);
        $rc = matrixSslDecode($ssl, $in, $out,
            $error, $alertLevel, $alertDescription);
        if ($rc == $SSL_SUCCESS || $rc == $SSL_SEND_RESPONSE) {
            @_[1,2] = ($in, $out);
        }
        elsif ($rc == $SSL_ERROR && $error == $SSL_ALERT_BAD_CERTIFICATE) {
            return;
        }
        else {
            warn sprintf "DECODE_Client handshake error:\n".
                "\trc=%s error=%s\n".
                "\talertLevel=%s alertDescription=%s\n",
                $rc, $Crypt::MatrixSSL::mxSSL_RETURN_CODES{$rc},
                $SSL_alertDescription{$error},
                $SSL_alertLevel{$alertLevel},
                $SSL_alertDescription{$alertDescription};
            return;
        }
    }
    return 1;
}

##############################################################################

sub leaktest {
    my $test = shift;
    my %arg  = (init=>10, test=>1000, max_mem_diff=>100, diag=>1, @_);
    my $code = do { no strict 'refs'; \&$test };
    $code->() for 1 .. $arg{init};
    my $mem = MEM_used();
    my $fd  = FD_used();
    $code->() for 1 .. $arg{test};
    diag sprintf "---- MEM $test\nWAS: %d\nNOW: %d\n", $mem, MEM_used() if $arg{diag};
    ok( MEM_used() - $mem < $arg{max_mem_diff},  "MEM: $test" );
    is( FD_used() - $fd, 0,                      " FD: $test" );
}

#########################
# General-purpose utils #
#########################
use Carp;
sub Cat {
    croak 'usage: Cat( FILENAME )' if @_ != 1;
    my ($filename) = @_;
    open my $f, '<', $filename or croak "open: $!";
    local $/ if !wantarray;
    return <$f>;
}
sub MEM_used {
    return(`ps -o'rss' -p $$` =~ /(\d+)/) if($^O=~/(^darwin$)/);	# Mac OS/X
    if($^O=~/Win32/i) { my($m)=`tasklist /nh /fi "PID eq $$"` =~/.*\s([\d,]+)/; $m=~tr/,//d; return $m;}	# MSWin32
    return (Cat('/proc/self/status') =~ /VmRSS:\s*(\d*)/)[0];		# Linux
};
sub FD_used {
    if($^O=~/^(darwin|MSWin32)$/) {
	diag sprintf "  If anyone knows how to find the process file-descriptor usage under Mac OS/X or $^O please let me know!\n";
	return 0;
    }
    opendir my $fd, '/proc/self/fd' or croak "opendir: $!";
    return @{[ readdir $fd ]} - 2;
};

