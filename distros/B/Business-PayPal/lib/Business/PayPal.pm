package Business::PayPal;

use 5.6.1;
use strict;
use warnings;

our $VERSION = '0.19';

use Net::SSLeay 1.14;
use Digest::MD5 qw(md5_hex);

our $Cert;
our $Certcontent;

my @certificates;
# added to 0.12 on 2014.04.19
push @certificates, <<'CERT';
-----BEGIN CERTIFICATE-----
MIIGCDCCBPCgAwIBAgIQCDTkU9Q6aFcjr/uxM85FfDANBgkqhkiG9w0BAQUFADCB
ujELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQL
ExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQLEzJUZXJtcyBvZiB1c2Ug
YXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAoYykwNjE0MDIGA1UEAxMr
VmVyaVNpZ24gQ2xhc3MgMyBFeHRlbmRlZCBWYWxpZGF0aW9uIFNTTCBDQTAeFw0x
NDA0MTUwMDAwMDBaFw0xNTA0MDIyMzU5NTlaMIIBCTETMBEGCysGAQQBgjc8AgED
EwJVUzEZMBcGCysGAQQBgjc8AgECEwhEZWxhd2FyZTEdMBsGA1UEDxMUUHJpdmF0
ZSBPcmdhbml6YXRpb24xEDAOBgNVBAUTBzMwMTQyNjcxCzAJBgNVBAYTAlVTMRMw
EQYDVQQRFAo5NTEzMS0yMDIxMRMwEQYDVQQIEwpDYWxpZm9ybmlhMREwDwYDVQQH
FAhTYW4gSm9zZTEWMBQGA1UECRQNMjIxMSBOIDFzdCBTdDEVMBMGA1UEChQMUGF5
UGFsLCBJbmMuMRQwEgYDVQQLFAtDRE4gU3VwcG9ydDEXMBUGA1UEAxQOd3d3LnBh
eXBhbC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC+rkZNmW5t
bDVLiDI4u9zQCZXQmuQ2558KsPLX0jBiAx+txvRtEIT3eRu8dMCo44L+1AqTLj1L
EiStrV9d7RzJHG8Te+LBJU5GX087LlrLwVq0gs+to2XohjO17R14mafH1foQLvsR
TiNYBpaHcXVRc4wP9Mp8j5EleRPcsPDeCAcBC2TMV2oShmIXPl25Yj1Yeypu9qYw
QQL87GRyM9XVP2ttl/PBYb84O6tBR9TCA9c7WVed4aEq1njog1093apdF/2U1uV6
7wJjxqPGLVszCIv1pQO0/vIdq79enrh4OSAraGFP5JnyqsJNS0jLaMIQP/qausVq
U48i89fJ7aTVAgMBAAGjggG2MIIBsjBnBgNVHREEYDBegg53d3cucGF5cGFsLmNv
bYISaGlzdG9yeS5wYXlwYWwuY29tggx0LnBheXBhbC5jb22CDGMucGF5cGFsLmNv
bYIOdG1zLnBheXBhbC5jb22CDHRtcy5lYmF5LmNvbTAJBgNVHRMEAjAAMA4GA1Ud
DwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwZgYDVR0g
BF8wXTBbBgtghkgBhvhFAQcXBjBMMCMGCCsGAQUFBwIBFhdodHRwczovL2Quc3lt
Y2IuY29tL2NwczAlBggrBgEFBQcCAjAZGhdodHRwczovL2Quc3ltY2IuY29tL3Jw
YTAfBgNVHSMEGDAWgBT8ilC6nrklWntVhU+VAGOP6VhrQzArBgNVHR8EJDAiMCCg
HqAchhpodHRwOi8vc2Euc3ltY2IuY29tL3NhLmNybDBXBggrBgEFBQcBAQRLMEkw
HwYIKwYBBQUHMAGGE2h0dHA6Ly9zYS5zeW1jZC5jb20wJgYIKwYBBQUHMAKGGmh0
dHA6Ly9zYS5zeW1jYi5jb20vc2EuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQB2CKtk
9vQL5IG9WbI+pPz1A3UEWWq1/hI0KgScic3L4TxsIDnU6m8nNH9iHEVyETnARaoq
NVy2BuMIp48Ir4CyEM6lKFscSVUR62sqgMEJ7YJySMoZi+U0lDxQJndrGmO6b2PR
WO0rHbenbgQlmcOUA5DsD0yTgzWG43CEDTzOr06AStORP1UzLx9nhy8JokHAEEos
xIigb5Ms7zjSYcfs8zd9yTKlXB5IDoVsRyp/xjBewvYu3eNNrP/vSCbHUXRHMkYL
zXoKXVvFje0XvN4JvOmTqXyFnIimg7zW5R8FEN+yT6LFlwCLV8cN58dXV4d9E59c
XPfzzQCJDYWaonDa
-----END CERTIFICATE-----
CERT

