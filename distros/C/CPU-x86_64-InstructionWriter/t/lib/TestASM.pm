package TestASM;
use strict;
use warnings;
no warnings 'portable';
use Exporter 'import';
use Test::More;
use IO::Handle;
use File::Temp;
use File::Spec::Functions 'splitpath', 'splitdir', 'catdir', 'catpath';
use Digest::MD5 'md5_hex';
use CPU::x86_64::InstructionWriter ':unknown';

our @EXPORT_OK= qw( reference_assemble iterate_mem_addr_combos
	hex_diff have_nasm asm_ok new_writer
	@r64 @r32 @r16 @r8 @r8h @immed64 @immed32 @immed16 @immed8
	unknown unknown8 unknown16 unknown32 unknown64 unknown7 unknown15 unknown31 unknown63
);

my $do_all= $ENV{TEST_EXHAUSTIVE}
	or note "Skipping exhaustive testing, set TEST_EXHAUSTIVE=1 to do a full test";

our @r64= $do_all? (qw( rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15 ))
	: (qw( rax rcx rbx rsp r11 r12 r13 ));
our @r32= $do_all? (qw( eax ecx edx ebx esp ebp esi edi r8d r9d r10d r11d r12d r13d r14d r15d ))
	: (qw( eax ecx esp ebp r8d r12d r13d ));
our @r16= $do_all? (qw( ax cx dx bx sp bp si di r8w r9w r10w r11w r12w r13w r14w r15w ))
	: (qw( ax cx sp bp r8w r12w r13w ));
our @r8 = $do_all? (qw( al cl dl bl spl bpl sil dil r8b r9b r10b r11b r12b r13b r14b r15b ))
	: (qw( al cl spl bpl r8b r12b r13b ));
our @r8h= qw( ah ch dh bh );

our @scale= (1, 2, 4, 8);

our @immed64= $do_all? (0, map { (1 << $_, -1 << $_) } 0..62)
	: (0, 1, -1, 0x7F, -0x80, 0x7FFFFFFF, -0x80000000, 0x7FFFFFFFFFFFFFFF, -0x8000000000000000);
our @immed32= $do_all? (0, map { (1 << $_, -1 << $_) } 0..30)
	: (0, 1, -1, 0x7F, -0x80, 0x7FFFFFFF, -0x80000000, -1);
our @immed16= $do_all? (0, map { (1 << $_, -1 << $_) } 0..14)
	: (0, 1, -1, 0x7F, -0x80, 0x7FFF, -0x8000);
our @immed8=  $do_all? (0, map { (1 << $_, -1 << $_) } 0..6)
	: (0, 1, -1, 0x7F, -0x80);

sub new_writer {
	CPU::x86_64::InstructionWriter->new
}

sub iterate_mem_addr_combos {
	my ($asm, $asm_fn, $out, $out_fn)= @_;
	if ($do_all) {
		for my $rbase (undef, @r64) {
			for my $ofs (0, 1, -1, 0x7FFFFFFF) {
				for my $ridx (undef, grep { $_ ne 'rsp' } @r64) {
					for my $scale ($rbase? (2, 4, 8) : (4, 8)) {
						next unless $rbase or $ofs or $ridx;
						push @$asm, $asm_fn->("["
							. (!defined $rbase? '' : $rbase)
							. (!defined $ofs? '' : $ofs >= 0? "+$ofs" : $ofs)
							. (!defined $ridx? '' : (defined $rbase || defined $ofs? "+":'')."$ridx*$scale")
							."]");
						push @$out, $out_fn->($rbase, $ofs, $ridx, $ridx? $scale : undef);
					}
				}
			}
		}
	} else {
		for my $rbase (undef, 'rax', 'rsp', 'rbp') {
			for my $ofs (0, 1, -1, 0x7FFFFFFF) {
				for my $ridx (undef, 'rax', 'rbp', 'r12') {
					next unless $rbase or $ofs or $ridx;
					push @$asm, $asm_fn->("["
						. (!defined $rbase? '' : $rbase)
						. (!defined $ofs? '' : $ofs >= 0? "+$ofs" : $ofs)
						. (!defined $ridx? '' : (defined $rbase || defined $ofs? "+":'')."$ridx*4")
						."]");
					push @$out, $out_fn->($rbase, $ofs, $ridx, $ridx? 4 : undef);
				}
			}
		}
	}
}

