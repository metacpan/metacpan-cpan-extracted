#!/usr/bin/perl
################################################################################
#
#  Script Name : $RCSFile$
#  Version     : $Revision: 0.3 $
#  Company     : Down Home Web Design, Inc
#  Author      : Duane Hinkley ( duane@dhwd.com )
#  Website     : www.DownHomeWebDesign.com
#
#  Description:  Program description.
#
#
#  Copyright (c) 2003-2004 Down Home Web Design, Inc.  All rights reserved.
#
#  $Header: /home/cvs/simple_smime/t/01_init.t,v 0.3 2004/10/10 18:32:25 cvs Exp $
#
#  $Log: 01_init.t,v $
#  Revision 0.3  2004/10/10 18:32:25  cvs
#  Added Interchange user tag and directions
#
#  Revision 0.2  2004/10/10 16:12:01  cvs
#  Get everything working
#
#  Revision 0.1  2004/10/10 00:00:14  cvs
#  Initial checkin
#
#  Revision 1.1  2004/10/09 15:51:27  cvs
#  Version one
#
#
#
################################################################################


use strict;
use lib qw( ./lib ../lib );
use Crypt::Simple::SMIME;

use ExtUtils::MakeMaker qw(prompt);

use Test::More tests => 24;


# Initialize module
#
my $c = new Crypt::Simple::SMIME();

isa_ok( $c, 'Crypt::Simple::SMIME' );

ok( $c->OpenSSLPath() , "Default openssl path set");
ok( $c->OpenSSLPath('c:\temp\openssl.exe') eq 'c:\temp\openssl.exe' , "Set & read openssl path");

ok( $c->SendmailPath() , "Default sendmail path set");
ok( $c->SendmailPath('c:\temp\sendmail.exe') eq 'c:\temp\sendmail.exe' , "Set & read sendmail path");

ok( $c->CertificatePath('/home/bob/certificate.pem') eq '/home/bob/certificate.pem' , "Set & read sendmail path");

my $c2 = new Crypt::Simple::SMIME( 
									{
										'openssl'	=>	'c:\temp\openssl.exe',
										'sendmail'	=>	'c:\temp\sendmail.exe',
										'certificate'	=>	'/home/bob/certificate.pem'
									}
								);

isa_ok( $c2, 'Crypt::Simple::SMIME' );
ok( $c2->OpenSSLPath() eq 'c:\temp\openssl.exe' , "Set openssl path in new");
ok( $c2->SendmailPath() eq 'c:\temp\sendmail.exe' , "Set sendmail path in new");
ok( $c2->CertificatePath() eq '/home/bob/certificate.pem' , "Set certificate path in new");


ok( ! $c2->Error(), "Read no error set");
ok( $c2->Error('This is an error'), "Read error set");
ok( $c2->Error() eq 'This is an error', "Read error message");

$c2->SendMail('','from','to','subject','message');
ok(  $c2->Error() eq "From address missing in method SendMail", "Missing From Address");

$c2->SendMail('to','','subject','message');
ok(  $c2->Error() eq "To address missing in method SendMail", "Missing To Address");

$c2->SendMail('to','from','','message');
ok(  $c2->Error() eq "Subject missing in method SendMail", "Missing Subject");

$c2->SendMail('to','from','subject','');
ok(  $c2->Error() eq "Message missing in method SendMail", "Missing Message");

$c2->OpenSSLPath('alsdkjfadfkalsdfk');
$c2->SendMail('to','from','to','subject','message');
ok(  $c2->Error() eq "Can't find openssl binary", "Bad openssl path");


$c = new Crypt::Simple::SMIME();
my $cmd = "touch " . $c->OpenSSLPath('t/tmp/openssl');  
system($cmd); # make sure open ssl exists for this test

$c->SendmailPath('alsdkjfadfkalsdfk');
$c->SendMail('to','from','to','subject','message');
ok(  $c->Error() eq "Can't find sendmail binary", "Bad sendmail path");

$c = new Crypt::Simple::SMIME();
$cmd = "touch " . $c->SendmailPath('t/tmp/sendmail');  
system($cmd); # make sure sendmail exists for this test

