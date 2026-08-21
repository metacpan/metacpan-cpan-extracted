#include "cli_common.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <unistd.h>

static void print_stats_usage(FILE *out) {
    if (!out) out = stdout;
    fprintf(out, "Usage: histo-stats [OPTIONS] [HISTOGRAM_FILE...]\n");
    fprintf(out, "       histo stats [OPTIONS] [HISTOGRAM_FILE...]\n\n");
    fprintf(out, "Displays comprehensive statistical summary, moments, and robust metrics.\n\n");
    fprintf(out, "Options:\n");
    fprintf(out, "  -f, --format=<FMT>       Output format: table (default), json, tsv\n");
    fprintf(out, "  -a, --all                Compute all extended higher moments and peak metrics\n");
    fprintf(out, "  -h, --help               Show this help message\n");
}

static void print_histogram_stats(const histo_t *h, const char *fmt, FILE *out) {
    if (!h) return;
    if (!out) out = stdout;

    double total_w = histo_total_weight(h);
    uint64_t n_entries = histo_num_entries(h);
    uint32_t nbins = histo_nbins(h);
    double range_min = 0.0, range_max = 0.0;
    histo_range(h, &range_min, &range_max);

    double mean = 0.0, var = 0.0, sdev = 0.0;
    double skew = 0.0, kurt = 0.0, ex_kurt = 0.0;
    double q05 = 0.0, q25 = 0.0, median = 0.0, q75 = 0.0, q95 = 0.0, iqr = 0.0, mad = 0.0;
    double t_mean = 0.0, w_mean = 0.0;
    uint32_t mode_bin = 0;
    double mode_cont = 0.0, fwhm = 0.0, rms = 0.0;

    if (total_w > 0.0) {
        histo_mean(h, &mean);
        histo_variance(h, &var);
        histo_std_dev(h, &sdev);
        histo_skewness(h, &skew);
        histo_kurtosis(h, &kurt);
        histo_excess_kurtosis(h, &ex_kurt);

        histo_quantile(h, 0.05, &q05);
        histo_quantile(h, 0.25, &q25);
        histo_median(h, &median);
        histo_quantile(h, 0.75, &q75);
        histo_quantile(h, 0.95, &q95);
        histo_iqr(h, &iqr);
        histo_mad(h, &mad);
        histo_trimmed_mean(h, 0.05, 0.95, &t_mean);
        histo_winsorized_mean(h, 0.05, 0.95, &w_mean);

        histo_mode_bin(h, &mode_bin);
        histo_mode_continuous(h, &mode_cont);
        histo_fwhm(h, &fwhm);
        histo_rms(h, &rms);
    }

    if (strcmp(fmt, "json") == 0) {
        fprintf(out, "{\n");
        fprintf(out, "  \"nbins\": %u,\n", nbins);
        fprintf(out, "  \"min\": %.8g,\n", range_min);
        fprintf(out, "  \"max\": %.8g,\n", range_max);
        fprintf(out, "  \"entries\": %llu,\n", (unsigned long long)n_entries);
        fprintf(out, "  \"total_weight\": %.8g,\n", total_w);
        fprintf(out, "  \"underflow\": %.8g,\n", histo_underflow(h));
        fprintf(out, "  \"overflow\": %.8g,\n", histo_overflow(h));
        fprintf(out, "  \"nan_count\": %llu,\n", (unsigned long long)histo_nan_count(h));
        fprintf(out, "  \"mean\": %.8g,\n", mean);
        fprintf(out, "  \"variance\": %.8g,\n", var);
        fprintf(out, "  \"std_dev\": %.8g,\n", sdev);
        fprintf(out, "  \"skewness\": %.8g,\n", skew);
        fprintf(out, "  \"kurtosis\": %.8g,\n", kurt);
        fprintf(out, "  \"excess_kurtosis\": %.8g,\n", ex_kurt);
        fprintf(out, "  \"median\": %.8g,\n", median);
        fprintf(out, "  \"q25\": %.8g,\n", q25);
        fprintf(out, "  \"q75\": %.8g,\n", q75);
        fprintf(out, "  \"iqr\": %.8g,\n", iqr);
        fprintf(out, "  \"mad\": %.8g,\n", mad);
        fprintf(out, "  \"trimmed_mean\": %.8g,\n", t_mean);
        fprintf(out, "  \"winsorized_mean\": %.8g,\n", w_mean);
        fprintf(out, "  \"mode_bin\": %u,\n", mode_bin);
        fprintf(out, "  \"mode_continuous\": %.8g,\n", mode_cont);
        fprintf(out, "  \"fwhm\": %.8g,\n", fwhm);
        fprintf(out, "  \"rms\": %.8g\n", rms);
        fprintf(out, "}\n");
    } else if (strcmp(fmt, "tsv") == 0) {
        fprintf(out, "metric\tvalue\n");
        fprintf(out, "nbins\t%u\n", nbins);
        fprintf(out, "min\t%.8g\n", range_min);
        fprintf(out, "max\t%.8g\n", range_max);
        fprintf(out, "entries\t%llu\n", (unsigned long long)n_entries);
        fprintf(out, "total_weight\t%.8g\n", total_w);
        fprintf(out, "mean\t%.8g\n", mean);
        fprintf(out, "variance\t%.8g\n", var);
        fprintf(out, "std_dev\t%.8g\n", sdev);
        fprintf(out, "skewness\t%.8g\n", skew);
        fprintf(out, "kurtosis\t%.8g\n", kurt);
        fprintf(out, "excess_kurtosis\t%.8g\n", ex_kurt);
        fprintf(out, "median\t%.8g\n", median);
        fprintf(out, "iqr\t%.8g\n", iqr);
        fprintf(out, "mad\t%.8g\n", mad);
        fprintf(out, "fwhm\t%.8g\n", fwhm);
        fprintf(out, "rms\t%.8g\n", rms);
    } else {
        fprintf(out, "===============================================================\n");
        fprintf(out, " HISTOGRAM SUMMARY STATISTICS\n");
        fprintf(out, "===============================================================\n");
        fprintf(out, "  Total Entries:    %llu\n", (unsigned long long)n_entries);
        fprintf(out, "  Total Weight:     %.6g\n", total_w);
        fprintf(out, "  Underflow Weight: %.6g\n", histo_underflow(h));
        fprintf(out, "  Overflow Weight:  %.6g\n", histo_overflow(h));
        fprintf(out, "  Rejected NaNs:    %llu\n", (unsigned long long)histo_nan_count(h));
        fprintf(out, "  Number of Bins:   %u\n", nbins);
        fprintf(out, "  Range:            [%.6g, %.6g]\n", range_min, range_max);
        fprintf(out, "---------------------------------------------------------------\n");
        fprintf(out, "  Moments & Central Tendency:\n");
        fprintf(out, "   Mean:            %-12.6g Std Dev:          %.6g\n", mean, sdev);
        fprintf(out, "   Variance:        %-12.6g RMS:              %.6g\n", var, rms);
        fprintf(out, "   Skewness:        %-12.6g Kurtosis:         %.6g\n", skew, kurt);
        fprintf(out, "   Excess Kurtosis: %-12.6g\n", ex_kurt);
        fprintf(out, "---------------------------------------------------------------\n");
        fprintf(out, "  Order Statistics & Quantiles:\n");
        fprintf(out, "   Median (Q50):    %-12.6g IQR:              %.6g\n", median, iqr);
        fprintf(out, "   Q25:             %-12.6g Q75:              %.6g\n", q25, q75);
        fprintf(out, "   Q05:             %-12.6g Q95:              %.6g\n", q05, q95);
        fprintf(out, "   MAD:             %-12.6g Trimmed Mean:     %.6g\n", mad, t_mean);
        fprintf(out, "   Winsorized Mean: %-12.6g\n", w_mean);
        fprintf(out, "---------------------------------------------------------------\n");
        fprintf(out, "  Peak & Mode Estimation:\n");
        fprintf(out, "   Mode (Bin):      %-12u Mode (Continuous): %.6g\n", mode_bin, mode_cont);
        fprintf(out, "   FWHM:            %-12.6g\n", fwhm);
        fprintf(out, "===============================================================\n");
    }
}

