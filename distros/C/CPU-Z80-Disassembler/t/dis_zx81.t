#!perl

#------------------------------------------------------------------------------
# create a ZX-81 ROM control file, disassemble with it, assemble, and compare binary
#------------------------------------------------------------------------------

use strict;
use warnings;

use Test::More;
use CPU::Z80::Assembler;
use Path::Tiny;

my $addr = 0;
my $next_addr = 0;
my @ctl;

my $rom_file 	= 't/data/zx81.rom';
my $ctl_file 	= 't/data/zx81.ctl';
my $asm_file 	= 't/data/zx81.asm';
my $original_asm_file = 't/data/zx81_version_2_rom_source.asm';
my $rom_size	= -s $rom_file;

use_ok 'CPU::Z80::Disassembler';
isa_ok my $dis = CPU::Z80::Disassembler->new(), 'CPU::Z80::Disassembler';
$dis->memory->load_file($rom_file, 0);
my @in_asm = path($original_asm_file)->lines;

create_empty_ctl_file();
create_asm_file();
test_assemble();

create_ctl_file();
create_asm_file();
test_assemble();

done_testing;

#------------------------------------------------------------------------------
sub create_asm_file {
	unlink $asm_file;
	isa_ok my $dis = CPU::Z80::Disassembler->new(), 'CPU::Z80::Disassembler';
	$dis->load_control_file($ctl_file);
	$dis->write_asm($asm_file);
	ok -f $asm_file;
	my @asm_lines_1 = path($asm_file)->lines;

	unlink $asm_file;
	ok 0 == system $^X, '-Iblib/lib', 'bin/z80dis', '-c', $ctl_file;
	ok -f $asm_file;
	my @asm_lines_2 = path($asm_file)->lines;
	
	is_deeply \@asm_lines_1, \@asm_lines_2;
}

#------------------------------------------------------------------------------
sub test_assemble {
	my $rom = path($rom_file)->slurp_raw;
	my $bin = z80asm_file($asm_file);
	ok $rom eq $bin, "assembly ok";

	if ($rom ne $bin) {
		if (length($rom) != length($bin)) {
			diag "Got ", length($bin), " bytes, expected ", length($rom), " bytes";
		}
		my $length = length($rom) < length($bin) ? length($rom) : length($bin);
		for my $addr (0 .. $length) {
			my $rom_byte = ord(substr($rom, $addr, 1));
			my $bin_byte = ord(substr($bin, $addr, 1));
			if ($rom_byte != $bin_byte) {
				diag x4($addr), " got ", x2($bin_byte), ", expected ", x2($rom_byte);
			}
		}
	}
}

#------------------------------------------------------------------------------
sub create_empty_ctl_file {
	unlink $ctl_file;
	CPU::Z80::Disassembler->create_control_file($ctl_file, $rom_file, 0);
	ok -f $ctl_file;
	my @ctl_lines_1 = path($ctl_file)->lines;

	unlink $ctl_file;
	ok 0 == system $^X, '-Iblib/lib', 'bin/z80dis', '-c', $rom_file;
	ok -f $ctl_file;
	my @ctl_lines_2 = path($ctl_file)->lines;

	is_deeply \@ctl_lines_1, \@ctl_lines_2;
}