# added to 0.14 on 2015.04.01
push @certificates, <<'CERT';
-----BEGIN CERTIFICATE-----
MIIGvjCCBaagAwIBAgIQWK6vRldyZAffQNciCpwKZzANBgkqhkiG9w0BAQUFADB3
MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAd
BgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxKDAmBgNVBAMTH1N5bWFudGVj
IENsYXNzIDMgRVYgU1NMIENBIC0gRzIwHhcNMTUwMzEyMDAwMDAwWhcNMTUxMDMx
MjM1OTU5WjCCAQkxEzARBgsrBgEEAYI3PAIBAxMCVVMxGTAXBgsrBgEEAYI3PAIB
AhMIRGVsYXdhcmUxHTAbBgNVBA8TFFByaXZhdGUgT3JnYW5pemF0aW9uMRAwDgYD
VQQFEwczMDE0MjY3MQswCQYDVQQGEwJVUzETMBEGA1UEERQKOTUxMzEtMjAyMTET
MBEGA1UECBMKQ2FsaWZvcm5pYTERMA8GA1UEBxQIU2FuIEpvc2UxFjAUBgNVBAkU
DTIyMTEgTiAxc3QgU3QxFTATBgNVBAoUDFBheVBhbCwgSW5jLjEUMBIGA1UECxQL
Q0ROIFN1cHBvcnQxFzAVBgNVBAMUDnd3dy5wYXlwYWwuY29tMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqko1WvJvFcFF1v4GUgNuMBHrNVqFClp72D76
Waua/+BGR1RVPT09jHXoV36FQcdRo1+c1fZmR5T+LCK28gY9UxsKPYm3M6eD9dHS
SzbbqEwQHmSNUSyAzq24f6lNAyFd+/+dSVbv6Ufc87WFIlN9GrXkDTDh7DI+aihS
UVZeaiPk+imBgFlwbuFYsEhrtBDNMcxUzC+5+T5w5YXF9S2WEkxQqhygZ+5IJl7h
g0tuoM8GE9+7rKckYor30ha4m40RCp7jDQhSnEsejGznblDNUBoOo0XaINI+5LHG
fZonCVvo5XaerZHiABl+eABYXMN2i2xRVQ2RG++hZvxZF+ZESQIDAQABo4ICsDCC
AqwwWAYDVR0RBFEwT4IMYy5wYXlwYWwuY29tgg1jNi5wYXlwYWwuY29tghJoaXN0
b3J5LnBheXBhbC5jb22CDHQucGF5cGFsLmNvbYIOd3d3LnBheXBhbC5jb20wCQYD
VR0TBAIwADAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsG
AQUFBwMCMGYGA1UdIARfMF0wWwYLYIZIAYb4RQEHFwYwTDAjBggrBgEFBQcCARYX
aHR0cHM6Ly9kLnN5bWNiLmNvbS9jcHMwJQYIKwYBBQUHAgIwGRoXaHR0cHM6Ly9k
LnN5bWNiLmNvbS9ycGEwHwYDVR0jBBgwFoAUS/ot5O4zMuLfDQGhhtOgOzq5rK4w
KwYDVR0fBCQwIjAgoB6gHIYaaHR0cDovL3N0LnN5bWNiLmNvbS9zdC5jcmwwVwYI
KwYBBQUHAQEESzBJMB8GCCsGAQUFBzABhhNodHRwOi8vc3Quc3ltY2QuY29tMCYG
CCsGAQUFBzAChhpodHRwOi8vc3Quc3ltY2IuY29tL3N0LmNydDCCAQUGCisGAQQB
1nkCBAIEgfYEgfMA8QB2AKS5CZC0GFgUh7sTosxncAo8NZgE+RvfuON3zQ7IDdwQ
AAABTBAIx7wAAAQDAEcwRQIgUYscJgszMFrBx1zbtdYs7DsNnDyeiq570NWMnm0/
2R0CIQCe+byVBqzuGe1SvVzZg2sDM/juENHN6afDVITPPlOwfgB3AFYUBpov18Ls
0/XhvUSyPsdGdrm8mRFcwO+UmFXWidDdAAABTBAIyawAAAQDAEgwRgIhANRNmPtV
ATw4FYVuGXESDyBU6d07gkcUsEUeVY0dD95WAiEAqBns/Pr3MX8RD1bLGriQduHO
tJ1FJKvWpvaSEbb6VRUwDQYJKoZIhvcNAQEFBQADggEBAJj9TEgvOyp7fqaAIUK5
bWkRbGCsSbUxNW4yxZxNjXwIvoI89IQwGydZkqRX7//fiKEW7iMFWN6nQXxrHKfQ
46DQdN8WgnLf2CqJZN3kwQrJdhsV+DJrplMJXN96QFrRXgM/BCC4e2h2dryJYsDE
2JKKUuU6s2DhZMJ/qnyrrFTnmTQeYwIwWdcC6txdZl3VZv+EbCZEHQDUpFvdQVmR
kasn+9reKda5JGTuBl22OHsF+5WWHL2nYM2Fnv1sRFOWzQfQFcIVcWbl1OdUV6SQ
cQRRhHyM6jwWBsVJxP5H/1byHeXZTvDRl6EaU5RRCoFZEaqWPD24X+8SRkkgkV9Y
n64=
-----END CERTIFICATE-----
CERT

