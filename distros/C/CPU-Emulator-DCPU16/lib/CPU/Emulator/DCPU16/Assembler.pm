package CPU::Emulator::DCPU16::Assembler;
use strict;

=head1 NAME

CPU::Emulator::DCPU16::Assembler -  assemble DCPU-16 bytecode

=head1 SYNOPSIS
    
    # Assemble a program
    my $bytes = CPU::Emulator::DCPU16::Assembler->assemble($asm);

    # Then either run it ...
    my $cpu   = CPU::Emulator::DCPU16->new();
    $cpu->load($bytes);
    $cpu-run;
    
    # ... or disassemble it
    my $asm   = CPU::Emulator::DCPU16::Disassembler->dump($bytes);

=head1 METHODS
    
=cut

=head2 assemble <assembler>

Return bytes representing an assembled program

=cut
sub assemble {
    my $class  = shift;
    my $asm    = shift;
    my $bytes  = "";
    my %labels = ();
    my %unres  = ();
    my $idx    = 1;
    for my $line (split /\n/, $asm) {
        $class->_parse_line($line, $idx++, \$bytes, \%labels, \%unres);
    }
    $class->_resolve_references(\$bytes, \%labels, \%unres);
    return $bytes;
}


our %_EXTENDED_OPS = (JSR => 0x01);
our %_OPS          = (SET => 0x01,
                      ADD => 0x02,
                      SUB => 0x03,
                      MUL => 0x04,
                      DIV => 0x05,
                      MOD => 0x06,
                      SHL => 0x07,
                      SHR => 0x08,
                      AND => 0x09,
                      BOR => 0x0a,
                      XOR => 0x0b,
                      IFE => 0x0c, 
                      IFN => 0x0d, 
                      IFG => 0x0e, 
                      IFB => 0x0f);

sub _parse_line {
    my $class  = shift;
    my $line   = shift;
    my $idx    = shift;
    my $bytes  = shift;
    my $labels = shift;
    my $unres  = shift;
    my $off    = length($$bytes)/2;
    my $oc;

    # trim and clean the line
    $line =~ s!(^\s*|\s*$|;.*$)!!g;
    return unless length($line);

    my ($label, $op, $a, $b) = $line =~ m!
        ^
        (?::(\w+)      \s+)? # optional label
        ([A-Za-z]+)    \s+   # opcode
        ([^,\s]+) (?:, \s+   # operand
        ([^,\s]+))?    \s*   # optional second opcode
        $
    !x;
    
    die "Couldn't parse line $idx: $line\n" unless defined $op;
    
    $labels->{$label} = $off if defined $label;
    
    $op = uc $op;
    if ($oc = $_EXTENDED_OPS{$op}) {
        die "$op takes one operand at line $idx: $line\n" unless defined $a && !defined $b;
        my ($val, $next_word, $label) = _parse_operand($a);
        die "Can't parse operand '$a' at line $idx: $line\n" unless defined $val;

        $oc <<= 4;
        $oc |= $val << 10;
         
        $unres->{$off} = [$label] if defined $label;
        $$bytes .= pack("S>", $oc);
        $$bytes .= pack("S>", $next_word) if defined $next_word;

    } elsif ($oc = $_OPS{$op}) {
         die "$op takes two operands at line $idx: $line\n" unless defined $a && defined $b;
       
         my ($val_a, $next_word_a, $label_a) = _parse_operand($a);
         die "Can't parse operand '$a' at line $idx: $line\n" unless defined $val_a;
         my ($val_b, $next_word_b, $label_b) = _parse_operand($b);
         die "Can't parse operand '$b' at line $idx: $line\n" unless defined $val_b;

         $oc |= $val_a << 4;
         $oc |= $val_b << 10;
         $unres->{$off} = [$label_a, $label_b] if defined $label_a || defined $label_b;
         
         $$bytes .= pack("S>", $oc);
         $$bytes .= pack("S>", $next_word_a) if defined $next_word_a;
         $$bytes .= pack("S>", $next_word_b) if defined $next_word_b;
    } else {
        die "Unknown opcode $op at line $idx: $line\n";
    }
    
    
}

sub _parse_num {
    my $num = shift;
    $num    = oct($num) if $num =~ /^0x/i;
    $num;
}

sub _parse_operand {
    my $op   = shift;
    my $regs = "ABCXYZIJ";
    my $nums = qr/(?:0x[0-9A-F]+|[0-9]+)/i;

    if (0<=index $regs, $op) {
        return (index $regs, $op);
    } elsif ($op =~ /^\[\s*([$regs])\s*\]$/) {
        return (0x08 + index $regs, uc($1));
    } elsif ($op =~ /^\[\s*($nums)\s*\+\s*([$regs])\s*\]$/) {
        return (0x10 + index($regs, uc($2)), _parse_num($1));
    } elsif ($op eq 'POP' || $op =~ /^\[\s*SP\+\+\s*\]$/) {
        return (0x18);
    } elsif ($op eq 'PEEK' || $op =~ /^\[\s*\-\-SP\s*\]$/) {
        return (0x19);
    } elsif ($op eq 'PUSH') {
        return (0x1a);
    } elsif ($op eq 'SP') {
        return (0x1b);
    } elsif ($op eq 'PC') {
        return (0x1c);
    } elsif ($op eq 'O') {
        return (0x1d);
    } elsif ($op =~ /^\[\s*($nums)\s*\]$/) {
        return (0x1e, _parse_num($1));
    } elsif ($op =~ /^($nums)$/) {
        my $num = _parse_num($1);
        return ($num < 0x20) ? (0x20 + $num) : (0x1f, $num);
    } elsif ($op =~ /\w+/) {
        return (0x1f, 0x00, $op);
    } else {
        return ();
    }
}

sub _resolve_references {
    my $class  = shift;
    my $bytes  = shift;
    my $labels = shift;
    my $unres  = shift;
    
    foreach my $pos (reverse sort { $a <=> $b } keys %$unres) {
        my @labels = grep { defined } @{ delete $unres->{$pos} };
        next unless @labels;

        my $offset = 2;
        for my $label (@labels) {
            my $resolved = $labels->{$label};
            die "Can't resolve label $label" unless defined $resolved;
            substr($$bytes, $pos * 2 + $offset, 2, pack("S>", $resolved));
            $offset += 2;
        }
    }
}



1;