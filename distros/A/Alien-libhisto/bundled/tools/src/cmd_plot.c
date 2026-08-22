/*
 * CLI subcommand histo plot: terminal histogram and heatmap plots.
 */

#include "cli_common.h"
#include "cli_palette.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <unistd.h>
#include <ctype.h>

static void print_plot_usage(FILE *out) {
    if (!out) out = stdout;
    fprintf(out, "Usage: histo-plot [OPTIONS] [HISTOGRAM_FILE...]\n");
    fprintf(out, "       histo plot [OPTIONS] [HISTOGRAM_FILE...]\n\n");
    fprintf(out, "Renders 1D distributions and 2D bivariate heatmaps as ASCII / Unicode terminal charts.\n\n");
    fprintf(out, "Display Options:\n");
    fprintf(out, "  -W, --width=<COLS>       Plot width in characters (default: auto terminal width)\n");
    fprintf(out, "  -s, --style=<STYLE>      Glyph style: blocks (default), ascii, shaded, sparkline\n");
    fprintf(out, "  -S, --sparkline          Render compact single-line sparkline (e.g.  ▂▃▅██▆▃▂ )\n");
    fprintf(out, "  -c, --color=<MODE>       Color mode: auto (default), always, never\n");
    fprintf(out, "  -p, --palette=<NAME>     Color palette: viridis (default), plasma, inferno, magma,\n");
    fprintf(out, "                           turbo, cividis, grayscale, rainbow (alias: --colormap)\n");
    fprintf(out, "  -l, --log                Use logarithmic scale for bar lengths / 2D intensity\n");
    fprintf(out, "  -e, --errors             Display error bars (1D mode when sum_w2 is tracked)\n");
    fprintf(out, "      --2d                 Render in 2D bivariate heatmap mode\n");
    fprintf(out, "      --stats              Show full statistical summary header/footer (default: ON)\n");
    fprintf(out, "      --no-stats           Suppress statistical summary header\n");
    fprintf(out, "      --title=<TITLE>      Set custom plot title\n\n");
    fprintf(out, "Live Streaming / Watch Mode:\n");
    fprintf(out, "  -w, --watch              Continuously render incoming snapshots from stream\n");
    fprintf(out, "      --clear              Clear entire screen between updates\n");
    fprintf(out, "  -h, --help               Show this help message\n");
}

/* Unicode horizontal sub-bin fractions (1/8ths) */
static const char *const UNICODE_BLOCKS[9] = {
    " ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"
};

/* Unicode and ASCII vertical sparkline glyphs (8 levels) */
static const char *const SPARKLINE_UNICODE[9] = {
    " ", " ", "▂", "▃", "▄", "▅", "▆", "▇", "█"
};

static const char *const SPARKLINE_ASCII[9] = {
    " ", ".", "_", "-", "~", "=", "*", "#", "^"
};

