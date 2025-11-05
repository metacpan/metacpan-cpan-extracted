
// gcc -O3 -Wall -Wextra -mno-avx512f -mavx512bw -mavx512vl -L ./src -l:hexsimd.o -o benchmark benchmark.c

#include "hexsimd.h"
#include <time.h>
#include <stdlib.h>   // getenv
#include <strings.h>  // strcasecmp (or use strcmp if you prefer exact case)
#include <string.h>  // for memcpy
#include <stdio.h>
#include <stdint.h>
#include <sys/stat.h> // For stat()


#if defined(_MSC_VER)
  #include <intrin.h>
#else
  #include <immintrin.h>
#endif

/* decide once. at compile time. whether AVX512 code exists in this file */
#if (defined(__AVX512BW__) && defined(__AVX512VL__)) || defined(HEXSIMD_ENABLE_AVX512)
#  define HEXSIMD_HAVE_AVX512 1
#else
#  define HEXSIMD_HAVE_AVX512 0
#endif

// -------------------------
// CPUID / XGETBV helpers
// -------------------------
static void cpuid_x86(unsigned leaf, unsigned subleaf, unsigned regs[4]) {
#if defined(_MSC_VER)
    int cpuInfo[4];
    __cpuidex(cpuInfo, (int)leaf, (int)subleaf);
    regs[0]=(unsigned)cpuInfo[0]; regs[1]=(unsigned)cpuInfo[1];
    regs[2]=(unsigned)cpuInfo[2]; regs[3]=(unsigned)cpuInfo[3];
#else
    unsigned a,b,c,d;
    __asm__ volatile("cpuid" : "=a"(a), "=b"(b), "=c"(c), "=d"(d)
                               : "a"(leaf), "c"(subleaf));
    regs[0]=a; regs[1]=b; regs[2]=c; regs[3]=d;
#endif
}

static unsigned long long xgetbv_x86(unsigned idx) {
#if defined(_MSC_VER)
    return _xgetbv(idx);
#else
    unsigned eax, edx;
    __asm__ volatile (".byte 0x0f, 0x01, 0xd0" : "=a"(eax), "=d"(edx) : "c"(idx));
    return ((unsigned long long)edx << 32) | eax;
#endif
}

typedef struct {
    int sse2, avx, avx2, avx512bw, avx512vl;
} isa_t;

static isa_t detect_isa_runtime(void) {
    isa_t f = {0};
    unsigned r[4] = {0};
    cpuid_x86(1,0,r);
    int osxsave = (r[2] & (1u<<27)) != 0;
    f.sse2 = (r[3] & (1u<<26)) != 0;

    if (osxsave) {
        unsigned long long xcr0 = xgetbv_x86(0);
        int os_avx = ((xcr0 & 0x6) == 0x6);
        if (os_avx && (r[2] & (1u<<28))) f.avx = 1;

        cpuid_x86(7,0,r);
        if (f.avx) f.avx2 = (r[1] & (1u<<5)) != 0;

        int os_avx512 = ((xcr0 & 0xE0) == 0xE0);
        if (os_avx512) {
            f.avx512bw = (r[1] & (1u<<30)) != 0;
            f.avx512vl = (r[1] & (1u<<31)) != 0;
        }
    }
    return f;
}

//
// -------------------------
// Optional micro-test
// -------------------------
extern const char* hexsimd_hex2bin_impl_name(void);

static void dump_features(void){
    isa_t f = detect_isa_runtime();
    printf("ISA: sse2=%d avx=%d avx2=%d avx512bw=%d avx512vl=%d\n",
           f.sse2, f.avx, f.avx2, f.avx512bw, f.avx512vl);
}

int NUMTESTS=1000;

int main(int argc, char *argv[]) {

    dump_features(); 

    struct timespec before, after;
    double elapsed;

    FILE *file = NULL;
    char *buffer = NULL;
    size_t file_size;
    struct stat st;

    // 1. Check for filename argument
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *filename = argv[1];

    // 2. Validate the file and get its size
    if (stat(filename, &st) == -1) {
        perror("Error getting file status");
        return EXIT_FAILURE;
    }

    if (!S_ISREG(st.st_mode)) {
        fprintf(stderr, "Error: '%s' is not a regular file.\n", filename);
        return EXIT_FAILURE;
    }

    file_size = st.st_size;

    // 3. Open the file
    file = fopen(filename, "rb"); // "rb" for read binary mode
    if (file == NULL) {
        perror("Error opening file");
        return EXIT_FAILURE;
    }


    // 4. Allocate buffer and read contents
    buffer = (char *)malloc(file_size + 1); // +1 for null terminator
    if (buffer == NULL) {
        perror("Error allocating memory");
        fclose(file);
        return EXIT_FAILURE;
    }

    size_t bytes_read = fread(buffer, 1, file_size, file);

    if (bytes_read != file_size) {
        fprintf(stderr, "Error reading file: expected %ld bytes, got %zu bytes.\n", file_size, bytes_read);
        free(buffer);
        fclose(file);
        return EXIT_FAILURE;
    }

    printf( "file size: %ld bytes, bytes read: %zu \n", file_size, bytes_read);
    // subtract 1 as the text file has a line ending character on linux
    buffer[file_size-1] = '\0'; // Null-terminate the buffer
    fclose(file);

    size_t buffer_len = strlen(buffer);
    size_t BIN_LEN = buffer_len + 1;
    uint8_t *bin = malloc(BIN_LEN);
    char *back = malloc( (BIN_LEN * 2) +1);
    memset(back, 0x5A, BIN_LEN * 2);
		   
    ptrdiff_t n = hex_to_bytes(buffer, buffer_len, bin, true);
    ptrdiff_t m = bytes_to_hex(bin, (size_t)n, back);
    back[m] = 0;
    puts(hexsimd_hex2bin_impl_name());

    int match = strcmp(buffer,back);

    if (match == 0 ){
        //puts(back);
	printf("OK\n");
	;
    } else {
	printf("match: %d\n", match);
	fprintf(stderr,"Source: %s\n",buffer);
        fprintf(stderr,"  Dest: %s\n",back);
        printf("Error! Src and Dest do not match\n");
	return 1;
    }

    clock_gettime(CLOCK_MONOTONIC, &before);
    for (int i=0; i < NUMTESTS; i++ ) {
       n = hex_to_bytes(buffer, buffer_len, bin, true);
       if (n < 0) { puts("parse failed"); return 1; }
    }
    clock_gettime(CLOCK_MONOTONIC, &after);
    elapsed = difftime(after.tv_sec, before.tv_sec) + (after.tv_nsec - before.tv_nsec)/1.0e9;
    printf("optimized lookup %s took %3.6f seconds for %d tests, avg: %2.9f\n", hexsimd_hex2bin_impl_name(), elapsed, NUMTESTS, elapsed/NUMTESTS);
    printf("g_hex2bin_name: %s\n",hexsimd_hex2bin_impl_name());

    free(buffer);
    return 0;
}

