#include "cli_common.h"
#include "histo/cli.h"
#include "histo/version.h"
#include <stdio.h>
#include <string.h>

static void print_usage(const char *prog, FILE *out) {
    if (!out) out = stdout;
    fprintf(out, "libhisto CLI toolkit v%s\n\n", HISTO_VERSION_STRING);
    fprintf(out, "Usage:\n");
    fprintf(out, "  %s <command> [options] [arguments...]\n", prog);
    fprintf(out, "  histo-fill [options] [arguments...]\n");
    fprintf(out, "  histo-plot [options] [arguments...]\n");
    fprintf(out, "  histo-stats [options] [arguments...]\n");
    fprintf(out, "  histo-fit [options] [arguments...]\n");
    fprintf(out, "  histo-cmp [options] [arguments...]\n\n");
    fprintf(out, "Commands:\n");
    fprintf(out, "  fill     Stream data in, aggregate into histogram, and emit binary/JSON/text\n");
    fprintf(out, "  plot     Render histogram as ASCII / Unicode terminal bar chart\n");
    fprintf(out, "  stats    Display detailed statistical metrics and moment analysis\n");
    fprintf(out, "  fit      Fit parametric models (Gaussian, Exponential, Polynomial, Breit-Wigner)\n");
    fprintf(out, "  cmp      Compare two histograms and compute statistical distance metrics\n\n");
    fprintf(out, "Flags:\n");
    fprintf(out, "  -h, --help       Show this help message\n");
    fprintf(out, "  -v, --version    Show version information\n\n");
    fprintf(out, "For command-specific help, run: %s <command> --help\n", prog);
}

int histo_cli_main(int argc, char **argv, FILE *out, FILE *err) {
    if (!out) out = stdout;
    if (!err) err = stderr;
    if (argc < 1) return 1;

    /* Check if invoked directly via symlink (e.g. histo-fill, histo_plot, phisto-fill) */
    const char *prog_name = argv[0];
    const char *slash = strrchr(prog_name, '/');
    if (slash) prog_name = slash + 1;

    if (strcmp(prog_name, "histo-fill") == 0 || strcmp(prog_name, "histo_fill") == 0 ||
        strcmp(prog_name, "phisto-fill") == 0) {
        return histo_cli_fill(argc, argv, out, err);
    }
    if (strcmp(prog_name, "histo-plot") == 0 || strcmp(prog_name, "histo_plot") == 0 ||
        strcmp(prog_name, "phisto-plot") == 0) {
        return histo_cli_plot(argc, argv, out, err);
    }
    if (strcmp(prog_name, "histo-stats") == 0 || strcmp(prog_name, "histo_stats") == 0 ||
        strcmp(prog_name, "phisto-stats") == 0) {
        return histo_cli_stats(argc, argv, out, err);
    }
    if (strcmp(prog_name, "histo-cmp") == 0 || strcmp(prog_name, "histo_cmp") == 0 ||
        strcmp(prog_name, "histo-compare") == 0 || strcmp(prog_name, "phisto-cmp") == 0) {
        return histo_cli_cmp(argc, argv, out, err);
    }
    if (strcmp(prog_name, "histo-fit") == 0 || strcmp(prog_name, "histo_fit") == 0 ||
        strcmp(prog_name, "phisto-fit") == 0) {
        return histo_cli_fit(argc, argv, out, err);
    }

    /* Multi-call dispatcher */
    if (argc < 2) {
        print_usage(prog_name, out);
        return 1;
    }

    const char *cmd = argv[1];
    if (strcmp(cmd, "-h") == 0 || strcmp(cmd, "--help") == 0 || strcmp(cmd, "help") == 0) {
        print_usage(prog_name, out);
        return 0;
    }
    if (strcmp(cmd, "-v") == 0 || strcmp(cmd, "--version") == 0 || strcmp(cmd, "version") == 0) {
        fprintf(out, "libhisto %s\n", HISTO_VERSION_STRING);
        return 0;
    }

    /* Shift argv for sub-command */
    int sub_argc = argc - 1;
    char **sub_argv = argv + 1;

    if (strcmp(cmd, "fill") == 0) {
        return histo_cli_fill(sub_argc, sub_argv, out, err);
    }
    if (strcmp(cmd, "plot") == 0 || strcmp(cmd, "draw") == 0) {
        return histo_cli_plot(sub_argc, sub_argv, out, err);
    }
    if (strcmp(cmd, "stats") == 0 || strcmp(cmd, "stat") == 0 || strcmp(cmd, "inspect") == 0) {
        return histo_cli_stats(sub_argc, sub_argv, out, err);
    }
    if (strcmp(cmd, "fit") == 0) {
        return histo_cli_fit(sub_argc, sub_argv, out, err);
    }
    if (strcmp(cmd, "cmp") == 0 || strcmp(cmd, "compare") == 0 || strcmp(cmd, "diff") == 0) {
        return histo_cli_cmp(sub_argc, sub_argv, out, err);
    }

    fprintf(err, "Error: Unknown command '%s'. Run '%s --help' for usage.\n", cmd, prog_name);
    return 1;
}

/* Backward-compatible wrappers */
int cmd_fill_main(int argc, char **argv) {
    return histo_cli_fill(argc, argv, stdout, stderr);
}

int cmd_plot_main(int argc, char **argv) {
    return histo_cli_plot(argc, argv, stdout, stderr);
}

int cmd_stats_main(int argc, char **argv) {
    return histo_cli_stats(argc, argv, stdout, stderr);
}

int cmd_fit_main(int argc, char **argv) {
    return histo_cli_fit(argc, argv, stdout, stderr);
}

int cmd_cmp_main(int argc, char **argv) {
    return histo_cli_cmp(argc, argv, stdout, stderr);
}
