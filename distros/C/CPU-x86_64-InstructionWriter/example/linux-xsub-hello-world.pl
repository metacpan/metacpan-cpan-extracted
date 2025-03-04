use v5.36;
use DynaLoader;
use CPU::x86_64::InstructionWriter;

use constant {
   SYS_mmap        => 9,
   SYS_read        => 0,
   SYS_write       => 1,
   PROT_READ       => 1,
   PROT_WRITE      => 2,
   PROT_EXEC       => 4,
   MAP_PRIVATE     => 2,
   MAP_ANONYMOUS   => 32,
};

# I don't know of a pure-perl way to write to an arbitrary memory location,
# but this works for linux :-)
sub memcpy($dst_addr, $src_sv, $size=length $src_sv) {
	if (-w '/proc/self/mem') {
		open my $mem, '+>', '/proc/self/mem'     or die "open(/dev/mem): $!";
		$mem->sysseek($dst_addr, 0) == $dst_addr or die "sysseek: $!";
		$mem->syswrite($src_sv, $size) == $size  or die "write: $!";
	} else {
		$size < 4096 or die "BUG: needs rewritten with a loop";
		pipe(my $rd, my $wr)                     or die "pipe: $!";
		$wr->syswrite($src_sv, $size) == $size   or die "write: $!";
		syscall(SYS_read, fileno($rd), $dst_addr, $size) == $size or die "read: $!";
	}
}

# Machine code to write "Hello, World!\n" to stdout (descriptor 1)
my %str;
my $msg= "Hello World!\n";
my $jit_code= CPU::x86_64::InstructionWriter->new
   ->mov('rax', SYS_write)->mov('rdi', 1)
   ->lea('rsi', [rip => \$str{$msg}])->mov('rdx',length $msg)
   ->syscall
   ->ret
   ->data_str(\%str)
   ->bytes;

# Allocate executable memory
my $page_size = 4096;
my $addr = syscall(SYS_mmap, 0, $page_size, PROT_READ | PROT_WRITE | PROT_EXEC,
   MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
die "mmap failed: $!" if $addr == -1;

memcpy($addr, $jit_code);

DynaLoader::dl_install_xsub("hello", $addr)->();
