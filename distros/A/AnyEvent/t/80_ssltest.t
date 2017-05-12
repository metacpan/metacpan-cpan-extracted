#!/usr/bin/perl

BEGIN { eval "use Net::SSLeay 1.33 (); 1" or ((print "1..0 # SKIP no usable Net::SSLeay\n"), exit 0) }

use Test::More tests => 415;

no warnings;
use strict qw(vars subs);

use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::TLS;

my $ctx = new AnyEvent::TLS cert_file => $0;

for my $mode (1..5) {
   ok (1, "mode $mode");

   my $server_done = AnyEvent->condvar;
   my $client_done = AnyEvent->condvar;

   my $server_port = AnyEvent->condvar;

   tcp_server "127.0.0.1", undef, sub {
      my ($fh, $host, $port) = @_;

      die unless $host eq "127.0.0.1";

      ok (1, "server_connect $mode");

      my $hd; $hd = new AnyEvent::Handle
         tls      => "accept",
         tls_ctx  => $ctx,
         fh       => $fh,
         timeout  => 8,
         on_error => sub {
            ok (0, "server_error <$_[2]>");
            $server_done->send; undef $hd;
         },
         on_eof   => sub {
            ok (1, "server_eof");
            $server_done->send; undef $hd;
         };

      if ($mode == 1) {
         $hd->push_read (line => sub {
            ok ($_[1] eq "1", "line 1 <$_[1]>");
         });
      } elsif ($mode == 2) {
         $hd->push_write ("2\n");
         $hd->on_drain (sub {
            ok (1, "server_drain");
            $server_done->send; undef $hd;
         });
      } elsif ($mode == 3) {
         $hd->push_read (line => sub {
            ok ($_[1] eq "3", "line 3 <$_[1]>");
            $hd->push_write ("4\n");
            $hd->on_drain (sub {
               ok (1, "server_drain");
               $server_done->send; undef $hd;
            });
         });
      } elsif ($mode == 4) {
         $hd->push_write ("5\n");
         $hd->push_read (line => sub {
            ok ($_[1] eq "6", "line 6 <$_[1]>");
         });
      } elsif ($mode == 5) {
         $hd->on_read (sub {
            ok (1, "on_read");
            $hd->push_read (line => sub {
               my $len = $_[1];
               ok (1, "push_read $len");
               $hd->push_read (packstring => "N", sub {
                  ok ($len == length $_[1], "block server $len");
                  $hd->push_write ("$len\n");
                  $hd->push_write (packstring => "N", $_[1]);
               });
            });
         });
      }

   }, sub {
      $server_port->send ($_[2]);
   };

   my $hd; $hd = new AnyEvent::Handle
      connect    => ["127.0.0.1", $server_port->recv],
      tls        => "connect",
      tls_ctx    => $ctx,
      timeout    => 8,
      on_connect => sub {
         ok (1, "client_connect $mode");
      },
      on_error   => sub {
         ok (0, "client_error <$_[2]>");
         $client_done->send; undef $hd;
      },
      on_eof     => sub {
         ok (1, "client_eof");
         $client_done->send; undef $hd;
      };

   if ($mode == 1) {
      $hd->push_write ("1\n");
      $hd->on_drain (sub {
         ok (1, "client_drain");
         $client_done->send; undef $hd;
      });
   } elsif ($mode == 2) {
      $hd->push_read (line => sub {
         ok ($_[1] eq "2", "line 2 <$_[1]>");
      });
   } elsif ($mode == 3) {
      $hd->push_write ("3\n");
      $hd->push_read (line => sub {
         ok ($_[1] eq "4", "line 4 <$_[1]>");
      });
   } elsif ($mode == 4) {
      $hd->push_read (line => sub {
         ok ($_[1] eq "5", "line 5 <$_[1]>");
         $hd->push_write ("6\n");
         $hd->on_drain (sub {
            ok (1, "client_drain");
            $client_done->send; undef $hd;
         });
      });
   } elsif ($mode == 5) {
      # some randomly-sized blocks
      srand 0;
      my $cnt = 64;
      my $block; $block = sub {
         my $len = (16 << int rand 14) - 16 + int rand 32;
         ok (1, "write $len");
         $hd->push_write ("$len\n");
         $hd->push_write (packstring => "N", "\x00" x $len);
      };

      for my $i (1..$cnt) {
         $hd->push_read (line => sub {
            my ($i, $cnt, $block) = ($i, $cnt, $block); # 5.8.9. bug workaround
            my $len = $_[1];
            ok (1, "client block $len/1");
            $hd->unshift_read (packstring => "N", sub {
               ok ($len == length $_[1], "client block $len/2");

               if ($i != $cnt) {
                  $block->();
               } else {
                  ok (1, "client_drain 5");
                  $client_done->send; undef $hd;
               }
            });
         });
      }

      $block->();
   }

   $server_done->recv;
   $client_done->recv;
}

__END__
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
