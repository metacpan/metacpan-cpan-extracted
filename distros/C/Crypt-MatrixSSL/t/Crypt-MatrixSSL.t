#! /opt/perl5/bin/perl -w
use ExtUtils::testlib;



# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-MatrixSSL.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 43;
use strict;
# BEGIN { plan tests => 9 };
use Crypt::MatrixSSL;
ok(1,'use'); # If we made it this far, we're ok. test 1
use IO::Socket;		# For the online testing part

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.



no warnings;
my($cdbg)=0;
my($rc)=333;	# Set the return code to an unlikley value



# Open the lib (most calls that work should return 0)
$rc=matrixSslOpen(); 
ok($rc==0,'matrixSslOpen');
print "matrixSslOpen() returns '$rc'\n" if($cdbg);




# Tell it where our key files are
my(%keys);
my $skeyfile = "mxprivkeySrv.pem";
my $ckeyfile = "mxprivkeyCln.pem";
my $scertfile = "mxcertSrv.pem";
my $ccertfile = "mxcertCln.pem";
my $sCAfile = "mxCAcertCln.pem";
my $cCAfile = "mxCAcertSrv.pem";
ok(&MakeKeys()==0,'MakeKeys');
my $smxkeys=333;
$rc=333;

# Read in our keys - not needed for clients who don't validate server certs.
# API in 1.7.3 has changed - memory keys are now binary encoded, not ascii-armour anymore - $rc=matrixSslReadKeysMem($smxkeys, $keys{'scertfile'}, $keys{'skeyfile'}, $keys{'sCAfile'});
$rc=matrixSslReadKeys($smxkeys, $scertfile, $skeyfile, undef, $sCAfile);
ok($rc==0,'matrixSslReadKeys');
ok($smxkeys!=0,'matrixSslReadKeys1');
ok($smxkeys!=333,'matrixSslReadKeys2');
print "matrixSslReadKeys('$smxkeys', '$scertfile', '$skeyfile', undef, '$sCAfile') returns '$rc'\n" if($cdbg);

my $cmxkeys=333;
$rc=333;

# Read in our keys - not needed for clients who don't validate server certs.
$rc=matrixSslReadKeys($cmxkeys, $ccertfile, $ckeyfile, undef, $cCAfile);
ok($rc==0,'matrixSslReadKeys');		# test 
ok($cmxkeys!=0,'matrixSslReadKeys1');	# test
ok($cmxkeys!=333,'matrixSslReadKeys2');	# test
print "matrixSslReadKeys('$cmxkeys', '$ccertfile', '$ckeyfile', undef, undef) returns '$rc'\n" if($cdbg);




my $cssl=333;
my $sssl=333;
my $csessionId=0;	# Client session (0 means new, >0 means resume)
my $ssessionId=0;	# Server session
my $flags=0; # 0=client, 1=server
$rc=333;

# Starts a new session (or resume if $sessionId>0) - done anytime a client wants one
$rc=matrixSslNewSession($cssl, $cmxkeys, $csessionId, $flags);
ok($rc==0,'matrixSslNewSession');		# test 7
ok($cssl!=0,'matrixSslNewSession1');		# test 8
ok($cssl!=333,'matrixSslNewSession2');		# test 9
ok($csessionId==0,'matrixSslNewSession3');	# test 10
print "matrixSslNewSession('$cssl', '$cmxkeys', '$csessionId', '$flags') returns '$rc'\n" if($cdbg);
$rc=333;

matrixSslSetCertValidator($cssl,sub {0},0);


# Starts a new server session (or resume if $sessionId>0) - done when a new client connects
$rc=matrixSslNewSession($sssl, $smxkeys, $ssessionId, $SSL_FLAGS_SERVER);
ok($rc==0,'matrixSslNewSession5');		# test 11
ok($sssl!=0,'matrixSslNewSession6');		# test 12
ok($sssl!=333,'matrixSslNewSession7');		# test 13
ok($ssessionId==0,'matrixSslNewSession8');	# test 14
print "matrixSslNewSession('$sssl', '$smxkeys', '$ssessionId', $SSL_FLAGS_SERVER) returns '$rc'\n"  if($cdbg);

# If wanting to extract cert info, or do more interesting validations, a call to matrixSslSetCertValidator should come next
matrixSslSetCertValidator($sssl,sub{0},0);






# Clients must build this now, for sending to the server
my($cout);
$rc=333;

