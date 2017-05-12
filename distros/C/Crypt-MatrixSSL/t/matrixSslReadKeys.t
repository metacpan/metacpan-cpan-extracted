use warnings;
use strict;
use Test::More tests => 14;

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


is(0, matrixSslOpen(), 'matrixSslOpen');


is(0, matrixSslReadKeys($Server_Keys, $certFile, $privFile, $privPass, undef),
    'matrixSslReadKeys (server) NO PASSWORD');
matrixSslFreeKeys($Server_Keys);

is(0, matrixSslReadKeys($Server_Keys, $certFile, $privFile, '', undef),
    'matrixSslReadKeys (server) EMPTY PASSWORD');
matrixSslFreeKeys($Server_Keys);

is(0, matrixSslReadKeys($Server_Keys, $certFile, $privFile, 'a_n_y', undef),
    'matrixSslReadKeys (server) ANY PASSWORD');
is(0, matrixSslReadKeys($Client_Keys, undef, undef, undef, $trustedCAcertFiles),
    'matrixSslReadKeys (client)');
is(0, matrixSslReadKeys($All_Keys, $certFile, $privFile, $privPass, $trustedCAcertFiles),
    'matrixSslReadKeys (all)');
matrixSslFreeKeys($Server_Keys);
matrixSslFreeKeys($Client_Keys);
matrixSslFreeKeys($All_Keys);


is(0, matrixSslReadKeysMem($Server_Keys, $cert, $priv, undef),
    'matrixSslReadKeysMem (server)');
matrixSslFreeKeys($Server_Keys);

=for fixed in 1-8-3

TODO: {
    local $TODO = 'Bug in MatrixSSL-1.8';
    diag "Apply this patch to pass next test:\n", <<'EOPATCH';
--- x509.c.orig	2006-04-04 14:14:02.000000000 +0300
+++ x509.c	2006-06-08 19:26:37.000000000 +0300
@@ -574,11 +574,13 @@
 /*
 	Parse private key
 */
+if (privLen > 0) {
 	if (matrixRsaParsePrivKey(pool, privBuf, privLen, &lkeys->cert.privKey) < 0) {
 		matrixStrDebugMsg("Error reading private key mem\n", NULL);
 		matrixRsaFreeKeys(lkeys);
 		return -1;
 	}
+}
 
 
 /*
EOPATCH

=cut
 
    my $rc = matrixSslReadKeysMem($Client_Keys, undef, undef, $trustedCA);
    is($rc, 0, 'matrixSslReadKeysMem (client)');
    matrixSslFreeKeys($Client_Keys) if $rc == 0; # avoid segfault
# }

is(0, matrixSslReadKeysMem($All_Keys, $cert, $priv, $trustedCA),
    'matrixSslReadKeysMem (all)');
matrixSslFreeKeys($All_Keys);


is(0, matrixSslReadKeys($Server_Keys, $certFile, $privFile_des3, $privPass_des3, undef),
    'matrixSslReadKeys (server, encrypted des3) RIGHT PASSWORD');
# diag "\nhi1\n";
matrixSslFreeKeys($Server_Keys);
# diag "\nhi2\n";
isnt(0, matrixSslReadKeys($Server_Keys, $certFile, $privFile_des3, $privPass, undef),
    'matrixSslReadKeys (server, encrypted des3) NO PASSWORD');
# diag "\nhi3\n";
isnt(0, matrixSslReadKeys($Server_Keys, $certFile, $privFile_des3, '', undef),
    'matrixSslReadKeys (server, encrypted des3) EMPTY PASSWORD');
# diag "\nhi4\n";
isnt(0, matrixSslReadKeys($Server_Keys, $certFile, $privFile_des3, 'WrOnG', undef),
    'matrixSslReadKeys (server, encrypted des3) WRONG PASSWORD');
# diag "\nhi5\n";


matrixSslClose();
# diag "\nhi55\n";
ok('just to be sure there was no SegFault until this point', 'matrixSslClose');

# diag "\nhi6\n";
