#!perl

# $Id: build_AsmTable.pl,v 1.11 2010/10/01 11:02:26 Paulo Exp $
# Build all CPU::Z80::Assembler instructions
# Needs sjasmplus (http://sjasmplus.sourceforge.net/) to validate assembled code

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use File::Slurp;
use Iterator::Array::Jagged;
use List::MoreUtils 'first_index';
use Text::Template 'fill_in_file';

#------------------------------------------------------------------------------
# generated table
my $asm_table = {};
my $disasm_table = {};

#------------------------------------------------------------------------------
# Load table
sub load_table { 
	my($line_iter) = @_;

	while ($_ = $line_iter->()) {
		s/\s*\#.*//; s/^\s+//; s/\s+$//;
		next unless /\S/;
		last if /__END__/;
		chomp;

		my($instr, $bytes) = split(/\s*=>\s*/, $_);
		my @instr_tmpl = split(/\s+|\s*,\s*/, $instr);
		my @bytes_tmpl = split(' ', $bytes);

		# convert each operand to a list of [index, value]
		for (@instr_tmpl) {
			if (s/^<(.*)>$/$1/) {
				my @list = split(/\./, $_);
				$_ = [ grep {$_->[1] ne ""} map {[$_, $list[$_]]} 0 .. $#list ];
			}
			else {
				$_ = [[0, $_]];
			}
		}
		
		# iterate through lists
		my $instr_iter = Iterator::Array::Jagged->new(data => \@instr_tmpl);
		while (my @set = $instr_iter->next) {
			# compute instr and bytes
			my @value = map {$_->[0]} @set;
			my @instr = map {$_->[1]} @set;

			# make a copy, so that @bytes remains intact
			my @bytes = @bytes_tmpl;	

			for (@bytes) {
				s/<(\d)(:(\d))?>/ $value[ $1 ] << ($3 || 0) /ge;
				if (! /(NN?|DIS)\d*/) {
					$_ = eval $_; $@ and die $@;
				}
			}
			
			# add "," tokens, and split arguments by tokens
			for (my $i = 2; $i < @instr; $i += 2) {
				splice(@instr, $i, 0, ",");
			}
			for (my $i = 0; $i < @instr; $i++) {
				next if $instr[$i] =~ /af\'/i;	# special case - af'
				
				my @arg = split(/\b/, $instr[$i]);
				if (@arg > 1) {
					splice(@instr, $i, 1, @arg);
				}
			}

			load_instr([@instr], [@bytes]);
			
			# convert "(ix+DIS)" into "(ix-NDIS)" and "(ix)" 
			my $dis_pos = first_index {$_ eq "DIS"} @instr;
			if ($dis_pos >= 0) {
				die unless $instr[$dis_pos-1] eq "+";
				my @instr_copy = @instr;
				my @bytes_copy = @bytes;
				
				@instr_copy[$dis_pos-1, $dis_pos] = ("-", "NDIS");
				for (@bytes_copy) {
					s/DIS/NDIS/;
				}
				load_instr([@instr_copy], [@bytes_copy]);
				
				splice(@instr_copy, $dis_pos-1, 2);
				for (@bytes_copy) {
					s/NDIS\+1/1/;
					s/NDIS/0/;
				}
				load_instr([@instr_copy], [@bytes_copy]);
			}
		}
	}
}

#------------------------------------------------------------------------------
# Load instruction
sub load_instr { my($instr, $bytes) = @_;
	my $code = 
		'$disasm_table->'.join("", map {'{"'.$_.'"}'} @$bytes, "").
		' ||= $instr; '.
		'$asm_table->'.join("", map {'{"'.$_.'"}'} ( @$instr, "" )).
		' ||= $bytes;';
	eval $code; $@ and die "$code: $@";
}

#------------------------------------------------------------------------------
# Build the output module
sub write_asm_table { 
	my($package, $file) = @_;

	my @template_args = (
		DELIMITERS 	=> [ '<%', '%>' ],
		HASH 		=> { 
				package			=> $package,
				program			=> basename($0),
				asm_table		=> $asm_table,
				disasm_table	=> $disasm_table,
				dump_table		=> \&dump_table,
				assembly_table	=> \&assembly_table,
			},
	);

	my $template_file = dirname($0).'/Table_template.pm';
	my $code = fill_in_file($template_file, @template_args);
	write_file($file, $code);
}

#------------------------------------------------------------------------------
# convert numbers to hex
sub dump_table {
	my($table) = @_;
	local $Data::Dumper::Indent		= 1;
	local $Data::Dumper::Terse		= 1;
	local $Data::Dumper::Sortkeys	= 1;

	my $table_dump = Dumper($table);
	for ($table_dump) {
		s/([^+])(\d+)\b/ $1 . sprintf("0x%02X", $2) /ge;
		s/'(0x[0-9a-f]+)'/$1/gi;
	}
	$table_dump;
}

#------------------------------------------------------------------------------
# create a complete assembly table
sub assembly_table {

	# build list of tokens and opcode bytes
	my @out;
	dump_assembly_table(\@out, $asm_table);
	
	# convert tokens to instruction
	my $max_len = 0;
	for (@out) {
		# tokens
		my @tokens = @{$_->[0]};
		$_->[0] = sprintf("  %-4s ", shift(@tokens));
		$_->[0] .= join('', @tokens);
		
		my $len = length($_->[0]);
		$max_len = $len if $max_len < $len;
		
		# bytes
		$_->[1] = join(' ', map { /\D/ ? $_ : sprintf("%02X", $_) } @{$_->[1]});
	}
	
	# align both columns
	for (@out) {
		$_ = sprintf("%-*s ; %s", $max_len, $_->[0], $_->[1]);
	}
	
	return join("\n", sort @out);
}

sub dump_assembly_table {
	my($out, $node, @tokens) = @_;

	for my $token (sort keys %$node) {
		if ($token eq '') {				# found data
			push @$out, [\@tokens, $node->{$token}];
		}
		else {							# recurse
			dump_assembly_table($out, $node->{$token}, @tokens, $token);
		}
	}
}
		


#------------------------------------------------------------------------------
# main
@ARGV == 2 or die "Usage: ",basename($0)," PACKAGE FILE.PM\n";
my($package, $file) = @ARGV;

my $data_file = dirname($0).'/Z80_instructions.dat';
open(my $fh, $data_file) or die "$data_file: $!\n";

load_table(sub {my $line = <$fh>; $line});
write_asm_table($package, $file);
