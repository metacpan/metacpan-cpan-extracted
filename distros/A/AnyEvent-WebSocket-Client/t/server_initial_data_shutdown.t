use strict;
use warnings;
use utf8;
BEGIN { eval q{ use EV } }
use AnyEvent;
use AnyEvent::WebSocket::Client;
use Test::More;
use FindBin ();
use lib $FindBin::Bin;
use testlib::Server;
use testlib::SSL;

testlib::SSL->try_ssl_modules_or_skip;
testlib::Server->set_timeout;

sub test_case
{
  my (%case_args) = @_;
  subtest $case_args{label}, sub {
    my $url = testlib::Server->start_server(
      tls => $case_args{server_tls},
      handshake => sub {
        my $opt = { @_ };
        $opt->{hdl}->push_write(Protocol::WebSocket::Frame->new("initial message from server")->to_bytes);
        $opt->{hdl}->push_shutdown();
      },
      message => sub {
        fail("server should not receive a message");
      },
    );
    my $cv_finish = AnyEvent->condvar;
    my $conn = eval { AnyEvent::WebSocket::Client->new(ssl_no_verify => 1)->connect($url)->recv };
    if($@)
    {
      my $error = $@;
      if($case_args{server_tls})
      {
        testlib::SSL->diag_about_issue22;
      }
      die $error;
    }
    my @received_messages = ();
    $conn->on(each_message => sub {
      my ($conn, $message) = @_;
      push(@received_messages, $message->body);
    });
    $conn->on(finish => sub {
      $cv_finish->send;
    });
    $cv_finish->recv;
    is_deeply(
      \@received_messages, ["initial message from server"],
      "client should receive the initial message sent from the server, even if the server immediately shuts down."
    );
  };
}

test_case(label => "no ssl");
test_case(label => "with ssl", server_tls => AnyEvent::TLS->new(cert => do { local $/; <DATA> }));

done_testing;


