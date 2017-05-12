#!perl 

#------------------------------------------------------------------------------
# parse the ZX Spectrum ROM disassembly file
package Parsezx48;

use strict;
use warnings;

use Fcntl 'O_RDONLY';
use Tie::File;
use Asm::Z80::Table;

#------------------------------------------------------------------------------
# collect info from disassembly file
use Class::XSAccessor {
	constructor	=> '_new',
	accessors	=> [
		'label_by_addr',	# hash of addr => label name
		'label_by_name',	# hash of label name => addr
		'label_by_line',	# hash of line number => label name
		'header',			# file header
		'footer',			# file footer
		'instr',			# array of instr by addr
	],
};

use Class::XSAccessor {
	class		=> 'My::Instr',
	constructor	=> 'new',
	accessors	=> [
		'addr',				# address
		'size',				# size
		'label',			# label, if any
		'block_comment',	# block comment before instruction
		'line_comment',		# line comment after instruction
		'opcode',			# assembly instruction
		'is_data',			# true if it is a def* opcode
	],
};

#------------------------------------------------------------------------------
# parse the given file
sub new { 
	my($class, $rom_asm_file) = @_;
	my $self = $class->_new( label_by_addr 	=> {}, 
							 label_by_name 	=> {},
							 label_by_line 	=> {},
							 instr 			=> []);
	$self->read_asm($rom_asm_file);
	
	return $self;
}

#------------------------------------------------------------------------------
# read assembly file
sub read_asm {
	my($self, $rom_asm_file) = @_;
	
	my @file;
	tie @file, 'Tie::File', $rom_asm_file, mode => O_RDONLY;
	
	# read file header and footer
	my $p_min = $self->read_header(\@file);
	my $p_max = $self->read_footer(\@file);
	
	# first pass : read all the labels
	$self->read_labels(\@file, $p_min, $p_max);
	
	# read all instr
	my $addr = 0;
	my $instr;
	for (my $p = $p_min ; $p <= $p_max ; $p++ ) {
		($instr, $p) = $self->read_instr($addr, \@file, $p, $p_max) or die;
		
		$self->instr->[$addr] and die;
		$self->instr->[$addr] = $instr;
		
		$addr += $instr->size;
	}		
}