$c->CertificatePath('alsdkjfadfkalsdfk');
$c->SendMail('to','from','to','subject','message');
ok(  $c->Error() eq "Can't find certificate file", "Bad certificate path");


ok(  $c->_str_replace('"', '\\"', 'This contains " that quote' ) eq 'This contains \" that quote', "Test str_replace command");

$c = new Crypt::Simple::SMIME();
$cmd = "touch " . $c->CertificatePath('t/tmp/crt');  
system($cmd); # make sure certfile exists for this test

#$c->SendMail('to','from','to','subject','message');
#print "Error: " . $c->Error();
#$c->SendMail('to','from','to','subject','message');
#ok( $c->Error()  eq "Unknown error sending encrypted mail", "Send email with bad certificate") or diag( $c->Error() );
#ok( ! $c->SendMail('to','from','to','subject','message'), "Send email with bad certificate return value") or diag( $c->Error() );


#$c = new Crypt::Simple::SMIME();
#if ( $c->CertificatePath() && $c->SendmailPath() ) {

#	$c->CertificatePath('t/crt/bob_cert.pem');
#	ok( $c->SendMail('bob@localhost','from','to','subject','message'), "Send email with good certificate") or diag( $c->Error() );
#}

ok(  $c->SignedEmailCertificate('t/crt/message.eml') , "Set certificate from signed email");

#####################################################################################################
# This is a signed email
#
my $cert = 'Return-Path: <duane@DownHomeWebDesign.com>
Received: from ns1.downhomewebdesign.com (primary [63.172.188.122])
	by downhom.homeip.net (8.11.6/8.11.6) with ESMTP id i99KXt906662
	for <dlhinkley@downhom.homeip.net>; Sat, 9 Oct 2004 14:33:55 -0600
Received: from DownHomeWebDesign.com ([67.137.253.2])
	(authenticated bits=0)
	by ns1.downhomewebdesign.com (8.12.11/8.12.11) with ESMTP id i99KXkBb030349
	for <duane@dhwd.com>; Sat, 9 Oct 2004 14:33:54 -0600
Message-ID: <41684B26.5010802@DownHomeWebDesign.com>
Date: Sat, 09 Oct 2004 14:33:42 -0600
From: Duane Hinkley <duane@DownHomeWebDesign.com>
User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.4) Gecko/20030624 Netscape/7.1 (ax)
X-Accept-Language: en-us, en
MIME-Version: 1.0
To: duane@dhwd.com
Subject: signed email
X-Enigmail-Version: 0.76.8.0
X-Enigmail-Supports: pgp-inline, pgp-mime
Content-Type: multipart/signed; protocol="application/x-pkcs7-signature"; micalg=sha1; boundary="------------ms080500010205090305070101"
X-Spam-Checker-Version: SpamAssassin 3.0.0-rc1 (2004-08-15) on 
	downhom.homeip.net
X-Spam-Status: No, score=-3.8 required=8.0 tests=AWL,BAYES_00 autolearn=ham 
	version=3.0.0-rc1
X-Spam-Level: 

This is a cryptographically signed message in MIME format.

--------------ms080500010205090305070101
Content-Type: text/plain; charset=us-ascii; format=flowed
Content-Transfer-Encoding: 7bit


-- 


Sincerely,

Duane Hinkley
Down Home Web Design, Inc.
(208) 424-0572 Fax(208) 587-0738

duane@downhomewebdesign.com
www.downhomewebdesign.com


--------------ms080500010205090305070101
Content-Type: application/x-pkcs7-signature; name="smime.p7s"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="smime.p7s"
Content-Description: S/MIME Cryptographic Signature

