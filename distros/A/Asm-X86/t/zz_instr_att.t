#!perl -T -w

use strict;
use warnings;

use Test::More tests => 1 + 12 + 26;
use Asm::X86 qw(@instr_att is_instr_att);

cmp_ok ( $#instr_att, '>', 0, "Non-empty instruction list" );

is ( is_instr_att ("MOV"), 0, "MOV is an instruction" );
is ( is_instr_att ("ADD"), 0, "ADD is an instruction" );
is ( is_instr_att ("MOVW"), 1, "MOVW is an instruction" );
is ( is_instr_att ("ADDL"), 1, "ADDL is an instruction" );
is ( is_instr_att ("Pxor"), 1, "Pxor is an instruction" );
is ( is_instr_att ("fcmovne"), 1, "fcmovne is an instruction" );
is ( is_instr_att ("cmpunordps"), 1, "cmpunordps is an instruction" );
is ( is_instr_att ("jnz"), 1, "jnz is an instruction" );
is ( is_instr_att ("prefetchnta"), 1, "prefetchnta is an instruction" );
is ( is_instr_att ("setna"), 1, "setna is an instruction" );
is ( is_instr_att ("vmwrite"), 1, "vmwrite is an instruction" );
is ( is_instr_att ("xorpd"), 1, "xorpd is an instruction" );

is ( is_instr_att ("aMOV"), 0, "aMOV is an instruction" );
is ( is_instr_att ("MOVa"), 0, "MOVa is an instruction" );
is ( is_instr_att ("ADDt"), 0, "ADDt is an instruction" );
is ( is_instr_att ("bADD"), 0, "bADD is an instruction" );
is ( is_instr_att ("Pxorl"), 0, "Pxorl is an instruction" );
is ( is_instr_att ("lPxor"), 0, "lPxor is an instruction" );
is ( is_instr_att ("fcmovnek"), 0, "fcmovnek is an instruction" );
is ( is_instr_att ("kfcmovne"), 0, "kfcmovne is an instruction" );
is ( is_instr_att ("bcmpunordps"), 0, "bcmpunordps is an instruction" );
is ( is_instr_att ("cmpunordpsb"), 0, "cmpunordpsb is an instruction" );
is ( is_instr_att ("jnbz"), 0, "jnbz is an instruction" );
is ( is_instr_att ("jnzb"), 0, "jnzb is an instruction" );
is ( is_instr_att ("bjnz"), 0, "bjnz is an instruction" );
is ( is_instr_att ("cprefetchnta"), 0, "cprefetchnta is an instruction" );
is ( is_instr_att ("prefetchntac"), 0, "prefetchntac is an instruction" );
is ( is_instr_att ("setnab"), 0, "setnab is an instruction" );
is ( is_instr_att ("setnba"), 0, "setnba is an instruction" );
is ( is_instr_att ("bsetna"), 0, "bsetna is an instruction" );
is ( is_instr_att ("axvmwrite"), 0, "axvmwrite is an instruction" );
is ( is_instr_att ("vmwriteax"), 0, "vmwriteax is an instruction" );
is ( is_instr_att ("pxorpd"), 0, "pxorpd is an instruction" );
is ( is_instr_att ("xorpdp"), 0, "xorpdp is an instruction" );
is ( is_instr_att ("fistp"), 0, "fistp is an instruction" );
is ( is_instr_att ("fistps"), 1, "fistps is an instruction" );
is ( is_instr_att ("fstp"), 0, "fstp is an instruction" );
is ( is_instr_att ("fstpl"), 1, "fstpl is an instruction" );