static void render_histo2d_heatmap(const histo2d_t *h, int term_width, bool use_color, histo_palette_t palette, const char *title, FILE *out) {
    if (!h || !out) return;
    (void)term_width;

    uint32_t nx = histo2d_nbins_x(h);
    uint32_t ny = histo2d_nbins_y(h);
    histo2d_axis_t ax, ay;
    histo2d_axis_x(h, &ax);
    histo2d_axis_y(h, &ay);

    double max_content = 0.0;
    for (uint32_t ix = 0; ix < nx; ++ix) {
        for (uint32_t iy = 0; iy < ny; ++iy) {
            double c = 0.0;
            histo2d_bin_content(h, ix, iy, &c);
            if (c > max_content) max_content = c;
        }
    }
    if (max_content <= 0.0) max_content = 1.0;

    if (title && *title) {
        fprintf(out, "\n── %s ──\n", title);
    } else {
        fprintf(out, "\n── 2D Histogram Heatmap (%u x %u bins, Entries: %llu, Weight: %.4g) ──\n",
               nx, ny, (unsigned long long)histo2d_num_entries(h), histo2d_total_weight(h));
    }

    /* Render Y rows from top (ny-1) to bottom (0) */
    for (int iy = (int)ny - 1; iy >= 0; --iy) {
        double ymin_b, ymax_b, dummy;
        histo2d_bin_bounds(h, 0, (uint32_t)iy, &dummy, &dummy, &ymin_b, &ymax_b);
        fprintf(out, "%7.2f │ ", 0.5 * (ymin_b + ymax_b));

        for (uint32_t ix = 0; ix < nx; ++ix) {
            double c = 0.0;
            histo2d_bin_content(h, ix, (uint32_t)iy, &c);
            double frac = (c > 0.0) ? (c / max_content) : 0.0;
            if (use_color) {
                char bg[32];
                histo_palette_sample_ansi_bg(palette, frac, bg, sizeof(bg));
                fprintf(out, "%s  \033[0m", bg);
            } else {
                static const char density[] = " .:-=+*#%@";
                int idx = (int)(frac * 9.0);
                if (idx < 0) idx = 0;
                if (idx > 9) idx = 9;
                fprintf(out, "%c ", density[idx]);
            }
        }
        fprintf(out, " │\n");
    }

    /* X Axis line and ticks */
    fprintf(out, "        └");
    for (uint32_t ix = 0; ix < nx; ++ix) fprintf(out, "──");
    fprintf(out, "─┘\n");

    fprintf(out, "         ");
    fprintf(out, "%-7.2f", ax.min);
    int mid_pad = (int)(nx * 2) - 14;
    if (mid_pad > 0) {
        for (int p = 0; p < mid_pad / 2; ++p) fputc(' ', out);
        fprintf(out, "%-7.2f", 0.5 * (ax.min + ax.max));
        for (int p = 0; p < (mid_pad - mid_pad / 2); ++p) fputc(' ', out);
    }
    fprintf(out, "%7.2f\n", ax.max);

    /* Color bar legend */
    if (use_color) {
        fprintf(out, "\n  Intensity: 0.00 ");
        for (int step = 0; step <= 20; ++step) {
            double frac = (double)step / 20.0;
            char bg[32];
            histo_palette_sample_ansi_bg(palette, frac, bg, sizeof(bg));
            fprintf(out, "%s \033[0m", bg);
        }
        fprintf(out, " %.2e [%s]\n\n", max_content, histo_palette_name(palette));
    } else {
        fprintf(out, "\n  Density scale: [ .:-=+*#%%@ ] (0.00 -> %.2e)\n\n", max_content);
    }
}

