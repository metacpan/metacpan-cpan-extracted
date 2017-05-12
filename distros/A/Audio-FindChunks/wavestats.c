#include <stdlib.h>
#include <wavestats.h>

void
le_short_sample_stats(char *buf, int stride, long samples, array_stats_t *stat)
{
    long i = 0;
#if WAVESTATS_DEBUG
    char *ibuf = buf;
#endif
    while (++i <= samples) {
	short elt;

	buf += stride;
#if NATIVE_LE_SHORTS
#  define NAT 1
	elt = *(short*)(void*)buf;	/* Avoid a warning about change of alignment */
#else
#  define NAT 0
	{
	    unsigned int u = *(unsigned char*)buf;
	    u += (*(unsigned char*)(buf+1))<<8;
	    if (u >= 0x8000)
		elt = u - 0x10000;
	    else
		elt = u;
	}
#endif
#if WAVESTATS_DEBUG
	if (elt > 40 && buf >= ibuf + 4) {
	    char b[512];
	    sprintf(b, "@%#lx: %d, NAT=%d; %#x %#x %#x %#x | %#x %#x %#x %#x\n",
		    (long)(buf - ibuf), (int)elt, NAT,
		    (int)buf[-4], (int)buf[-3], (int)buf[-2], (int)buf[-1],
		    (int)buf[0], (int)buf[1], (int)buf[2], (int)buf[3]);
	    write(2,b,strlen(b));
	}
#endif
	if (elt < stat->min)
	    stat->min = elt;
	if (elt > stat->max)
	    stat->max = elt;
	stat->sum += elt;
	stat->sum_square += elt*elt;
    }
}

void
double_median3(double *rmsarray, double *medarray, long total_blocks)
{
    long l;

    /* A more or less optimized version of a median computation... */
    for (l = 1; l < total_blocks - 1; l++) {
	int up = (rmsarray[l - 1] < rmsarray[l]);

	if (up == (rmsarray[l] < rmsarray[l + 1])) {	/* A < B < C or A >= B >= C */
	    medarray[l] = rmsarray[l];	/* Not a peak */
	} else {	/* A < B >= C or A >= B < C */
	    int right = (up == (rmsarray[l - 1] < rmsarray[l + 1]));
			/* True  if A < C <= B or A >= C > B */
			/* False if C <= A < B or C > A >= B */
	    medarray[l] = rmsarray[l - 1 + 2*right];
	}
    }
    if (total_blocks < 3) {
	medarray[0] = rmsarray[0];
	medarray[total_blocks - 1] = rmsarray[total_blocks - 1];
    } else {				/* Use shifted medians... */
	medarray[0] = medarray[1];
	medarray[total_blocks - 1] = medarray[total_blocks - 2];
    }
}

static int
double_compare(const void *in1, const void *in2)
{
    double d1 = *(const double *)in1, d2 = *(const double *)in2;

    if (d1 < d2)
	return -1;
    if (d1 > d2)
	return 1;
    return 0;
}

void
double_sort(double *input, double *output, long cnt)
{
    if (input) {
	long l;

	for (l = 0; l < cnt; l++)	/* Fill arrays */
	    output[l] = input[l];
    }

    qsort((void*)output, cnt, sizeof(double), &double_compare);
}

void
double_find_above(double *input, int *output, long cnt, double threshold)
{
    long l;

    for (l = 0; l < cnt; l++)
	output[l] = (input[l] >= threshold);
}

double
double_sum(double *input, long off, long cnt)
{
    long l, end = off + cnt;
    double total = 0;

    for (l = off; l < end; l++)
	total += input[l];
    return total;
}

void
int_find_above(int *input, int *output, long cnt, int threshold)
{
    long l;

    for (l = 0; l < cnt; l++)
	output[l] = (input[l] > threshold);
}

void
int_sum_window(int *input, int *output, long cnt, int window_size)
{
    long l, window_start, window_end, win_pre = window_size/2;
    long win_post = window_size - win_pre - 1;

    for (l = 0; l < cnt; l++) {
	window_start = (l - win_pre) * (l >= win_pre);
	window_end = l + win_post;
	if (window_end >= cnt)
	    window_end = cnt - 1;
	
	output[l] = 0;
	while (window_start <= window_end)
	    output[l] += input[window_start++];
    }
}

long
bool_find_runs(int *input, array_run_t *output, long cnt, long out_cnt)
{
    long l = 0;
    long cur_run = 0;
    long cur_val;

    if (out_cnt < 1)
	return -1;
    if (cnt <= 0)
	return 0;
    cur_val = input[0];
    output[cur_run].val = cur_val;
    output[cur_run].start = 0;

    while (++l < cnt) {
	if (input[l] == cur_val)
	    continue;
	output[cur_run].len = l - output[cur_run].start;
	cur_val = input[l];
	if (++cur_run >= out_cnt)
	    return -1;
	output[cur_run].start = l;
	output[cur_run].val = cur_val;
    }
    output[cur_run].len = l - output[cur_run].start;
    return cur_run + 1;
}