push @certificates, <<'CERT';
-----BEGIN CERTIFICATE-----
MIIG0jCCBbqgAwIBAgIQB2T3ui0CFx+cSA3+e2W7bzANBgkqhkiG9w0BAQUFADB3
MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAd
BgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxKDAmBgNVBAMTH1N5bWFudGVj
IENsYXNzIDMgRVYgU1NMIENBIC0gRzIwHhcNMTUwNDIyMDAwMDAwWhcNMTUxMDMx
MjM1OTU5WjCCAQkxEzARBgsrBgEEAYI3PAIBAxMCVVMxGTAXBgsrBgEEAYI3PAIB
AhMIRGVsYXdhcmUxHTAbBgNVBA8TFFByaXZhdGUgT3JnYW5pemF0aW9uMRAwDgYD
VQQFEwczMDE0MjY3MQswCQYDVQQGEwJVUzETMBEGA1UEERQKOTUxMzEtMjAyMTET
MBEGA1UECBMKQ2FsaWZvcm5pYTERMA8GA1UEBxQIU2FuIEpvc2UxFjAUBgNVBAkU
DTIyMTEgTiAxc3QgU3QxFTATBgNVBAoUDFBheVBhbCwgSW5jLjEUMBIGA1UECxQL
Q0ROIFN1cHBvcnQxFzAVBgNVBAMUDnd3dy5wYXlwYWwuY29tMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwPisQKaRu+4RFWHn4T5QUeeoQ0H5U6KXTdXp
EfjvdCDhAJQjDA4qwHw514zBcgrVIV/c22yUsr+RBnBYZ/rdlCiZGPT0kVYal9ts
XJyBFfvS3q2XMAzBg5I171geP7G46VbMBXfVkAoH1zND7O7AcNjb7z44oJgELvym
almQzTrfmN7RPjosfGJrQzCnMATT0Up94yIt1Imv5yCavWrIY1ImcuSjUMxTHaRy
D3jtnp2aBC+jhfoZYJ8a2uM6+j5h0gYpaEsLq5ilFWpvsHoKa1ZQit2/p/yE9+6U
oCAuJHYJRicHMNv3EdZMt7xVi5MKFCX7H+ZOmHHuZidDeL0gUQIDAQABo4ICxDCC
AsAwbgYDVR0RBGcwZYIMYy5wYXlwYWwuY29tgg1jNi5wYXlwYWwuY29tghRkZXZl
bG9wZXIucGF5cGFsLmNvbYISaGlzdG9yeS5wYXlwYWwuY29tggx0LnBheXBhbC5j
b22CDnd3dy5wYXlwYWwuY29tMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgWgMB0G
A1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjBmBgNVHSAEXzBdMFsGC2CGSAGG
+EUBBxcGMEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3BzMCUG
CCsGAQUFBwICMBkaF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMB8GA1UdIwQYMBaA
FEv6LeTuMzLi3w0BoYbToDs6uayuMCsGA1UdHwQkMCIwIKAeoByGGmh0dHA6Ly9z
dC5zeW1jYi5jb20vc3QuY3JsMFcGCCsGAQUFBwEBBEswSTAfBggrBgEFBQcwAYYT
aHR0cDovL3N0LnN5bWNkLmNvbTAmBggrBgEFBQcwAoYaaHR0cDovL3N0LnN5bWNi
LmNvbS9zdC5jcnQwggEDBgorBgEEAdZ5AgQCBIH0BIHxAO8AdgCkuQmQtBhYFIe7
E6LMZ3AKPDWYBPkb37jjd80OyA3cEAAAAUzjP5slAAAEAwBHMEUCIFvjUjcbhLRI
0c2PUzTVMSItRsGRsoZqdz433/3MnXilAiEA3paAILaCCR6OSp/H7js1R4IxsdCx
Y/d9UhzFxUFevxoAdQBWFAaaL9fC7NP14b1Esj7HRna5vJkRXMDvlJhV1onQ3QAA
AUzjP5waAAAEAwBGMEQCICcbFi1Lzw4R+ptZUnTBHJGRSTUUjptEljDAVNZmI7Xi
AiAM/Gly9qoF18kqaPIRZIibSoh+JnYYFuTpec2vNi12XzANBgkqhkiG9w0BAQUF
AAOCAQEAoUACGhsYuAMEt+420Y+q97KpGBGfRDw+5mJFuER1e3p69KAsFZRBufJb
BjJCbY3yWgqnNTvF+klDvok499g8I51+3fo/wdROX+fyeor+0W8Nv7Q/tNQ3J5gZ
CaoNT4yYOdT2wyswOzHLaQJhNNcTlbxy0lEh3f3S04MnhpB4jVCakRvORlU0FD2R
G4oHGhNJqthJc54f5yvlvhXi5ac9hHd8n+G86dS6QI/QWvkg2EXm0/6huSLP2Bvt
z6CSbS+tefVGVei0hvFvlM/ZVkaWGyJvQXli9MnQd1Fh+CkhGgOJSaGJ2/PM47zz
Gp3OLqh4jMEbNLobkIdLkZ2F9jYMDw==
-----END CERTIFICATE-----
CERT

# added to 0.17 on 2015.10.02
push @certificates, <<'CERT';
-----BEGIN CERTIFICATE-----
MIIHTTCCBjWgAwIBAgIQf8Ays2+fnhrB7auXE2UpNTANBgkqhkiG9w0BAQsFADB3
MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAd
BgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxKDAmBgNVBAMTH1N5bWFudGVj
IENsYXNzIDMgRVYgU1NMIENBIC0gRzMwHhcNMTUwOTAyMDAwMDAwWhcNMTcxMDMw
MjM1OTU5WjCCAQkxEzARBgsrBgEEAYI3PAIBAxMCVVMxGTAXBgsrBgEEAYI3PAIB
AgwIRGVsYXdhcmUxHTAbBgNVBA8TFFByaXZhdGUgT3JnYW5pemF0aW9uMRAwDgYD
VQQFEwczMDE0MjY3MQswCQYDVQQGEwJVUzETMBEGA1UEEQwKOTUxMzEtMjAyMTET
MBEGA1UECAwKQ2FsaWZvcm5pYTERMA8GA1UEBwwIU2FuIEpvc2UxFjAUBgNVBAkM
DTIyMTEgTiAxc3QgU3QxFTATBgNVBAoMDFBheVBhbCwgSW5jLjEUMBIGA1UECwwL
Q0ROIFN1cHBvcnQxFzAVBgNVBAMMDnd3dy5wYXlwYWwuY29tMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3G8cYNqcMviCcnf9UYBZa9vFajZNbopJg951
H5DLtlO5PEK5HLVTr1CIjeiof6amHw0h1FxvDDN+OhlY2V0B0wji0llUqcerTcb/
BaYLv7YREjTq1yPOPmAhvv7N22Ucr2KWPnO9CAVu6jMe1VnCcaXlIs7QF6XSrHzc
6ui6cBaL5ZBsfKC0eXNQXiaIo1/4R2NzUmIfxuLq9fYhQF3yGfJzBSU572/PoITp
pO9XrGwlzXx81DQkIAfdDQlFvZip7oPV8osFoik3DPRiF8InV53jA+OrAp36yf+B
FqsqlJs+BLd4L+l9djsihbZFn0JVNirLSQrA+7gPW4XRhyYb6QIDAQABo4IDPzCC
AzswbgYDVR0RBGcwZYIMYy5wYXlwYWwuY29tgg1jNi5wYXlwYWwuY29tghRkZXZl
bG9wZXIucGF5cGFsLmNvbYISaGlzdG9yeS5wYXlwYWwuY29tggx0LnBheXBhbC5j
b22CDnd3dy5wYXlwYWwuY29tMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgWgMB0G
A1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjBmBgNVHSAEXzBdMFsGC2CGSAGG
+EUBBxcGMEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3BzMCUG
CCsGAQUFBwICMBkaF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMB8GA1UdIwQYMBaA
FAFZq+fdOgtZpmRj1s8gB1fVkedqMCsGA1UdHwQkMCIwIKAeoByGGmh0dHA6Ly9z
ci5zeW1jYi5jb20vc3IuY3JsMFcGCCsGAQUFBwEBBEswSTAfBggrBgEFBQcwAYYT
aHR0cDovL3NyLnN5bWNkLmNvbTAmBggrBgEFBQcwAoYaaHR0cDovL3NyLnN5bWNi
LmNvbS9zci5jcnQwggF+BgorBgEEAdZ5AgQCBIIBbgSCAWoBaAB2AKS5CZC0GFgU
h7sTosxncAo8NZgE+RvfuON3zQ7IDdwQAAABT5BxKnwAAAQDAEcwRQIhALSBH+ef
tqIGyQuTuyGHJ2UFAS1mQGQUHxNt8UuakU9TAiA3Fw34Zr39bP5VYi3NvHkLCj+B
kc7VhicRoRhiV1TrjwB2AFYUBpov18Ls0/XhvUSyPsdGdrm8mRFcwO+UmFXWidDd
AAABT5BxKtsAAAQDAEcwRQIhAOiqWJCHdJZc+2kog+8uQNVX/1qEZWUuJ0xMkeUU
sb/4AiAPE2v5U5jJrIGgCVLdhQe31YNw32iWoU38gAPsaIhftQB2AGj2mPgfZIK+
OozuuSgdTPxxUV1nk9RE0QpnrLtPT/vEAAABT5BxKnEAAAQDAEcwRQIhALUKK1wh
kGZHnBKN1FyOmFs1SI0MuXeyNrvuDGJ/BD28AiBays0D+G2vJXUVC6SVR5oEJEnL
eRiHwSh1XUc3RQYbazANBgkqhkiG9w0BAQsFAAOCAQEAm4EBf+YSO2RRvyX/Gvks
jxHsFVvIfKF8y7k3pKqL5RWuH8wub+qg0CKXBK40uMF47mcG4o7cKEjY3Wrxruu6
uO8bG23u9Pnzky9I1wXHCElCW5ja/MZ+oKvIxfYLbBtfQ1aLkD73xyP1qMQh+oBw
jtn19UGev1qLvOrmyugKDVjcsaP9WD1M3WUcQxPpOJ9Dx3KyGe8qUuOH1GPpWjfr
3iHPxRDtcejvdKLWvB/K2lCfef8TXSja+a5ml0ATYNQDRJwmZFzobM/GLrl4modk
JdIGuJhwGjvYvVfglJ+dXEFcThb76lJ1/A3p5ieSNpPCjIBAK0To1RS/RRiNWcfI
nA==
-----END CERTIFICATE-----
CERT

