#!perl

#------------------------------------------------------------------------------
# disassemble ZX Spectrum ROM

use strict;
use warnings;

BEGIN { use lib 't/tools' }
use Parsezx48;
use TestAsm;

use Test::More;
use File::Slurp;

use CPU::Z80::Disassembler;
use CPU::Z80::Disassembler::Format;

my $CUT_OFF_ADDR = 0x2DA1;

my $rom_asm   = 't/data/zx48.asm';
my $rom_input = 't/data/zx48.rom';

my $asm_output = 'zx48.asm';
my $asm_benchmark = 't/data/zx48_benchmark.asm';

my($dis, $rom);

#------------------------------------------------------------------------------
# read data from the disassemly file
isa_ok	$rom = Parsezx48->new($rom_asm), 'Parsezx48';

#------------------------------------------------------------------------------
# disassemble 
isa_ok	$dis = CPU::Z80::Disassembler->new, 'CPU::Z80::Disassembler';
$dis->memory->load_file($rom_input);

#------------------------------------------------------------------------------
# calls 
for (0x0010, 0x0F2C, 0x15D4, 0x15E6, 0x1601, 0x162C, 0x19FB, 0x1B17, 
	 0x2D3B, 0x1833, 0x1855, 0x2DA2, 0x04C2, 0x0556, 0x0802, 0x1FC3, 
	 0x21FC, 0x1031, 0x1701, 0x175D, 0x204E, 0x20C1, 0x1DDA, 0x2DC1,
	 0x247D, 0x2D28, 0x2D4F, 0x2D2B, 0x2DE3) {
	$dis->set_call($_, 1);
}
$dis->set_call(0x0008, \&rst_08_call);
$dis->set_call(0x0028, \&rst_28_call);
$dis->set_call(0x335E, \&rst_28_call);
$dis->set_call(0x3362, \&rst_28_call);

#------------------------------------------------------------------------------
# tables
dis_unused($dis);
dis_messages($dis);
dis_offset_tables($dis);
dis_tkn_table($dis);
dis_keyboard_tbl($dis);
dis_semi_tone($dis);
dis_offst_tbl($dis);
dis_init_chan($dis);
dis_line_zero($dis);
dis_calc_tables($dis);
dis_char_set($dis);
dis_system_vars($dis);

#------------------------------------------------------------------------------
# copy disassembly points and comments from the ROM
dis_copy_code_labels($dis, $CUT_OFF_ADDR);
dis_copy_comments($dis);


#------------------------------------------------------------------------------
# assembly expressions
$dis->relative_arg(0x0341, 'E_UNSHIFT');
$dis->relative_arg(0x0347, 'EXT_SHIFT');
$dis->relative_arg(0x034F, 'SYM_CODES');
$dis->relative_arg(0x0370, 'E_DIGITS');
$dis->relative_arg(0x0389, 'CTL_CODES');
$dis->relative_arg(0x03A1, 'CTL_CODES');
$dis->relative_arg(0x078E, 'tape_msgs_2');
$dis->relative_arg(0x0A04, 'ctlchrtab');
$dis->relative_arg(0x0F95, 'ed_keys_t');
$dis->relative_arg(0x1296, 'copyright');
$dis->relative_arg(0x134A, 'comma_sp');
$dis->relative_arg(0x16F5, 'init_strm');
$dis->relative_arg(0x272F, 'tbl_priors');

$dis->instr->[0x0609]->format->{N}  = sub { '+(P_SAVE + 1) % 256' };
$dis->instr->[0x0667]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x0DAF]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x0E13]->format->{NN} = sub { $_[0] };
$dis->instr->[0x108E]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x116C]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x1314]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x1557]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x16EB]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x1860]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x1CA5]->format->{N}  = sub { '+(P_INK - 0xD8) % 256' };
$dis->instr->[0x1EA4]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x1F1A]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x2574]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x25B6]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x29E7]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x2A9C]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x2C9F]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x3000]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x30AE]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x33FB]->format->{NN} = sub { format_hex4($_[0]) };
$dis->instr->[0x3657]->format->{NN} = sub { format_hex4($_[0]) };
	
#------------------------------------------------------------------------------
# generate and test assembly
$dis->analyse;
$dis->write_asm($asm_output);
my $ok = lines_equal(scalar(read_file($asm_benchmark)), 
					 scalar(read_file($asm_output)));