static void print_histo2d_stats(const histo2d_t *h, const char *fmt, FILE *out) {
    if (!h) return;
    if (!out) out = stdout;
    histo2d_stats_t s;
    histo2d_get_stats(h, &s);

    uint32_t nx = histo2d_nbins_x(h);
    uint32_t ny = histo2d_nbins_y(h);

    if (strcmp(fmt, "json") == 0) {
        fprintf(out, "{\n");
        fprintf(out, "  \"type\": \"2d\",\n");
        fprintf(out, "  \"nbins_x\": %u,\n", nx);
        fprintf(out, "  \"nbins_y\": %u,\n", ny);
        fprintf(out, "  \"entries\": %llu,\n", (unsigned long long)s.n_entries);
        fprintf(out, "  \"total_weight\": %.8g,\n", s.total_weight);
        fprintf(out, "  \"mean_x\": %.8g,\n", s.mean_x);
        fprintf(out, "  \"mean_y\": %.8g,\n", s.mean_y);
        fprintf(out, "  \"variance_x\": %.8g,\n", s.variance_x);
        fprintf(out, "  \"variance_y\": %.8g,\n", s.variance_y);
        fprintf(out, "  \"std_dev_x\": %.8g,\n", s.std_dev_x);
        fprintf(out, "  \"std_dev_y\": %.8g,\n", s.std_dev_y);
        fprintf(out, "  \"covariance\": %.8g,\n", s.covariance);
        fprintf(out, "  \"correlation\": %.8g\n", s.correlation);
        fprintf(out, "}\n");
    } else if (strcmp(fmt, "tsv") == 0) {
        fprintf(out, "metric\tvalue\n");
        fprintf(out, "nbins_x\t%u\n", nx);
        fprintf(out, "nbins_y\t%u\n", ny);
        fprintf(out, "entries\t%llu\n", (unsigned long long)s.n_entries);
        fprintf(out, "total_weight\t%.8g\n", s.total_weight);
        fprintf(out, "mean_x\t%.8g\n", s.mean_x);
        fprintf(out, "mean_y\t%.8g\n", s.mean_y);
        fprintf(out, "variance_x\t%.8g\n", s.variance_x);
        fprintf(out, "variance_y\t%.8g\n", s.variance_y);
        fprintf(out, "std_dev_x\t%.8g\n", s.std_dev_x);
        fprintf(out, "std_dev_y\t%.8g\n", s.std_dev_y);
        fprintf(out, "covariance\t%.8g\n", s.covariance);
        fprintf(out, "correlation\t%.8g\n", s.correlation);
    } else {
        fprintf(out, "===============================================================\n");
        fprintf(out, " 2-DIMENSIONAL HISTOGRAM SUMMARY STATISTICS\n");
        fprintf(out, "===============================================================\n");
        fprintf(out, "  Grid Dimensions:  %u x %u bins\n", nx, ny);
        fprintf(out, "  Total Entries:    %llu\n", (unsigned long long)s.n_entries);
        fprintf(out, "  Total Weight:     %.6g\n", s.total_weight);
        fprintf(out, "  Rejected NaNs:    %llu\n", (unsigned long long)histo2d_nan_count(h));
        fprintf(out, "---------------------------------------------------------------\n");
        fprintf(out, "  X-Axis:  Range [%.4g, %.4g]\n", s.min_x, s.max_x);
        fprintf(out, "    Mean (X):       %-12.6g Std Dev (X):  %.6g\n", s.mean_x, s.std_dev_x);
        fprintf(out, "    Variance (X):   %-12.6g\n", s.variance_x);
        fprintf(out, "  Y-Axis:  Range [%.4g, %.4g]\n", s.min_y, s.max_y);
        fprintf(out, "    Mean (Y):       %-12.6g Std Dev (Y):  %.6g\n", s.mean_y, s.std_dev_y);
        fprintf(out, "    Variance (Y):   %-12.6g\n", s.variance_y);
        fprintf(out, "---------------------------------------------------------------\n");
        fprintf(out, "  Bivariate Correlation & Covariance:\n");
        fprintf(out, "    Covariance:     %-12.6g Pearson (rho): %.6f\n", s.covariance, s.correlation);
        fprintf(out, "===============================================================\n");
    }
}