$rc=matrixSslEncodeClientHello($cssl,$cout,0);
ok($rc==0,'matrixSslEncodeClientHello');		# test 15
ok(length($cout)>9,'matrixSslEncodeClientHello1');	# test 16
print "matrixSslEncodeClientHello('$cssl', '${\showme($cout)}',0) returns '$rc'\n" if($cdbg);



# we are now going to "send" our client HELLO request to our server session (this normally happens over TCP)
$rc=333;
my $error='333';
my $alertLevel='333';
my $alertDescription='333';
my $sin;
my $trymore=20;
my $hc=333;
my $sout='';
my $cin='';
my $buf='';


# Let the client and server talk amongst themselves to establish a connection
while((($hc=matrixSslHandshakeIsComplete($sssl))!=1)&&($trymore--)) {
  print "hc=$hc\n"  if($cdbg);
  # Is there stuff from the client to send to the server?
  if(length($cout)) {
    # $sin=$cout; $cout='';
    $rc=matrixSslDecode($sssl, $cout, $sout, $error, $alertLevel, $alertDescription);
    if($rc==-1) {
      $trymore=0;
    } else {
      ok(1,'decode');
    }
  }
  # Is there stuff from the server to send to the client?
  if(length($sout)) {
    # $cin=$sout; $sout='';
    $rc=matrixSslDecode($cssl, $sout, $cout, $error, $alertLevel, $alertDescription);
    if($rc==-1) {
      $trymore=0;
    } else {
      ok(1,'decode');
    }
  }
}

# We now deliberately check that it knows the handshake is complete
$rc=333;
$rc=matrixSslHandshakeIsComplete($cssl);
ok($rc==1, 'matrixSslHandshakeIsComplete1');						# test x
print "matrixSslHandshakeIsComplete('$cssl') returns '$rc'\n"  if($cdbg);

# We now deliberately check that it knows the handshake is not complete
$rc=333;
$rc=matrixSslHandshakeIsComplete($sssl);
ok($rc==1, 'matrixSslHandshakeIsComplete2');						# test x
print "matrixSslHandshakeIsComplete('$sssl') returns '$rc'\n"  if($cdbg);



# Our client is now going to send a message to the server
$rc=333;
$cin="Hello Me!\000\r\n";
$cout='';
$rc=matrixSslEncode($cssl, $cin, $cout);	# compose msg
# ok($rc==$SSL_SEND_RESPONSE,'matrixSslDecode');		# test 17
ok($rc>=0,'matrixSslEecode');		# test 17
ok(length($cout)>0,'matrixSslEecode1');	# test 18
print "matrixSslEncode('$cssl', '${\showme($cin)}', '${\showme($cout)}') returns '$rc'\n"  if($cdbg);
$rc=matrixSslDecode($sssl, $cout, $sout, $error, $alertLevel, $alertDescription); # send it
ok($rc==$SSL_PROCESS_DATA,'matrixSslDecde');		# test 17
is($sout, "Hello Me!\000\r\n", 'encode');
print "Server got $sout\n" if($cdbg);


# Our Server in now going to send a message to the client
$rc=333;
$sin="Hi Back!\000\n\r";
$sout='';
$rc=matrixSslEncode($sssl, $sin, $sout);
# ok($rc==$SSL_SEND_RESPONSE,'matrixSslDecode');		# test 17
ok($rc>=0,'matrixSslEecode');		# test 17
ok(length($sout)>0,'matrixSslEecode1');	# test 18
print "matrixSslEncode('$sssl', '${\showme($sin)}', '${\showme($sout)}') returns '$rc'\n" if($cdbg);
$rc=matrixSslDecode($cssl, $sout, $cout, $error, $alertLevel, $alertDescription); # send it
ok($rc==$SSL_PROCESS_DATA,'matrixSslDecde');		# test 17
is($cout, "Hi Back!\000\n\r", 'encode');
print "Server got $cout\n" if($cdbg);



$rc=333;
$cout='';
$rc=matrixSslGetSessionId($cssl, $cout);
ok($rc==0,'matrixSslGetSessionId');		# test
ok($cout ne '','matrixSslGetSessionId');		# test
ok($cout!=0,'matrixSslGetSessionId');		# test
print "\n\n\nmatrixSslGetSessionId($cssl, $cout)=$rc\n" if($cdbg);


$rc=333;
matrixSslFreeSessionId($cout);
print "matrixSslFreeSessionId($cout)=$rc\n"  if($cdbg);