ok $ok, "$asm_benchmark $asm_output : equal";
test_assembly($asm_output, $rom_input);
unlink $asm_output if ($ok && ! $ENV{DEBUG});


done_testing();


#------------------------------------------------------------------------------
# Follow code after RST 0x08
sub rst_08_call {
	my($self, $addr) = @_;
	my $error = $self->memory->peek($addr) + 1;
	$self->defb($addr);
	return ();
}

#------------------------------------------------------------------------------
# Follow code after RST 0x28
sub rst_28_call {
	my($self, $addr) = @_;
	
	my @stack = ($addr);
	my @ret;
	while (@stack) {
		$addr = pop @stack;
		my $instr = $self->instr->[$addr];
		die("Data region afer RST 28H run into code region at address ".
			format_hex4($addr)) if $instr && $self->get_type($addr) eq TYPE_CODE;
		next if $instr;
		
		my $op = $self->memory->peek($addr);
		$self->defb($addr++);
		
		if ($op == 0) {	# jump_true
			my $jump = $self->memory->peek8s($addr);
			$self->defb($addr++);
			my $target = $addr-1+$jump;
			
			$self->labels->add($target);
			push @stack, $addr, $target;
		}
		elsif ($op == 0x33) { # jump
			my $jump = $self->memory->peek8s($addr);
			$self->defb($addr++);
			
			push @stack, $addr-1+$jump;
		}
		elsif ($op == 0x34) { # stk_data
			$addr = dis_float_const($self, $addr);
			push @stack, $addr;
		}
		elsif ($op == 0x38) { # end
			push @ret, $addr;
		}
		elsif (($op & 0xE0) == 0x80) {	# series
			my $count = $op & 0x1F;
			for (1 .. $count) {
				$addr = dis_float_const($self, $addr);
			}
			push @stack, $addr;
		}
		else {
			push @stack, $addr;
		}
	}
	@ret;
}

sub dis_float_const {
	my($self, $addr, $label) = @_;
	
	$self->labels->add($addr, $label) if defined $label;
	
	my $exp = $self->memory->peek($addr);
	$self->defb($addr++);
	my $nbytes = (($exp & 0xC0) >> 6) + 1;
	$nbytes++ if ($exp & 0x3F) == 0;
	
	$self->defb($addr, $nbytes);
	$addr += $nbytes;

	return $addr;
}

#------------------------------------------------------------------------------
# copy code labels from ROM up to cut-off-address
sub dis_copy_code_labels {
	my($self, $cut_off_addr) = @_;
	
	# data labels
	$self->labels->add(0x1DE2, 'NEXT_1');
	$self->labels->add(0x1DE9, 'NEXT_2');
	$self->labels->add(0x23A3, 'DR_SIN_NZ');
	$self->labels->add(0x2758, 'L2758');
	$self->labels->add(0x2D6D, 'E_DIVSN');
	$self->labels->add(0x2D6E, 'E_FETCH');
	$self->labels->add(0x2DF2, 'PF_NEGTVE');
	$self->labels->add(0x2DF8, 'PF_POSTVE');
	$self->labels->add(0x2E25, 'L2E25');
	$self->labels->add(0x36B7, 'X_NEG');
	$self->labels->add(0x36C2, 'EXIT');
	$self->labels->add(0x371C, 'VALID');
	$self->labels->add(0x373D, 'GRE_8');
	$self->labels->add(0x37A1, 'ZPLUS');
	$self->labels->add(0x37A8, 'YNEG');
	$self->labels->add(0x37B7, 'C_ENT');
	$self->labels->add(0x37FA, 'CASES');
	$self->labels->add(0x385D, 'XIS0');
	$self->labels->add(0x386A, 'ONE');
	$self->labels->add(0x386C, 'LAST');
	
	# copy from ROM up to cut-off-address
	for my $instr (@{$rom->instr}) {
		next unless $instr;
		last if $instr->addr >= $CUT_OFF_ADDR;
		next unless defined $instr->label;
		next if $instr->is_data;
		next if $self->labels->search_addr($instr->addr);
		
		$self->code($instr->addr, $instr->label);
	}
	
	# modify code labels from default format to ROM names
	for my $instr (@{$self->instr}) {
		next unless $instr;
		my $rom_instr = $rom->instr->[$instr->addr];
		next unless $rom_instr;
		
		if (defined($rom_instr->label) && ! $rom_instr->is_data) {
			my $label = $self->labels->search_addr($rom_instr->addr);
			if (! $label || $label->name =~ /^L_[0-9A-F]{4}$/) {
				# label not defined or temporary
				$self->code($rom_instr->addr, $rom_instr->label);
			}
		}
	}
}