static void render_histogram_console(const histo_t *h, int term_width, const char *style, bool use_color, histo_palette_t palette, bool log_scale, bool show_errors, bool show_stats, const char *title, FILE *out) {
    if (!h || !out) return;

    uint32_t nbins = histo_nbins(h);
    double total_w = histo_total_weight(h);
    uint64_t n_fills = histo_num_entries(h);

    double max_content = 0.0;
    int max_bounds_len = 0;
    int max_count_len = 0;
    int max_err_len = 0;

    for (uint32_t i = 0; i < nbins; ++i) {
        double lower = 0.0, upper = 0.0, content = 0.0, err = 0.0;
        histo_bin_bounds(h, i, &lower, &upper);
        histo_bin_content(h, i, &content);
        if (content > max_content) max_content = content;

        char b_tmp[64];
        int blen = snprintf(b_tmp, sizeof(b_tmp), "[%6.2f, %6.2f)", lower, upper);
        if (blen > max_bounds_len) max_bounds_len = blen;

        char c_tmp[64];
        int clen;
        if (content == floor(content) && content >= 0.0 && content < 1e12) {
            clen = snprintf(c_tmp, sizeof(c_tmp), "%.0f", content);
        } else {
            clen = snprintf(c_tmp, sizeof(c_tmp), "%.4g", content);
        }
        if (clen > max_count_len) max_count_len = clen;

        if (show_errors) {
            histo_bin_error(h, i, &err);
            if (err > 0.0) {
                char e_num[32];
                int nlen = snprintf(e_num, sizeof(e_num), "%.2g", err);
                int elen = (strcmp(style, "ascii") == 0) ? (nlen + 3) : (nlen + 4);
                if (elen > max_err_len) max_err_len = elen;
            }
        }
    }

    if (max_bounds_len < 16) max_bounds_len = 16;
    if (max_count_len < 6) max_count_len = 6;

    /* Print Title & Header */
    if (title && *title) {
        char tot_str[32];
        snprintf(tot_str, sizeof(tot_str), (total_w == floor(total_w) && total_w >= 0.0 && total_w < 1e12) ? "%.0f" : "%.4g", total_w);
        fprintf(out, "\033[1m%s\033[0m (Entries: %llu, Total Weight: %s)\n", title, (unsigned long long)n_fills, tot_str);
    }

    if (show_stats && total_w > 0.0) {
        double mean = 0.0, sdev = 0.0, med = 0.0, iqr = 0.0, mode = 0.0;
        histo_mean(h, &mean);
        histo_std_dev(h, &sdev);
        histo_median(h, &med);
        histo_iqr(h, &iqr);
        histo_mode_continuous(h, &mode);

        char s_mean[32], s_sdev[32], s_med[32], s_iqr[32], s_mode[32];
        snprintf(s_mean, sizeof(s_mean), "Mean: %-6.4g", mean);
        snprintf(s_sdev, sizeof(s_sdev), "StdDev: %-5.4g", sdev);
        snprintf(s_med, sizeof(s_med), "Median: %-5.4g", med);
        snprintf(s_iqr, sizeof(s_iqr), "IQR: %-6.4g", iqr);
        snprintf(s_mode, sizeof(s_mode), "Mode: %-6.4g", mode);

        int inner_width = 75;

        if (strcmp(style, "ascii") == 0) {
            fprintf(out, "+-- Statistics ");
            for (int k = 0; k < inner_width - 14; ++k) fputc('-', out);
            fprintf(out, "+\n");

            fprintf(out, "| %-12s | %-13s | %-13s | %-11s | %-12s |\n",
                   s_mean, s_sdev, s_med, s_iqr, s_mode);

            fprintf(out, "+");
            for (int k = 0; k < inner_width; ++k) fputc('-', out);
            fprintf(out, "+\n");
        } else {
            fprintf(out, "┌─ Statistics ");
            for (int k = 0; k < inner_width - 13; ++k) fprintf(out, "─");
            fprintf(out, "┐\n");

            fprintf(out, "│ %-12s │ %-13s │ %-13s │ %-11s │ %-12s │\n",
                   s_mean, s_sdev, s_med, s_iqr, s_mode);

            fprintf(out, "└");
            for (int k = 0; k < inner_width; ++k) fprintf(out, "─");
            fprintf(out, "┘\n");
        }
    }

    /* Calculate column widths for bounds and counts */
    int prefix_width = max_bounds_len + max_count_len + 6; /* "%-*s │ %*s │ " */
    int suffix_width = show_errors ? max_err_len : 0;
    int bar_max_chars = term_width - prefix_width - suffix_width - 2;
    if (bar_max_chars < 5) bar_max_chars = 5;

    double max_scaled = max_content;
    if (log_scale && max_content > 0.0) {
        max_scaled = log10(max_content + 1.0);
    }

    /* Render each bin */
    for (uint32_t i = 0; i < nbins; ++i) {
        double lower = 0.0, upper = 0.0, content = 0.0, err = 0.0;
        histo_bin_bounds(h, i, &lower, &upper);
        histo_bin_content(h, i, &content);
        if (show_errors) {
            histo_bin_error(h, i, &err);
        }

        char bounds_str[64];
        snprintf(bounds_str, sizeof(bounds_str), "[%6.2f, %6.2f)", lower, upper);

        char count_str[64];
        if (content == floor(content) && content >= 0.0 && content < 1e12) {
            snprintf(count_str, sizeof(count_str), "%.0f", content);
        } else {
            snprintf(count_str, sizeof(count_str), "%.4g", content);
        }

        fprintf(out, "%-*s │ %*s │ ", max_bounds_len, bounds_str, max_count_len, count_str);

        if (max_scaled <= 0.0 || content <= 0.0) {
            fprintf(out, "\n");
            continue;
        }

        double val_scaled = log_scale ? log10(content + 1.0) : content;
        double frac_total = val_scaled / max_scaled;
        double bar_len_exact = frac_total * (double)bar_max_chars;

        char color_ansi[32] = "";
        if (use_color) {
            histo_palette_sample_ansi_fg(palette, frac_total, color_ansi, sizeof(color_ansi));
            fprintf(out, "%s", color_ansi);
        }

        if (strcmp(style, "ascii") == 0) {
            int full_chars = (int)bar_len_exact;
            for (int k = 0; k < full_chars; ++k) {
                fputc('#', out);
            }
            if (show_errors && err > 0.0 && full_chars < bar_max_chars) {
                fprintf(out, " ±%.2g", err);
            }
        } else if (strcmp(style, "shaded") == 0) {
            int full_chars = (int)bar_len_exact;
            for (int k = 0; k < full_chars; ++k) {
                fprintf(out, "█");
            }
        } else { /* blocks with 1/8th sub-character precision */
            int full_chars = (int)bar_len_exact;
            int remainder_eighths = (int)((bar_len_exact - (double)full_chars) * 8.0);
            if (remainder_eighths < 0) remainder_eighths = 0;
            if (remainder_eighths > 8) remainder_eighths = 8;

            for (int k = 0; k < full_chars; ++k) {
                fprintf(out, "█");
            }
            if (remainder_eighths > 0 && full_chars < bar_max_chars) {
                fprintf(out, "%s", UNICODE_BLOCKS[remainder_eighths]);
            }
            if (show_errors && err > 0.0) {
                if (use_color) fprintf(out, "\033[0m\033[90m");
                fprintf(out, " ╎±%.2g╎", err);
            }
        }

        if (use_color) {
            fprintf(out, "\033[0m");
        }
        fprintf(out, "\n");
    }

    /* Print out-of-range footer */
    double uflow = histo_underflow(h);
    double oflow = histo_overflow(h);
    uint64_t n_nan = histo_nan_count(h);

    char uflow_str[32], oflow_str[32], tot_str[32];
    snprintf(uflow_str, sizeof(uflow_str), (uflow == floor(uflow) && uflow >= 0.0 && uflow < 1e12) ? "%.0f" : "%.4g", uflow);
    snprintf(oflow_str, sizeof(oflow_str), (oflow == floor(oflow) && oflow >= 0.0 && oflow < 1e12) ? "%.0f" : "%.4g", oflow);
    snprintf(tot_str, sizeof(tot_str), (total_w == floor(total_w) && total_w >= 0.0 && total_w < 1e12) ? "%.0f" : "%.4g", total_w);

    fprintf(out, " Underflow: %s │ In-Range: %s │ Overflow: %s │ Non-Finite/NaN: %llu\n",
           uflow_str, tot_str, oflow_str, (unsigned long long)n_nan);
}