#------------------------------------------------------------------------------
sub create_ctl_file {
	unlink $ctl_file;
	CPU::Z80::Disassembler->create_control_file($ctl_file, $rom_file, 0);
	ok -f $ctl_file;
	
	# copy ctl file header
	ok open(my $fh, $ctl_file), "open $ctl_file";
	@ctl = ();
	while (<$fh>) {
		last if /^[0-9A-F]{4} [0-9A-F]{2,}/;
		push @ctl, $_;
	}
	close($fh);
	
	# copy ASM header
	$addr = 0;
	while (@in_asm && $in_asm[0] !~ /^\#/) {
		push @ctl, "\t:<".shift(@in_asm);
	}
	while (@in_asm && $in_asm[0] =~ /^\#/) {
		shift(@in_asm);
	}
	push @ctl, "\n#include zx81_sysvars.ctl\n\n";
	
	# add code
	while (@in_asm && $addr < $rom_size) {
		# read block header before code, add it after code
		my @header = read_header();
		
		# label
		my $label = read_label(@header);
		
		# code or data block
		if (@in_asm) {
			if ($in_asm[0] =~ s/^\s*DEFB\b//) {
				read_bytes(1, $label, @header);
			}
			elsif ($in_asm[0] =~ s/^\s*DEFW\b//) {
				read_bytes(2, $label, @header);
			}
			else {
				read_code($label, @header);
			}
		}
		
		# comments
		read_comments();
		
		$addr = $next_addr;
	}

	path($ctl_file)->spew(@ctl);
	ok -f $ctl_file;
}

#------------------------------------------------------------------------------
sub read_header {
	my @header;
	while (@in_asm && $in_asm[0] =~ /^\s*;|^\s*$/) {
		chomp(my $line = shift(@in_asm));
		push @header, "$line\n";
	}
	return @header;
}

#------------------------------------------------------------------------------
sub read_label {
	my(@header) = @_;
	my $label;
	if (@in_asm && $in_asm[0] =~ s/^L([0-9A-F]{4})://) {
		$addr == hex($1) or die "$addr != $in_asm[0] ";
		if (@header && $header[-1] =~ /^;;\s+(\S+)/) {
			$label = $1;
			$label =~ s/\W/_/g;
		}
	}
	return $label;
}

#------------------------------------------------------------------------------
sub read_bytes {
	my($size, $label, @header) = @_;
	@in_asm or die;
	$in_asm[0] =~ s/^([^;]+)/ / or die;
	my $args = $1;
	shift (@in_asm) if $in_asm[0] =~ /^\s*$/;

	my $num_args = scalar(split(/,/, $args));
	my $last_addr = $addr + $size * $num_args - 1;
	my $type = ($size == 1 ? "B" : "W");
	
	push @ctl, "\n", 
			x4($addr), ":$type\n",
			(map {"\t:#$_"} @header),
			x4($addr)."-".x4($last_addr)." ".
			join("", map {x2($dis->memory->peek($_))} $addr .. $last_addr).
			"\t:$type".(defined($label) ? " $label" : "").
			"\n";
	
	$next_addr = $last_addr + 1;
}

#------------------------------------------------------------------------------
sub read_code {
	my($label, @header) = @_;
	@in_asm or die;
	$in_asm[0] =~ s/^\s*([^;]+)/ / or die "no opcode in $in_asm[0] ";
	my $opcode = $1;
	shift (@in_asm) if $in_asm[0] =~ /^\s*$/;
	
	my $instr = CPU::Z80::Disassembler::Instruction->disassemble($dis->memory, $addr) 
		or die x4($addr);
	my $rom_opcode = $instr->opcode;
	for ($rom_opcode) {
		s/\s+/\\s*/g;
		s/([\(\)])/\\$1/g;
		s/(N|NN|DIS)/.*?/g;
	}
	
	$opcode =~ /$rom_opcode/i or die "at ".x4($addr).": $opcode !~ /$rom_opcode/";
	
	chomp(my $dump = $instr->dump);
	push @ctl, "\n", 
			x4($addr), ":C\n",
			(map {"\t:#$_"} @header),
			$dump."\t:C".
			(defined($label) ? " $label" : "").
			"\n";

	$next_addr = $instr->next_addr;
}

#------------------------------------------------------------------------------
sub read_comments {
	while (@in_asm && $in_asm[0] =~ s/^\s+;|^\s*$//) {
		chomp(my $line = shift(@in_asm));
		push @ctl, "\t:;$line\n";
	}
}

#------------------------------------------------------------------------------
sub x2 { sprintf('%02X', @_) }
sub x4 { sprintf('%04X', @_) }