#------------------------------------------------------------------------------
# copy all line comments and existing code labels
sub dis_copy_comments {
	my($self) = @_;
	
	$dis->header( $rom->header );
	$dis->footer( $rom->footer );

	for my $instr (@{$rom->instr}) {
		next unless $instr;
		
		$dis->block_comment($instr->addr, $instr->block_comment);
	}

	for my $instr (@{$self->instr}) {
		next unless $instr;

		# comments
		if (! defined $instr->comment) {
			# get all comments for that range from rom
			my @comments = 
					grep { defined $_ }
					map  { $_->line_comment }
					grep { defined $_ }
					map  { $rom->instr->[$_] }
					($instr->addr .. $instr->next_addr - 1);
			if (@comments) {
				$instr->comment(join("\n", @comments));
			}
		}
	}
}

#------------------------------------------------------------------------------
# messages
sub dis_messages {
	my($self) = @_;
	
	my $addr = 0x1391;
	my $instr = $self->defb($addr, undef, 'rpt_mesgs'); $addr += $instr->size;
	for (0 .. 27) {
		$instr = $self->defm7($addr); $addr += $instr->size;
	}
	$instr = $self->defm7($addr, undef, 'comma_sp'); $addr += $instr->size;
	$instr = $self->defb($addr, undef, 'copyright'); $addr += $instr->size;
	$instr = $self->defm7($addr); $addr += $instr->size;
	
	$addr = 0x0CF8;
	$instr = $self->defb($addr, undef, 'scrl_mssg'); $addr += $instr->size;
	$instr = $self->defm7($addr); $addr += $instr->size;

	$addr = 0x09A1;
	$instr = $self->defb($addr, 1, 'tape_msgs'); $addr += $instr->size;
	$instr = $self->defm7($addr); $addr += $instr->size;
	$self->labels->add($addr, 'tape_msgs_2');
	do {
		if ($self->memory->peek($addr) == 0x0D) {
			$self->defb($addr++);
		}
		$instr = $self->defm7($addr); $addr += $instr->size;
	} while ($instr->STR ne "Bytes: ");

}

#------------------------------------------------------------------------------
# token table
sub dis_tkn_table {
	my($self) = @_;
	
	my $addr = 0x0095;
	$self->labels->add($addr, 'TKN_TABLE');
	my $instr;
	do {
		$instr = $self->defm7($addr); $addr += $instr->size;
	} while ($instr->STR ne "COPY");
}

#------------------------------------------------------------------------------
# keyboard tables
sub dis_keyboard_tbl {
	my($self) = @_;
	
	$self->labels->add(0x0205, 'MAIN_KEYS');
	$self->labels->add(0x022C, 'E_UNSHIFT');
	$self->labels->add(0x0246, 'EXT_SHIFT');
	$self->labels->add(0x0260, 'CTL_CODES');
	$self->labels->add(0x026A, 'SYM_CODES');
	$self->labels->add(0x0284, 'E_DIGITS');
	for my $addr (0x0205 .. 0x028D) {
		my $key = $self->memory->peek($addr);
		if ($key >= 0x20 && $key < 0x7F && $key != 0x60) {
			$self->defm($addr, 1);
		}
		else {
			$self->defb($addr);
		}
	}
}

#------------------------------------------------------------------------------
# semi-tone table
sub dis_semi_tone {
	my($self) = @_;
	
	$self->labels->add(0x046E, 'semi_tone');
	for (my $addr = 0x046E; $addr <= 0x04A9; $addr += 5) {
		$self->defb($addr, 5);
	}
}

#------------------------------------------------------------------------------
# Decode offset table into code functions
sub dis_code_offset_table {
	my($self, $addr, $label, @code) = @_;
	
	$self->labels->add($addr, $label);
	for my $code (@code) {
		# decode offset
		my $offset = $self->memory->peek($addr);
		my $cmd_addr = $addr + $offset;
		$self->defb($addr++)->format->{N} = sub { $code.' - $' };
		
		# decode routine
		$self->code($cmd_addr, $code);
	}
}
	