static void render_histogram_sparkline(const histo_t *h, const char *style, bool use_color, histo_palette_t palette, bool log_scale, bool show_stats, FILE *out) {
    if (!h || !out) return;

    uint32_t nbins = histo_nbins(h);
    double max_content = 0.0;
    for (uint32_t i = 0; i < nbins; ++i) {
        double c = 0.0;
        histo_bin_content(h, i, &c);
        if (c > max_content) max_content = c;
    }

    double max_scaled = (log_scale && max_content > 0.0) ? log10(max_content + 1.0) : max_content;
    bool is_ascii = (strcmp(style, "ascii") == 0);

    for (uint32_t i = 0; i < nbins; ++i) {
        double content = 0.0;
        histo_bin_content(h, i, &content);

        if (content <= 0.0 || max_scaled <= 0.0) {
            fputc(' ', out);
            continue;
        }

        double val_scaled = log_scale ? log10(content + 1.0) : content;
        double frac = val_scaled / max_scaled;
        int level = (int)(frac * 8.0 + 0.5);
        if (level < 1) level = 1;
        if (level > 8) level = 8;

        if (use_color) {
            char color_ansi[32] = "";
            histo_palette_sample_ansi_fg(palette, frac, color_ansi, sizeof(color_ansi));
            fprintf(out, "%s", color_ansi);
        }

        if (is_ascii) {
            fprintf(out, "%s", SPARKLINE_ASCII[level]);
        } else {
            fprintf(out, "%s", SPARKLINE_UNICODE[level]);
        }

        if (use_color) {
            fprintf(out, "\033[0m");
        }
    }

    if (show_stats) {
        double mean = 0.0, sdev = 0.0, rmin = 0.0, rmax = 0.0;
        histo_mean(h, &mean);
        histo_std_dev(h, &sdev);
        histo_range(h, &rmin, &rmax);
        uint64_t entries = histo_num_entries(h);

        fprintf(out, "  [N=%llu, range=[%.2g, %.2g), μ=%.2g, σ=%.2g]",
               (unsigned long long)entries, rmin, rmax, mean, sdev);
    }
    fprintf(out, "\n");
}

