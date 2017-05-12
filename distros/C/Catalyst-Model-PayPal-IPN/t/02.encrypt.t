#
#===============================================================================
#
#         FILE:  02.encrypt.t
#
#  DESCRIPTION:  Test Encryption with Business::PayPal::EWP
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Gavin Henry (GH), <ghenry@suretecsystems.com>
#      COMPANY:  Suretec Systems Ltd.
#      VERSION:  1.0
#      CREATED:  02/10/07 09:26:25 BST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More;                      # last test to print
eval 'use Business::PayPal::EWP';
plan $@? ( skip_all => 'Business::PayPal::EWP not installed' )  : ( tests => 1 );

TODO: {
    local $TODO="PKCS7 block seems to differ each time";

    is(
        Business::PayPal::EWP::SignAndEncrypt(
            "Testing, 123!","t/test.key","t/test.crt","t/paypal.pem"
        )
        ,join("",<DATA>)
        ,"Ran SignAndEncrypt"
    );
}

__DATA__
-----BEGIN PKCS7-----
MIIFugYJKoZIhvcNAQcEoIIFqzCCBacCAQExggE6MIIBNgIBADCBnjCBmDELMAkG
A1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExETAPBgNVBAcTCFNhbiBKb3Nl
MRUwEwYDVQQKEwxQYXlQYWwsIEluYy4xFjAUBgNVBAsUDXNhbmRib3hfY2VydHMx
FDASBgNVBAMUC3NhbmRib3hfYXBpMRwwGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwu
Y29tAgEAMA0GCSqGSIb3DQEBAQUABIGAefVM3cA5LMcppoSAY3NSOwEhp3GXf1gE
4CkBq27oMyY8U+p5QwMrNv9qvXiJcUE7hlpxFL8SrHl7zcgeyeiqO/itcts2YgmP
Fge24+Mn0iW6RmAS3ibSjbfHH/geT5y0shJ77sK44/8yasmrGFU+zxhApw8g3Nj4
L8wcbYCZCdUxCzAJBgUrDgMCGgUAMDMGCSqGSIb3DQEHATAUBggqhkiG9w0DBwQI
ySyG8KxV4XWAEAAI497mlUMn5XrnhVQDcnKgggLZMIIC1TCCAj6gAwIBAgIBADAN
BgkqhkiG9w0BAQQFADA5MRgwFgYDVQQDEw9Jc3NhYyBHb2xkc3RhbmQxHTAbBgkq
hkiG9w0BCQEWDmlzYWFjQGNwYW4ub3JnMB4XDTA0MTIwNjIwMDk0MloXDTE0MTIw
NDIwMDk0MlowOTEYMBYGA1UEAxMPSXNzYWMgR29sZHN0YW5kMR0wGwYJKoZIhvcN
AQkBFg5pc2FhY0BjcGFuLm9yZzCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA
3LYE/dY5y/svEJAraWV9T4ZsRLb2kvafUFCPqSa5I5sNsJiPoJvE7fKkn5NVjwmT
bSiip7QvxvP5uhTu0hMD0rNB3kCxphXSoOuaTx4woiN9VNSvjR8GsHeWJwOendVR
u8Md7vDe03FaoV0U54iVDm9SapFq+lhdg/YAWBx8oc8CAwEAAaOB7DCB6TAdBgNV
HQ4EFgQUCkmisNBu+RlHE03sclv7LMPsHNowYQYDVR0jBFowWIAUCkmisNBu+RlH
E03sclv7LMPsHNqhPaQ7MDkxGDAWBgNVBAMTD0lzc2FjIEdvbGRzdGFuZDEdMBsG
CSqGSIb3DQEJARYOaXNhYWNAY3Bhbi5vcmeCAQAwDwYDVR0TAQH/BAUwAwEB/zAL
BgNVHQ8EBAMCAQYwEQYJYIZIAYb4QgEBBAQDAgEGMBkGA1UdEQQSMBCBDmlzYWFj
QGNwYW4ub3JnMBkGA1UdEgQSMBCBDmlzYWFjQGNwYW4ub3JnMA0GCSqGSIb3DQEB
BAUAA4GBABa744x7/i5DLqYGwHJ659uBlr0BUa1oC5PY1N9RDlMiWo/y0+aMNS96
HxYs3NKz940ArUplbmCtVqbgzBTMwNm7OosYLXVN2hnqF8zeYVPYxp5XsjDfOYFc
4r+GySIObUZOiaHaleTyGVnVC2kWyFyM8qoelb6RUBTXyarTp+rRMYIBQzCCAT8C
AQEwPjA5MRgwFgYDVQQDEw9Jc3NhYyBHb2xkc3RhbmQxHTAbBgkqhkiG9w0BCQEW
DmlzYWFjQGNwYW4ub3JnAgEAMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJ
KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0wOTA1MDEyMTAzNTdaMCMGCSqGSIb3
DQEJBDEWBBRLD/XlFBsPzaw47r/bf85uXvjvAjANBgkqhkiG9w0BAQEFAASBgBXv
M0ik9MxoNYAJsWmPgLjyzItOYkf0jDWG+4zey7PJqr0vSD9ht+ydAXWVRG5Iyrnb
H0Dvsh9ZalUbUpRNOZ+GFMN/6FUTSM8k7f62ijDlUZj6jyZPj4wMRZsBK2k9ZoOo
1EuIdgwVjGrnFvkcrA6P/5v/3JwpxP7gSum4/J6X
-----END PKCS7-----