sub dis_offset_tables {
	my($self) = @_;

	# control character table
	dis_code_offset_table($self, 0x0A11, 'ctlchrtab',
				qw(	PO_COMMA PO_QUEST PO_BACK_1 PO_RIGHT PO_QUEST PO_QUEST
					PO_QUEST PO_ENTER PO_QUEST PO_QUEST PO_1_OPER PO_1_OPER
					PO_1_OPER PO_1_OPER PO_1_OPER PO_1_OPER PO_2_OPER 
					PO_2_OPER ));

	# BASIC command class table
	dis_code_offset_table($self, 0x1C01, 'class_tbl',
				qw( CLASS_00 CLASS_01 CLASS_02 CLASS_03 CLASS_04 CLASS_05 
					 EXPT_1NUM CLASS_07 EXPT_2NUM CLASS_09 EXPT_EXP CLASS_0B ));

	# Editing keys table
	dis_code_offset_table($self, 0x0FA0, 'ed_keys_t',
				qw( ED_EDIT ED_LEFT ED_RIGHT ED_DOWN ED_UP ED_DELETE
					ED_ENTER ED_SYMBOL ED_GRAPH ));
}

#------------------------------------------------------------------------------
# BASIC offset table
sub dis_offst_tbl {
	my($self) = @_;
	
	my @cmds_ptr = (qw( P_DEF_FN P_CAT P_FORMAT P_MOVE P_ERASE P_OPEN P_CLOSE
						P_MERGE P_VERIFY P_BEEP P_CIRCLE P_INK P_PAPER P_FLASH
						P_BRIGHT P_INVERSE P_OVER P_OUT P_LPRINT P_LLIST P_STOP
						P_READ P_DATA P_RESTORE P_NEW P_BORDER P_CONT P_DIM P_REM
						P_FOR P_GO_TO P_GO_SUB P_INPUT P_LOAD P_LIST P_LET P_PAUSE
						P_NEXT P_POKE P_PRINT P_PLOT P_RUN P_SAVE P_RANDOM P_IF
						P_CLS P_DRAW P_CLEAR P_RETURN P_COPY ));
	my %cmd = 		( 	'P_FORMAT' 	=> 'CAT_ETC',
						'P_MOVE'	=> 'CAT_ETC',
						'P_ERASE'	=> 'CAT_ETC',
						'P_CAT'		=> 'CAT_ETC',
						'P_RANDOM'	=> 'RANDOMIZE',
						'P_CONT'	=> 'CONTINUE',
						'P_STOP'	=> 'STOP_BAS',
						'P_BEEP'	=> 'beep',
						'P_OUT'		=> 'OUT_BAS');						
	$self->labels->add(0x1A48, 'offst_tbl');
	for (my $addr = 0x1A48; @cmds_ptr; $addr++ ) {
		# decode offset table
		my $cmd_ptr = shift @cmds_ptr;
		my $cmd = $cmd{$cmd_ptr} || substr($cmd_ptr, 2);	# special or remove P_
		
		my $cmd_offset = $self->memory->peek($addr);
		my $p = $addr + $cmd_offset;
		$self->defb($addr)->format->{N} = sub { $cmd_ptr.' - $' };
		
		# decode instruction table
		$self->labels->add($p, $cmd_ptr);
		for (;;) {
			my $class = $self->memory->peek($p);
			$self->defb($p++);

			if ($class == 0 || $class == 3 || $class == 5) { 
				# followed by routine
				$self->defw($p);
				my $cmd_addr = $self->memory->peek16u($p);
				$self->code($cmd_addr, $cmd);
				last;
			}
			elsif ($class == 1) {		
				# followed by separator and another class
				$self->defb($p++);
			}
			elsif ($class == 2) {		
				# end of table
				last;
			}
			elsif ($class == 4 || $class == 6 || $class == 8 || $class == 9 ||
				   $class == 10) { 
				# followed by separator, or another Class byte
				my $sep = $self->memory->peek($p);
				if ($sep >= 32) {
					$self->defb($p++);
				}
			}
			else {
				last;
			}
		}
	}
}

