#include "intspan.h"

// codes from http://stackoverflow.com/questions/1861294
#ifdef WIN32

#include <windows.h>
double get_time() {
    LARGE_INTEGER t, f;
    QueryPerformanceCounter(&t);
    QueryPerformanceFrequency(&f);
    return (double)t.QuadPart / (double)f.QuadPart;
}

#else

#include <sys/time.h>
#include <sys/resource.h>

double get_time() {
    struct timeval t;
    struct timezone tzp;
    gettimeofday(&t, &tzp);
    return t.tv_sec + t.tv_usec * 1e-6;
}

#endif

void intspan_basic_info(intspan *this_intspan) {
    int len = 1024;
    char *runlist = malloc(len + 1); /* + 1 for NULL */

    printf("edge size %d, edge capacity %d\n", intspan_edge_size(this_intspan),
           intspan_edge_capacity(this_intspan));
    printf("is_empty %d, cardinality %d\n", intspan_is_empty(this_intspan),
           intspan_cardinality(this_intspan));
    printf("span size %d\n", intspan_span_size(this_intspan));

    intspan_as_string(this_intspan, &runlist, len);
    printf("runlist %s\n", runlist);
    printf("\n");
    free(runlist);
}

void print_vec(veci *vec) {
    int i, j;
    for (i = 0; i < veci_size(vec); i++) {
        j = veci_get(vec, i);
        printf("%d ", j);
    }
    printf("\n");
}

void print_intspan_asvec(intspan *this_intspan) {
    veci *vec = intspan_as_veci(this_intspan);
    print_vec(vec);
    veci_destroy(vec);
}

void test_add_range(int step) {
    veci *vec1 = veci_create(64);
    veci *vec2 = veci_create(64);

    int i, j, len = 1045;
    char *runlist;
    int ary[] = {1,   30,  32,  149, 153, 155, 159, 247, 250, 250, 253,
                 464, 516, 518, 520, 523, 582, 585, 595, 600, 622, 1679};
    for (i = 0; i < 22; i++) {
        veci_add(vec1, ary[i]);
    }
    veci_add(vec2, 100);
    veci_add(vec2, 1000000);

    for (i = 1; i <= 50000; i++) {
        intspan *this_intspan = intspan_new();

        if (step >= 2) {
            intspan_add_range(this_intspan, vec1);
        }
        if (step >= 3) {
            intspan_add_range(this_intspan, vec2);
        }
        if (step >= 4) {
            runlist = malloc(len + 1);
            intspan_as_string(this_intspan, &runlist, len);
            free(runlist);
        }

        if (step >= 5) {
            for (j = 1; j <= 200; j++) {
                intspan_add(this_intspan, j);
            }
        }

        if (step >= 6) {
            for (j = 1; j <= 100; j++) {
                veci *vec3 = veci_create(64);
                veci_add(vec3, j * 5);
                veci_add(vec3, j * 10);
                intspan_add_range(this_intspan, vec3);
                veci_destroy(vec3);
            }
        }

        intspan_destroy(this_intspan);
    }

    veci_destroy(vec1);
    veci_destroy(vec2);
}

void test_add_vec(int step) {
    veci *vec1 = veci_create(10);

    intspan *test_intspan;
    char *runlist;
    int i, j, len = 1024;

    for (i = 1; i <= 30; i++) {
        veci_add(vec1, i);
    }
    for (i = 32; i <= 149; i++) {
        veci_add(vec1, i);
    }
    for (i = 32; i <= 149; i++) {
        veci_add(vec1, i);
    }
    for (i = 153; i <= 155; i++) {
        veci_add(vec1, i);
    }
    for (i = 159; i <= 247; i++) {
        veci_add(vec1, i);
    }
    veci_add(vec1, 250);
    for (i = 253; i <= 464; i++) {
        veci_add(vec1, i);
    }
    for (i = 516; i <= 518; i++) {
        veci_add(vec1, i);
    }
    for (i = 520; i <= 523; i++) {
        veci_add(vec1, i);
    }
    for (i = 582; i <= 585; i++) {
        veci_add(vec1, i);
    }
    for (i = 595; i <= 600; i++) {
        veci_add(vec1, i);
    }
    for (i = 622; i <= 1679; i++) {
        veci_add(vec1, i);
    }

    for (j = 1; j <= 50000; j++) {

        if (step >= 1) {
            test_intspan = intspan_new();
        }
        if (step >= 2) {
            intspan_add_vec(test_intspan, vec1);
        }
        if (step >= 3) {
            intspan_add_pair(test_intspan, 100, 1000000);
        }
        if (step > 4) {
            runlist = malloc(len + 1);
            intspan_as_string(test_intspan, &runlist, len);
            free(runlist);
        }

        intspan_destroy(test_intspan);
    }

    veci_destroy(vec1);
}