$rc=333;
$cout='';
$rc=matrixSslEncodeClosureAlert($cssl, $cout);
print "matrixSslEncodeClosureAlert($cssl, $cout)='$rc'\n"  if($cdbg);
$rc=matrixSslDecode($sssl, $cout, $sout, $error, $alertLevel, $alertDescription); # send it
ok($rc==$SSL_ALERT,'matrixSslFreeSessionId');		# test






# Clear up the finished session now
$rc=333;
$rc=matrixSslDeleteSession($cssl);
ok($rc==0,'matrixSslDeleteSession');		# test ??
print "matrixSslDeleteSession($cssl)='$rc'\n"  if($cdbg);

$rc=333;
$rc=matrixSslDeleteSession($sssl);
ok($rc==0,'matrixSslDeleteSession2');		# test ??
print "matrixSslDeleteSession($sssl)='$rc'\n"  if($cdbg);



# Free our keys
$rc=matrixSslFreeKeys($smxkeys);
print "matrixSslFreeKeys($smxkeys)=$rc\n"  if($cdbg);
$rc=matrixSslFreeKeys($cmxkeys);
print "matrixSslFreeKeys($cmxkeys)=$rc\n"  if($cdbg);

# Tidy up
matrixSslClose();


SKIP: { skip "online tests are not enabled", 1 unless -e 't/online.enabled';

	diag "";
	diag "";
	diag "\tLooking up https://www.google.com/ ...\n";

	ok(&online_test(),'online tests');

}









unlink($skeyfile);
unlink($ckeyfile);
unlink($scertfile);
unlink($ccertfile);
unlink($sCAfile);
unlink($cCAfile);

#end
exit(0);


# Display (possibly binary) data on-screen
sub showme {
  no warnings;
  my($buf,$col2,$src)=@_;
  my $col=$col2; my($red)=''; my($norm)='';

  $buf =~ s/[\000-\011\013-\014\016-\037\177-\377]/"\\$red".unpack("H*",$&)."$col"/esmg; # Do every non-ascii char too
  $buf=~s/\r/$red\\r$col/g;
  #$buf=~s/\n/$red\\n$col\n/g;
  $buf=~s/\n/$red\\n$col/g;
  # &printa("$col$buf$norm\n")  unless($switch{'quiet'});
  return "$col$buf$norm";

}