__END__

copy_information_to_ctl($ctl_file, $original_asm_file);
create_asm_file($asm_file, $ctl_file);
test_assemble($asm_file, $rom_file);


#------------------------------------------------------------------------------
# read the control file and the original assembly file and create control
# file commands to enrich the disassembly
#------------------------------------------------------------------------------
sub copy_information_to_ctl {
	my($ctl_file, $original_asm_file) = @_;
	
	my @ctl_from = path($ctl_file)->lines;
	my @ctl_to;
	my @asm = path($original_asm_file)->lines;
	
	copy_header(\@ctl_from, \@ctl_to, \@asm);

	my $addr = 0;
	while (@asm) {
		$addr = copy_block($addr, \@ctl_from, \@ctl_to, \@asm);
	}
	
	path($ctl_file)->spew(@ctl_to, @ctl_from);
}

sub copy_header {
	my($ctl_from, $ctl_to, $asm) = @_;

	my @header;
	while (@$asm && $asm->[0] =~ /^\s*;|^\s*$/) {		# read header
		my $line = shift @$asm;
		push @header, "\t:<".$line;
	}
	
	push @header, "\n", "#include zx81_sysvars.ctl\n", "\n";
	insert_before(qr/^0000\s+[0-0A-F]+/, $ctl_from, $ctl_to, \@header);
}

sub skip_blanks {
	my($asm) = @_;
	while (@$asm && $asm->[0] =~ /^\#|^\s*$|^\s*\.end/i) {	# skip #define, blank lines and .end
		shift @$asm;
	}
}