int run_test() {
    intspan *this_intspan = intspan_new();
    intspan_basic_info(this_intspan);

    intspan_add_pair(this_intspan, 1, 9);
    intspan_add_pair(this_intspan, 20, 39);
    intspan_basic_info(this_intspan);
    print_intspan_asvec(this_intspan);
    printf("val %d pos %d contain %d\n", -5,
           intspan_find_pos(this_intspan, -5, 0),
           intspan_contains(this_intspan, -5));
    printf("val %d pos %d contain %d\n", 29,
           intspan_find_pos(this_intspan, 29, 0),
           intspan_contains(this_intspan, 29));
    printf("val %d pos %d contain %d\n", 100,
           intspan_find_pos(this_intspan, 100, 0),
           intspan_contains(this_intspan, 100));

    veci *vec = veci_create(64);
    veci_add(vec, 5);
    veci_add(vec, 30);
    printf("contains_all %d\n", intspan_contains_all(this_intspan, vec));
    printf("contains_any %d\n", intspan_contains_any(this_intspan, vec));
    veci_add(vec, -5);
    printf("contains_all %d\n", intspan_contains_all(this_intspan, vec));
    printf("contains_any %d\n", intspan_contains_any(this_intspan, vec));

    print_vec(vec);
    veci *ranges = veci_to_range(vec);
    print_vec(ranges);

    veci_clear(vec);
    veci_add(vec, 60);
    veci_add(vec, 70);
    veci_add(vec, 80);
    veci_add(vec, 90);
    print_vec(vec);
    intspan_add_range(this_intspan, vec);
    intspan_basic_info(this_intspan);

    veci_clear(vec);
    veci_add(vec, 68);
    veci_add(vec, 75);
    print_vec(vec);
    intspan_add_range(this_intspan, vec);
    intspan_basic_info(this_intspan);

    intspan_add(this_intspan, 99);
    intspan_basic_info(this_intspan);

    veci_clear(vec);
    veci_add(vec, 77);
    veci_add(vec, 79);
    print_vec(vec);
    intspan_add_vec(this_intspan, vec);
    intspan_basic_info(this_intspan);

    intspan_invert(this_intspan);
    intspan_basic_info(this_intspan);
    intspan_invert(this_intspan);
    intspan_basic_info(this_intspan);

    veci_clear(vec);
    veci_add(vec, 66);
    veci_add(vec, 71);
    print_vec(vec);
    intspan_remove_range(this_intspan, vec);
    intspan_basic_info(this_intspan);

    intspan_remove(this_intspan, 85);
    intspan_basic_info(this_intspan);

    veci_clear(vec);
    veci_add(vec, 87);
    veci_add(vec, 88);
    print_vec(vec);
    intspan_remove_vec(this_intspan, vec);
    intspan_basic_info(this_intspan);

    vec = runlist_to_range("-");
    print_vec(vec);

    vec = runlist_to_range("1-10,15,20-31");
    print_vec(vec);

    vec = runlist_to_range("-50--10,1-10,15,20-31");
    print_vec(vec);

    intspan_add_runlist(this_intspan, "-30--10");
    intspan_basic_info(this_intspan);

    intspan_remove_runlist(this_intspan, "62-78");
    intspan_basic_info(this_intspan);

    intspan *supplied = intspan_new();
    intspan_add_runlist(supplied, "-15-5");
    intspan_merge(this_intspan, supplied);
    intspan_basic_info(this_intspan);

    intspan_clear(supplied);
    intspan_add_runlist(supplied, "-20--5");
    intspan_subtract(this_intspan, supplied);
    intspan_basic_info(this_intspan);

    intspan_clear(supplied);
    intspan_add_pair(supplied, NEG_INF, 1);
    intspan_basic_info(supplied);
    printf("is_nef_inf %d is_pos_inf %d\n", intspan_is_neg_inf(supplied),
           intspan_is_pos_inf(supplied));
    printf("is_inf %d is_fin %d\n", intspan_is_infinite(supplied),
           intspan_is_finite(supplied));

    intspan_clear(supplied);
    intspan_add_pair(supplied, 1, POS_INF - 1);
    intspan_basic_info(supplied);
    printf("is_nef_inf %d is_pos_inf %d\n", intspan_is_neg_inf(supplied),
           intspan_is_pos_inf(supplied));
    printf("is_inf %d is_fin %d\n", intspan_is_infinite(supplied),
           intspan_is_finite(supplied));

    intspan_clear(supplied);
    intspan_add_pair(supplied, NEG_INF, POS_INF - 1);
    intspan_basic_info(supplied);
    printf("is_nef_inf %d is_pos_inf %d\n", intspan_is_neg_inf(supplied),
           intspan_is_pos_inf(supplied));
    printf("is_inf %d is_fin %d\n", intspan_is_infinite(supplied),
           intspan_is_finite(supplied));
    printf("is_universal %d\n", intspan_is_universal(supplied));

    intspan_destroy(this_intspan);
    intspan_destroy(supplied);
    veci_destroy(vec);

    return 0;
}