# added to 0.18 on 2016.08.02
push @certificates, <<'CERT';
-----BEGIN CERTIFICATE-----
MIIHWTCCBkGgAwIBAgIQLNGVEFQ30N5KOSAFavbCfzANBgkqhkiG9w0BAQsFADB3
MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAd
BgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxKDAmBgNVBAMTH1N5bWFudGVj
IENsYXNzIDMgRVYgU1NMIENBIC0gRzMwHhcNMTYwMjAyMDAwMDAwWhcNMTcxMDMw
MjM1OTU5WjCCAQkxEzARBgsrBgEEAYI3PAIBAxMCVVMxGTAXBgsrBgEEAYI3PAIB
AgwIRGVsYXdhcmUxHTAbBgNVBA8TFFByaXZhdGUgT3JnYW5pemF0aW9uMRAwDgYD
VQQFEwczMDE0MjY3MQswCQYDVQQGEwJVUzETMBEGA1UEEQwKOTUxMzEtMjAyMTET
MBEGA1UECAwKQ2FsaWZvcm5pYTERMA8GA1UEBwwIU2FuIEpvc2UxFjAUBgNVBAkM
DTIyMTEgTiAxc3QgU3QxFTATBgNVBAoMDFBheVBhbCwgSW5jLjEUMBIGA1UECwwL
Q0ROIFN1cHBvcnQxFzAVBgNVBAMMDnd3dy5wYXlwYWwuY29tMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2kPIs6YzXYPAYxRH/Wsivb9Op0MRVesgi+Rh
E+7efsbiRTSjol9+SV5RN5pKFfOnvpgbAUQUGPu6cLI5PYdFuLUG6NGxkYQGRk8R
+90ma7lNae+aFN19jfKHAtAQXXZQPeyj7XKTYmNKidkvU14V5G6fcD25BBkrlUfB
9/HnkxqEiBdAdzC8g1YioT46cPv/gQ44JfAQDYKEZAUEvTCDxQhtJLkZRh47mwJK
fm7M3+6yx/GMNu7tYrVUkGdPmhRmjbly9NSbh5SAjDDvLkC0ldGqotXuRI5+doaS
6+v1d6JT/6S2eR5tP59+XtexehUAxQFptRAWpYX4/QeEmskUkQIDAQABo4IDSzCC
A0cwfAYDVR0RBHUwc4ISaGlzdG9yeS5wYXlwYWwuY29tggx0LnBheXBhbC5jb22C
DGMucGF5cGFsLmNvbYINYzYucGF5cGFsLmNvbYIUZGV2ZWxvcGVyLnBheXBhbC5j
b22CDHAucGF5cGFsLmNvbYIOd3d3LnBheXBhbC5jb20wCQYDVR0TBAIwADAOBgNV
HQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMGYGA1Ud
IARfMF0wWwYLYIZIAYb4RQEHFwYwTDAjBggrBgEFBQcCARYXaHR0cHM6Ly9kLnN5
bWNiLmNvbS9jcHMwJQYIKwYBBQUHAgIwGRoXaHR0cHM6Ly9kLnN5bWNiLmNvbS9y
cGEwHwYDVR0jBBgwFoAUAVmr5906C1mmZGPWzyAHV9WR52owKwYDVR0fBCQwIjAg
oB6gHIYaaHR0cDovL3NyLnN5bWNiLmNvbS9zci5jcmwwVwYIKwYBBQUHAQEESzBJ
MB8GCCsGAQUFBzABhhNodHRwOi8vc3Iuc3ltY2QuY29tMCYGCCsGAQUFBzAChhpo
dHRwOi8vc3Iuc3ltY2IuY29tL3NyLmNydDCCAXwGCisGAQQB1nkCBAIEggFsBIIB
aAFmAHYA3esdK3oNT6Ygi4GtgWhwfi6OnQHVXIiNPRHEzbbsvswAAAFSpFZ5PQAA
BAMARzBFAiB6j3nYN/CojD81wKOoDOhcUiK0EU32KilH3synHO5XEwIhAM2eM8Ws
vGK6rfGe8nJ4fGs9QMmXI3bTnRxcdWSeCem7AHUApLkJkLQYWBSHuxOizGdwCjw1
mAT5G9+443fNDsgN3BAAAAFSpFZ5bgAABAMARjBEAiApYKfEn4BLd4uZERNZ9/4e
w3NlCcoN9KcCVKesPx7OKwIgEyKaNe98YBdY9b4nw+KcJRzjZZIFJVIu7R53cfO1
wv4AdQBo9pj4H2SCvjqM7rkoHUz8cVFdZ5PURNEKZ6y7T0/7xAAAAVKkVnlXAAAE
AwBGMEQCIHQpjXQ06MfOV9DjzEnQm2CLPnui8P/lLyZrM6sEZvCNAiAziNOuyunX
wsaILVE7FMjg96sY02A0dsW/mGVPps7lJDANBgkqhkiG9w0BAQsFAAOCAQEAS6lk
IMx3CzCraVDTf97cfOL7k4T9eKcG6BQDmcDkSu/DXRUqgaG5/9w6r82A8HyPjh1X
BWlw0Zr6JZ87V8IxdYV/UQWKQLRnnEp9yaRT/4f/fbS9ObsQH3YmMbLDs2I2zAIB
ZdZuwaOv/PAR29XusH8fY//HNR2I2wTXGg8Ztpad6KT9gIqFfHvfSZ8VDSU9IdjN
fDlUABWAm1B+nDxoZWlyvHHmmOgw6m4wm5ANFul1hjAWeaR/TlWd20lj7iXUt+dW
GN/QMQ3a55rjwNQnA3s2WWuHGPaE/jMG17iiL2O/hUdIvLE9+wA+fWrey5//74xl
NeQitYiySDIepHGnng==
-----END CERTIFICATE-----
CERT

