#!perl

# $Id: Table.t,v 1.1 2010/11/20 20:38:51 Paulo Exp $

use warnings;
use strict;

use Test::More;

use_ok 'Asm::Z80::Table';

is_deeply 
	Asm::Z80::Table->asm_table->{'adc'}{'a'}{','}{'('}{'hl'}{')'}{''},
	[0x8E];
is_deeply 
	Asm::Z80::Table->disasm_table->{0x8E}{''},
	['adc', 'a', ',', '(', 'hl', ')'];

is_deeply 
	Asm::Z80::Table->asm_table->{'adc'}{'a'}{','}{'N'}{''},
	[0xCE, 'N'];
is_deeply 
	Asm::Z80::Table->disasm_table->{0xCE}{'N'}{''},
	['adc', 'a', ',', 'N'];
	
is_deeply 
	Asm::Z80::Table->asm_table->{'call'}{'NN'}{''},
	[0xCD, 'NNl', 'NNh'];
is_deeply 
	Asm::Z80::Table->disasm_table->{0xCD}{'NNl'}{'NNh'}{''},
	['call', 'NN'];
	
is_deeply 
	Asm::Z80::Table->asm_table->{'jr'}{'NN'}{''},
	[0x18, 'NNo'];
is_deeply 
	Asm::Z80::Table->disasm_table->{0x18}{'NNo'}{''},
	['jr', 'NN'];
	
is_deeply 
	Asm::Z80::Table->asm_table->{'adc'}{'a'}{','}{'('}{'ix'}{'+'}{'DIS'}{')'}{''},
	[0xDD, 0x8E, 'DIS'];
is_deeply 
	Asm::Z80::Table->disasm_table->{0xDD}{0x8E}{'DIS'}{''},
	['adc', 'a', ',', '(', 'ix', '+', 'DIS', ')'];
	
is_deeply 
	Asm::Z80::Table->asm_table->{'adc'}{'a'}{','}{'('}{'ix'}{'-'}{'NDIS'}{')'}{''},
	[0xDD, 0x8E, 'NDIS'];
is_deeply 
	Asm::Z80::Table->disasm_table->{0xDD}{0x8E}{'NDIS'}{''},
	['adc', 'a', ',', '(', 'ix', '-', 'NDIS', ')'];

is_deeply 
	Asm::Z80::Table->asm_table->{'ld'}{'bc'}{','}{'('}{'ix'}{'+'}{'DIS'}{')'}{''},
	[0xDD, 0x4E, 'DIS', 0xDD, 0x46, 'DIS+1'];
is_deeply 
	Asm::Z80::Table->disasm_table->{0xDD}{0x4E}{'DIS'}{0xDD}{0x46}{'DIS+1'}{''},
	['ld', 'bc', ',', '(', 'ix', '+', 'DIS', ')'];

is_deeply 
	Asm::Z80::Table->asm_table->{'ld'}{'bc'}{','}{'('}{'ix'}{'-'}{'NDIS'}{')'}{''},
	[0xDD, 0x4E, 'NDIS', 0xDD, 0x46, 'NDIS+1'];
is_deeply 
	Asm::Z80::Table->disasm_table->{0xDD}{0x4E}{'NDIS'}{0xDD}{0x46}{'NDIS+1'}{''},
	['ld', 'bc', ',', '(', 'ix', '-', 'NDIS', ')'];

#------------------------------------------------------------------------------
# iterator

# recursively build table of all asm_table
my %asm_table;
my %disasm_table;
my %seen_disasm_key;
build_table(\%asm_table, 	Asm::Z80::Table->asm_table);
build_table(\%disasm_table,	Asm::Z80::Table->disasm_table);

# note that some byte sequences have more than one possible representation
is scalar(keys %asm_table), 	2452, "assembly table";
is scalar(keys %disasm_table), 	2384, "disassembly table";

isa_ok my $iter = Asm::Z80::Table->iterator, 'CODE';

# iterator lookup in instruction sort order
for my $key (sort keys %asm_table) {
	ok my($iter_tokens,  $iter_bytes)  = $iter->(),				"iterator lookup";

	# compare iterator with asm_table
	ok my($table_tokens, $table_bytes) = @{$asm_table{$key}},	"asm table lookup";	
	is_deeply $table_tokens, $iter_tokens,						"same tokens";
	is_deeply $table_bytes,  $iter_bytes,						"same bytes";
	
	# compare with corresponding disassembly
	my $disasm_key = key(@$iter_bytes);
	ok exists $disasm_table{$disasm_key},						"disasm table lookup";
	$seen_disasm_key{$disasm_key}++;
	
	ok my($distable_bytes, $distable_tokens) = @{$disasm_table{$disasm_key}},	
																"asm distable lookup";	

	# check for special cases
	if ("@$table_tokens" eq "sla hl") {
		ok "@$distable_tokens", "add hl , hl";			# sla hl is add hl,hl
	}
	elsif ("@$table_tokens" =~ /^(sli|sll)(.*)/i) {
		my $rest = qr/\Q$2\E/;
		like "@$distable_tokens", qr/^(sli|sll)$rest/;	# sli and sll are the same
	}
	else {
		ok "@$table_tokens", "@$distable_tokens";
	}
	
	is_deeply $distable_bytes,  $iter_bytes,					"same bytes";
}

# check which disasm_table was not seen
for my $key (sort keys %disasm_table) {
	next if $seen_disasm_key{$key};
	
	ok my($distable_bytes, $distable_tokens) = @{$disasm_table{$key}},	
																"asm distable lookup";

	# special cases of instrutions that have a smaller code sequence for assembly
	next if "@$distable_bytes" eq "203 37 203 20" && "@$distable_tokens" eq "sla hl";
	next if "@$distable_bytes" eq "237 107 NNl NNh" && "@$distable_tokens" eq "ld hl , ( NN )";
	next if "@$distable_bytes" eq "237 99 NNl NNh" && "@$distable_tokens" eq "ld ( NN ) , hl";

	ok 0, "unexpected @$distable_bytes => @$distable_tokens";
}


done_testing();


#------------------------------------------------------------------------------
# tools
sub build_table {
	my($table, $node, @tokens) = @_;
	for my $child (sort keys %$node) {
		if ($child eq '') {
			$table->{key(@tokens)} = [\@tokens, $node->{''}];
		}
		else {
			build_table($table, $node->{$child}, @tokens, $child);
		}
	}
}

sub key {
	my(@tokens) = @_;
	join(' ', map {sprintf("%-4s", $_)} @tokens);
}

