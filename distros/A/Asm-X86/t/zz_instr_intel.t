#!perl -T -w

use strict;
use warnings;

use Test::More tests => 1 + 10 + 22;
use Asm::X86 qw(@instr_intel is_instr_intel);

cmp_ok ( $#instr_intel, '>', 0, "Non-empty instruction list" );

is ( is_instr_intel ("MOV"), 1, "MOV is an instruction" );
is ( is_instr_intel ("ADD"), 1, "ADD is an instruction" );
is ( is_instr_intel ("Pxor"), 1, "Pxor is an instruction" );
is ( is_instr_intel ("fcmovne"), 1, "fcmovne is an instruction" );
is ( is_instr_intel ("cmpunordps"), 1, "cmpunordps is an instruction" );
is ( is_instr_intel ("jnz"), 1, "jnz is an instruction" );
is ( is_instr_intel ("prefetchnta"), 1, "prefetchnta is an instruction" );
is ( is_instr_intel ("setna"), 1, "setna is an instruction" );
is ( is_instr_intel ("vmwrite"), 1, "vmwrite is an instruction" );
is ( is_instr_intel ("xorpd"), 1, "xorpd is an instruction" );

is ( is_instr_intel ("aMOV"), 0, "aMOV is an instruction" );
is ( is_instr_intel ("MOVa"), 0, "MOVa is an instruction" );
is ( is_instr_intel ("ADDt"), 0, "ADDt is an instruction" );
is ( is_instr_intel ("bADD"), 0, "bADD is an instruction" );
is ( is_instr_intel ("Pxorl"), 0, "Pxorl is an instruction" );
is ( is_instr_intel ("lPxor"), 0, "lPxor is an instruction" );
is ( is_instr_intel ("fcmovnek"), 0, "fcmovnek is an instruction" );
is ( is_instr_intel ("kfcmovne"), 0, "kfcmovne is an instruction" );
is ( is_instr_intel ("bcmpunordps"), 0, "bcmpunordps is an instruction" );
is ( is_instr_intel ("cmpunordpsb"), 0, "cmpunordpsb is an instruction" );
is ( is_instr_intel ("jnbz"), 0, "jnbz is an instruction" );
is ( is_instr_intel ("jnzb"), 0, "jnzb is an instruction" );
is ( is_instr_intel ("bjnz"), 0, "bjnz is an instruction" );
is ( is_instr_intel ("cprefetchnta"), 0, "cprefetchnta is an instruction" );
is ( is_instr_intel ("prefetchntac"), 0, "prefetchntac is an instruction" );
is ( is_instr_intel ("setnab"), 0, "setnab is an instruction" );
is ( is_instr_intel ("setnba"), 0, "setnba is an instruction" );
is ( is_instr_intel ("bsetna"), 0, "bsetna is an instruction" );
is ( is_instr_intel ("axvmwrite"), 0, "axvmwrite is an instruction" );
is ( is_instr_intel ("vmwriteax"), 0, "vmwriteax is an instruction" );
is ( is_instr_intel ("pxorpd"), 0, "pxorpd is an instruction" );
is ( is_instr_intel ("xorpdp"), 0, "xorpdp is an instruction" );

