use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use File::Temp qw(tempdir tempfile);
use File::Spec;

my $is_x86 = ($Config{archname} =~ /x86_64|i[3456]86/) ? 1 : 0;

# Global flags (safe for all TUs)
my $ccflags = $Config{ccflags} || '';
$ccflags .= ' -O3 -Wall -Wextra -fPIC -DHEXSIMD_BUILD';
$ccflags .= ' -march=x86-64 -mno-avx -mno-avx2 -mno-avx512f' if $is_x86;

# --- helpers --------------------------------------------------------------

sub env_truthy {
  my ($v) = @_;
  return 0 unless defined $v;
  return 0 if $v eq '' || $v eq '0' || lc($v) eq 'false' || lc($v) eq 'off' || lc($v) eq 'no';
  return 1;
}

sub cpu_has_avx512_bw_vl {
  return 0 unless -r '/proc/cpuinfo';
  open my $fh, '<', '/proc/cpuinfo' or return 0;
  while (my $line = <$fh>) {
    next unless $line =~ /^flags\s*:/;
    my $flags = lc $line;
    if ($flags =~ /\bavx512bw\b/ && $flags =~ /\bavx512vl\b/) {
      close $fh;
      return 1;
    }
  }
  close $fh;
  return 0;
}

sub cc_accepts_flags {
  my ($flags) = @_;
  my ($fh, $src) = tempfile(SUFFIX => '.c', UNLINK => 1);
  print $fh "int main(void){return 0;}\n";
  close $fh;
  my $cc = $Config{cc} || 'cc';
  my ($outfh, $out) = tempfile(UNLINK => 1);
  close $outfh;
  my $cmd = "$cc $flags -o " . File::Spec->rel2abs($out) . " " . File::Spec->rel2abs($src) . " >/dev/null 2>&1";
  my $ok = (system($cmd) == 0) ? 1 : 0;
  unlink $out;
  return $ok;
}

# --- decide AVX-512 enablement -------------------------------------------

my $env = $ENV{HEXSIMD_ENABLE_AVX512};
my $force_on  = env_truthy($env);
my $force_off = (defined($env) && !env_truthy($env));

my $cpu_ok = $is_x86 && cpu_has_avx512_bw_vl();
my $cc_ok  = cc_accepts_flags('-mavx512f -mavx512bw -mavx512vl');

my $enable_avx512 =
    $force_on  ? 1 :
    $force_off ? 0 :
    ($cpu_ok && $cc_ok ? 1 : 0);

# We do NOT add -mavx512* globally. We define the macro so the AVX-512 code is compiled in,
# and rely on per-function pragmas for codegen.
my $extra_src_cflags = '-fvisibility=hidden';
if ($enable_avx512) {
  $ccflags .= ' -DHEXSIMD_ENABLE_AVX512';
  # Optional: also pass -mavx512* ONLY for src/hexsimd.c to help old GCC with intrinsics.
  $extra_src_cflags .= ' -mavx512f -mavx512bw -mavx512vl';
}

WriteMakefile(
  NAME         => 'Data::HexConverter',
  VERSION_FROM => 'lib/Data/HexConverter.pm',
  ABSTRACT     => 'SIMD accelerated hex <-> binary with runtime dispatch',
  AUTHOR       => 'Jared Still',
  LICENSE      => 'perl',
  CCFLAGS      => $ccflags,
  INC          => '-Isrc',
  OBJECT       => 'HexConverter$(OBJ_EXT) src/hexsimd$(OBJ_EXT)',
  clean        => { FILES => 'Data-HexConverter-* *.gcov *.gcda *.gcno' },
  META_MERGE   => { resources => { repository => 'https://metacpan.org/release/Data-HexConverter' } },
);

# Compile src/hexsimd.c with its own cflags (visibility hidden, and conditionally -mavx512*).
sub MY::postamble {
  my $cflags = $extra_src_cflags; # captured from outer scope
  return <<"POST";
src/hexsimd\$(OBJ_EXT): src/hexsimd.c src/hexsimd.h
\t\$(CC) \$(CCFLAGS) $cflags \$(OPTIMIZE) \$(INC) -c src/hexsimd.c -o \$@
POST
}