sub which_nasm {
	return $ENV{NASM_PATH} if defined $ENV{NASM_PATH};
	chomp(my $path= `which nasm`);
	$? == 0 or die "Can't locate nasm (tests require nasm unless cached in t/nasm_cache)\nInstall NASM or set environment var \$NASM_PATH\n";
	$path;
}

sub nasm_cache_file {
	my $md5= shift;
	my ($vol, $path, $file)= splitpath(__FILE__);
	$path =~ s,[\\/]$,,; # IMO this is a bug in File::Spec
	my @dirs= splitdir($path);
	$dirs[-1]= 'nasm_cache';
	catpath($vol, catdir(@dirs), $md5);
}

sub asm_ok {
	my ($output, $asm_text, $message)= @_;
	# Run a test as one giant block of asm
	my $reference= eval { reference_assemble(join("\n", @$asm_text)) };
	# Compare it with what we built
	if (defined $reference and join('', @$output) eq $reference) {
		pass $message;
	} else {
		fail $message;
		# Use a binary search to find which instructions failed
		eval { show_bad_instructions($output, $asm_text, 0, $#$output) };
	}
}

sub show_bad_instructions {
	my ($output, $asm_text, $min, $max)= @_;
	if ($max - $min < 8) {
		my $found;
		for ($min..$max) {
			my $out= $output->[$_];
			my $ref= eval { reference_assemble($asm_text->[$_]); };
			if (!defined $ref) {
				my $asm_str= $asm_text->[$_];
				$asm_str =~ s/\n/; /g;
				diag "Can't get reference ASM for $asm_str: $@";
				$found++;
			} elsif ($out ne $ref) {
				diag "$asm_text->[$_] was ".hex_dump($out)." but should be ".hex_dump($ref);
				$found++;
			}
		}
		note "Reference assembler seems to compile individual statements differently than the whole..."
			unless $found;
		note "(and possibly more)"
			if $found;
		die; # quick exit
	}
	else {
		my $mid= int(($min+$max)/2);
		my $out= join('', @{$output}[$min..$mid] );
		my $ref= reference_assemble(join "\n", @{$asm_text}[$min..$mid]);
		show_bad_instructions($output, $asm_text, $min, $mid) unless $out eq $ref;
		$out= join('', @{$output}[($mid+1)..$max] );
		$ref= reference_assemble(join "\n", @{$asm_text}[($mid+1)..$max]);
		show_bad_instructions($output, $asm_text, $mid+1, $max) unless $out eq $ref;
	}
}

sub reference_assemble {
	my $asm_source= shift;
	my $md5= md5_hex($asm_source);
	my $cache_file= nasm_cache_file($md5);
	unless (-f $cache_file) {
		# Can't pipe to nasm, because it tries to mmap the input, or something.
		# So use clumsy temp files.
		my $infile= File::Temp->new(TEMPLATE => 'asm-XXXXXX', SUFFIX => '.asm')
			or die "tmpfile: $!";
		$infile->print("[bits 64]\n".$asm_source);
		$infile->close;
		mkdir nasm_cache_file(undef);
		unless (system(which_nasm, '-o', $cache_file, $infile) == 0) {
			my $e= $?;
			system('cp', $infile, 'died.asm');
			die "nasm: $e (input = died.asm)";
		}
	}
	open my $fh, '<:raw', $cache_file or die "open: $!";
	local $/= undef;
	scalar <$fh>;
}

sub hex_dump {
	join(' ', map { sprintf("%02X", ord($_)) } split //, $_[0]);
}

sub hex_diff {
	my ($data1, $data2)= @_;
	my $o= 0;
	my $ret= '';
	while ($o < length($data1) || $o < length($data2)) {
		my $d1= length $data1 >= $o? substr($data1, $o, 16) : '';
		my $d2= length $data2 >= $o? substr($data2, $o, 16) : '';
		$d1 =~ s/(.)/sprintf("%02x ",ord($1))/gse;
		substr($d1, 24, 0)= ' ' if length $d1 > 24;
		$d2 =~ s/(.)/sprintf("%02x ",ord($1))/gse;
		substr($d2, 24, 0)= ' ' if length $d2 > 24;
		$ret .= sprintf("%-48s |  %-48s%s\n", $d1, $d2, $d1 eq $d2? '':' *');
		$o+= 16;
	}
	return $ret;
}

1;
