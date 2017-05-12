#!perl -T -w

use strict;
use warnings;

use Test::More tests => (1+1+1) + (13 + 27) + (8);
use Asm::X86 qw(@instr_att is_instr_att @instr_intel is_instr_intel @instr is_instr);

cmp_ok ( $#instr_att, '>', 0, "Non-empty instruction list" );
cmp_ok ( $#instr_intel, '>', 0, "Non-empty instruction list" );
cmp_ok ( $#instr, '>', 0, "Non-empty instruction list" );

is ( is_instr ("MOV"), 1, "MOV is an instruction" );
is ( is_instr ("ADD"), 1, "ADD is an instruction" );
is ( is_instr ("MOVW"), 1, "MOVW is an instruction" );
is ( is_instr ("ADDL"), 1, "ADDL is an instruction" );
is ( is_instr ("Pxor"), 1, "Pxor is an instruction" );
is ( is_instr ("cmpxchg8b"), 1, "cmpxchg8b is an instruction" );
is ( is_instr ("fldln2"), 1, "fldln2 is an instruction" );
is ( is_instr ("cmpeqps"), 1, "cmpeqps is an instruction" );
is ( is_instr ("jge"), 1, "jge is an instruction" );
is ( is_instr ("prefetcht2"), 1, "prefetcht2 is an instruction" );
is ( is_instr ("setc"), 1, "setc is an instruction" );
is ( is_instr ("ud2"), 1, "ud2 is an instruction" );
is ( is_instr ("xorps"), 1, "xorps is an instruction" );

is ( is_instr ("aMOV"), 0, "aMOV is an instruction" );
is ( is_instr ("MOVa"), 0, "MOVa is an instruction" );
is ( is_instr ("ADDt"), 0, "ADDt is an instruction" );
is ( is_instr ("bADD"), 0, "bADD is an instruction" );
is ( is_instr ("Pxorl"), 0, "Pxorl is an instruction" );
is ( is_instr ("lPxor"), 0, "lPxor is an instruction" );
is ( is_instr ("fcmovnes"), 0, "fcmovnes is an instruction" );
is ( is_instr ("fcmovneq"), 0, "fcmovneq is an instruction" );
is ( is_instr ("kfcmovne"), 0, "kfcmovne is an instruction" );
is ( is_instr ("bcmpunordps"), 0, "bcmpunordps is an instruction" );
is ( is_instr ("cmpunordpsb"), 0, "cmpunordpsb is an instruction" );
is ( is_instr ("jnbz"), 0, "jnbz is an instruction" );
is ( is_instr ("jnzb"), 0, "jnzb is an instruction" );
is ( is_instr ("bjnz"), 0, "bjnz is an instruction" );
is ( is_instr ("cprefetchnta"), 0, "cprefetchnta is an instruction" );
is ( is_instr ("prefetchntac"), 0, "prefetchntac is an instruction" );
is ( is_instr ("setnab"), 0, "setnab is an instruction" );
is ( is_instr ("setnba"), 0, "setnba is an instruction" );
is ( is_instr ("bsetna"), 0, "bsetna is an instruction" );
is ( is_instr ("axvmwrite"), 0, "axvmwrite is an instruction" );
is ( is_instr ("vmwriteax"), 0, "vmwriteax is an instruction" );
is ( is_instr ("pxorpd"), 0, "pxorpd is an instruction" );
is ( is_instr ("xorpdp"), 0, "xorpdp is an instruction" );
is ( is_instr ("fistp"), 1, "fistp is an instruction" );
is ( is_instr ("fistps"), 1, "fistps is an instruction" );
is ( is_instr ("fstp"), 1, "fstp is an instruction" );
is ( is_instr ("fstpl"), 1, "fstpl is an instruction" );

is ( is_instr ("Por"), 1, "Por is an instruction" );
is ( is_instr ("fcmovnel"), 0, "fcmovnel is an instruction" );
is ( is_instr ("cmpunordpd"), 1, "cmpunordpd is an instruction" );
is ( is_instr ("rep"), 1, "rep is an instruction" );
is ( is_instr ("prefetchnta"), 1, "prefetchnta is an instruction" );
is ( is_instr ("setna"), 1, "setna is an instruction" );
is ( is_instr ("vmwrite"), 1, "vmwrite is an instruction" );
is ( is_instr ("xorpd"), 1, "xorpd is an instruction" );
