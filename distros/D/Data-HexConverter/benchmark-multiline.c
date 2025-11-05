
#define _GNU_SOURCE
// gcc -O3 -Wall -Wextra -mno-avx512f -mavx512bw -mavx512vl -L ./src -l:hexsimd.o -o benchmark benchmark.c

#include "hexsimd.h"
#include <time.h>
#include <stdlib.h>   // getenv
#include <strings.h>  // strcasecmp (or use strcmp if you prefer exact case)
#include <string.h>  // for memcpy
#include <stdio.h>
#include <stdint.h>
#include <sys/types.h>
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

int main(int argc, char *argv[]) {

    dump_features(); 

    FILE *file = NULL;
    char *line = NULL;
    size_t line_cap = 0;
    struct stat st;
    uint8_t *bin = NULL;
    size_t bin_capacity = 0;
    char *back = NULL;
    size_t back_capacity = 0;
    size_t line_count = 0;
    double total_elapsed = 0.0;
    int status = EXIT_SUCCESS;

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

    // 3. Open the file
    file = fopen(filename, "rb");
    if (file == NULL) {
        perror("Error opening file");
        return EXIT_FAILURE;
    }

    printf("g_hex2bin_name: %s\n", hexsimd_hex2bin_impl_name());

    while (1) {
        ssize_t read = getline(&line, &line_cap, file);
        if (read == -1) {
            if (feof(file)) {
                break;
            }
            perror("Error reading line");
            status = EXIT_FAILURE;
            goto cleanup;
        }

        size_t line_len = (size_t)read;
        while (line_len > 0 && (line[line_len - 1] == '\n' || line[line_len - 1] == '\r')) {
            line[--line_len] = '\0';
        }
        if (line_len == 0) {
            continue;
        }

        size_t bin_needed = (line_len / 2) + 1;
        size_t back_needed = line_len + 1;

        if (bin_capacity < bin_needed) {
            uint8_t *tmp = realloc(bin, bin_needed);
            if (tmp == NULL) {
                perror("Error allocating bin buffer");
                status = EXIT_FAILURE;
                goto cleanup;
            }
            bin = tmp;
            bin_capacity = bin_needed;
        }

        if (back_capacity < back_needed) {
            char *tmp = realloc(back, back_needed);
            if (tmp == NULL) {
                perror("Error allocating back buffer");
                status = EXIT_FAILURE;
                goto cleanup;
            }
            back = tmp;
            back_capacity = back_needed;
        }

        struct timespec before, after;
        if (clock_gettime(CLOCK_MONOTONIC, &before) != 0) {
            perror("clock_gettime");
            status = EXIT_FAILURE;
            goto cleanup;
        }

        ptrdiff_t n = hex_to_bytes(line, line_len, bin, true);

        if (clock_gettime(CLOCK_MONOTONIC, &after) != 0) {
            perror("clock_gettime");
            status = EXIT_FAILURE;
            goto cleanup;
        }

        double delta = (after.tv_sec - before.tv_sec) +
                       (after.tv_nsec - before.tv_nsec) / 1.0e9;
        total_elapsed += delta;

        if (n < 0) {
            fprintf(stderr, "hex_to_bytes failed on line %zu\n", line_count + 1);
            status = EXIT_FAILURE;
            goto cleanup;
        }

        ptrdiff_t m = bytes_to_hex(bin, (size_t)n, back);
        back[m] = '\0';

        if (strcmp(line, back) != 0) {
            fprintf(stderr, "Round-trip mismatch on line %zu\n", line_count + 1);
            status = EXIT_FAILURE;
            goto cleanup;
        }

        line_count++;
    }

    printf("Processed %zu lines from %s\n", line_count, filename);
    printf("Total hex->bin time: %.6f seconds\n", total_elapsed);
    if (line_count > 0) {
        printf("Average per line: %.9f seconds\n", total_elapsed / line_count);
    }

cleanup:
    free(line);
    free(bin);
    free(back);
    if (file) fclose(file);
    return status;
}