#------------------------------------------------------------------------------
# unused data
sub dis_unused {
	my($self) = @_;

	$self->defb(0x0013, 5);
	$self->defb(0x0025, 3);
	$self->defb(0x002B, 5);
	$self->defb(0x005F, 7);

	$self->defb(0x386E, 2, 'spare');
	for (my $addr = 0x3870; $addr < 0x3D00; $addr += 8) {
		$self->defb($addr, 8);
	}	
}

#------------------------------------------------------------------------------
# channels and streams data
sub dis_init_chan {
	my($self) = @_;

	# Initial channel information
	my $addr = 0x15AF;
	$self->labels->add($addr, 'init_chan');
	my @cmd = (qw(  PRINT_OUT KEY_INPUT PRINT_OUT REPORT_J ADD_CHAR REPORT_J
					PRINT_OUT REPORT_J ));
	while (@cmd) {
		for (1..2) {
			my $cmd_addr = $self->memory->peek16u($addr);
			$self->code($cmd_addr, shift @cmd);
			$self->defw($addr); $addr += 2;
		}
		$self->defb($addr); $addr++;
	}
	$self->defb($addr); $addr++;
	
	# Initial stream information
	$addr = 0x15C6;
	$self->labels->add($addr, 'init_strm');
	for (1..7) {
		$self->defb($addr, 2); $addr += 2;
	}
	
	# Channel code look-up table
	$addr = 0x162D;
	$self->labels->add($addr, 'chn_cd_lu');
	@cmd = (qw( CHAN_K CHAN_S CHAN_P ));
	for my $cmd (@cmd) {
		$self->defm($addr, 1); $addr++;
		my $offset = $self->memory->peek($addr);
		$self->code($addr + $offset, $cmd);
		$self->defb($addr)->format->{N} = sub { $cmd.' - $'}; $addr++;
	}
	$self->defb($addr); $addr++;
	
	# Close stream look-up table 
	$addr = 0x1716;
	$self->labels->add($addr, 'cl_str_lu');
	@cmd = (qw( CLOSE_STR CLOSE_STR CLOSE_STR ));
	for my $cmd (@cmd) {
		$self->defm($addr, 1); $addr++;
		my $offset = $self->memory->peek($addr);
		$self->code($addr + $offset, $cmd);
		$self->defb($addr)->format->{N} = sub { $cmd.' - $'}; $addr++;
	}

	# Open stream look-up table 
	$addr = 0x177A;
	$self->labels->add($addr, 'op_str_lu');
	@cmd = (qw( OPEN_K OPEN_S OPEN_P ));
	for my $cmd (@cmd) {
		$self->defm($addr, 1); $addr++;
		my $offset = $self->memory->peek($addr);
		$self->code($addr + $offset, $cmd);
		$self->defb($addr)->format->{N} = sub { $cmd.' - $'}; $addr++;
	}
	$self->defb($addr); $addr++;
}

#------------------------------------------------------------------------------
sub dis_line_zero {
	my($self) = @_;
	$self->defb(0x168F, 2, 'LINE_ZERO');
}

