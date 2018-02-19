# make test
# perl Makefile.PL; make; perl -Iblib/lib t/31_readable.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 37;

#----------bytes_readable
my %br=(
   999              => '999 B',
   1000             => '1000 B',
   1024             => '1.00 kB',
   1153433          => '1.10 MB',
   1181116006       => '1.10 GB',
   1209462790553    => '1.10 TB',
   1088516511498    => '0.99 TB'
);
my($br,@brk)=('',sort {$a<=>$b} keys %br);
ok(($br=bytes_readable($_)) eq $br{$_}, "bytes_readable($_) == $br (should be $br{$_})") for @brk;
s/( [^B])/0$1/ for values %br;
ok(($br=bytes_readable($_,3)) eq $br{$_}, "bytes_readable($_,3) == $br (should be $br{$_})") for @brk;

#----------sec_readable
my %sr=(
   0                => '0s',
   0.0123           => '0.0123s',
  -0.0123           =>'-0.0123s',
   1.23             => '1.23s',
   1                => '1s',
   9.87             => '9.87s',
   10               => '10s',
   10.1             => '10.1s',
   59               => '59s',
   59.123           => '59.1s',
   60               => '1m 0s',
   60.1             => '1m 0s',
   121              => '2m 1s',
   131              => '2m 11s',
   1331             => '22m 11s',
  -1331             =>'-22m 11s',
   13331            => '3h 42m',
   133331           => '1d 13h',
   1333331          => '15d 10h',
   13333331         => '154d 7h',
   133333331        => '4yr 82d',
   1333333331       => '42yr 91d',
   133333333331     => '4225yr 28d',
);
my($sr,@srk)=('',sort {$a<=>$b} keys %sr);
ok(($sr=sec_readable($_)) eq $sr{$_}, "sec_readable($_) == $sr (should be $sr{$_})") for @srk;
