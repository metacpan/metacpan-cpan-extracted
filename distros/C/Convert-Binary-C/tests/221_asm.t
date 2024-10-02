################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN {
  plan tests => 14;
}

my $c = eval {
  Convert::Binary::C->new(
    KeywordMap => { __asm__ => 'asm', __volatile__ => 'volatile' }
  );
};
ok($@,'');

my $d = eval { Convert::Binary::C->new( DisabledKeywords => [ 'asm' ] ) };
ok($@,'');

for my $code ( do { local $/; split /-{20,}\r?\n?/, <DATA> } ) {
  my $out = $code;
  $out =~ s/^/# /mg;
  print '# ', '-'x72, "\n", $out, '# ', '-'x72, "\n";
  my @pass = map { $_ ? '' : qr/\S/ } $code =~ /\((\d+)(?:,(\d+))*\)/m;
  eval { $c->clean->parse( $code ) };
  ok($@, $pass[0]);
  eval { $d->clean->parse( $code ) };
  ok($@, $pass[1]);
}

################################################################################
# CODE SNIPPETS
################################################################################

__DATA__

/* (1,1) function-like calls aren't a problem anyway */

void main()
{
  asm("foo");
  __asm__("foo");
  asm("\n\
        global memctl\n\
memctl:\n\
        movq &75,%d0\n\
        trap &0\n\
        bcc.b noerror\n\
        jmp cerror%\n\
noerror:\n\
        movq &0,%d0\n\
        rts");
}

--------------------------------------------------

/* (1,0) this one's a lot better ;-) */

void main()
{
  __asm__ ("" : : "r" (reference));
}

--------------------------------------------------

/* (1,0) even more complex statements */

void main()
{
  __asm__ __volatile__ ("getcon cr%1, %0" : "=r" (res) : "n" (k));
  __asm__ __volatile__ ("putcon %0, cr%1" : : "r" (mm), "n" (k));
  __asm__ __volatile__ ("putcfg %0, %1, %2" : : "r" (mm), "n" (s), "r" (mw));
  __asm__ __volatile__ ("ld.b   %m0, r63" : : "o" (((char*)mm)[s]));
  __asm__ __volatile__ ("" : "+m"(x->a) : "r"(x) : "memory", "cc");
  __asm__ ("" : "=r"(tmp), "=r"(ret));
  asm volatile ("sleep");
  asm("%0"::"r"(1.5));
}

--------------------------------------------------

/* (1,0) declarators */

void main()
{
  register unsigned long long r18 asm ("r18");
  register unsigned long long r19 asm ("r19");
  register unsigned long long r0 asm ("r0") = 0;
  register unsigned long long r1 asm ("r1") = 1;
  register int r2 asm ("r2") = i >> 31;
  register int r3 asm ("r3") = j >> 31;
}

--------------------------------------------------

/* (1,0) declarators */

__asm__ ("foo");
__asm__ ("foo");
register unsigned long long r18 asm ("r18");

--------------------------------------------------

/* (1,0) from the gcc regression tests */

f(){asm("f":::"cc");}
g(x,y){asm("g"::"%r"(x), "r"(y));}

void foo (void) asm ("_bar");

void main()
{
  asm("": "+r" (v) : "r" (0), "r" (1));
  __asm__ ("mull %3" : "=a" (rp[0]), "=d" (rp[1]) : "%0" (7), "rm" (7));
  asm volatile ("" : : :
                "f0", "f1", "f2", "f3", "f4", "f5", "f6", "f7",
                "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15",
                "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23",
                "f24", "f25", "f26", "f27", "f28", "f29", "f30", "f31");

  asm volatile ("test0 X%0Y%[arg]Z" : [arg] "=g" (x));
  asm volatile ("test1 X%[out]Y%[in]Z" : [out] "=g" (y) : [in] "0"(y));
  asm volatile ("test2 X%a0Y%a[arg]Z" : : [arg] "p" (&z));
  asm volatile ("test3 %[in]" : [inout] "=g"(x) : "[inout]" (x), [in] "g" (y));
}