#------------------------------------------------------------------------------
# calculator tables
sub dis_calc_tables {
	my($self) = @_;

	my $addr = 0x2795;
	$self->labels->add($addr, 'tbl_of_ops');
	for (1..8) {
		$self->defm($addr++, 1);
		$self->defb($addr++);
	}
	for (1..5) {
		$self->defb($addr++);
		$self->defb($addr++);
	}
	$self->defb($addr++);
	
	$self->labels->add($addr, 'tbl_priors');
	for (1..13) {
		$self->defb($addr++);
	}
	
	$addr = 0x2596;
	$self->labels->add($addr, 'scan_func');
	my @cmd = (qw( 	S_QUOTE S_BRACKET S_DECIMAL S_U_PLUS S_FN S_RND S_PI
					S_INKEY_ S_DECIMAL S_SCREEN_ S_ATTR S_POINT ));
	for my $cmd (@cmd) {
		my $op = $self->memory->peek($addr);
		if ($op < 0x80 && $op != 0x22) {
			$self->defm($addr++, 1);
		}
		else {
			$self->defb($addr++);
		}
		my $offset = $self->memory->peek($addr);
		$self->code($addr + $offset, $cmd);
		$self->defb($addr)->format->{N} = sub { $cmd.' - $'}; $addr++;
	}
	$self->defb($addr); $addr++;
	
	# table of addresses
	$addr = 0x32D7;
	$self->labels->add($addr, 'tbl_addrs');
	@cmd = (qw(	jump_true exchange delete subtract multiply division 
				to_power or_func no___no no_l_eql_etc_ no_l_eql_etc_ 
				no_l_eql_etc_ no_l_eql_etc_ no_l_eql_etc_ no_l_eql_etc_ 
				addition str___no no_l_eql_etc_ no_l_eql_etc_ no_l_eql_etc_ 
				no_l_eql_etc_ no_l_eql_etc_ no_l_eql_etc_ strs_add val_ 
				usr__ read_in negate code val_ len sin cos tan asn acs 
				atn ln exp int sqr sgn abs peek in_func usr_no str_ chrs not 
				MOVE_FP n_mod_m JUMP stk_data dec_jr_nz less_0 greater_0 
				end_calc get_argt truncate fp_calc_2 E_TO_FP re_stack 
				series_xx stk_const_xx st_mem_xx get_mem_xx ));
	for my $cmd (@cmd) {
		my $cmd_addr = $self->memory->peek16u($addr);
		$self->code($cmd_addr, $cmd);
		$self->defw($addr); $addr += 2;
	}

	# constants
	$addr = 0x32C5;
	$addr = dis_float_const($self, $addr, 'stk_zero');
	$addr = dis_float_const($self, $addr, 'stk_one');
	$addr = dis_float_const($self, $addr, 'stk_half');
	$addr = dis_float_const($self, $addr, 'stk_pi_2');
	$addr = dis_float_const($self, $addr, 'stk_ten');
}

#------------------------------------------------------------------------------
sub dis_char_set {
	my($self) = @_;
	my $addr = 0x3D00;
	$self->labels->add($addr, 'char_set');
	for (0x3D00 .. 0x3FFF) {
		$self->defb($addr++)->format->{N} = sub { format_bin8($_[0]) };
	}
}