# added to 0.19 on 2020.03.07
push @certificates, <<'CERT';
-----BEGIN CERTIFICATE-----
MIIHmTCCBoGgAwIBAgIQDsNOdwJXAE+tzPSi9RnWDDANBgkqhkiG9w0BAQsFADB1
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMTQwMgYDVQQDEytEaWdpQ2VydCBTSEEyIEV4dGVuZGVk
IFZhbGlkYXRpb24gU2VydmVyIENBMB4XDTIwMDEwOTAwMDAwMFoXDTIyMDExMjEy
MDAwMFowgdwxHTAbBgNVBA8MFFByaXZhdGUgT3JnYW5pemF0aW9uMRMwEQYLKwYB
BAGCNzwCAQMTAlVTMRkwFwYLKwYBBAGCNzwCAQITCERlbGF3YXJlMRAwDgYDVQQF
EwczMDE0MjY3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTERMA8G
A1UEBxMIU2FuIEpvc2UxFTATBgNVBAoTDFBheVBhbCwgSW5jLjEUMBIGA1UECxML
Q0ROIFN1cHBvcnQxFzAVBgNVBAMTDnd3dy5wYXlwYWwuY29tMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAq5rER+ZPS/B6KW+aHWtO1QQOsgLtjdGprtXa
IIx+ikkaPAkT93LuLkDgKUECeJdV+AYNeyrj4LPlZPLeuLg14cV86xLjaEd0bLwE
JTMJFyjgyTqyTmVQ0ErkO7LhLoJFy1IFO6S3N+vIKfxDZ8xmqeWfIhsb94Y2NZtF
9Q9sPR0VVV3+yn1c7x12t/BZhYkaydK/WLwmnBF1YMtZ5nQY7g4GvFShR/n1tcC+
rW3u3Zm2UO2FM/W9k0tmqQjwZ8e9QiTCO+N/8eJRYrVRriGoJNnJ7dO0YBdqDHhp
wZatYh0YEabq9IPrLa6wvi5Wnc+dLHBa37IeOsfkI+M7WOH9nQIDAQABo4IDuzCC
A7cwHwYDVR0jBBgwFoAUPdNQpdagre7zSmAKZdMh1Pj41g8wHQYDVR0OBBYEFPAe
9ePuM1NpVGonQODOhLZpaEueMGcGA1UdEQRgMF6CDnd3dy5wYXlwYWwuY29tghBs
b2dpbi5wYXlwYWwuY29tghJoaXN0b3J5LnBheXBhbC5jb22CFXd3dy5wYXlwYWxv
YmplY3RzLmNvbYIPcGljcy5wYXlwYWwuY29tMA4GA1UdDwEB/wQEAwIFoDAdBgNV
HSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwdQYDVR0fBG4wbDA0oDKgMIYuaHR0
cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItZXYtc2VydmVyLWcyLmNybDA0oDKg
MIYuaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItZXYtc2VydmVyLWcyLmNy
bDBLBgNVHSAERDBCMDcGCWCGSAGG/WwCATAqMCgGCCsGAQUFBwIBFhxodHRwczov
L3d3dy5kaWdpY2VydC5jb20vQ1BTMAcGBWeBDAEBMIGIBggrBgEFBQcBAQR8MHow
JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBSBggrBgEFBQcw
AoZGaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkV4dGVu
ZGVkVmFsaWRhdGlvblNlcnZlckNBLmNydDAMBgNVHRMBAf8EAjAAMIIBfgYKKwYB
BAHWeQIEAgSCAW4EggFqAWgAdwCkuQmQtBhYFIe7E6LMZ3AKPDWYBPkb37jjd80O
yA3cEAAAAW+Hv9N9AAAEAwBIMEYCIQD22HBv3vOh3xDflHjmJ5ipfGDRwgl9Od4Y
5kvUeff7AAIhAKW5E/P2aatw3NDzrR/v+k9XDjgAbEioeJmcjDKUlyEkAHYAVhQG
mi/XwuzT9eG9RLI+x0Z2ubyZEVzA75SYVdaJ0N0AAAFvh7/UXwAABAMARzBFAiEA
/5GV9keLQVjAvRlzi5+YoFzymiQiKvJkD0i33kAijdwCIEuaqfF5owFlEMq8/CT1
Cp2aGgUQ8C4M78yprySEEymgAHUA7ku9t3XOYLrhQmkfq+GeZqMPfl+wctiDAMR7
iXqo/csAAAFvh7/TxQAABAMARjBEAiAI/pmrL76VNgjgI/f6De5QokYAUdP0inWM
dGICpFNcigIgE4pM5uLHDTg560kp1CNDTPpLAYzS28t/OUyEFOSk3SQwDQYJKoZI
hvcNAQELBQADggEBAJUGjFwcOaoZMwxwWH+UK6RxvvcTTiNz8Kh8NRYO4r5ZVj2M
XfqM+93ejjSjarOGWylSSl/3yx8zuMhgOzBylPxh312AL/mPrfOFmCro7WwC4T7Q
zO9oNk6uUW3KLnuuo3k9J2d0FU3PyR2h+UNpzmay6+zEMUgn2S3i6/RyCnMj0Zxd
jjSylaOoCRbOL7/R+Ee9wW02fjqcWMFHQJKOtjKXiV77RsM9LAZGI4YqbNI6GD46
K/zDOsAXakwy9dKoqaNfKlPJv4ifD8Z0Y32DF0lgctLLybgCWPfZ8Dz+H03760Og
+lieGRy3bEXsDLkNSgm+dmg1SGJcgjyA5Od7Zvc=
-----END CERTIFICATE-----
CERT