MIAGCSqGSIb3DQEHAqCAMIACAQExCzAJBgUrDgMCGgUAMIAGCSqGSIb3DQEHAQAAoIIJETCC
AuMwggJMoAMCAQICAwxPPjANBgkqhkiG9w0BAQQFADBiMQswCQYDVQQGEwJaQTElMCMGA1UE
ChMcVGhhd3RlIENvbnN1bHRpbmcgKFB0eSkgTHRkLjEsMCoGA1UEAxMjVGhhd3RlIFBlcnNv
bmFsIEZyZWVtYWlsIElzc3VpbmcgQ0EwHhcNMDQwNTE0MDI0ODMxWhcNMDUwNTE0MDI0ODMx
WjBNMR8wHQYDVQQDExZUaGF3dGUgRnJlZW1haWwgTWVtYmVyMSowKAYJKoZIhvcNAQkBFhtk
dWFuZUBkb3duaG9tZXdlYmRlc2lnbi5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQDI5KBcn1creINwe69LX+s9cFYalGT2GOexBfhTy59kX+3hx+1YTcraIz0QSKPQRH/S
0oXsu36zhPciso9wf9jdSRm63YEy7FZcPQK55jvPZNj5NQCXC+Q4j1FxKcjYuzif9SAdrXnu
Y3foWP0GoZ3aTO5Dcb9C9LrUaqsFIApH7kF2j741yKKH0st5e2Xjt8cjNJL4SO71zuVi102D
87lv962AA8PgYhj+zoq7k/PMtxVW8PYWNHLtpihcdzv0XFd/rbAwwc0BMqFMccQ+d5le1bLS
m/tV+w+sjTdUYjdoR87aQ/2AJKg9IuvO1DthPNdeRrrUYEeV6a7zGonwLoVLAgMBAAGjODA2
MCYGA1UdEQQfMB2BG2R1YW5lQGRvd25ob21ld2ViZGVzaWduLmNvbTAMBgNVHRMBAf8EAjAA
MA0GCSqGSIb3DQEBBAUAA4GBAJEhqQe0zDcGpRi95R4PjB4071MIFBjLcOhilkQsCDL1L38d
UszkuAICasPoIwV5Rg1xtTjT0g5+voRqlCpCOcyT5d03y5augXZvtlTFsB7B+8QKEcRbvCFF
XpMSMPTsyLXat3IRPQTu9sLL2FyoUigfW+Zk+nz6deO02a0UE83DMIIC4zCCAkygAwIBAgID
DE8+MA0GCSqGSIb3DQEBBAUAMGIxCzAJBgNVBAYTAlpBMSUwIwYDVQQKExxUaGF3dGUgQ29u
c3VsdGluZyAoUHR5KSBMdGQuMSwwKgYDVQQDEyNUaGF3dGUgUGVyc29uYWwgRnJlZW1haWwg
SXNzdWluZyBDQTAeFw0wNDA1MTQwMjQ4MzFaFw0wNTA1MTQwMjQ4MzFaME0xHzAdBgNVBAMT
FlRoYXd0ZSBGcmVlbWFpbCBNZW1iZXIxKjAoBgkqhkiG9w0BCQEWG2R1YW5lQGRvd25ob21l
d2ViZGVzaWduLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMjkoFyfVyt4
g3B7r0tf6z1wVhqUZPYY57EF+FPLn2Rf7eHH7VhNytojPRBIo9BEf9LShey7frOE9yKyj3B/
2N1JGbrdgTLsVlw9ArnmO89k2Pk1AJcL5DiPUXEpyNi7OJ/1IB2tee5jd+hY/QahndpM7kNx
v0L0utRqqwUgCkfuQXaPvjXIoofSy3l7ZeO3xyM0kvhI7vXO5WLXTYPzuW/3rYADw+BiGP7O
iruT88y3FVbw9hY0cu2mKFx3O/RcV3+tsDDBzQEyoUxxxD53mV7VstKb+1X7D6yNN1RiN2hH
ztpD/YAkqD0i687UO2E8115GutRgR5XprvMaifAuhUsCAwEAAaM4MDYwJgYDVR0RBB8wHYEb
ZHVhbmVAZG93bmhvbWV3ZWJkZXNpZ24uY29tMAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEE
BQADgYEAkSGpB7TMNwalGL3lHg+MHjTvUwgUGMtw6GKWRCwIMvUvfx1SzOS4AgJqw+gjBXlG
DXG1ONPSDn6+hGqUKkI5zJPl3TfLlq6Bdm+2VMWwHsH7xAoRxFu8IUVekxIw9OzItdq3chE9
BO72wsvYXKhSKB9b5mT6fPp147TZrRQTzcMwggM/MIICqKADAgECAgENMA0GCSqGSIb3DQEB
BQUAMIHRMQswCQYDVQQGEwJaQTEVMBMGA1UECBMMV2VzdGVybiBDYXBlMRIwEAYDVQQHEwlD
YXBlIFRvd24xGjAYBgNVBAoTEVRoYXd0ZSBDb25zdWx0aW5nMSgwJgYDVQQLEx9DZXJ0aWZp
Y2F0aW9uIFNlcnZpY2VzIERpdmlzaW9uMSQwIgYDVQQDExtUaGF3dGUgUGVyc29uYWwgRnJl
ZW1haWwgQ0ExKzApBgkqhkiG9w0BCQEWHHBlcnNvbmFsLWZyZWVtYWlsQHRoYXd0ZS5jb20w
HhcNMDMwNzE3MDAwMDAwWhcNMTMwNzE2MjM1OTU5WjBiMQswCQYDVQQGEwJaQTElMCMGA1UE
ChMcVGhhd3RlIENvbnN1bHRpbmcgKFB0eSkgTHRkLjEsMCoGA1UEAxMjVGhhd3RlIFBlcnNv
bmFsIEZyZWVtYWlsIElzc3VpbmcgQ0EwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAMSm
PFVzVftOucqZWh5owHUEcJ3f6f+jHuy9zfVb8hp2vX8MOmHyv1HOAdTlUAow1wJjWiyJFXCO
3cnwK4Vaqj9xVsuvPAsH5/EfkTYkKhPPK9Xzgnc9A74r/rsYPge/QIACZNenprufZdHFKlSF
D0gEf6e20TxhBEAeZBlyYLf7AgMBAAGjgZQwgZEwEgYDVR0TAQH/BAgwBgEB/wIBADBDBgNV
HR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLnRoYXd0ZS5jb20vVGhhd3RlUGVyc29uYWxGcmVl
bWFpbENBLmNybDALBgNVHQ8EBAMCAQYwKQYDVR0RBCIwIKQeMBwxGjAYBgNVBAMTEVByaXZh
dGVMYWJlbDItMTM4MA0GCSqGSIb3DQEBBQUAA4GBAEiM0VCD6gsuzA2jZqxnD3+vrL7CF6FD
lpSdf0whuPg2H6otnzYvwPQcUCCTcDz9reFhYsPZOhl+hLGZGwDFGguCdJ4lUJRix9sncVcl
jd2pnDmOjCBPZV+V2vf3h9bGCE6u9uo05RAaWzVNd+NWIXiC3CEZNd4ksdMdRv9dX2VPMYID
OzCCAzcCAQEwaTBiMQswCQYDVQQGEwJaQTElMCMGA1UEChMcVGhhd3RlIENvbnN1bHRpbmcg
KFB0eSkgTHRkLjEsMCoGA1UEAxMjVGhhd3RlIFBlcnNvbmFsIEZyZWVtYWlsIElzc3Vpbmcg
Q0ECAwxPPjAJBgUrDgMCGgUAoIIBpzAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqG
SIb3DQEJBTEPFw0wNDEwMDkyMDMzNDNaMCMGCSqGSIb3DQEJBDEWBBQn+EUMxBkcr7to7Yzr
+1U2q8wX0DBSBgkqhkiG9w0BCQ8xRTBDMAoGCCqGSIb3DQMHMA4GCCqGSIb3DQMCAgIAgDAN
BggqhkiG9w0DAgIBQDAHBgUrDgMCBzANBggqhkiG9w0DAgIBKDB4BgkrBgEEAYI3EAQxazBp
MGIxCzAJBgNVBAYTAlpBMSUwIwYDVQQKExxUaGF3dGUgQ29uc3VsdGluZyAoUHR5KSBMdGQu
MSwwKgYDVQQDEyNUaGF3dGUgUGVyc29uYWwgRnJlZW1haWwgSXNzdWluZyBDQQIDDE8+MHoG
CyqGSIb3DQEJEAILMWugaTBiMQswCQYDVQQGEwJaQTElMCMGA1UEChMcVGhhd3RlIENvbnN1
bHRpbmcgKFB0eSkgTHRkLjEsMCoGA1UEAxMjVGhhd3RlIFBlcnNvbmFsIEZyZWVtYWlsIElz
c3VpbmcgQ0ECAwxPPjANBgkqhkiG9w0BAQEFAASCAQAKmNeqJ4aTVRJM77s5KMbO9l9/7S7R
7ZpRDUlsAI1UXsfp1ztq74FOhVz+VWe6JXaob3Z3ULBcriUFkwmfNRR1ceVI4NetYV+awA04
J3CLbr9zvCIUUS5JLEnyp4jeNuTNjwZRuCuYeTt9L27jfRliLNqlq61Yz2BA/S37m+TGbgUT
KTbr8CBGOnt1ChYJ/ZFnQVVhS2W4nXlsVOwHJuBIVmWSEMv9Amn/1MCPK8cseg+cliA2vrJ/
v+F7/XLZ2WuUkGrhh9DKWllMqfazCI2+XMq1+kdmlMWb6CmKNydloYogW9ydJVxO0NQQ2Ly4
HoCdzp4mHlbH/LtgC+mkUqH/AAAAAAAA
--------------ms080500010205090305070101--

