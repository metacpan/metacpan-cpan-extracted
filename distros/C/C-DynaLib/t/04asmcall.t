# -*- perl -*-
use Test;
###### tested on ix86 machines with cdecl (caller adjusts stack)
BEGIN {
  use Config;
  use C::DynaLib;
  if ($Config{archname} !~ /[ix]\d?86|cygwin-/) {
    print"1..0 # skip Invalid $Config{archname}. Only x86\n";
    exit 0;
  } elsif ($C::DynaLib::decl ne 'cdecl') {
    print"1..0 # skip This test only works with cdecl, have $C::DynaLib::decl\n";
    exit 0;
  } else {
    plan tests => 1;
  }
};

$asm = "\x90\xb8\x05\x00\x00\x00\xc3\x90\x90";
# 90 nop - replace with cc for debugger
# b805000000 mov eax, 5 # RETURN VALUE of 5
# c3 ret cdecl call return - caller adjust stack
# 90 90 (2)nop 2 nops for room (stdcall stack adjustment)

$asmptr = unpack(C::DynaLib::PTR_TYPE, pack("P", $asm)); # get pointer to routine
$AsmFunc = C::DynaLib::DeclareSub($asmptr , "i"); # define sub(returns int) no args
$ret = &$AsmFunc(); # call asm routine

ok($ret, 5);
