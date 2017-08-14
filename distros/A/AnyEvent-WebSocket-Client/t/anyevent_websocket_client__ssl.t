use lib 't/lib';
use Test2::Require::SSL;
use Test2::Plugin::EV;
use Test2::Plugin::AnyEvent::Timeout;
use Test2::V0 -no_srand => 1;
use Test2::Tools::WebSocket::Server qw( start_server );
use AnyEvent::WebSocket::Client;

my $counter;
my $max;

my $uri = start_server(
  tls => AnyEvent::TLS->new(cert => do { local $/; <DATA> }),
  handshake => sub {  # handshake
    my $opt = { @_ };
    $counter = 1;
    $max = 15;
    note "max = $max";
    note "resource = " . $opt->{handshake}->req->resource_name;
    if($opt->{handshake}->req->resource_name =~ /\/count\/(\d+)/)
    { $max = $1 }
    note "max = $max";
  },
  message => sub {  # message
    my $opt = { @_ };
    eval q{
      note "send $counter";
      $opt->{hdl}->push_write($opt->{frame}->new($counter++)->to_bytes);
      if($counter >= $max)
      {
        $opt->{hdl}->push_write($opt->{frame}->new(type => 'close')->to_bytes);
        $opt->{hdl}->push_shutdown;
      }
    };
  },
);

$uri->path('/count/10');
note $uri;

my $connection = eval { AnyEvent::WebSocket::Client->new( ssl_no_verify => 1 )->connect($uri)->recv };

if(my $error = $@)
{
  #testlib::SSL->diag_about_issue22();
  die $error;
}

isa_ok $connection, 'AnyEvent::WebSocket::Connection';

my $done = AnyEvent->condvar;

$connection->send('ping');

my $last;

$connection->on(each_message => sub {
  my $message = pop->body;
  note "recv $message";
  $connection->send('ping');
  $last = $message;
});

$connection->on(finish => sub {
  $done->send(1);
});

is $done->recv, '1', 'friendly disconnect';

is $last, 9, 'last = 9';

done_testing;