sub copy_block {
	my($addr, $ctl_from, $ctl_to, $asm) = @_;

	skip_blanks($asm);
	return $addr unless @$asm;
	
	@$ctl_from or die "unexpected end of ctl file";
	substr($ctl_from->[0], 0, 4) eq x4($addr) 
			or die "address ",x4($addr)," different from ",$ctl_from->[0];
			
	if ($asm->[0] =~ /^;|^\s*$/) {		# block header
		my @block = (x4($addr)."\t:#\n");
		my $label;
		while (@$asm && $asm->[0] =~ /^;|^\s*$/) {
			my $line = shift @$asm;
			push @block, "\t:#$line";
			if ($line =~ /^;;\s+(\S+)/) {
				#defined $label and die "label $label already defined, found $line";
				$label = $1;
				$label =~ s/\W/_/g;
			}
		}
		
		# get address and opcode
		(@$asm && $asm->[0] =~ /^(?:L[0-9A-F]{4}:\s*|\s+)(\w+)/) or die;
		my $opcode = $1;
		
		# insert label
		if (defined $label) {
			if ($opcode eq 'DEFB') {
				push @block, "\n", x4($addr)."\t:B $label\n", "\n";
			}
			elsif ($opcode eq 'DEFW') {
				push @block, "\n", x4($addr)."\t:W $label\n", "\n";
			}
			else {
				push @block, "\n", x4($addr)."\t:C $label\n", "\n";
			}
		}
		
		push @$ctl_to, @block;
		
		return $addr;
	}
	elsif ($asm->[0] =~ /^L[0-9A-F]+:\s*|^\s+/) {		# code block
		# get opcode and first comment
		my $line = $';
		my($opcode, $comment);
		if ($line =~ /\s*;/) {
			$opcode = $`;
			chomp($comment = $');
		}
		else {
			($opcode = $line) =~ s/\s+$//;
		}
		
		# update ctl file
		if ($opcode =~ /^DEFB\s+(.*)/) {
			$addr = consume_bytes($addr, 1, $1, $ctl_from, $ctl_to, $comment);
		}
		elsif ($opcode =~ /^DEFW\s+(.*)/) {
			$addr = consume_bytes($addr, 2, $1, $ctl_from, $ctl_to, $comment);
		}
		else {
			$addr = consume_code($addr, $opcode, $ctl_from, $ctl_to, $comment);
		}
		
		# get following comments
		shift @$asm;
		while (@$asm && $asm->[0] =~ /^\s+;|^\s*$/) {			# follow-on comments
			chomp(my $comment = $');
			push @$ctl_to, " " x 32, ":;$comment\n";
			shift @$asm;		
		}
		
		return $addr;
	}
	else {
		die "cannot parse ", $asm->[0];
	}
}

sub consume_bytes {
	my($addr, $size, $def_args, $ctl_from, $ctl_to, $comment) = @_;
	my $num = scalar(split(/,/, $def_args));
	my($new_addr, $bytes_str) = get_bytes_str($addr, $num * $size, $ctl_from);
	
	push @$ctl_to, sprintf("%-31s", x4($addr).'-'.x4($new_addr-1).' '.$bytes_str)." :".
			($size == 1 ? 'B' : 'W')."\n";
	
	if (defined $comment) {
		push @$ctl_to, (" " x 32).":;$comment\n";
	}
	
	# synchronize code after bytes
	isa_ok my $dis = CPU::Z80::Disassembler->new(), 'CPU::Z80::Disassembler';
	$dis->memory->load_file($rom_file, $new_addr, $new_addr);
	$dis->write_dump($ctl_file."2");
	@$ctl_from = path($ctl_file."2")->lines;
	unlink $ctl_file."2";
	
	return $new_addr;
}

sub consume_code {
	my($addr, $opcode, $ctl_from, $ctl_to, $comment) = @_;
	
	# compare asm hash
	@$ctl_from or die;
	$ctl_from->[0] =~ /^([0-9A-F]{4})\s+([0-9A-F]+)\s+(.*)/ or die;
	hex($1) == $addr or die;
	my $size = length($2) / 2;

	my $ctl_hash = $3;
	my $opcode_hash = $opcode;
	for ($ctl_hash, $opcode_hash) {
		$_ = uc($_);
		s/\s+//g;
		s/[L\$]([0-9A-F]{4})/\$$1/g;
		s/(I[XY])\+\$0+/$1/g;
		s/(RST)\$?([0-9A-F]{2})H?/$1$2/;
		s/[L\$]([0-9A-F]+)\+\$?([0-9A-F]+)/ '$' . x4(hex($1)+hex($2)) /ge;
		s/[L\$]([0-9A-F]+)\-\$?([0-9A-F]+)/ '$' . x4(hex($1)-hex($2)) /ge;
	}
	$ctl_hash eq $opcode_hash or die "($ctl_hash,$opcode_hash)";
	
	# copy to output
	chomp(my $line = shift @$ctl_from); 
	$line = sprintf("%-31s", $line).(defined $comment ? " :;$comment" : "")."\n";
	push @$ctl_to, $line;
	
	$addr += $size;
	return $addr;
}

sub get_bytes_str {
	my($addr, $num, $ctl_from) = @_;
	my $bytes_str = '';
	my $got = 0;
	
	while ($got < $num) {
		@$ctl_from or die;
		if ($ctl_from->[0] =~ /^([0-9A-F]{4})\s+([0-9A-F]{2})([0-9A-F]*)/) {	# has one byte
			hex($1) == $addr or die;
			$ctl_from->[0] = x4($addr+1).' '.$3.'  '.$';
			$bytes_str .= $2;
			
			shift @$ctl_from if $3 eq '';		# was last byte in the line
			
			$addr++;
			$got++;
		}
		else {
			shift @$ctl_from;
		}
	}

	return ($addr, $bytes_str);
}

sub insert_before {
	my($re, $ctl_from, $ctl_to, $insert) = @_;
	
	while (@$ctl_from && $ctl_from->[0] !~ /$re/) {
		push @$ctl_to, shift @$ctl_from;
	}
	
	if (@$ctl_from) {
		push @$ctl_to, @$insert;
	}
	else {
		die;
	}
}