__DATA__
-----BEGIN RSA PRIVATE KEY-----
MIIEjwIBAAKB/gCyz86uPwnt2zuYsER3FHfOY8hrNg5ddyjP2tB12T2JfvfjkX3W
ejpQknw5sqTkf7T31cU+XsiqNH4s5wgU90PvdP8qEktupikqbcqlMHpnsbkzcdkW
mM4LYFSiZa7j6H7ytIN8zZB1yDWZA1RoS64JzUil++KJQkipJUaB3eG8WvIyi4Mi
5geOtT1E4JeNipcQo2Mge1TbzC//S+Qnai0JVqK4i4sE5sqS7BzbN+2V9zsqE86R
pgzQCvKlKe1ZcuQkDDZWQUaKK1HvzfqHKmf0RgAl29XZFSUEd/hlGowtv5Xo/8n2
ATnWt3p6bjifKgSWlDHrlAG+3EMhkIjtAgMBAAECgf4AsrSRIQALklZat3zi0Af6
vKBo+w0pSiv+880CLeWRZMsqP5t2olXB1iiwUpHBzkP7vv08hdsAvWp8969mGl4M
3VKWeZuTG+Cgn7DeqD1M+DlcmJedmMHamvAJZcwt/8SqqzHRf3eKesw/FM+JGjsY
kt9BTfHxM7C1IacJUl1IVL4ZSLMvYiyI41bb3w5X4nEtnXyzOK7HRhmGWd+5Fdbi
TCds6ZWmE59k+Ur/aqRhQycVtWOkdJiRtA10/YWSdtclLEek0o91IVVroeZmH1Hf
TWinB1aytbr4qMh/LHFmbqQStZvMShZ5meLBwe59tauRfhHXaGPc6brBBnEfQQJ/
Dop1agrtkX1f0QpstamE64bhTEyEGK4YXN3a32lgCemQwBDxBcPbgDgE0l/TTZv2
5rr69sAtMguqIQa0a1/WQSQ+pzy2EuLT/uSXXINlmo+lec79fv/7niELpUkKQFAE
FP7bmk3rqa+jU40KKIXBw0D13/Rsc1lUzwcqGNjHxQJ/DEwVGlBCT7D7ajauHC/I
nD3KVLn9CN9lPBmdGStx+z+Ofi/TYsU/fshs9q5Z5mVYrD910M+n8FbYW9y9Ua0S
zUHllOZCigCm7kLfCWIUY851h8MHf5ZL22Q7oIN4vGx3QjZga6upepexOsVVq0N6
ulLLPvitMGS94MExUyCnCQJ/B1bsHTKW57EZBDL23FtMtHXIkvKsWqjFs1poeAyA
ZYB3h/sFLZvG19lu1aF4ztvCrIQE2Tf3mCM7JKB1wR0G0Kqy1UdXwACucSKBJDlO
t816ARnx6oDbSN31OuC7Q+sfpFlgD2r1YRk+n5W5Yurg+uV3Nivx8edNX5KGNTR2
4QJ/AJeZXI8I4nWPZeoEMG9MpdmD6NicCtVXNrG1EwU4k/TXk9QRxevhxuU3+hkj
UykGQCU+MzQMzlIgUSwsIcbH5QKLX8RG6AZoA4lM3FLQ0I2cs1D9B3Pha0tEY9Jw
+gHvLE0aD5VQsAqmCkJ+gaTaQCbEit/G11HCoxQqn+ouoQJ/CRgX2kYT54PJE4vO
dbaYPzetQc6ujwzvdxSv6ZjRe4oOU/r78Bq3va0JCRBisx5Iya1fT4Rmm3bIBUNm
+0mKo4bwbyOObLMPDGlFwlyu4c8w/cd4RLOMzItg7DvofunVK9cMEKa3B7kbbH7I
4wW9UpsxOv1UbvTZDFp6qKfwuA==
-----END RSA PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIDQDCCAiwCCQC6APskLJemOjANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJK
UDERMA8GA1UECAwIU2hpenVva2ExETAPBgNVBAcMCEtha2VnYXdhMQ0wCwYDVQQK
DARBY21lMQ0wCwYDVQQLDARhY21lMRIwEAYDVQQDDAl0b3NoaW9pdG8wIBcNMTYw
NzMxMDExMDIyWhgPMjI5MDA1MTYwMTEwMjJaMGUxCzAJBgNVBAYTAkpQMREwDwYD
VQQIDAhTaGl6dW9rYTERMA8GA1UEBwwIS2FrZWdhd2ExDTALBgNVBAoMBEFjbWUx
DTALBgNVBAsMBGFjbWUxEjAQBgNVBAMMCXRvc2hpb2l0bzCCAR4wDQYJKoZIhvcN
AQEBBQADggELADCCAQYCgf4Ass/Orj8J7ds7mLBEdxR3zmPIazYOXXcoz9rQddk9
iX7345F91no6UJJ8ObKk5H+099XFPl7IqjR+LOcIFPdD73T/KhJLbqYpKm3KpTB6
Z7G5M3HZFpjOC2BUomWu4+h+8rSDfM2Qdcg1mQNUaEuuCc1IpfviiUJIqSVGgd3h
vFryMouDIuYHjrU9ROCXjYqXEKNjIHtU28wv/0vkJ2otCVaiuIuLBObKkuwc2zft
lfc7KhPOkaYM0ArypSntWXLkJAw2VkFGiitR7836hypn9EYAJdvV2RUlBHf4ZRqM
Lb+V6P/J9gE51rd6em44nyoElpQx65QBvtxDIZCI7QIDAQABMA0GCSqGSIb3DQEB
CwUAA4H+AFaiRAnMe88wgahCjj4juGhpOb2ZxNkJQ72AumMx43xL650YPlrgE2Kk
KUeEoJLTJOH6LFRtpjgD4+xvAA6GbM+KyEqlqH7hQb7qot4JbYlovpc7OS0UPAnK
s8ZO8CHcu0isirtXrWq0iCbZfu3df93bO5kAvYENWKXqUvCU8ldpYpe148JteCBm
Y16aItJBGMkrD3toT0awoNwCnw5r7Gl5VXibfwVy1m8WHqpruDtR+sGCZSX1jX/v
28ih8cn/j7LqchBHuVid7iRU9h9/UDHd3P/+6PhYfO45yGZDnwpEtjglREaODkKS
CCvihjShLl0zaoSpHqTLqr9W24c=
-----END CERTIFICATE-----
