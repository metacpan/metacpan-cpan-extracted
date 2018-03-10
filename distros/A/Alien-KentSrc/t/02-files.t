use strict;
use warnings;
use File::Spec::Functions qw{catfile};
use Test::More;
use Test::Alien qw{alien_ok with_subtest xs_ok};
use Alien::KentSrc;

alien_ok 'Alien::KentSrc';

my $kent_src = Alien::KentSrc->dist_dir;
my $machtype = Alien::KentSrc->machtype;

like $kent_src, qr{^/.*}, 'looks like a path';
like $machtype, qr/^\w+$/, 'valid machtype';

## these are all required for 01-compile.t except the first
my $jkweb  = catfile $kent_src, 'lib', $machtype, 'jkweb.a';
my $jkweb2 = catfile $kent_src, 'lib', $machtype, 'libjkweb.a';
my $htslib = catfile $kent_src, 'lib', $machtype, 'libhts.a';
my $bigwig = catfile $kent_src, 'inc', 'bigWig.h';
my $hts    = catfile $kent_src, 'inc', 'htslib', 'hts.h';

ok -e $jkweb,  "jkweb library exists at $jkweb";
ok -e $jkweb2, "jkweb library exists at $jkweb2";
ok -e $htslib, "htslib library exists at $htslib";
ok -e $bigwig, "header file exists at $bigwig";
ok -e $hts,    "header file exists at $hts";

done_testing;
