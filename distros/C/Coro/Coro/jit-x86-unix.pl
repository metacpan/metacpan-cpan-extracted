#!/opt/bin/perl

{
   package Coro::State;

   use common::sense;

   my @insn;

   $insn[0][1] = "\x0f\xb6"; # movzbl mem -> rax
   $insn[0][2] = "\x0f\xb7"; # movzwl mem -> rax
   $insn[0][4] =     "\x8b"; # movl   mem -> rax
   $insn[1][1] =     "\x88"; # movb    al -> mem
   $insn[1][2] = "\x66\x89"; # movw   eax -> mem
   $insn[1][4] =     "\x89"; # movl   rax -> mem

   my $modrm_abs    = 0x05;
   my $modrm_disp8  = 0x40;
   my $modrm_disp32 = 0x80;
   my $modrm_edx    = 0x02;

   my @vars;

   my $mov = sub {
      my ($size, $mod_rm, $store, $offset) = @_;

      if ($mod_rm == $modrm_abs) {
         $offset = pack "V", $offset;
      } else {
         if ($offset < -128 || $offset > 127) {
            $mod_rm |= $modrm_disp32;
            $offset = pack "V", $offset;
         } elsif ($offset) {
            $mod_rm |= $modrm_disp8;
            $offset = pack "c", $offset;
         } else {
            $offset = "";
         }
      }

      my $insn = $insn[$store][$size] . (chr $mod_rm) . $offset;

      # some instructions have shorter sequences

      $insn =~ s/^\x8b\x05/\xa1/;
      $insn =~ s/^\x88\x05/\xa2/;
      $insn =~ s/^\x66\x89\x05/\x66\xa3/;
      $insn =~ s/^\x89\x05/\xa3/;

      $insn
   };

   my $gencopy = sub {
      my ($save) = shift;

      my $code = "\x8b\x54\x24\x04"; # mov 4(%esp),%edx

      my $curslot = 0;

      for (@vars) {
         my ($addr, $asize, $slot, $ssize) = @$_;

         my $slotofs = $slot - $curslot;

         # the sort ensures that this condition and adjustment suffices
         if ($slotofs > 127) {
            my $adj = 256;
            $code .= "\x81\xc2" . pack "V", $adj; # add imm32, %edi
            $curslot += $adj;
            $slotofs -= $adj;
         }

         if ($save) {
            $code .= $mov->($asize, $modrm_abs, 0, $addr);
            $code .= $mov->($ssize, $modrm_edx, 1, $slotofs);
         } else {
            $code .= $mov->($ssize, $modrm_edx, 0, $slotofs);
            $code .= $mov->($asize, $modrm_abs, 1, $addr);
         }
      }

      $code .= "\xc3"; # retl

      $code
   };

   sub _jit {
      @vars = @_;

      # split 8-byte accesses into two 4-byte accesses
      # not needed even for 64 bit perls, but you never know
      for (@vars) {
         if ($_->[1] == 8) {
            die "Coro: FATAL - cannot handle size mismatch between 8 and $_->[3] byte slots.\n";

            $_->[1] =
            $_->[3] = 4;

            push @vars,
               [$_->[0] + 4, 4,
                $_->[1] + 4, 4];
         }
      }

      # sort by slot offset, required by gencopy to work
      @vars = sort { $a->[2] <=> $b->[2] } @vars;

      # we *could* combine adjacent vars, but this is not very common

      my $load = $gencopy->(0);
      my $save = $gencopy->(1);

      #open my $fh, ">dat"; syswrite $fh, $save; system "objdump -b binary -m i386 -D dat";
      #warn length $load;
      #warn length $save;

      ($load, $save)
   }
}

1
