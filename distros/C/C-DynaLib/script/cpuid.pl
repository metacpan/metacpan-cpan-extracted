#!/usr/bin/perl
use C::DynaLib qw(DeclareSub PTR_TYPE);
use Config;

die "Invalid $Config{archname}. Only x86\n" 
    unless $Config{archname} =~ /[ix]\d?86|cygwin-/;

$asmblock = "\x90"      .           #  nop or int3 for debugging
    "\x55"      .                   #  push ebp
    "\x89\xE5"  .                   #  mov ebp,esp
    "\x53"      .                   #  push ebx
    "\x52"      .                   #  push edx
    "\x51"      .                   #  push ecx
    "\xB8\x00\x00\x00\x00" .        #  mov  eax,0x0
    "\x0F\xA2"      .               #  cpuid
    "\x89\x1D\x00\x00\x00\x00"  .   #  mov [$ebx],ebx   ;  save in perl string $ebx
    "\x89\x15\x00\x00\x00\x00"  .   #  mov [$edx],edx   ;  save in perl string $edx
    "\x89\x0D\x00\x00\x00\x00"  .   #  mov [$ecx],ecx   ;  save in perl string $ecx
    "\x59"      .                   #  pop ecx
    "\x5a"      .                   #  pop edx
    "\x5B"      .                   #  pop ebx
    "\x89\xec"  .                   #  mov esp,ebp
    "\x5D"      .                   #  pop ebp
    "\xc3"                          #  ret   - back to perl
    ;

$ebx = "NUL1";
$edx = "NUL2";
$ecx = "NUL3";
#  EDIT the 3 move instructions for the addresses of the last 3 perl strings
substr $asmblock, 16, 4,  pack("P",$ebx); # store $ebx address  on first  mov instruction
substr $asmblock, 22, 4,  pack("P",$edx); # store $edx address  on second mov instruction
substr $asmblock, 28, 4,  pack("P",$ecx); # store $ecx address  on third  mov instruction
  
$asmsub = DeclareSub( unpack(PTR_TYPE, pack("P", $asmblock)),"i");

$highnum  = &$asmsub( );  # call cpuid routine

print "cpu vendor: ",$ebx,$edx,$ecx,"\n";
