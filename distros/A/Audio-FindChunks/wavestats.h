typedef struct {
    double sum_square;
    double sum;
    long min;
    long max;
} array_stats_t;

void le_short_sample_stats(char *buf, int stride, long samples, array_stats_t *stat);
void double_median3(double *rmsarray, double *medarray, long total_blocks);
void double_sort(double *input, double *output, long cnt);
void double_find_above(double *input, int *output, long cnt, double threshold);
double double_sum(double *input, long off, long cnt);
void int_find_above(int *input, int *output, long cnt, int threshold);
void int_sum_window(int *input, int *output, long cnt, int window_size);

typedef struct {
    long val;
    long start;
    long len;
} array_run_t;

long bool_find_runs(int *input, array_run_t *output, long cnt, long out_cnt);

#if !defined(WAVESTATS_DEBUG)
#  define WAVESTATS_DEBUG 0
#endif				/* Avoid a warning */