int run_benchmark() {
    double start, end;
    int i;

    printf("\n test_add_range\n");
    for (i = 2; i <= 6; i++) {
        printf("step %d\n", i);
        start = get_time();
        test_add_range(i);
        end = get_time();
        printf("duration %f\n", end - start);
    }

    printf("\n test_add_vec\n");
    for (i = 2; i <= 5; i++) {
        printf("step %d\n", i);
        start = get_time();
        test_add_vec(i);
        end = get_time();
        printf("duration %f\n", end - start);
    }

    return 0;
}

void read_file(char **str, char *filename, size_t len) {
    FILE *fp;
    int buf_size = 512;
    char buf[buf_size];
    fp = fopen(filename, "rt");
    if (!fp) {
        fprintf(stderr, "can't open %s\n", filename);
        exit(1);
    }

    while (fgets(buf, buf_size, fp) != NULL) {
        if (len - strlen(*str) < buf_size) {
            len = strlen(*str) + buf_size + 1;
            kroundup32(len);
            *str = (char *) realloc(*str, len);
        }
        strncat(*str, buf, buf_size);
    }
    fclose(fp);
}

int run_file() {
    size_t len = 1024 * sizeof(char);
    char *runlist1 = (char *) malloc(len);
    char *runlist2 = (char *) malloc(len);

    read_file(&runlist1, "r1.yml", len);
    printf("%ld\n", strlen(runlist1));
    printf("%s", runlist1);

    free(runlist1);
    free(runlist2);

    return 0;
}

static int usage() {
    fprintf(stderr, "\n"
            "Usage:     test_c test\n"
            "           test_c benchmark\n"
            "           test_c file\n"
    );
    return 1;
}

int main(int argc, char *argv[]) {
    if (argc == 1) return usage();

    if (strcmp(argv[1], "test") == 0)
        run_test();
    else if (strcmp(argv[1], "benchmark") == 0)
        run_benchmark();
    else if (strcmp(argv[1], "file") == 0)
        run_file();
    else {
        fprintf(stderr, "unrecognized commad '%s'. Abort!\n", argv[1]);
        return 1;
    }
    return 0;
}
