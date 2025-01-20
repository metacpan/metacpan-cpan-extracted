#include <stdint.h>

////////////////////////////////////////////////////////////////////////////////
// rdtsc_rand.h: v0.1
//
// https://github.com/scottchiefbaker/rdtsc_rand
////////////////////////////////////////////////////////////////////////////////

#if defined(_WIN32) || defined(_WIN64)
#include <intrin.h>
#pragma intrinsic(__rdtsc)
#endif

uint64_t get_rdtsc() {
#if defined(_WIN32) || defined(_WIN64)
	// Use the __rdtsc intrinsic for Windows
	return __rdtsc();
#elif defined(__GNUC__) || defined(__clang__)
	// Use inline assembly for Linux
	uint32_t low, high;
	__asm__ volatile (
		"rdtsc"
		: "=a"(low), "=d"(high)
	);
	return ((uint64_t)(high) << 32) | low;
#else
	#error "Unsupported platform"
#endif
}

// Borrows and (slightly modified) from
// https://elixir.bootlin.com/linux/v6.11.5/source/include/linux/hash.h
uint64_t hash64(uint64_t val) {
	return (val * 0x61c8864680b583ebull);
}

// Get an unsigned 64bit random integer
uint64_t rdtsc_rand64() {
	// Hash the rdtsc value through hash64
	uint64_t rdtsc_val = get_rdtsc();
	uint64_t ret       = hash64(rdtsc_val);

	return ret;
}
