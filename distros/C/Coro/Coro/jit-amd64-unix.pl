#!/opt/bin/perl

{
   package Coro::State;

   use common::sense;

   my @insn;

   $insn[0][1] = "\x0f\xb6"; # movzbl mem -> rax
   $insn[0][2] = "\x0f\xb7"; # movzwl mem -> rax
   $insn[0][4] =     "\x8b"; # movl   mem -> rax
   $insn[0][8] = "\x48\x8b"; # movq   mem -> rax
   $insn[1][1] =     "\x88"; # movb    al -> mem
   $insn[1][2] = "\x66\x89"; # movw    ax -> mem
   $insn[1][4] =     "\x89"; # movl   eax -> mem
   $insn[1][8] = "\x48\x89"; # movq   rax -> mem

   my $modrm_disp8  = 0x40;
   my $modrm_disp32 = 0x80;
   my $modrm_rsi    = 0x06;
   my $modrm_rdi    = 0x07;

   my @vars;

   my $mov_ind = sub {
      my ($size, $mod_rm, $store, $offset) = @_;

      if ($offset < -128 || $offset > 127) {
         $mod_rm |= $modrm_disp32;
         $offset = pack "V", $offset;
      } elsif ($offset) {
         $mod_rm |= $modrm_disp8;
         $offset = pack "c", $offset;
      } else {
         $offset = "";
      }

      $insn[$store][$size] . (chr $mod_rm) . $offset
   };

   my $gencopy = sub {
      my ($save) = shift;

      my $curbase = undef;

      my $code;

      my $curslot = 0;

      for (@vars) {
         my ($addr, $asize, $slot, $ssize) = @$_;

         if (!defined $curbase || abs ($curbase - $addr) > 0x7ffffff) {
            $curbase = $addr + 128;
            $code .= "\x48\xbe" . pack "Q", $curbase; # mov imm64, %rsi
         }

         my $slotofs = $slot - $curslot;

         # the sort ensures that this condition and adjustment suffices
         if ($slotofs > 127) {
            my $adj = 256;
            $code .= "\x48\x81\xc7" . pack "i", $adj; # addq imm32, %rdi
            $curslot += $adj;
            $slotofs -= $adj;
         }

         if ($save) {
            $code .= $mov_ind->($asize, $modrm_rsi, 0, $addr - $curbase);
            $code .= $mov_ind->($ssize, $modrm_rdi, 1, $slotofs);
         } else {
            $code .= $mov_ind->($ssize, $modrm_rdi, 0, $slotofs);
            $code .= $mov_ind->($asize, $modrm_rsi, 1, $addr - $curbase);
         }
      }

      $code .= "\xc3"; # retq

      $code
   };

   sub _jit {
      @vars = @_;

      # sort all variables into 256 byte blocks, biased by -128
      # so gencopy can += 256 occasionally. within those blocks,
      # sort by address so we can play further tricks.
      @vars = sort {
         (($a->[2] + 128) & ~255) <=> (($b->[2] + 128) & ~255)
            or $a->[0] <=> $b->[0]
      } @vars;

      # we *could* combine adjacent vars, but this is not very common

      my $load = $gencopy->(0);
      my $save = $gencopy->(1);

      #open my $fh, ">dat"; syswrite $fh, $save; system "objdump -b binary -m i386 -M x86-64 -D dat";#d#
      #warn length $load;#d#
      #warn length $save;#d#

      ($load, $save)
   }
}

1