__DATA__
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA02VwAqlQzCrPenkxUjawHcXzJreJ9LDhX7Bkg3E/RB6Ilm4D
LBeilCmzkY7avp57+WCiVw2qkg+kH4Ef2sd+r10UCGPh/1diLehRAzp3Ho1bixyg
w+zkDm79OnN3uHxuKigkAxx3GGz9HhQA83U+RUns+39/OnFh0RY6/f5rV2ziA9jD
6HK3Mnsuxocd46YbVdiqlQK430CgiGj8dV44JG6+R6x3r5qXDbbRtGubC29kQOUq
kYslbpTo7ml8ShyqAP6qa8BpeSIaNG1CQQ/7JkAdxSWyFHqMQ0HR3BUiaEfUElZt
DFgXcCkKB5F8jx+wYoLzlPHHZaUvfP2nueYjcwIDAQABAoIBAQCtRDMuu0ByV5R/
Od5nGFP500mcrkrwuBnBqH56DdRhLPWe9sS62xRyhEuePoykOJo8qCvnVlg8J33K
JLfLRkBb09qbleKiuyjJn+Tm1IDWFd62gtxyOjQicG41/nZeS/6vpv79XdNvvcUp
ZhPxeGN1v0XyTWomqNAX5DSuAl5Q5HxkaRYNeuLZaPYkqmEVTgYqNSes/wRLKUb6
MaVrZ9AA/oHJMmmV4evf06s7l7ICjxAWeas7CI6UGkEz8ZFoVRJsLk5xtTsnZLgf
f24/pqHz1vApPs7CsJhK2HsLZcxMPD+hmTNI/Njl51WoH8zGhkv+p88vDzybpNSF
Hpkl+ZlBAoGBAOyfjVLD0OznJKSFksoCZKS4dlPHgXUb47Qb/XchIySQ/DNO6ff9
AA6r6doDFp51A8N1GRtGQN4LKujFPOdZ5ah7zbc2PfuOJGHku0Oby+ydgHJ19eW4
s3CIM20TuzLndFPrEGFgOrt+i5qKisti2OOZhjsDwfd48vsBm9U20lUpAoGBAOS1
Chm+vA7JevPzl+acbDSiyELaNRAXZ73CX4NIxJURjsgDeOurnBtLQEQyagZbNHcx
W4pc59Ql5KDLzu/Sne8oC3pxhaWeIPhc2d3cd/8UyGtQLtN2QnilwkjHgi3x1JGb
RPRsgAV6nwn10qUrze1XLkHsTCRI4QYD/k0uXcs7AoGBAMStJaFag2i2Ax4ArG7e
KFtFu4yNckwtv0kwTrBbScOWAxp+iDiJASgwunJsSLuylUs8JH8oGLi23ZaWgrXl
Yd918BpNqp1Rm2oG3aQndguZKm95Hscvi26Itv39/YYlHeq2omndu1OmrlDowM6m
vZIIRKr+x5Vz4brCro09QPxpAoGARJAdghBTEl/Gc2HgdOsJ6VGvlZMS+0r498NQ
nOvwuvuzgTTBSG1+9BPAJXGzpUosVVs/pSArA8eEXcwbsnvCixLHNiLYPQlFuw8i
5UcV1iul1b4I+63lSYPv1Z+x4BIydqBEsL3iN0JGcVb3mjqilndfT7YGMY6DnykN
UJgI2EcCgYAMfZHnD06XFM8ny+NsFILItpGqjCmAhkEPGwl1Zhy5Hx16CFDPDwGt
CmIbxNSLsDyiiK+i5tuSUFhV2Bw/iT539979INTIdNL1ughfhATR8MVNiOKCvZBa
uoEeE19szmG7Mj2eV2IDH0e8iaikjRFcfN89s39tNn1AjBNmEccUJA==
-----END RSA PRIVATE KEY-----
-----
-----BEGIN CERTIFICATE-----
MIIDHTCCAgWgAwIBAgIJAPASTbY2HCx0MA0GCSqGSIb3DQEBBQUAMBMxETAPBgNV
BAMTCEFueUV2ZW50MB4XDTEyMDQwNTA1NTk1MFoXDTM3MDQwNTA1NTk1MFowEzER
MA8GA1UEAxMIQW55RXZlbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQDTZXACqVDMKs96eTFSNrAdxfMmt4n0sOFfsGSDcT9EHoiWbgMsF6KUKbORjtq+
nnv5YKJXDaqSD6QfgR/ax36vXRQIY+H/V2It6FEDOncejVuLHKDD7OQObv06c3e4
fG4qKCQDHHcYbP0eFADzdT5FSez7f386cWHRFjr9/mtXbOID2MPocrcyey7Ghx3j
phtV2KqVArjfQKCIaPx1Xjgkbr5HrHevmpcNttG0a5sLb2RA5SqRiyVulOjuaXxK
HKoA/qprwGl5Iho0bUJBD/smQB3FJbIUeoxDQdHcFSJoR9QSVm0MWBdwKQoHkXyP
H7BigvOU8cdlpS98/ae55iNzAgMBAAGjdDByMB0GA1UdDgQWBBTHphJ9Il0PtIWD
DI9aueToXo9DYzBDBgNVHSMEPDA6gBTHphJ9Il0PtIWDDI9aueToXo9DY6EXpBUw
EzERMA8GA1UEAxMIQW55RXZlbnSCCQDwEk22NhwsdDAMBgNVHRMEBTADAQH/MA0G
CSqGSIb3DQEBBQUAA4IBAQA/vY+qg2xjNeOuDySW/VOsStEwcaiAm/t24z3TYoZG
2ZzyKuvFXolhXsalCahNPcyUxZqDAekODPRaq+geFaZrOn41cq/LABTKv5Theukv
H7IruIFARBo1pTPFCKMnDqESBdHvV1xTOcKGxGH5I9iMgiUrd/NnlAaloT/cCNFI
OwhEPsF9kBsZwJBGWrjjVttU2lzMzizS7vaSIWLBuEDObWbSXiU+IdG+nODOe2Dv
W7PL43yd4fz4HQvN4IaZrtwkd7XiKodRR1gWjLjW/3y5kuXL+DA/jkTjrRgiH8K7
lVjm7gvkULRV2POQqtc2DUVXLubQmmGSjmQmxSwFX65t
-----END CERTIFICATE-----