static void render_histogram_dispatch(const histo_t *h, int term_width, const char *style, bool use_color, histo_palette_t palette, bool log_scale, bool show_errors, bool show_stats, const char *title, bool sparkline, FILE *out) {
    if (sparkline) {
        render_histogram_sparkline(h, style, use_color, palette, log_scale, show_stats, out);
    } else {
        render_histogram_console(h, term_width, style, use_color, palette, log_scale, show_errors, show_stats, title, out);
    }
}

int histo_cli_plot(int argc, char **argv, FILE *out, FILE *err) {
    if (!out) out = stdout;
    if (!err) err = stderr;
    optind = 1;

    int term_width = cli_get_terminal_width(80);
    const char *style = "blocks";
    const char *color_mode = "auto";
    histo_palette_t palette = HISTO_PALETTE_VIRIDIS;
    bool log_scale = false;
    bool show_errors = false;
    bool show_stats = true;
    bool sparkline = false;
    bool watch_mode = false;
    bool clear_screen = false;
    const char *title = NULL;

    int file_start = argc;
    for (int i = 1; i < argc; ++i) {
        const char *arg = argv[i];
        if (strcmp(arg, "-h") == 0 || strcmp(arg, "--help") == 0) {
            print_plot_usage(out);
            return 0;
        } else if (strncmp(arg, "-W=", 3) == 0) {
            term_width = atoi(arg + 3);
        } else if (strcmp(arg, "-W") == 0 && i + 1 < argc) {
            term_width = atoi(argv[++i]);
        } else if (strncmp(arg, "--width=", 8) == 0) {
            term_width = atoi(arg + 8);
        } else if (strncmp(arg, "-s=", 3) == 0) {
            style = arg + 3;
        } else if (strcmp(arg, "-s") == 0 && i + 1 < argc) {
            style = argv[++i];
        } else if (strncmp(arg, "--style=", 8) == 0) {
            style = arg + 8;
        } else if (strcmp(arg, "-S") == 0 || strcmp(arg, "--sparkline") == 0) {
            sparkline = true;
        } else if (strncmp(arg, "-c=", 3) == 0) {
            color_mode = arg + 3;
        } else if (strcmp(arg, "-c") == 0 && i + 1 < argc) {
            color_mode = argv[++i];
        } else if (strncmp(arg, "--color=", 8) == 0) {
            color_mode = arg + 8;
        } else if (strncmp(arg, "-p=", 3) == 0) {
            palette = histo_palette_from_name(arg + 3);
        } else if (strcmp(arg, "-p") == 0 && i + 1 < argc) {
            palette = histo_palette_from_name(argv[++i]);
        } else if (strncmp(arg, "--palette=", 10) == 0) {
            palette = histo_palette_from_name(arg + 10);
        } else if (strncmp(arg, "--colormap=", 11) == 0) {
            palette = histo_palette_from_name(arg + 11);
        } else if (strcmp(arg, "-l") == 0 || strcmp(arg, "--log") == 0) {
            log_scale = true;
        } else if (strcmp(arg, "-e") == 0 || strcmp(arg, "--errors") == 0) {
            show_errors = true;
        } else if (strcmp(arg, "--stats") == 0) {
            show_stats = true;
        } else if (strcmp(arg, "--no-stats") == 0) {
            show_stats = false;
        } else if (strcmp(arg, "-w") == 0 || strcmp(arg, "--watch") == 0) {
            watch_mode = true;
        } else if (strcmp(arg, "--clear") == 0) {
            clear_screen = true;
        } else if (strcmp(arg, "--2d") == 0) {
            /* 2D stream plotting is auto-detected */
        } else if (strncmp(arg, "--title=", 8) == 0) {
            title = arg + 8;
        } else if (strcmp(arg, "--title") == 0 && i + 1 < argc) {
            title = argv[++i];
        } else if (arg[0] == '-' && arg[1] != '\0') {
            fprintf(err, "Unknown option '%s'. Run 'histo-plot --help' for usage.\n", arg);
            return 1;
        } else {
            file_start = i;
            break;
        }
    }

    if (strcmp(style, "sparkline") == 0) {
        sparkline = true;
    }

    bool use_color = false;
    if (strcmp(color_mode, "always") == 0) {
        use_color = true;
    } else if (strcmp(color_mode, "never") == 0) {
        use_color = false;
    } else {
        use_color = (out == stdout) && cli_is_stdout_tty();
    }

    int num_files = argc - file_start;
    const char *default_files[] = {"-"};
    const char **files = (num_files > 0) ? (const char **)(argv + file_start) : default_files;
    int nfiles = (num_files > 0) ? num_files : 1;

    for (int f = 0; f < nfiles; ++f) {
        FILE *in_fp = NULL;
        if (strcmp(files[f], "-") == 0) {
            in_fp = stdin;
        } else {
            in_fp = fopen(files[f], "rb");
            if (!in_fp) {
                fprintf(err, "Error: Cannot open file '%s'\n", files[f]);
                continue;
            }
        }

        cli_input_format_t fmt = cli_detect_stream_format(in_fp);
        if (fmt == CLI_INPUT_BINARY_HISTO || fmt == CLI_INPUT_JSON_HISTO) {
            histo2d_t *h2d = NULL;
            if (watch_mode) {
                while (cli_read_histo2d_from_stream(in_fp, &h2d) == HISTO_OK) {
                    if (clear_screen) {
                        fprintf(out, "\033[2J\033[H");
                    } else {
                        fprintf(out, "\033[H");
                    }
                    render_histo2d_heatmap(h2d, term_width, use_color, palette, title, out);
                    histo2d_destroy(h2d);
                    h2d = NULL;
                }
                if (!h2d) {
                    histo_t *h = NULL;
                    while (cli_read_histogram_from_stream(in_fp, &h) == HISTO_OK) {
                        if (clear_screen) {
                            fprintf(out, "\033[2J\033[H");
                        } else {
                            fprintf(out, "\033[H");
                        }
                        render_histogram_dispatch(h, term_width, style, use_color, palette, log_scale, show_errors, show_stats, title, sparkline, out);
                        histo_destroy(h);
                        h = NULL;
                    }
                }
            } else {
                histo_t *h = NULL;
                histo2d_t *h2d = NULL;
                if (cli_read_any_histogram_from_stream(in_fp, &h, &h2d) == HISTO_OK) {
                    if (h2d) {
                        render_histo2d_heatmap(h2d, term_width, use_color, palette, title, out);
                        histo2d_destroy(h2d);
                    } else if (h) {
                        render_histogram_dispatch(h, term_width, style, use_color, palette, log_scale, show_errors, show_stats, title, sparkline, out);
                        histo_destroy(h);
                    }
                } else {
                    fprintf(err, "Error: Failed to deserialize histogram from '%s'\n", files[f]);
                }
            }

        } else {
            /* Raw numbers / text: ingest into auto-ranged histogram on the fly */
            char line[2048];
            size_t count = 0, cap = 1024;
            double *samples = (double *)malloc(cap * sizeof(double));
            while (fgets(line, sizeof(line), in_fp)) {
                char *p = line;
                while (*p && isspace((unsigned char)*p)) p++;
                if (*p == '\0' || *p == '#') continue;
                char *endp = NULL;
                double val = strtod(p, &endp);
                if (endp != p) {
                    if (count >= cap) {
                        cap *= 2;
                        samples = (double *)realloc(samples, cap * sizeof(double));
                    }
                    samples[count++] = val;
                }
            }

            if (count > 0) {
                histo_t *h = histo_create_auto(count, samples, HISTO_BIN_RULE_AUTO, HISTO_FLAG_TRACK_SUMW2);
                if (h) {
                    render_histogram_dispatch(h, term_width, style, use_color, palette, log_scale, show_errors, show_stats, title, sparkline, out);
                    histo_destroy(h);
                }
            }
            free(samples);
        }

        if (in_fp != stdin) fclose(in_fp);
    }

    return 0;
}