# NEXT @certificates comes here
# added to 0.17 on 2015.10.02
# push @certificates, <<'CERT';
# CERT

chomp(@certificates);

my @cert_contents;
push @cert_contents, <<'CERTCONTENT';
Subject Name: /1.3.6.1.4.1.311.60.2.1.3=US/1.3.6.1.4.1.311.60.2.1.2=Delaware/businessCategory=Private Organization/serialNumber=3014267/C=US/postalCode=95131-2021/ST=California/L=San Jose/street=2211 N 1st St/O=PayPal, Inc./OU=CDN Support/CN=www.paypal.com
Issuer  Name: /C=US/O=VeriSign, Inc./OU=VeriSign Trust Network/OU=Terms of use at https://www.verisign.com/rpa (c)06/CN=VeriSign Class 3 Extended Validation SSL CA
CERTCONTENT

push @cert_contents, <<'CERTCONTENT';
Subject Name: /1.3.6.1.4.1.311.60.2.1.3=US/1.3.6.1.4.1.311.60.2.1.2=Delaware/businessCategory=Private Organization/serialNumber=3014267/C=US/postalCode=95131-2021/ST=California/L=San Jose/street=2211 N 1st St/O=PayPal, Inc./OU=CDN Support/CN=www.paypal.com
Issuer  Name: /C=US/O=Symantec Corporation/OU=Symantec Trust Network/CN=Symantec Class 3 EV SSL CA - G2
CERTCONTENT

# added to 0.17 on 2015.10.02
push @cert_contents, <<'CERTCONTENT';
Subject Name: /1.3.6.1.4.1.311.60.2.1.3=US/1.3.6.1.4.1.311.60.2.1.2=Delaware/businessCategory=Private Organization/serialNumber=3014267/C=US/postalCode=95131-2021/ST=California/L=San Jose/street=2211 N 1st St/O=PayPal, Inc./OU=CDN Support/CN=www.paypal.com
Issuer  Name: /C=US/O=Symantec Corporation/OU=Symantec Trust Network/CN=Symantec Class 3 EV SSL CA - G3
CERTCONTENT

# added to 0.19 on 2020.03.07
push @cert_contents, <<'CERTCONTENT';
Subject Name: /businessCategory=Private Organization/jurisdictionC=US/jurisdictionST=Delaware/serialNumber=3014267/C=US/ST=California/L=San Jose/O=PayPal, Inc./OU=CDN Support/CN=www.paypal.com
Issuer  Name: /C=US/O=DigiCert Inc/OU=www.digicert.com/CN=DigiCert SHA2 Extended Validation Server CA
CERTCONTENT

chomp(@cert_contents);

# creates new PayPal object.  Assigns an id if none is provided.
sub new {
    my $class = shift;

    my $self = {
        id => undef,
        address => 'https://www.paypal.com/cgi-bin/webscr',
        check_cert => 1,
        @_,
    };
    bless $self, $class;
    $self->{id} = md5_hex(rand()) unless $self->{id};

    return $self;
}

sub check_cert {
    my ($self, $value) = @_;
    $self->{check_cert} = $value;
    return;
}

# returns current PayPal id
sub id {
    my ($self) = @_;

    return $self->{id};
}