sub online_test {
  # This is basically a copy of the mxgg.pl sample program

  my($rc,$host,$remote,$hc,$cssl,$cout,$cin,$b,$l,$error, $alertLevel,$alertDescription, $cssl,$cmxkeys,$csessionId,$flags, $cin2, $prevcin);

=for testing:

  "Opens" MatrixSSL
  Opens a socket to google
  Establishes SSL session
  Issues an HTTP "GET /"
  Reads response
  exits.

=cut

$flags=0;

$rc=matrixSslOpen();
$rc=matrixSslReadKeys($cmxkeys, $ccertfile, $ckeyfile, undef, $cCAfile);
$rc=matrixSslNewSession($cssl, $cmxkeys, $csessionId, $flags);
matrixSslSetCertValidator($cssl,sub{0},0);


$host="www.google.com:443";
# $host="www.paypal.com:443";
diag "Connecting to https://$host/ ...";
$remote=new IO::Socket::INET(PeerAddr=>$host,Proto=>'tcp') || return 0; # die "sock:$!"; # Connect to a server

diag "Writing hello ...";
$rc=matrixSslEncodeClientHello($cssl,$cout,0);if($rc){die "hello fail";} # in SSL, Clients talk 1st

# SSL connections require some back-and-forth chatskis - this loop feeds MatrixSSL with the data until it says we're connected OK.
diag "SSL Handshaking ...";
my($decodeRc)=$SSL_PARTIAL;
while(($hc=matrixSslHandshakeIsComplete($cssl))!=1) {
  print "shake complete=$hc decodeRc=$decodeRc cin_len=" . length($cin) . " cout_len=" . length($cout) . "\n";
  # if(($decodeRc==$SSL_SEND_RESPONSE)&&(length($cout)>0)) { # -4 }
  if(length($cout)>0) {
    $b=syswrite($remote,$cout); die "Socket error: $!" unless(defined($b));
    $cout=substr($cout,$b); print "wrote bytes=$b, new cout_len=" . length($cout) . "\n";
  }
  if(($decodeRc==$SSL_PARTIAL)||($decodeRc==$SSL_SEND_RESPONSE)) { # -3
    $buf='';$b=sysread($remote,$buf,17000);$cin.=$buf;
    print "Read bytes=$b new cin_len=" .length($cin) . " got: '${\showme($buf)}'\n"; $buf='';
  } else {
    print "'$decodeRc' != ' " . $SSL_PARTIAL . "'\n";
  }
  # elsif($prevcin eq $cin) { # These 6 lines contributed by Alex Efros
  #  $b=sysread($remote,$cin2,17000);
  #  print "A Read bytes=$b '${\showme($cin2)}'\n";
  #  $cin.=$cin2;
  #}
  #$prevcin=$cin;

  $decodeRc=-100;

  while( ($decodeRc==-100) || (($decodeRc==0)&&(length($cin)>0))) { # !=$SSL_PARTIAL)  # -3  length($cin)>0)  #}
  # while($decodeRc==0) { # !=$SSL_PARTIAL) { # -3  length($cin)>0) { #}
    #print "cin len=" . length($cin) . "\n";
    $decodeRc=matrixSslDecode($cssl, $cin, $buf, $error, $alertLevel, $alertDescription);
    print "matrixSslDecode rc=$decodeRc($Crypt::MatrixSSL::mxSSL_RETURN_CODES{$decodeRc}) cin_len=" . length($cin) . " cout_len=" . length($cout);
    $cout.=$buf; $buf='';
    # Need to end if $rc hit an error
    if($decodeRc){ print " err=$error ($SSL_alertDescription{$error})"}; print "\n";
    die "oops" if($l++>20);
  }
  die "oops" if($l++>20);
}


# Our client is now going to send a message to the server
diag "Requesting page ...";
$rc=matrixSslEncode($cssl, "GET / HTTP/1.1\r\nAccept: */*\r\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)\r\nHost: $host\r\n\r\n", $cout);
syswrite($remote,$cout); print "wrote bytes=" . length($cout) . "\n" if(length($cout));


# Wait for google to talk back to us:-
diag "Reading response ...";
$b=sysread($remote,$cin,17000); print "Read bytes=$b '${\showme($cin)}'\n";

# Decrypt what it said:-
$rc=matrixSslDecode($cssl, $cin, $cout, $error, $alertLevel, $alertDescription);
print "Read($rc): '$cout'";

my $ret=0;
$ret=1 if($cout=~/^(Content-Type:|Location:)/im);


# Tell google we're about to go away now
$rc=matrixSslEncodeClosureAlert($cssl, $cout);
syswrite($remote,$cout); print "wrote bytes=" . length($cout) . "\n" if(length($cout));


# Clear up the finished session now
$rc=matrixSslDeleteSession($cssl);

# Free our keys
$rc=matrixSslFreeKeys($cmxkeys);

return $ret; # Worked

}



