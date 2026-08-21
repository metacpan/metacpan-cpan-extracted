#include "cli_common.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <unistd.h>

static void print_cmp_usage(FILE *out) {
    if (!out) out = stdout;
    fprintf(out, "Usage: histo-cmp [OPTIONS] <HISTO_A> <HISTO_B>\n");
    fprintf(out, "       histo cmp [OPTIONS] <HISTO_A> <HISTO_B>\n\n");
    fprintf(out, "Compares two histograms and computes statistical distance metrics and compatibility.\n\n");
    fprintf(out, "Options:\n");
    fprintf(out, "  -f, --format=<FMT>       Output format: table (default), json, tsv\n");
    fprintf(out, "  -h, --help               Show this help message\n");
}

int histo_cli_cmp(int argc, char **argv, FILE *out, FILE *err) {
    if (!out) out = stdout;
    if (!err) err = stderr;
    optind = 1;

    const char *fmt = "table";
    int file_start = argc;

    for (int i = 1; i < argc; ++i) {
        const char *arg = argv[i];
        if (strcmp(arg, "-h") == 0 || strcmp(arg, "--help") == 0) {
            print_cmp_usage(out);
            return 0;
        } else if (strncmp(arg, "-f=", 3) == 0) {
            fmt = arg + 3;
        } else if (strcmp(arg, "-f") == 0 && i + 1 < argc) {
            fmt = argv[++i];
        } else if (strncmp(arg, "--format=", 9) == 0) {
            fmt = arg + 9;
        } else if (arg[0] == '-' && arg[1] != '\0') {
            fprintf(err, "Unknown option '%s'. Run 'histo-cmp --help' for usage.\n", arg);
            return 1;
        } else {
            file_start = i;
            break;
        }
    }

    if (argc - file_start < 2) {
        fprintf(err, "Error: Two histogram input paths are required.\n\n");
        print_cmp_usage(err);
        return 1;
    }

    const char *path1 = argv[file_start];
    const char *path2 = argv[file_start + 1];

    histo_t *h1 = NULL;
    histo_t *h2 = NULL;

    if (cli_read_histogram_from_file(path1, &h1) != HISTO_OK) {
        fprintf(err, "Error: Failed to read first histogram from '%s'\n", path1);
        return 1;
    }
    if (cli_read_histogram_from_file(path2, &h2) != HISTO_OK) {
        fprintf(err, "Error: Failed to read second histogram from '%s'\n", path2);
        histo_destroy(h1);
        return 1;
    }

    double chi2 = 0.0;
    uint32_t ndf = 0;
    double ks = 0.0;
    double w1 = 0.0;
    double kl = 0.0;
    double bhat = 0.0;

    histo_cmp_chi2(h1, h2, &chi2, &ndf);
    histo_cmp_ks(h1, h2, &ks);
    histo_cmp_wasserstein_1d(h1, h2, &w1);
    histo_cmp_kl_divergence(h1, h2, &kl);
    histo_cmp_bhattacharyya(h1, h2, &bhat);


    if (strcmp(fmt, "json") == 0) {
        fprintf(out, "{\n");
        fprintf(out, "  \"file_a\": \"%s\",\n", path1);
        fprintf(out, "  \"file_b\": \"%s\",\n", path2);
        fprintf(out, "  \"chi2\": %.6g,\n", chi2);
        fprintf(out, "  \"ndf\": %u,\n", ndf);
        fprintf(out, "  \"ks_distance\": %.6g,\n", ks);
        fprintf(out, "  \"wasserstein_1d\": %.6g,\n", w1);
        fprintf(out, "  \"kl_divergence\": %.6g,\n", kl);
        fprintf(out, "  \"bhattacharyya\": %.6g\n", bhat);
        fprintf(out, "}\n");
    } else if (strcmp(fmt, "tsv") == 0) {
        fprintf(out, "Metric\tValue\n");
        fprintf(out, "Chi2\t%.8g\n", chi2);
        fprintf(out, "NDF\t%u\n", ndf);
        fprintf(out, "KS\t%.8g\n", ks);
        fprintf(out, "Wasserstein\t%.8g\n", w1);
        fprintf(out, "KL\t%.8g\n", kl);
        fprintf(out, "Bhattacharyya\t%.8g\n", bhat);
    } else {
        fprintf(out, "===============================================================\n");
        fprintf(out, "  Two-Sample Histogram Compatibility & Distance Analysis\n");
        fprintf(out, "===============================================================\n");
        fprintf(out, "  Dataset A:        %s\n", path1);
        fprintf(out, "  Dataset B:        %s\n", path2);
        fprintf(out, "---------------------------------------------------------------\n");
        fprintf(out, "  Chi-Square (Chi2):      %-12.6g  NDF: %u\n", chi2, ndf);
        if (ndf > 0) {
            fprintf(out, "  Chi2 / NDF:             %-12.6g\n", chi2 / (double)ndf);
        }
        fprintf(out, "  Kolmogorov-Smirnov (KS):%-12.6g\n", ks);
        fprintf(out, "  Wasserstein (EMD 1D):   %-12.6g\n", w1);
        fprintf(out, "  KL Divergence (A || B): %-12.6g\n", kl);
        fprintf(out, "  Bhattacharyya Distance: %-12.6g\n", bhat);
        fprintf(out, "===============================================================\n");
    }

    histo_destroy(h1);
    histo_destroy(h2);
    return 0;
}