#creates a PayPal button
sub button {
    my $self = shift;

    my %buttonparam = (
        cmd                 => '_ext-enter',
        redirect_cmd        => '_xclick',
        button_image        => qq{<input type="image" name="submit" src="http://images.paypal.com/images/x-click-but01.gif" alt="Make payments with PayPal" />},
        business            => undef,
        item_name           => undef,
        item_number         => undef,
        image_url           => undef,
        no_shipping         => 1,
        return              => undef,
        cancel_return       => undef,
        no_note             => 1,
        undefined_quantity  => 0,
        notify_url          => undef,
        first_name          => undef,
        last_name           => undef,
        shipping            => undef,
        shipping2           => undef,
        quantity            => undef,
        amount              => undef,
        address1            => undef,
        address2            => undef,
        city                => undef,
        state               => undef,
        zip                 => undef,
        night_phone_a       => undef,
        night_phone_b       => undef,
        night_phone_c       => undef,
        day_phone_a         => undef,
        day_phone_b         => undef,
        day_phone_c         => undef,
        receiver_email      => undef,
        invoice             => undef,
        currency_code       => undef,
        custom              => $self->{id},
        @_,
    );
    my $key;
    my $form_id = '';
    if (defined $buttonparam{form_id}) {
        $form_id = qq{id="$buttonparam{form_id}"};
        delete $buttonparam{form_id};
    }
    my $content = qq{<form method="post" action="$self->{address}" enctype="multipart/form-data" $form_id>\n};

    foreach my $param (sort keys %buttonparam) {
        next if not defined $buttonparam{$param};
        next if $param eq 'button_image';
        $content .= qq{<input type="hidden" name="$param" value="$buttonparam{$param}" />\n};
    }
    $content .= "$buttonparam{button_image}\n";
    $content .= qq{</form>\n};

    return $content;
}


# takes a reference to a hash of name value pairs, such as from a CGI query
# object, which should contain all the name value pairs which have been
# posted to the script by PayPal's Instant Payment Notification
# posts that data back to PayPal, checking if the ssl certificate matches,
# and returns success or failure, and the reason.
sub ipnvalidate {
    my ($self, $query) = @_;

    $query->{cmd} = '_notify-validate';
    my $id = $self->{id};
    my ($succ, $reason) = $self->postpaypal($query);

    return (wantarray ? ($id,   $reason) : $id  ) if $succ;
    return (wantarray ? (undef, $reason) : undef);
}

# this method should not normally be used unless you need to test, or if
# you are overriding the behaviour of ipnvalidate.  It takes a reference
# to a hash containing the query, posts to PayPal with the data, and returns
# success or failure, as well as PayPal's response.
sub postpaypal {
    my ($self, $query) = @_;

    my $address = $self->{address};
    my ($site, $port, $path);

    #following code splits an url into site, port and path components
    my @address = split /:\/\//, $address, 2;
    @address = split /(?=\/)/, $address[1], 2;
    if ($address[0] =~ /:/) {
        ($site, $port) = split /:/, $address[0];
    }
    else {
        ($site, $port) = ($address[0], '443');
    }
    $path = $address[1];
    my ($page,
        $response,
        $headers,
        $ppcert,
        ) = Net::SSLeay::post_https3($site,
                                         $port,
                                         $path,
                                         '',
                                         Net::SSLeay::make_form(%$query));

    return (wantarray ? (undef, "No PayPal cert found") : undef)
        unless $ppcert;

    my $ppx509 = Net::SSLeay::PEM_get_string_X509($ppcert);
    my $ppcertcontent =
    'Subject Name: '
        . Net::SSLeay::X509_NAME_oneline(
               Net::SSLeay::X509_get_subject_name($ppcert))
            . "\nIssuer  Name: "
                . Net::SSLeay::X509_NAME_oneline(
                       Net::SSLeay::X509_get_issuer_name($ppcert))
                    . "\n";

    chomp $ppx509;
    chomp $ppcertcontent;

    my @certs = @certificates;
    if ($Cert) {
        # TODO added in 0.12
        warn "The global variable \$Cert is deprecated and will be removed soon. Pass a certificate to the constructor using the 'cert' parameter.\n";
        push @certs, $Cert;
    }
    my @cert_cont = @cert_contents;
    if ($Certcontent) {
        # TODO added in 0.12
        warn "The global variable \$Certcontent is deprecated and will be removed soon. Pass a certificate to the constructor using the 'certcontent' parameter.\n";
        push @cert_cont, $Certcontent;
    }

    if ($self->{addcert}) {
        push @certs, $self->{cert};
    }
    if ($self->{addcertcontent}) {
        push @cert_cont, $self->{certcontent};
    }

    if ($self->{cert}) {
        @certs = $self->{cert};
    }
    if ($self->{certcontent}) {
        @cert_cont = $self->{certcontent};
    }

    if ($self->{check_cert}) {
        return (wantarray ? (undef, "PayPal cert failed to match:\n$ppx509") : undef)
            unless grep {$_ eq $ppx509} @certs;
        return (wantarray ? (undef, "PayPal cert contents failed to match:\n$ppcertcontent") : undef)
        unless grep { $_ eq $ppcertcontent } @cert_cont;
    }
    return (wantarray ? (undef, 'PayPal says transaction INVALID') : undef)
        if $page eq 'INVALID';
    return (wantarray ? (1, 'PayPal says transaction VERIFIED') : 1)
        if $page eq 'VERIFIED';
    warn "Bad stuff happened\n$page";
    return (wantarray ? (undef, "Bad stuff happened") :undef);
}



1;

=head1 NAME

Business::PayPal - Perl extension for automating PayPal transactions

=head1 ABSTRACT

Business::PayPal makes the automation of PayPal transactions as simple
as doing credit card transactions through a regular processor.  It includes
methods for creating PayPal buttons and for validating the Instant Payment
Notification that is sent when PayPal processes a payment.

=head1 SYNOPSIS

To generate a PayPal button for use on your site
Include something like the following in your CGI

  use Business::PayPal;
  my $paypal = Business::PayPal->new;
  my $button = $paypal->button(
      business => 'dr@dursec.com',
      item_name => 'CanSecWest Registration Example',
      return => 'http://www.cansecwest.com/return.cgi',
      cancel_return => 'http://www.cansecwest.com/cancel.cgi',
      amount => '1600.00',
      quantity => 1,
      notify_url => http://www.cansecwest.com/ipn.cgi
  );
  my $id = $paypal->id;

Store $id somewhere so we can get it back again later

Store current context with $id.

Print button to the browser.

Note, button is an HTML form, already enclosed in <form></form> tags



To validate the Instant Payment Notification from PayPal for the
button used above include something like the following in your
'notify_url' CGI.

  use CGI;
  my $query = CGI->new;
  my %query = $query->Vars;
  my $id = $query{custom};
  my $paypal = Business::PayPal->new(id => $id);
  my ($txnstatus, $reason) = $paypal->ipnvalidate(\%query);
  die "PayPal failed: $reason" unless $txnstatus;
  my $money = $query{payment_gross};
  my $paystatus = $query{payment_status};