#------------------------------------------------------------------------------
# read file header
sub read_header {
	my($self, $file) = @_;

	my $header = '';
	my $found_org;
	for my $p (0 .. $#$file) {
		if ($file->[$p] =~ / ^ \s* org /ix) {
			$found_org++;
		}
		elsif ( $found_org ?
					$file->[$p] =~ / ^ (?:     \s* $ | (\#) ) /x :
					$file->[$p] =~ / ^ (?: ; | \s* $ | (\#) ) /x ) {
			$header .= ($1 ? ';' : '') . $file->[$p] . "\n";	# comment '#'
		}
		else {
			$self->header($header) unless $header eq ''; 
			return $p;
		}
	}
	return 0;	# no header;
}

#------------------------------------------------------------------------------
# read file footer
sub read_footer {
	my($self, $file) = @_;

	my $footer = '';
	for my $p (reverse 0 .. $#$file) {
		if ($file->[$p] =~ / ^ (?: ; | \s* $ | (\#) ) /x ) {
			$footer = ($1 ? ';' : '') . $file->[$p] . "\n" .	# comment '#'
					  $footer;
		}
		else {
			$self->footer($footer) unless $footer eq ''; 
			return $p;
		}
	}
	return $#$file;	# no footer;
}

#------------------------------------------------------------------------------
# read labels
sub read_labels {
	my($self, $file, $p_min, $p_max) = @_;

	for my $p ($p_min .. $p_max) {
		if ($file->[$p] =~ /^([a-z_]\w*)/i) {
			my $label = $1;
			next if $label =~ /^org$/i;
			$label =~ /^[LX]([0-9A-F]{4})$/ 
				or die "unrecoginzed label format at line ".($p+1);
			my $addr = hex($1);
			
			# search for label name
			my $label_name = $label;		# default
			for my $q (reverse $p_min .. $p-1) {
				last unless $file->[$q] =~ /^\s*(;|$)/;
				if ($file->[$q] =~ /^;;\s+(\S+)/) {
					$label_name = $1;
					last;
				}
			}
			
			# make label name valid
			$label_name =~ s/\W/_/g;
			
			# cannot exist
			exists $self->label_by_addr->{$addr}
				and die "two labels at the same address at line ".($p+1); 
			exists $self->label_by_name->{uc($label_name)}
				and die "two labels with the same name at line ".($p+1); 
			exists $self->label_by_line->{$p}
				and die "two labels at the same line at line ".($p+1); 
				
			$self->label_by_addr->{$addr} = $label_name;
			$self->label_by_name->{uc($label_name)} = $addr;
			$self->label_by_line->{$p} = $label_name;
		}
	}
}

#------------------------------------------------------------------------------
# read the next opcode
sub read_instr {
	my($self, $addr, $file, $p, $p_max) = @_;
	
	my $instr = My::Instr->new(addr => $addr);
	
	# block comment
	my $block_comment = '';
	while ($p <= $p_max &&
		   $file->[$p] =~ /^\s*(;|$|org)/i) {
		$block_comment .= $file->[$p] . "\n" unless $file->[$p] =~ /^\s*org/i;
		$p++;
	}
	$instr->block_comment($block_comment) unless $block_comment eq '';
	
	# first opcode line
	if ($p <= $p_max &&
	    $file->[$p] =~ / ^ ( [a-z_]\w* [:\s] \s* | \s+ ) 
						   ( \w+ .*? )?
						   ( ; .*)? $ /ix) {
		my($label, $opcode, $comment) = ($1, $2, $3);
		
		# get label from $self, already processed
		if ($label =~ /\w+/) {
			my $label_name = $self->label_by_line->{$p} 
				or die "label $label not found at line ".($p+1);
			$instr->label($label_name);
			
			$addr == $self->label_by_name->{uc($instr->label)}
				or die "address $addr does not match label $label_name".
					   " at line ".($p+1);			
		}
		
		# convert opcode format to lower case, 0xhhhh numbers, include labels
		if (! $opcode) {
			# need to read opcode from next line
			$comment and die "comment unexpected at line ".($p+1);
			$p++;
			$p > $p_max and die "opcode not found at line ".($p+1);
			$file->[$p] =~ / ^ \s+ ( \w+ .*? )
						           ( ; .*)? $ /ix 
				or die "cannot parse line ".($p+1);
			($opcode, $comment) = ($1, $2);
		}
		
		my @tokens = $self->lexer($opcode);
		$opcode = join('', @tokens);

		$instr->opcode($opcode);
		$instr->is_data( $opcode =~ /^def/i );
		$instr->size($self->opcode_size($p, @tokens));
		
		# line comment
		if (defined $comment) {
			for ($comment) {
				s/^;\s?//;
				s/\s+$//;
			}
			$instr->line_comment($comment) unless $comment eq '';
		}
	}
	else {
		die "cannot parse instruction at line ".($p+1);
	}

	# following comment lines
	while ($p+1 <= $p_max &&
		   $file->[$p+1] =~ /^\s*(;.*)/) {
		my $comment = $1;
		$comment =~ s/^;\s?//; $comment =~ s/\s+$//;
		if ($comment ne '') {
			defined($instr->line_comment) or $instr->line_comment('');
			$instr->line_comment($instr->line_comment . "\n" . $comment);
		}
		
		$p++;
	}
	
	return ($instr, $p);
}

#------------------------------------------------------------------------------
# convert opcode into tokens
sub lexer {
	my($self, $opcode) = @_;
	my @tokens;
	
	for ($opcode) {
		s/\s+$//;
		while (! / \G \z /gcxi) {
			if (/ \G \s+ /gcxi) {
				push @tokens, " ";
			}
			elsif (/ \G \$ ([0-9A-F]+) \b /gcxi) {
				push @tokens, "0x".$1;
			}
			elsif (/ \G (\d [0-9A-F]*) h \b /gcxi) {
				push @tokens, "0x".$1;
			}
			elsif (/ \G [LX] ([0-9A-F]{4}) \b /gcxi) {
				my $addr = hex($1);
				my $label_name = $self->label_by_addr->{$addr} or die;
				push @tokens, $label_name;
			}
			elsif (/ \G (' [^']* ') /gcxi) {
				push @tokens, $1;
			}
			elsif (/ \G (" [^"]* ") /gcxi) {
				push @tokens, $1;
			}
			elsif (/ \G (af' | \w+ | .) /gcxi) {
				push @tokens, lc($1);
			}
			else {
				die 'not reached';
			}
		}
	}
	return @tokens;
}

#------------------------------------------------------------------------------
# compute size of assembly opcode
sub opcode_size {
	my($self, $p, @tokens) = @_;
	my $opcode = join('', @tokens);
	
	@tokens = grep {! /^\s*$/} @tokens;
	if (@tokens && $tokens[0] =~ /^def/i) {
		# compute size of defb, defw
		my $token = shift @tokens;
		if ($token eq 'defm') {
			@tokens == 1 
				or die "cannot parse '$opcode' at line ".($p+1);
			return length($tokens[0]) - 2;	# length minus quotes
		}
		else {
			my $size = 
				$token eq 'defb' ? 1 : 
				$token eq 'defw' ? 2 : 
				die("cannot parse token '$token' from '$opcode' at line ".($p+1));
			my $count = 1;
			for (@tokens) { $count++ if $_ eq ',' }
			return $count * $size;
		}
	}
	else {
		my $table = Asm::Z80::Table->asm_table;
		while (defined(my $token = shift @tokens)) {
			$token = oct($token) if $token =~ /^0x/;
		
			if (exists $table->{$token}) {
				$table = $table->{$token};
			}
			elsif ( exists($table->{NN}  ) || 
					exists($table->{N}   ) || 
					exists($table->{DIS} ) || 
					exists($table->{NDIS}) ) {
				$table = $table->{NN}  || 
						 $table->{N}   || 
						 $table->{DIS} || 
						 $table->{NDIS};
				
				# $token is first term of expression
				my $paren = $token eq '(' ? 1 : 0;
				while (@tokens) {
					last if $tokens[0] eq ',';					# term separator
					last if $tokens[0] eq ')' && $paren == 0;	# end of expression
					
					$token = shift @tokens;
					$paren++ if $token eq '(';
					$paren-- if $token eq ')';
				}
			}
			else {			
				die "cannot parse token '$token' from opcode '$opcode' at line ".
				    ($p+1);
			}
		}
		
		return scalar @{$table->{''}};
	}
}

#------------------------------------------------------------------------------
# send the disassembly to the given file
sub write {
	my($self, $file) = @_;
	
	my $fh;
	if ($file) {
		open($fh, ">", $file) or die "write $file: $!";
	}
	else {
		$fh = \*STDOUT;
	}
	
	print $fh $self->header if defined $self->header;
	
	print $fh " " x 8, "org ", sprintf("0x%04X", $self->instr->[0]->addr), "\n\n"
		if @{$self->instr};
	
	for my $instr (@{$self->instr}) {
		next unless $instr;
		
		print $fh $instr->block_comment if defined $instr->block_comment;
		
		if (defined $instr->label) {
			print $fh $instr->label, ":\n";
		}
		if (! defined $instr->line_comment) {
			print $fh " " x 8, $instr->opcode, "\n";
		}
		else {
			my @line_comment = split(/\n/, $instr->line_comment);
			
			if (! @line_comment ||
			    length($instr->opcode) >= 24) {
				print $fh " " x 8, $instr->opcode, "\n";
			}
			else {
				print $fh " " x 8, sprintf("%-24s", $instr->opcode),
						  "; ", shift(@line_comment), "\n";
			}
		
			while (@line_comment) {
				print $fh " " x 32, "; ", shift(@line_comment), "\n";
			}
		}
	}
	print $fh $self->footer if defined $self->footer;
}

1;