# Create the key files for testing with
sub MakeKeys {

# TO DO: replace all these with the new peersec ones with longer expiration dates:
# privkeySrv.pem
# privkeyCln.pem
# certSrv.pem
# certCln.pem
# CAcertSrv.pem
# CAcertCln.pem

open(PEM,">$skeyfile");
$keys{'skeyfile'}= q ~-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQDd5a6/JzURVbrPRc0H445n2JhcHRCiU7AKXCmLrOvr07kQRF+S
lN4iLIK7l0ksTU6bFagbJ56NOHkjgGcVoTN/Qp3jeFPAsJ8BUB0oiCat9y6vwyGF
WXk3Kv99AJeZV+VS1g1t29u+0tKBqKMJxBOckqHnxJeK27SRvIrlNED85QIDAQAB
AoGAVP26dwD/dIpPqUBlDdZ9Hw15Hh8L1gET9oPibdtn6cYIplBqAuz+QDyoPk3t
+wgJSaF76Bq+wfyVeaGe2kwKOseOC0j8Zh1ELyrwYM4oFDky8Q61JNmauic3n8Px
GQzV2hGfY3ZXYJWmr1cg50qypq1pqcI1M2TsfX+6Bu2UzWkCQQD2NYq8SxJF/kDC
WzW2nb+l+uCa3V8vg+Syai8aWrL9S4PX+ksNpRi990K6ozX6UvxPeSXfwb7YSxTN
MrLqYPkTAkEA5rij4toqWcwsJ9wj/VvJ+j0waaf+7un2r6LrWLdaGzgEZYhi0Dlk
k7DpkjDglLitepLj6sLFUmj0EgDkO+0pJwJBAKBa5u0UB+bGXe838JfrzjKQX1D9
9UzBHmaFegA0KneGg2xbfB569M5lCHT+b92FxwcL5HsDeQTugbHT32t/lTkCQHHY
VfXQFOmuV3Nrqs6PhkBWBRd9b8vP4ouT5nEmN+4KXBEFlUyNpVVDDF24hHieD+vV
o2TpqpgZdaWUjwoK4i0CPw8C07aOC/Hp5ia6lTtoA4Zk04m9aaONjRywOGe6XKge
fp2V6yZuKqt0okYUNahhuenYDSUbErPS8pe0gV20eQ==
-----END RSA PRIVATE KEY-----
~;
print PEM $keys{'skeyfile'};
close(PEM);
open(PEM,">$scertfile");
$keys{'scertfile'}=q ~Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1 (0x1)
        Signature Algorithm: md5WithRSAEncryption
        Issuer: CN=PeerSec Sample CA, ST=Washington, C=US/emailAddress=peersec@peersec.com, O=PeerSec Networks LLC, OU=MatrixSSL
        Validity
            Not Before: Mar 11 20:02:34 2004 GMT
            Not After : Mar 11 20:02:34 2005 GMT
        Subject: CN=Sample MatrixSSL Cert, ST=Washington, C=US/emailAddress=matrixssl@peersec.com, O=PeerSec Networks LLC, OU=MatrixSSL
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
            RSA Public Key: (1024 bit)
                Modulus (1024 bit):
                    00:dd:e5:ae:bf:27:35:11:55:ba:cf:45:cd:07:e3:
                    8e:67:d8:98:5c:1d:10:a2:53:b0:0a:5c:29:8b:ac:
                    eb:eb:d3:b9:10:44:5f:92:94:de:22:2c:82:bb:97:
                    49:2c:4d:4e:9b:15:a8:1b:27:9e:8d:38:79:23:80:
                    67:15:a1:33:7f:42:9d:e3:78:53:c0:b0:9f:01:50:
                    1d:28:88:26:ad:f7:2e:af:c3:21:85:59:79:37:2a:
                    ff:7d:00:97:99:57:e5:52:d6:0d:6d:db:db:be:d2:
                    d2:81:a8:a3:09:c4:13:9c:92:a1:e7:c4:97:8a:db:
                    b4:91:bc:8a:e5:34:40:fc:e5
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
            CA:FALSE
    Signature Algorithm: md5WithRSAEncryption
        39:22:28:1d:78:ce:95:65:7d:df:6a:1a:64:53:50:e3:ad:41:
        d9:a5:41:49:36:45:fc:6d:97:02:65:25:07:18:c9:05:ae:95:
        95:52:14:6b:98:84:dc:0c:40:e1:7e:7f:11:6e:8d:4c:34:06:
        06:89:0e:16:13:c7:40:15:76:a9:6f:d8:d1:c3:81:a7:35:67:
        f9:da:ba:21:94:16:3d:d0:6d:48:14:d3:35:ae:14:f2:84:4d:
        51:5f:8e:5b:f6:20:27:09:85:2c:58:80:d2:9b:68:ae:8b:93:
        1e:96:5f:6f:74:54:50:5c:9f:7f:3b:c9:62:e4:f7:be:6f:cd:
        d1:31
-----BEGIN CERTIFICATE-----
MIICtTCCAh6gAwIBAgIBATANBgkqhkiG9w0BAQQFADCBlTEaMBgGA1UEAxMRUGVl
clNlYyBTYW1wbGUgQ0ExEzARBgNVBAgTCldhc2hpbmd0b24xCzAJBgNVBAYTAlVT
MSIwIAYJKoZIhvcNAQkBFhNwZWVyc2VjQHBlZXJzZWMuY29tMR0wGwYDVQQKExRQ
ZWVyU2VjIE5ldHdvcmtzIExMQzESMBAGA1UECxMJTWF0cml4U1NMMB4XDTA0MDMx
MTIwMDIzNFoXDTA1MDMxMTIwMDIzNFowgZsxHjAcBgNVBAMTFVNhbXBsZSBNYXRy
aXhTU0wgQ2VydDETMBEGA1UECBMKV2FzaGluZ3RvbjELMAkGA1UEBhMCVVMxJDAi
BgkqhkiG9w0BCQEWFW1hdHJpeHNzbEBwZWVyc2VjLmNvbTEdMBsGA1UEChMUUGVl
clNlYyBOZXR3b3JrcyBMTEMxEjAQBgNVBAsTCU1hdHJpeFNTTDCBnzANBgkqhkiG
9w0BAQEFAAOBjQAwgYkCgYEA3eWuvyc1EVW6z0XNB+OOZ9iYXB0QolOwClwpi6zr
69O5EERfkpTeIiyCu5dJLE1OmxWoGyeejTh5I4BnFaEzf0Kd43hTwLCfAVAdKIgm
rfcur8MhhVl5Nyr/fQCXmVflUtYNbdvbvtLSgaijCcQTnJKh58SXitu0kbyK5TRA
/OUCAwEAAaMNMAswCQYDVR0TBAIwADANBgkqhkiG9w0BAQQFAAOBgQA5IigdeM6V
ZX3fahpkU1DjrUHZpUFJNkX8bZcCZSUHGMkFrpWVUhRrmITcDEDhfn8Rbo1MNAYG
iQ4WE8dAFXapb9jRw4GnNWf52rohlBY90G1IFNM1rhTyhE1RX45b9iAnCYUsWIDS
m2iui5Mell9vdFRQXJ9/O8li5Pe+b83RMQ==
-----END CERTIFICATE-----
~;
print PEM $keys{'scertfile'};
close(PEM);
open(PEM,">$sCAfile");
$keys{'sCAfile'}= q ~-----BEGIN CERTIFICATE-----
MIICoDCCAgmgAwIBAgIBADANBgkqhkiG9w0BAQQFADCBjDEXMBUGA1UEAxMOQWNt
ZSBTYW1wbGUgQ0ExFTATBgNVBAgTDFJob2RlIElzbGFuZDELMAkGA1UEBhMCVVMx
HzAdBgkqhkiG9w0BCQEWEGNvbnRhY3RAYWNtZS5jb20xEjAQBgNVBAoTCUFjbWUg
SW5jLjEYMBYGA1UECxMPRGV2aWNlIFNlY3VyaXR5MB4XDTA0MDQyMTAzMDkwOVoX
DTA0MDUyMTAzMDkwOVowgYwxFzAVBgNVBAMTDkFjbWUgU2FtcGxlIENBMRUwEwYD
VQQIEwxSaG9kZSBJc2xhbmQxCzAJBgNVBAYTAlVTMR8wHQYJKoZIhvcNAQkBFhBj
b250YWN0QGFjbWUuY29tMRIwEAYDVQQKEwlBY21lIEluYy4xGDAWBgNVBAsTD0Rl
dmljZSBTZWN1cml0eTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAy1ajcGGP
pJ2azxAmnLD/i1FyhdPKtOZLX7dAhSA30llTxeBXz3hUJBe55Hq9k7jPrwPVNecI
NziSKjxarrvNC/BcYTC6H9NZy8mx6BpZn6Utd4aXuI12mo+QB0G7xkw2hh8HFH+c
6T7QEeK+Du4zFJ0c51s44DtEfl1r/KSCVh0CAwEAAaMQMA4wDAYDVR0TBAUwAwEB
/zANBgkqhkiG9w0BAQQFAAOBgQAtest5gKwgk+sLkTIS5R8pWFs7UKAQf9w9/H80
Pv7tKtkqBSVvCfynWyxFT4EATihi6akixauyHDbpV63Rh26OEw03Ir4E38w7A+Ux
HqHo0YYy2VLDkCYsGJrQZ9THfknxKtjEz1xVdaUwNjzpTzyYjh994f6/ATVeUxRh
WPLjqA==
-----END CERTIFICATE-----
~;
print PEM $keys{'sCAfile'};
close(PEM);
open(PEM,">$cCAfile");
print PEM q ~-----BEGIN CERTIFICATE-----
MIICsjCCAhugAwIBAgIBADANBgkqhkiG9w0BAQQFADCBlTEaMBgGA1UEAxMRUGVl
clNlYyBTYW1wbGUgQ0ExEzARBgNVBAgTCldhc2hpbmd0b24xCzAJBgNVBAYTAlVT
MSIwIAYJKoZIhvcNAQkBFhNwZWVyc2VjQHBlZXJzZWMuY29tMR0wGwYDVQQKExRQ
ZWVyU2VjIE5ldHdvcmtzIExMQzESMBAGA1UECxMJTWF0cml4U1NMMB4XDTA0MDMx
MTE5MjM0NFoXDTA3MDMxMTE5MjM0NFowgZUxGjAYBgNVBAMTEVBlZXJTZWMgU2Ft
cGxlIENBMRMwEQYDVQQIEwpXYXNoaW5ndG9uMQswCQYDVQQGEwJVUzEiMCAGCSqG
SIb3DQEJARYTcGVlcnNlY0BwZWVyc2VjLmNvbTEdMBsGA1UEChMUUGVlclNlYyBO
ZXR3b3JrcyBMTEMxEjAQBgNVBAsTCU1hdHJpeFNTTDCBnzANBgkqhkiG9w0BAQEF
AAOBjQAwgYkCgYEAr3fxAYbVGTmLovfLGbc/REP94OrA6Ccrn3vidJjWysoQ2jGM
tBhDUWEuCjJusxs6sw+RTHKtBt6Qp37PfNFNj3UDX9xrw4/rGsM6dj5v4xslpraq
pKeIKB3tXvIV//Ud9FWGbWW836zXUUUHTTQ/BoYqoefAPglY4RytSncdeFMCAwEA
AaMQMA4wDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQQFAAOBgQBf/tmt/5jqWTVz
cCkLE2oLY4daC8sY54ACURtylCdI4Q7ozRIfKzrFrpEjPY5qOFvN48CZPzvSA/En
42ozML6rxRCeMsgyjbpsmwWzRWdNFGeIoUlMauK1u4GgaQ+xsd9iORFqGZ2jSUWm
RepGD+pOov+ZreAg41ahXVF0dTDQpA==
-----END CERTIFICATE-----
~;
close(PEM);
open(PEM,">$ccertfile");
print PEM q ~Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 7 (0x7)
        Signature Algorithm: sha1WithRSAEncryption
        Issuer: CN=Acme Sample CA, ST=Rhode Island, C=US/emailAddress=contact@acme.com, O=Acme Inc., OU=Device Security
        Validity
            Not Before: Apr 21 03:17:05 2004 GMT
            Not After : Apr 21 03:17:05 2005 GMT
        Subject: CN=Sample Acme Cert, ST=Rhode Island, C=US/emailAddress=support@acme.com, O=Acme Inc., OU=Device Security
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
            RSA Public Key: (1024 bit)
                Modulus (1024 bit):
                    00:c7:e3:9f:ba:06:69:4f:7f:58:ea:6d:14:0f:84:
                    f6:21:e6:44:17:ee:b6:35:84:19:13:98:91:0e:15:
                    54:5d:62:93:d5:dd:52:1f:e0:36:7d:71:52:96:18:
                    3a:e8:dd:8f:5f:8b:4b:67:a2:70:33:9d:06:8c:5a:
                    10:0e:a8:42:1a:8a:2e:8f:32:44:d8:fe:a8:0a:6e:
                    9e:9f:88:d6:7f:3a:57:12:e6:73:96:f3:db:f4:bc:
                    0a:39:35:a2:fd:3a:6b:9c:e4:58:f3:e0:68:76:31:
                    43:42:71:b3:7e:de:1f:c7:8d:ad:27:9e:a2:4b:00:
                    25:e3:13:bc:8d:e6:03:20:5d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Alternative Name: 
                URI:what, DNS:www.acme.com, email:support@acme.com
            X509v3 Basic Constraints: 
                CA:FALSE
    Signature Algorithm: sha1WithRSAEncryption
        66:19:07:df:d0:86:1f:f2:15:99:f5:2c:06:d1:f2:51:91:5e:
        61:1e:ff:ac:3c:7f:94:f4:2c:fe:5a:70:75:6d:e3:dd:42:dd:
        d2:00:87:cf:d0:38:f5:84:49:cb:01:20:73:55:e0:18:b5:9a:
        e7:f1:96:0a:97:12:b0:68:30:8f:fd:9a:fe:43:4d:5f:27:ed:
        e0:3d:91:c0:e0:d1:b5:08:32:1c:ef:03:54:fc:20:6a:26:bb:
        a5:50:0f:52:50:ee:77:15:52:23:78:97:2e:43:34:ac:71:cc:
        97:3f:78:5e:06:7a:ac:26:fa:f6:32:11:a6:bc:01:cc:b6:4d:
        47:21
-----BEGIN CERTIFICATE-----
MIIC0DCCAjmgAwIBAgIBBzANBgkqhkiG9w0BAQUFADCBjDEXMBUGA1UEAxMOQWNt
ZSBTYW1wbGUgQ0ExFTATBgNVBAgTDFJob2RlIElzbGFuZDELMAkGA1UEBhMCVVMx
HzAdBgkqhkiG9w0BCQEWEGNvbnRhY3RAYWNtZS5jb20xEjAQBgNVBAoTCUFjbWUg
SW5jLjEYMBYGA1UECxMPRGV2aWNlIFNlY3VyaXR5MB4XDTA0MDQyMTAzMTcwNVoX
DTA1MDQyMTAzMTcwNVowgY4xGTAXBgNVBAMTEFNhbXBsZSBBY21lIENlcnQxFTAT
BgNVBAgTDFJob2RlIElzbGFuZDELMAkGA1UEBhMCVVMxHzAdBgkqhkiG9w0BCQEW
EHN1cHBvcnRAYWNtZS5jb20xEjAQBgNVBAoTCUFjbWUgSW5jLjEYMBYGA1UECxMP
RGV2aWNlIFNlY3VyaXR5MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDH45+6
BmlPf1jqbRQPhPYh5kQX7rY1hBkTmJEOFVRdYpPV3VIf4DZ9cVKWGDro3Y9fi0tn
onAznQaMWhAOqEIaii6PMkTY/qgKbp6fiNZ/OlcS5nOW89v0vAo5NaL9Omuc5Fjz
4Gh2MUNCcbN+3h/Hja0nnqJLACXjE7yN5gMgXQIDAQABoz4wPDAvBgNVHREEKDAm
hgR3aGF0ggx3d3cuYWNtZS5jb22BEHN1cHBvcnRAYWNtZS5jb20wCQYDVR0TBAIw
ADANBgkqhkiG9w0BAQUFAAOBgQBmGQff0IYf8hWZ9SwG0fJRkV5hHv+sPH+U9Cz+
WnB1bePdQt3SAIfP0Dj1hEnLASBzVeAYtZrn8ZYKlxKwaDCP/Zr+Q01fJ+3gPZHA
4NG1CDIc7wNU/CBqJrulUA9SUO53FVIjeJcuQzSsccyXP3heBnqsJvr2MhGmvAHM
tk1HIQ==
-----END CERTIFICATE-----
~;
close(PEM);
open(PEM,">$ckeyfile");
print PEM q ~-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQDH45+6BmlPf1jqbRQPhPYh5kQX7rY1hBkTmJEOFVRdYpPV3VIf
4DZ9cVKWGDro3Y9fi0tnonAznQaMWhAOqEIaii6PMkTY/qgKbp6fiNZ/OlcS5nOW
89v0vAo5NaL9Omuc5Fjz4Gh2MUNCcbN+3h/Hja0nnqJLACXjE7yN5gMgXQIDAQAB
AoGAQVTYY8isqtsIiLZWFCx09ed44gmXbC5cs9btshiulkcd4oyPxvNVW/Kp93y7
5Fhl/+hbIOgqm/P6q+zTyrabw9RD5Fudzgb0Qsz01wNdJwz5L6Ist9dxVhV0EeFz
7SsrtB4z/UKt3OLNLvQinsaPdjiR3faszlVHCKV6a4gZ1tECQQD52c7YTWF8cdiq
UbETl2pMvure7fyGdZesiBh4CEOuXSR+darzWNk2+oaZ9+snyA2z+ASgfs0YWvA8
rKV0t9y3AkEAzM8H+GrBN1ILUP9LlMvXR/HI84js8C6zB6R13VNqP4JP7ne6btD+
KK3GM2fJVhU4Am/iNZup3KM/Lggy/Uz/iwJBAIFafLaLyW7uWihDxxPHjqdRKLRm
LhlHBFG03EY4sSGy41P9g5YdZ8gJCGrqafrcnguQ2oRlYbW8Tyh6kebN0h0CQA6q
gKKcWmuwt1i8f1gPZMIlIUO3OWhVn8JbV4la0M/tb/Xeov4OfzTAhOHne7ZrXJBo
HKXEGNzQ39RXB/e1jNMCQAJL81AimL997kBMZef66b38le1pC6o3GS1foACAFqB8
GaSP/Y50CcBz2cBagigDQ778zNyiyXsSHnjKeNTshHU=
-----END RSA PRIVATE KEY-----
~;
close(PEM);

return 0;
} # MakeKeys