Check if paystatus eq 'Completed'.
Check if $money is the amount you expected.
Save payment status information to store as $id.


To tell the user if their payment succeeded or not, use something like
the following in the CGI pointed to by the 'return' parameter in your
PayPal button.

  use CGI;
  my $query = CGI->new;
  my $id = $query{custom};

  #get payment status from store for $id
  #return payment status to customer

In order to use the sandbox provided by PayPal, you can provide the address of the sandbox
in the constructor:

  my $pp = Business::PayPal->new( address  => 'https://www.sandbox.paypal.com/cgi-bin/webscr' );

=head1 DESCRIPTION

=head2 new()

Creates a new Business::PayPal object, it can take the
following parameters:

=over 2

=item id

The Business::PayPal object id, if not specified a new
id will be created using md5_hex(rand())

=item address

The address of PayPal's payment server, currently:
https://www.paypal.com/cgi-bin/webscr

=item cert

The x509 certificate for I<address>, see source for default.

=item certcontent

The contents of the x509 certificate I<cert>, see source for
default.

=item addcert

The x509 certificate for I<address>.
This is added to the default values.

=item addcertcontent

The contents of the x509 certificate I<cert>,
This is added to the default values.

=back

=head2 id()

Returns the id for the Business::PayPal object.

=head2 button()

Returns the HTML for a PayPal button.  It takes a large number of
parameters, which control the look and function of the button, some
of which are required and some of which have defaults.  They are
as follows:

=over 2

=item cmd

required, defaults to '_ext-enter'

This allows the user information to be pre-filled in.
You should never need to specify this, as the default should
work fine.

=item redirect_cmd

required, defaults to '_xclick'

This allows the user information to be pre-filled in.
You should never need to specify this, as the default should
work fine.

=item button_image

required, defaults to:

    CGI::image_button(-name => 'submit',
                      -src  => 'http://images.paypal.com/x-click-but01.gif'
                      -alt  => 'Make payments with PayPal',
                     )

You may wish to change this if the button is on an https page
so as to avoid the browser warnings about insecure content on a
secure page.

for example use a Bootstrap style button:

  button_image  => '<button type="button" class="btn btn-success">9 USD per month</button>',

=item form_id

  form_id => 'some_id',

Adding id="some_id" to the form created. Adding and id will make it easier to locate
the form on the page by some JavaScript code.

=item business

required, no default

This is the name of your PayPal account.

=item item_name

This is the name of the item you are selling.

=item item_number

This is a numerical id of the item you are selling.

=item image_url

A URL pointing to a 150 x 50 image which will be displayed
instead of the name of your PayPal account.

=item no_shipping

defaults to 1

If set to 1, does not ask customer for shipping info, if
set to 0 the customer will be prompted for shipping information.

=item return

This is the URL to which the customer will return to after
they have finished paying.

=item cancel_return

This is the URL to which the customer will be sent if they cancel
before paying.

=item no_note

defaults to 1

If set to 1, does not ask customer for a note with the payment,
if set to 0, the customer will be asked to include a note.

=item currency_code

Currency the payment should be taken in, e.g. EUR, GBP.
If not specified payments default to USD.

=item address1

=item undefined_quantity

defaults to 0

If set to 0 the quantity defaults to 1, if set to 1 the user
can edit the quantity.

=item notify_url

The URL to which PayPal Instant Payment Notification is sent.

=item first_name

First name of customer, used to pre-fill PayPal forms.

=item last_name

Last name of customer, used to pre-fill PayPal forms.

=item shipping

I don't know, something to do with shipping, please tell me if
you find out.

=item shipping2

I don't know, something to do with shipping, please tell me if you
find out.

=item quantity

defaults to 1

Number of items being sold.

=item amount

Price of the item being sold.

=item address1

Address of customer, used to pre-fill PayPal forms.

=item address2

Address of customer, used to pre-fill PayPal forms.

=item city

City of customer, used to pre-fill PayPal forms.

=item state

State of customer, used to pre-fill PayPal forms.

=item zip

Zip of customer, used to pre-fill PayPal forms.

=item night_phone_a

Phone

=item night_phone_b

Phone

=item night_phone_c

Phone

=item day_phone_a

Phone

=item day_phone_b

Phone

=item day_phone_c

Phone

=item receiver_email

Email address of customer - I think

=item invoice

Invoice number - I think

=item custom

defaults to the Business::PayPal id

Used by Business::PayPal to track which button is associated
with which Instant Payment Notification.

=back

=head2 ipnvalidate()

Takes a reference to a hash of name value pairs, such as from a
CGI query object, which should contain all the name value pairs
which have been posted to the script by PayPal's Instant Payment
Notification posts that data back to PayPal, checking if the ssl
certificate matches, and returns success or failure, and the
reason.

=head2 postpaypal()

This method should not normally be used unless you need to test,
or if you are overriding the behaviour of ipnvalidate.  It takes a
reference to a hash containing the query, posts to PayPal with
the data, and returns success or failure, as well as PayPal's
response.

=head1 MAINTAINER

Gabor Szabo, L<http://szabgab.com/>, L<http://perlmaven.com/>

phred, E<lt>fred@redhotpenguin.comE<gt>

=head1 AUTHOR

mock, E<lt>mock@obscurity.orgE<gt>

=head1 SEE ALSO

L<CGI>, L<perl>, L<Apache::Session>.

Explanation of the fields: L<http://www.paypalobjects.com/en_US/ebook/subscriptions/html.html>
See also in the pdf here: L<https://www.paypal.com/cgi-bin/webscr?cmd=p/xcl/rec/subscr-manual-outside>


=head1 LICENSE

Copyright (c) 2010, phred E<lt>fred@redhotpenguin.comE<gt>. All rights reserved.

Copyright (c) 2002, mock E<lt>mock@obscurity.orgE<gt>.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
