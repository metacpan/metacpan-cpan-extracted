use strict;
use warnings;

load_extension('Dist::Build::XS');
load_extension('Dist::Build::XS::Conf');

my @sources = map { "src/$_.c" } qw{argon2 core encoding thread blake2/blake2b switch};

sub add_source {
	my ($name, $input_base, @flags) = @_;
	push @sources, {
		source  => "src/$input_base.c",
		object  => "src/$name.o",
		flags   => \@flags,
		defines => { fill_segment => "fill_segment_$name" },
	};
}

sub try_optimized {
	my ($name, $flag, $code) = @_;
	my $can_build = try_compile_run(source => $code, define => "HAVE_\U$name", extra_compiler_flags => [ $flag ]);
	add_source($name, 'opt', $flag) if $can_build;
}

add_source('ref', 'ref');

my $has_sse3 = try_optimized('sse3', '-msse3', <<'EOF');
#include <immintrin.h>
int main () {
    __m128i input, output;
	if (__builtin_cpu_supports("sse3"))
		output = _mm_loadu_si128(&input);
}
EOF

if ($has_sse3) {
	try_optimized('avx2', '-march=haswell', <<'EOF');
#include <immintrin.h>
int main () {
	__m256i input, output;
	if (__builtin_cpu_supports("avx2"))
		output = _mm256_loadu_si256(&input);
}
EOF

	try_optimized('avx512', '-march=skylake-avx512', <<'EOF');
#include <immintrin.h>
int main () {
	__m512i input, output;
	if (__builtin_cpu_supports("avx512f"))
		output = _mm512_loadu_si512(&input);
}
EOF

	try_compile_run(source => <<'EOF', define => 'HAVE_IFUNC');
#include <stddef.h>

void fill_segment_sse3(const int *instance, size_t position) {
}
void fill_segment_ref(const int *instance, size_t position) {
}

static void (*resolve_fill_segment(void))(const int *instance, size_t position) {
	__builtin_cpu_init();
	if (__builtin_cpu_supports("sse3"))
		return fill_segment_sse3;
	else
	return fill_segment_ref;
}

void fill_segment(const int *instance, size_t position) __attribute__ ((ifunc ("resolve_fill_segment")));

int main() {
	fill_segment(NULL, 0);
	return 0;
}
EOF
}

if (is_os_type('Unix')) {
	push_extra_compiler_flags('-pthread');
	push_extra_linker_flags('-pthread');
}

add_xs(
	include_dirs         => [ 'include' ],
	extra_sources        => \@sources,
);