int histo_cli_stats(int argc, char **argv, FILE *out, FILE *err) {
    if (!out) out = stdout;
    if (!err) err = stderr;
    optind = 1;

    const char *fmt = "table";
    int file_start = argc;

    for (int i = 1; i < argc; ++i) {
        const char *arg = argv[i];
        if (strcmp(arg, "-h") == 0 || strcmp(arg, "--help") == 0) {
            print_stats_usage(out);
            return 0;
        } else if (strncmp(arg, "-f=", 3) == 0) {
            fmt = arg + 3;
        } else if (strcmp(arg, "-f") == 0 && i + 1 < argc) {
            fmt = argv[++i];
        } else if (strncmp(arg, "--format=", 9) == 0) {
            fmt = arg + 9;
        } else if (strcmp(arg, "-a") == 0 || strcmp(arg, "--all") == 0) {
            /* all is default */
        } else if (arg[0] == '-' && arg[1] != '\0') {
            fprintf(err, "Unknown option '%s'. Run 'histo-stats --help' for usage.\n", arg);
            return 1;
        } else {
            file_start = i;
            break;
        }
    }

    int num_files = argc - file_start;
    const char *default_files[] = {"-"};
    const char **files = (num_files > 0) ? (const char **)(argv + file_start) : default_files;
    int nfiles = (num_files > 0) ? num_files : 1;

    int status = 0;
    for (int f = 0; f < nfiles; ++f) {
        histo_t *h = NULL;
        histo2d_t *h2d = NULL;
        if (cli_read_any_histogram_from_file(files[f], &h, &h2d) == HISTO_OK) {
            if (h2d) {
                print_histo2d_stats(h2d, fmt, out);
                histo2d_destroy(h2d);
            } else if (h) {
                print_histogram_stats(h, fmt, out);
                histo_destroy(h);
            }
        } else {
            fprintf(err, "Error: Failed to read histogram from '%s'\n", files[f]);
            status = 1;
        }
    }

    return status;
}