';
$c = new Crypt::Simple::SMIME();

#ok(  $c->CertificatePath('t/crt/duane.pem') , "Set certificate from variable");
ok(  $c->SignedEmailCertificate($cert) , "Set certificate from variable");

$c->SendMail('duane@downhomewebdesign.com','dlhinkley@dhwd.com','SMIME Test',"This is an encrypted test\nIt has more than one line\nIt has four lines");
print $c->EncryptCommand() . "\n";
print $c->Error() . "\n";
$c->Close();


$cert = '-----BEGIN CERTIFICATE-----
MIIC4zCCAkygAwIBAgIDDE8+MA0GCSqGSIb3DQEBBAUAMGIxCzAJBgNVBAYTAlpB
MSUwIwYDVQQKExxUaGF3dGUgQ29uc3VsdGluZyAoUHR5KSBMdGQuMSwwKgYDVQQD
EyNUaGF3dGUgUGVyc29uYWwgRnJlZW1haWwgSXNzdWluZyBDQTAeFw0wNDA1MTQw
MjQ4MzFaFw0wNTA1MTQwMjQ4MzFaME0xHzAdBgNVBAMTFlRoYXd0ZSBGcmVlbWFp
bCBNZW1iZXIxKjAoBgkqhkiG9w0BCQEWG2R1YW5lQGRvd25ob21ld2ViZGVzaWdu
LmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMjkoFyfVyt4g3B7
r0tf6z1wVhqUZPYY57EF+FPLn2Rf7eHH7VhNytojPRBIo9BEf9LShey7frOE9yKy
j3B/2N1JGbrdgTLsVlw9ArnmO89k2Pk1AJcL5DiPUXEpyNi7OJ/1IB2tee5jd+hY
/QahndpM7kNxv0L0utRqqwUgCkfuQXaPvjXIoofSy3l7ZeO3xyM0kvhI7vXO5WLX
TYPzuW/3rYADw+BiGP7OiruT88y3FVbw9hY0cu2mKFx3O/RcV3+tsDDBzQEyoUxx
xD53mV7VstKb+1X7D6yNN1RiN2hHztpD/YAkqD0i687UO2E8115GutRgR5XprvMa
ifAuhUsCAwEAAaM4MDYwJgYDVR0RBB8wHYEbZHVhbmVAZG93bmhvbWV3ZWJkZXNp
Z24uY29tMAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEEBQADgYEAkSGpB7TMNwal
GL3lHg+MHjTvUwgUGMtw6GKWRCwIMvUvfx1SzOS4AgJqw+gjBXlGDXG1ONPSDn6+
hGqUKkI5zJPl3TfLlq6Bdm+2VMWwHsH7xAoRxFu8IUVekxIw9OzItdq3chE9BO72
wsvYXKhSKB9b5mT6fPp147TZrRQTzcM=
-----END CERTIFICATE-----
';

ok(  $c->Certificate($cert) , "Set certificate from variable");

#$c->SendMail('duane@downhomewebdesign.com','dlhinkley@dhwd.com','SMIME Test2',"This is an encrypted test\nIt has more than one line\nIt has four lines");
#print $c->EncryptCommand() . "\n";
#print $c->Error() . "\n";
#$c->Close();