#------------------------------------------------------------------------------
sub dis_system_vars {
	my($self) = @_;
	
	$self->labels->add(0x5C00, 'KSTATE'    )->comment("Used in reading the keyboard.");
	$self->labels->add(0x5C01, 'KSTATE1'   )->comment("");
	$self->labels->add(0x5C02, 'KSTATE2'   )->comment("");
	$self->labels->add(0x5C03, 'KSTATE3'   )->comment("");
	$self->labels->add(0x5C04, 'KSTATE4'   )->comment("");
	$self->labels->add(0x5C05, 'KSTATE5'   )->comment("");
	$self->labels->add(0x5C06, 'KSTATE6'   )->comment("");
	$self->labels->add(0x5C07, 'KSTATE7'   )->comment("");
	$self->labels->add(0x5C08, 'LAST_K'    )->comment("Stores newly pressed key.");
	$self->labels->add(0x5C09, 'REPDEL'    )->comment("Time (in 50ths of a second in 60ths of a second in\n".
													  "N. America) that a key must be held down before it\n".
													  "repeats. This starts off at 35, but you can POKE\n".
													  "in other values.");
	$self->labels->add(0x5C0A, 'REPPER'    )->comment("Delay (in 50ths of a second in 60ths of a second in\n".
													  "N. America) between successive repeats of a key\n".
													  "held down: initially 5.");
	$self->labels->add(0x5C0B, 'DEFADD'    )->comment("Address of arguments of user defined function if\n".
													  "one is being evaluated; otherwise 0.");
	$self->labels->add(0x5C0D, 'K_DATA'    )->comment("Stores 2nd byte of colour controls entered\n".
													  "from keyboard .");
	$self->labels->add(0x5C0E, 'TVDATA'    )->comment("Stores bytes of coiour, AT and TAB controls going\n".
													  "to television.");
	$self->labels->add(0x5C10, 'STRMS'     )->comment("Addresses of channels attached to streams.");
	$self->labels->add(0x5C36, 'CHARS'     )->comment("256 less than address of character set (which\n".
													  "starts with space and carries on to the copyright\n".
													  "symbol). Normally in ROM, but you can set up your\n".
													  "own in RAM and make CHARS point to it.");
	$self->labels->add(0x5C38, 'RASP'      )->comment("Length of warning buzz.");
	$self->labels->add(0x5C39, 'PIP'       )->comment("Length of keyboard click.");
	$self->labels->add(0x5C3A, 'ERR_NR'    )->comment("1 less than the report code. Starts off at 255 (for 1)\n".
													  "so PEEK 23610 gives 255.");
	$self->labels->add(0x5C3B, 'FLAGS'     )->comment("Various flags to control the BASIC system.");
	$self->labels->add(0x5C3C, 'TV_FLAG'   )->comment("Flags associated with the television.");
	$self->labels->add(0x5C3D, 'ERR_SP'    )->comment("Address of item on machine stack to be used as\n".
													  "error return.");
	$self->labels->add(0x5C3F, 'LIST_SP'   )->comment("Address of return address from automatic listing.");
	$self->labels->add(0x5C41, 'MODE'      )->comment("Specifies K, L, C. E or G cursor.");
	$self->labels->add(0x5C42, 'NEWPPC'    )->comment("Line to be jumped to.");
	$self->labels->add(0x5C44, 'NSPPC'     )->comment("Statement number in line to be jumped to. Poking\n".
													  "first NEWPPC and then NSPPC forces a jump to\n".
													  "a specified statement in a line.");
	$self->labels->add(0x5C45, 'PPC'       )->comment("Line number of statement currently being executed.");
	$self->labels->add(0x5C47, 'SUBPPC'    )->comment("Number within line of statement being executed.");
	$self->labels->add(0x5C48, 'BORDCR'    )->comment("Border colour * 8; also contains the attributes\n".
													  "normally used for the lower half of the screen.");
	$self->labels->add(0x5C49, 'E_PPC'     )->comment("Number of current line (with program cursor).");
	$self->labels->add(0x5C4B, 'VARS'      )->comment("Address of variables.");
	$self->labels->add(0x5C4D, 'DEST'      )->comment("Address of variable in assignment.");
	$self->labels->add(0x5C4F, 'CHANS'     )->comment("Address of channel data.");
	$self->labels->add(0x5C51, 'CURCHL'    )->comment("Address of information currently being used for\n".
													  "input and output.");
	$self->labels->add(0x5C53, 'PROG'      )->comment("Address of BASIC program.");
	$self->labels->add(0x5C55, 'NXTLIN'    )->comment("Address of next line in program.");
	$self->labels->add(0x5C57, 'DATADD'    )->comment("Address of terminator of last DATA item.");
	$self->labels->add(0x5C59, 'E_LINE'    )->comment("Address of command being typed in.");
	$self->labels->add(0x5C5B, 'K_CUR'     )->comment("Address of cursor.");
	$self->labels->add(0x5C5D, 'CH_ADD'    )->comment("Address of the next character to be interpreted:\n".
													  "the character after the argument of PEEK, or\n".
													  "the NEWLINE at the end of a POKE statement.");
	$self->labels->add(0x5C5F, 'X_PTR'     )->comment("Address of the character after the ? marker.");
	$self->labels->add(0x5C61, 'WORKSP'    )->comment("Address of temporary work space.");
	$self->labels->add(0x5C63, 'STKBOT'    )->comment("Address of bottom of calculator stack.");
	$self->labels->add(0x5C65, 'STKEND'    )->comment("Address of start of spare space.");
	$self->labels->add(0x5C67, 'BREG'      )->comment("Calculator's b register.");
	$self->labels->add(0x5C68, 'MEM'       )->comment("Address of area used for calculator's memory.\n".
													  "(Usually MEMBOT, but not always.)");
	$self->labels->add(0x5C6A, 'FLAGS2'    )->comment("More flags.");
	$self->labels->add(0x5C6B, 'DF_SZ'     )->comment("The number of lines (including one blank line)\n".
													  "in the lower part of the screen.");
	$self->labels->add(0x5C6C, 'S_TOP'     )->comment("The number of the top program line in automatic\n".
													  "listings.");
	$self->labels->add(0x5C6E, 'OLDPPC'    )->comment("Line number to which CONTINUE jumps.");
	$self->labels->add(0x5C70, 'OSPCC'     )->comment("Number within line of statement to which\n".
													  "CONTINUE jumps.");
	$self->labels->add(0x5C71, 'FLAGX'     )->comment("Various flags.");
	$self->labels->add(0x5C72, 'STRLEN'    )->comment("Length of string type destination in assignment.");
	$self->labels->add(0x5C74, 'T_ADDR'    )->comment("Address of next item in syntax table (very unlikely\n".
													  "to be useful).");
	$self->labels->add(0x5C76, 'SEED'      )->comment("The seed for RND. This is the variable that is set\n".
													  "by RANDOMIZE.");
	$self->labels->add(0x5C78, 'FRAMES'    )->comment("3 byte (least significant first), frame counter.\n".
													  "Incremented every 20ms. See Chapter 18.");
	$self->labels->add(0x5C7A, 'FRAMES3'   )->comment("3rd byte of FRAMES");
	$self->labels->add(0x5C7B, 'UDG'       )->comment("Address of 1st user defined graphic You can change\n".
													  "this for instance to save space by having fewer\n".
													  "user defined graphics.");
	$self->labels->add(0x5C7D, 'COORDS'    )->comment("x-coordinate of last point plotted.");
	$self->labels->add(0x5C7E, 'COORDS_hi' )->comment("y-coordinate of last point plotted.");
	$self->labels->add(0x5C7F, 'P_POSN'    )->comment("33 column number of printer position");
	$self->labels->add(0x5C80, 'PR_CC'     )->comment("Full address of next position for LPRINT to print at\n".
													  "(in ZX printer buffer). Legal values 5B00 - 5B1F.\n".
													  "[Not used in 128K mode or when certain peripherals\n".
													  "are attached]");
	$self->labels->add(0x5C82, 'ECHO_E'    )->comment("33 column number and 24 line number (in lower half)\n".
													  "of end of input buffer.");
	$self->labels->add(0x5C84, 'DF_CC'     )->comment("Address in display file of PRINT position.");
	$self->labels->add(0x5C86, 'DFCCL'     )->comment("Like DF CC for lower part of screen.");
	$self->labels->add(0x5C88, 'S_POSN'    )->comment("33 column number for PRINT position");
	$self->labels->add(0x5C89, 'S_POSN_hi' )->comment("24 line number for PRINT position.");
	$self->labels->add(0x5C8A, 'SPOSNL'    )->comment("Like S POSN for lower part");
	$self->labels->add(0x5C8C, 'SCR_CT'    )->comment("Counts scrolls: it is always 1 more than the number\n".
													  "of scrolls that will be done before stopping with\n".
													  "scroll? If you keep poking this with a number\n".
													  "bigger than 1 (say 255), the screen will scroll\n".
													  "on and on without asking you.");
	$self->labels->add(0x5C8D, 'ATTR_P'    )->comment("Permanent current colours, etc (as set up by colour\n".
													  "statements).");
	$self->labels->add(0x5C8E, 'MASK_P'    )->comment("Used for transparent colours, etc. Any bit that\n".
													  "is 1 shows that the corresponding attribute bit\n".
													  "is taken not from ATTR P, but from what is already\n".
													  "on the screen.");
	$self->labels->add(0x5C8F, 'ATTR_T'    )->comment("Temporary current colours, etc (as set up by\n".
													  "colour items).");
	$self->labels->add(0x5C90, 'MASK_T'    )->comment("Like MASK P, but temporary.");
	$self->labels->add(0x5C91, 'P_FLAG'    )->comment("More flags.");
	$self->labels->add(0x5C92, 'MEMBOT'    )->comment("Calculator's memory area; used to store numbers\n".
													  "that cannot conveniently be put on\n".
													  "the calculator stack.");
	$self->labels->add(0x5CB0, 'NMIADD'    )->comment("This is the address of a user supplied NMI address\n".
													  "which is read by the standard ROM when a peripheral\n".
													  "activates the NMI. Probably intentionally disabled\n".
													  "so that the effect is to perform a reset if both\n".
													  "locations hold zero, but do nothing if the locations\n".
													  "hold a non-zero value. Interface 1's with serial\n".
													  "number greater than 87315 will initialize these\n".
													  "locations to 0 and 80 to allow the RS232 \"T\" channel\n".
													  "to use a variable line width. 23728 is the current\n".
													  "print position and 23729 the width - default 80.");
	$self->labels->add(0x5CB2, 'RAMTOP'    )->comment("Address of last byte of BASIC system area.");
	$self->labels->add(0x5CB4, 'P_RAMT'    )->comment("Address of last byte of physical RAM.");
	
	$self->iy_base(0x5C3A);
}
