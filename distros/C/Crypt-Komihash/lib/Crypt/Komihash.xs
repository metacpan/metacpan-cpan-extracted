#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ctype.h>
#include <string.h>
#include <inttypes.h>
#include "komihash.h"
#include "rdtsc_rand.h"

// Global seeds used for komirand
uint64_t SEED1;
uint64_t SEED2;

bool has_been_seeded = false;

// External function allow setting the seeds
static void komirand_seed(uint64_t seed1, uint64_t seed2) {
	SEED1 = seed1;
	SEED2 = seed2;

	//printf("SEED: %llu / %llu\n", seed1, seed2);

	has_been_seeded = true;
}

static uint64_t komirand64() {
	if (!has_been_seeded) {
		komirand_seed(rdtsc_rand64(), rdtsc_rand64());
	}

	uint64_t ret = komirand(&SEED1, &SEED2);

	return ret;
}

// XS binding
MODULE = Crypt::Komihash   PACKAGE = Crypt::Komihash

UV komihash(SV *input, UV seednum = 0)
	CODE:
		STRLEN len = 0;
		// Take the bytes in input, put the length in len, and get a pointer to the bytes
		// We use SvPVbyte instead of SvPV to handle unicode correctly
		char *buf  = SvPVbyte(input, len);

		RETVAL = (UV)komihash(buf, len, seednum);
	OUTPUT:
		RETVAL

UV komirand64()

void komirand_seed(UV seed1, UV seed2)

UV rdtsc_rand64()

UV get_rdtsc()
