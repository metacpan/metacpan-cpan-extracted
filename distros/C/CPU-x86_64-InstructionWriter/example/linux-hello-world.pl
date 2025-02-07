use v5.36;
use ELF::Writer::Linux_x86_64;
use CPU::x86_64::InstructionWriter ':registers';

my %str;
my $program= CPU::x86_64::InstructionWriter->new
   # write(1, "Hello World\n", 12)
   ->mov(RAX, 1)->mov(RDI, 1)
	->lea(RSI, [RIP => \$str{"Hello World\n"}])->mov(RDX, 12)->syscall
   # exit(0)
   ->mov(RAX, 60)->mov(RDI, 0)->syscall
	# ought to be in a data segment, but this is convenient
   ->data_str(\%str)
	->bytes;

my $elf= ELF::Writer::Linux_x86_64->new(type => 'executable');
my $prog_ofs= $elf->elf_header_len + $elf->segment_header_elem_len;
my $seg_addr= 0x10000;
push $elf->segments->@*, ELF::Writer::Segment->new({
   offset => 0,
   virt_addr => $seg_addr,
   data_start => $prog_ofs,
   data => $program,
});
$elf->entry_point($seg_addr + $prog_ofs);
$elf->write_file("hello");
exec "./hello";