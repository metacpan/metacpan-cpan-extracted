/*
 * CLI subcommand histo fill: ingest data streams and serialize histograms.
 */

#include "cli_common.h"
#include "histo/histo2d.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <math.h>





static char auto_detect_delimiter(const char *line) {
    int commas = 0, tabs = 0, semicolons = 0, pipes = 0;
    for (const char *p = line; *p; ++p) {
        if (*p == ',') commas++;
        else if (*p == '\t') tabs++;
        else if (*p == ';') semicolons++;
        else if (*p == '|') pipes++;
    }
    if (commas > 0 && commas >= tabs && commas >= semicolons && commas >= pipes) return ',';
    if (tabs > 0 && tabs >= semicolons && tabs >= pipes) return '\t';
    if (semicolons > 0 && semicolons >= pipes) return ';';
    if (pipes > 0) return '|';
    return ' ';
}

static histo_status_t emit_histogram(const histo_t *h, const char *fmt, FILE *out_fp,
                                     uint32_t rebin_factor, bool do_cdf, double norm_area) {
    if (!h || !out_fp) return HISTO_ERR_INVALID_ARG;
    histo_t *emit_h = (histo_t *)h;
    bool needs_free = false;

    if (rebin_factor > 1) {
        histo_t *rebinned = histo_rebin(emit_h, rebin_factor);
        if (rebinned) {
            if (needs_free) histo_destroy(emit_h);
            emit_h = rebinned;
            needs_free = true;
        }
    }

    if (do_cdf) {
        histo_t *cdf_h = histo_cdf(emit_h, 1.0);
        if (cdf_h) {
            if (needs_free) histo_destroy(emit_h);
            emit_h = cdf_h;
            needs_free = true;
        }
    }

    if (norm_area > 0.0) {
        if (!needs_free) {
            emit_h = histo_clone(emit_h, false);
            needs_free = true;
        }
        histo_normalize(emit_h, norm_area);
    }

    histo_status_t status = HISTO_OK;
    if (strcmp(fmt, "binary") == 0 || strcmp(fmt, "bin") == 0) {
        void *buf = NULL;
        size_t size = 0;
        status = histo_serialize_binary(emit_h, &buf, &size);
        if (status == HISTO_OK) {
            fwrite(buf, 1, size, out_fp);
            fflush(out_fp);
            histo_free_buffer(buf);
        }
    } else if (strcmp(fmt, "json") == 0) {
        char *json = NULL;
        status = histo_serialize_json(emit_h, &json);
        if (status == HISTO_OK) {
            fprintf(out_fp, "%s\n", json);
            fflush(out_fp);
            histo_free_buffer(json);
        }
    } else if (strcmp(fmt, "tsv") == 0) {
        uint32_t n = histo_nbins(emit_h);
        for (uint32_t i = 0; i < n; ++i) {
            double lower = 0.0, upper = 0.0, content = 0.0, err = 0.0;
            histo_bin_bounds(emit_h, i, &lower, &upper);
            histo_bin_content(emit_h, i, &content);
            histo_bin_error(emit_h, i, &err);
            fprintf(out_fp, "%u\t%.8g\t%.8g\t%.8g\t%.8g\n", i, lower, upper, content, err);
        }
        fflush(out_fp);
    } else { /* table */
        uint32_t n = histo_nbins(emit_h);
        fprintf(out_fp, "Bin\tLower\tUpper\tContent\tError\n");
        for (uint32_t i = 0; i < n; ++i) {
            double lower = 0.0, upper = 0.0, content = 0.0, err = 0.0;
            histo_bin_bounds(emit_h, i, &lower, &upper);
            histo_bin_content(emit_h, i, &content);
            histo_bin_error(emit_h, i, &err);
            fprintf(out_fp, "[%u]\t%.4f\t%.4f\t%.4f\t%.4f\n", i, lower, upper, content, err);
        }
        fflush(out_fp);
    }

    if (needs_free) {
        histo_destroy(emit_h);
    }
    return status;
}

static histo_status_t emit_histo2d(const histo2d_t *h2, const char *fmt, FILE *out_fp) {
    if (!h2 || !out_fp) return HISTO_ERR_INVALID_ARG;
    histo_status_t status = HISTO_OK;

    if (strcmp(fmt, "binary") == 0 || strcmp(fmt, "bin") == 0) {
        void *buf = NULL;
        size_t size = 0;
        status = histo2d_serialize_binary_alloc(h2, &buf, &size);
        if (status == HISTO_OK) {
            fwrite(buf, 1, size, out_fp);
            fflush(out_fp);
            histo_free_buffer(buf);
        }
    } else if (strcmp(fmt, "json") == 0) {
        char *json = NULL;
        size_t size = 0;
        status = histo2d_serialize_json_alloc(h2, &json, &size);
        if (status == HISTO_OK) {
            fprintf(out_fp, "%s\n", json);
            fflush(out_fp);
            histo_free_buffer(json);
        }
    } else {
        /* TSV / Table */
        uint32_t nx = 0, ny = 0;
        histo2d_axis_t x_axis, y_axis;
        histo2d_axis_x(h2, &x_axis);
        histo2d_axis_y(h2, &y_axis);
        nx = x_axis.nbins;
        ny = y_axis.nbins;


        fprintf(out_fp, "Bin_X\tBin_Y\tCenter_X\tCenter_Y\tContent\tError\n");
        for (uint32_t ix = 0; ix < nx; ++ix) {
            for (uint32_t iy = 0; iy < ny; ++iy) {
                double cx = 0.0, cy = 0.0, content = 0.0, err = 0.0;
                histo2d_bin_center(h2, ix, iy, &cx, &cy);
                histo2d_bin_content(h2, ix, iy, &content);
                histo2d_bin_error(h2, ix, iy, &err);
                fprintf(out_fp, "%u\t%u\t%.4f\t%.4f\t%.4f\t%.4f\n", ix, iy, cx, cy, content, err);
            }
        }
        fflush(out_fp);
    }
    return status;
}

#include "cli_opt.h"

typedef struct {
    double *var_edges;
    size_t n_edges;
} fill_edges_ctx_t;

static int cb_parse_edges(const char *opt_name, const char *val, void *data, char *err_buf, size_t err_size) {
    (void)opt_name;
    fill_edges_ctx_t *ctx = (fill_edges_ctx_t *)data;
    if (!val || !*val) {
        snprintf(err_buf, err_size, "Option '--edges' requires comma-separated numbers");
        return 1;
    }
    const char *p = val;
    size_t edge_cap = 16;
    ctx->var_edges = (double *)malloc(edge_cap * sizeof(double));
    ctx->n_edges = 0;
    while (*p) {
        if (ctx->n_edges >= edge_cap) {
            edge_cap *= 2;
            ctx->var_edges = (double *)realloc(ctx->var_edges, edge_cap * sizeof(double));
        }
        char *endp = NULL;
        ctx->var_edges[ctx->n_edges++] = strtod(p, &endp);
        if (endp == p) break;
        if (*endp == ',') p = endp + 1;
        else p = endp;
    }
    return 0;
}

int histo_cli_fill(int argc, char **argv, FILE *out, FILE *err) {
    if (!out) out = stdout;
    if (!err) err = stderr;

    bool is_2d = false;
    uint32_t nbins = 50;
    double range_min = NAN, range_max = NAN;
    bool auto_range = false;
    const char *auto_bins_rule_str = NULL;
    int auto_bins_rule = -1;

    uint32_t xbins = 0, ybins = 0;
    double xmin = NAN, xmax = NAN, ymin = NAN, ymax = NAN;

    fill_edges_ctx_t edges_ctx = {NULL, 0};
    bool has_weights = false;
    int val_col = 1;
    int x_col = 1, y_col = 2;
    int w_col = 0;
    char delim = '\0';
    bool binary_input = false;
    bool merge_mode = false;
    bool flag_no_sumw2 = false;
    bool flag_exact_moments = false;
    uint32_t flags = HISTO_FLAG_TRACK_SUMW2;
    uint32_t rebin_factor = 1;
    bool do_cdf = false;
    double norm_area = 0.0;
    double scale_input = 1.0;
    const char *out_format = NULL;
    const char *out_file = NULL;
    uint64_t emit_every = 0;
    double emit_interval = 0.0;

    const cli_opt_spec_t specs[] = {
        {'n', "bins", NULL, CLI_OPT_TYPE_UINT32, &nbins, NULL, 0, "N",
         "Number of uniform bins (default: 50)", "50"},
        {'S', "scale-input", NULL, CLI_OPT_TYPE_DOUBLE, &scale_input, NULL, 0, "FACTOR",
         "Multiply incoming measurements by scale factor (e.g. 1e-3 for ns->us)", "1.0"},
        {0, "min", NULL, CLI_OPT_TYPE_DOUBLE, &range_min, NULL, 0, "X",
         "Lower boundary (required unless --auto-range)", NULL},
        {0, "max", NULL, CLI_OPT_TYPE_DOUBLE, &range_max, NULL, 0, "X",
         "Upper boundary (required unless --auto-range)", NULL},
        {0, "edges", NULL, CLI_OPT_TYPE_CALLBACK, &edges_ctx, cb_parse_edges, 0, "E0,E1,...",
         "Variable bin edges (comma-separated)", NULL},
        {0, "auto-range", NULL, CLI_OPT_TYPE_BOOL, &auto_range, NULL, CLI_OPT_FLAG_SET_TRUE, NULL,
         "Buffer input to determine min/max automatically", NULL},
        {'a', "auto-bins", NULL, CLI_OPT_TYPE_STRING, &auto_bins_rule_str, NULL, CLI_OPT_FLAG_OPTIONAL_ARG, "RULE",
         "Buffer input and estimate optimal bins (fd, scott, sturges, doane, knuth)", "auto"},
        {0, "2d", NULL, CLI_OPT_TYPE_BOOL, &is_2d, NULL, CLI_OPT_FLAG_SET_TRUE, NULL,
         "Enable 2D bivariate histogramming mode", NULL},
        {0, "xbins", NULL, CLI_OPT_TYPE_UINT32, &xbins, NULL, 0, "N",
         "Number of bins along X axis (default: 50)", "50"},
        {0, "ybins", NULL, CLI_OPT_TYPE_UINT32, &ybins, NULL, 0, "N",
         "Number of bins along Y axis (default: 50)", "50"},
        {0, "xmin", NULL, CLI_OPT_TYPE_DOUBLE, &xmin, NULL, 0, "X",
         "X axis lower bound", NULL},
        {0, "xmax", NULL, CLI_OPT_TYPE_DOUBLE, &xmax, NULL, 0, "X",
         "X axis upper bound", NULL},
        {0, "ymin", NULL, CLI_OPT_TYPE_DOUBLE, &ymin, NULL, 0, "Y",
         "Y axis lower bound", NULL},
        {0, "ymax", NULL, CLI_OPT_TYPE_DOUBLE, &ymax, NULL, 0, "Y",
         "Y axis upper bound", NULL},
        {'w', "weights", NULL, CLI_OPT_TYPE_BOOL, &has_weights, NULL, CLI_OPT_FLAG_SET_TRUE, NULL,
         "Input contains weights: reads 'x weight' pairs", NULL},
        {0, "value-col", NULL, CLI_OPT_TYPE_INT, &val_col, NULL, 0, "COL",
         "1-based column for sample coordinate (default: 1)", "1"},
        {0, "xcol", NULL, CLI_OPT_TYPE_INT, &x_col, NULL, 0, "COL",
         "1-based column for X coordinate in 2D mode (default: 1)", "1"},
        {0, "ycol", NULL, CLI_OPT_TYPE_INT, &y_col, NULL, 0, "COL",
         "1-based column for Y coordinate in 2D mode (default: 2)", "2"},
        {0, "weights-col", NULL, CLI_OPT_TYPE_INT, &w_col, NULL, 0, "COL",
         "1-based column for sample weight (default: 2 for 1D, 3 for 2D)", NULL},
        {'d', "delimiter", NULL, CLI_OPT_TYPE_CHAR, &delim, NULL, 0, "CHAR",
         "Field delimiter character (default: auto-detect)", NULL},
        {0, "binary-f64", NULL, CLI_OPT_TYPE_BOOL, &binary_input, NULL, CLI_OPT_FLAG_SET_TRUE, NULL,
         "Read raw Little-Endian double binary stream", NULL},
        {0, "merge", NULL, CLI_OPT_TYPE_BOOL, &merge_mode, NULL, CLI_OPT_FLAG_SET_TRUE, NULL,
         "Read and add/merge incoming serialized histograms", NULL},
        {0, "sumw2", NULL, CLI_OPT_TYPE_BOOL, &flags, NULL, CLI_OPT_FLAG_HIDDEN, NULL, NULL, NULL},
        {0, "no-sumw2", NULL, CLI_OPT_TYPE_BOOL, &flag_no_sumw2, NULL, CLI_OPT_FLAG_SET_TRUE, NULL,
         "Disable sum_w2 error tracking", NULL},
        {0, "exact-moments", NULL, CLI_OPT_TYPE_BOOL, &flag_exact_moments, NULL, CLI_OPT_FLAG_SET_TRUE, NULL,
         "Enable online exact Welford moments", NULL},
        {0, "rebin", NULL, CLI_OPT_TYPE_UINT32, &rebin_factor, NULL, 0, "FACTOR",
         "Rebin uniform histogram by integer factor (1D only)", NULL},
        {0, "cdf", NULL, CLI_OPT_TYPE_BOOL, &do_cdf, NULL, CLI_OPT_FLAG_SET_TRUE, NULL,
         "Generate Cumulative Distribution Function (CDF)", NULL},
        {0, "normalize", NULL, CLI_OPT_TYPE_DOUBLE, &norm_area, NULL, 0, "AREA",
         "Scale histogram total weight to target area", NULL},
        {'o', "output", NULL, CLI_OPT_TYPE_STRING, &out_format, NULL, 0, "FORMAT",
         "Output format: binary (default for pipes), json, tsv, table", NULL},
        {'f', "output-file", "file", CLI_OPT_TYPE_STRING, &out_file, NULL, 0, "FILE",
         "Output destination (default: stdout)", NULL},
        {0, "emit-every", NULL, CLI_OPT_TYPE_UINT64, &emit_every, NULL, 0, "N",
         "Emit intermediate snapshot every N samples", NULL},
        {0, "emit-interval", NULL, CLI_OPT_TYPE_DOUBLE, &emit_interval, NULL, 0, "S",
         "Emit intermediate snapshot every S seconds", NULL}
    };

    cli_opt_parser_t parser;
    cli_opt_init(&parser, specs, sizeof(specs) / sizeof(specs[0]),
                 "histo-fill", "[OPTIONS] [FILE...]",
                 "Reads streaming data, aggregates into a histogram (1D or 2D), and emits the serialized result.");

    int rc = cli_opt_parse(&parser, argc, argv, 1);
    if (rc < 0) {
        cli_opt_print_help(&parser, out);
        if (edges_ctx.var_edges) free(edges_ctx.var_edges);
        cli_opt_free(&parser);
        return 0;
    }
    if (rc > 0) {
        fprintf(err, "%s\n", cli_opt_error(&parser));
        if (edges_ctx.var_edges) free(edges_ctx.var_edges);
        cli_opt_free(&parser);
        return 1;
    }

    if (auto_bins_rule_str) {
        auto_range = true;
        if (strcasecmp(auto_bins_rule_str, "fd") == 0) auto_bins_rule = HISTO_BIN_RULE_FD;
        else if (strcasecmp(auto_bins_rule_str, "scott") == 0) auto_bins_rule = HISTO_BIN_RULE_SCOTT;
        else if (strcasecmp(auto_bins_rule_str, "sturges") == 0) auto_bins_rule = HISTO_BIN_RULE_STURGES;
        else if (strcasecmp(auto_bins_rule_str, "doane") == 0) auto_bins_rule = HISTO_BIN_RULE_DOANE;
        else if (strcasecmp(auto_bins_rule_str, "knuth") == 0) auto_bins_rule = HISTO_BIN_RULE_KNUTH;
        else auto_bins_rule = HISTO_BIN_RULE_AUTO;
    }

    bool has_min = !isnan(range_min);
    bool has_max = !isnan(range_max);
    bool has_xmin = !isnan(xmin);
    bool has_xmax = !isnan(xmax);
    bool has_ymin = !isnan(ymin);
    bool has_ymax = !isnan(ymax);

    if (has_xmin || has_xmax || has_ymin || has_ymax || xbins > 0 || ybins > 0) {
        is_2d = true;
    }
    if (xbins == 0) xbins = 50;
    if (ybins == 0) ybins = 50;

    if (w_col != 0) {
        has_weights = true;
    } else {
        w_col = is_2d ? 3 : 2;
    }

    if (flag_no_sumw2) flags &= ~HISTO_FLAG_TRACK_SUMW2;
    if (flag_exact_moments) flags |= HISTO_FLAG_EXACT_MOMENTS;

    double *var_edges = edges_ctx.var_edges;
    size_t n_edges = edges_ctx.n_edges;

    if (!out_format) {
        out_format = ((out == stdout) && cli_is_stdout_tty() && !out_file) ? "json" : "binary";
    }

    FILE *out_fp = out;
    if (out_file && strcmp(out_file, "-") != 0) {
        out_fp = fopen(out_file, "wb");
        if (!out_fp) {
            fprintf(err, "Error: Cannot open output file '%s'\n", out_file);
            if (var_edges) free(var_edges);
            cli_opt_free(&parser);
            return 1;
        }
    }

    const char *default_files[] = {"-"};
    const char **files = (parser.num_positionals > 0) ? parser.positionals : default_files;
    int nfiles = (parser.num_positionals > 0) ? parser.num_positionals : 1;

    if (is_2d) {
        /* -------------------------------------------------------------
         * 2D Histogram Ingestion Pipeline
         * ------------------------------------------------------------- */
        double *x_samples = NULL, *y_samples = NULL, *w_samples = NULL;
        size_t count_2d = 0, cap_2d = 0;
        bool auto_range_2d = (!has_xmin || !has_xmax || !has_ymin || !has_ymax || auto_range);
        uint64_t sample_count_2d = 0;
        double last_emit_time_2d = cli_get_time_sec();


        histo2d_t *h2 = NULL;
        if (!auto_range_2d) {
            h2 = histo2d_create_uniform(xbins, xmin, xmax, ybins, ymin, ymax, flags);
            if (!h2) {
                fprintf(stderr, "Error: Failed to initialize 2D histogram.\n");
                if (out_fp != stdout) fclose(out_fp);
                return 1;
            }
        }

        for (int f = 0; f < nfiles; ++f) {
            FILE *in_fp = strcmp(files[f], "-") == 0 ? stdin : fopen(files[f], "r");
            if (!in_fp) {
                fprintf(stderr, "Warning: Cannot open input file '%s'\n", files[f]);
                continue;
            }

            char line[4096];
            char detected_delim = delim;

            while (fgets(line, sizeof(line), in_fp)) {
                char *p = line;
                while (*p && isspace((unsigned char)*p)) p++;
                if (*p == '\0' || *p == '#') continue;

                if (detected_delim == '\0') {
                    detected_delim = auto_detect_delimiter(p);
                }

                double vx = 0.0, vy = 0.0, vw = 1.0;
                bool parsed_x = false, parsed_y = false;

                if (detected_delim != ' ') {
                    int col = 1;
                    char *tok = strtok(p, (char[]){detected_delim, '\0'});
                    while (tok) {
                        if (col == x_col) { vx = atof(tok); parsed_x = true; }
                        else if (col == y_col) { vy = atof(tok); parsed_y = true; }
                        else if (has_weights && col == w_col) { vw = atof(tok); }
                        tok = strtok(NULL, (char[]){detected_delim, '\0'});
                        col++;
                    }
                } else {
                    int col = 1;
                    char *tok = strtok(p, " \t\r\n");
                    while (tok) {
                        if (col == x_col) { vx = atof(tok); parsed_x = true; }
                        else if (col == y_col) { vy = atof(tok); parsed_y = true; }
                        else if (has_weights && col == w_col) { vw = atof(tok); }
                        tok = strtok(NULL, " \t\r\n");
                        col++;
                    }
                }

                if (!parsed_x || !parsed_y) continue;
                if (scale_input > 0.0 && scale_input != 1.0) {
                    vx *= scale_input;
                    vy *= scale_input;
                }

                if (auto_range_2d) {
                    if (count_2d >= cap_2d) {
                        cap_2d = cap_2d == 0 ? 1024 : cap_2d * 2;
                        x_samples = (double *)realloc(x_samples, cap_2d * sizeof(double));
                        y_samples = (double *)realloc(y_samples, cap_2d * sizeof(double));
                        if (has_weights) w_samples = (double *)realloc(w_samples, cap_2d * sizeof(double));
                    }
                    x_samples[count_2d] = vx;
                    y_samples[count_2d] = vy;
                    if (has_weights) w_samples[count_2d] = vw;
                    count_2d++;
                } else {
                    histo2d_fill_w(h2, vx, vy, vw);
                    sample_count_2d++;
                    if ((emit_every > 0 && sample_count_2d % emit_every == 0) ||
                        (emit_interval > 0.0 && (cli_get_time_sec() - last_emit_time_2d) >= emit_interval)) {
                        emit_histo2d(h2, out_format, out_fp);
                        last_emit_time_2d = cli_get_time_sec();
                    }
                }
            }
            if (in_fp != stdin) fclose(in_fp);
        }


        if (auto_range_2d) {
            if (count_2d == 0) {
                xmin = 0.0; xmax = 100.0; ymin = 0.0; ymax = 100.0;
            } else {
                xmin = x_samples[0]; xmax = x_samples[0];
                ymin = y_samples[0]; ymax = y_samples[0];
                for (size_t i = 1; i < count_2d; ++i) {
                    if (x_samples[i] < xmin) xmin = x_samples[i];
                    if (x_samples[i] > xmax) xmax = x_samples[i];
                    if (y_samples[i] < ymin) ymin = y_samples[i];
                    if (y_samples[i] > ymax) ymax = y_samples[i];
                }
                if (fabs(xmax - xmin) < 1e-12) { xmin -= 1.0; xmax += 1.0; }
                else { xmax += (xmax - xmin) * 1e-6; }
                if (fabs(ymax - ymin) < 1e-12) { ymin -= 1.0; ymax += 1.0; }
                else { ymax += (ymax - ymin) * 1e-6; }
            }

            h2 = histo2d_create_uniform(xbins, xmin, xmax, ybins, ymin, ymax, flags);
            if (h2) {
                if (has_weights && w_samples) {
                    histo2d_fill_n(h2, count_2d, x_samples, y_samples, w_samples);
                } else {
                    histo2d_fill_n(h2, count_2d, x_samples, y_samples, NULL);
                }
            }
            if (x_samples) free(x_samples);
            if (y_samples) free(y_samples);
            if (w_samples) free(w_samples);
        }

        if (h2) {
            emit_histo2d(h2, out_format, out_fp);
            histo2d_destroy(h2);
        }
        if (out_fp != out && out_fp != stdout) fclose(out_fp);
        cli_opt_free(&parser);
        return 0;
    }

    /* -------------------------------------------------------------
     * 1D Histogram Ingestion Pipeline
     * ------------------------------------------------------------- */
    double *auto_samples = NULL;
    double *auto_weights = NULL;
    size_t auto_count = 0;
    size_t auto_cap = 0;

    if (!has_min || !has_max) {
        if (!var_edges) {
            auto_range = true;
        }
    }

    histo_t *h = NULL;
    if (!auto_range) {
        if (var_edges && n_edges >= 2) {
            h = histo_create_variable((uint32_t)(n_edges - 1), var_edges, flags);
        } else {
            if (range_min >= range_max) {
                range_min = 0.0;
                range_max = 100.0;
            }
            h = histo_create_uniform(nbins, range_min, range_max, flags);
        }
        if (!h) {
            fprintf(stderr, "Error: Failed to initialize histogram.\n");
            if (var_edges) free(var_edges);
            if (out_fp != stdout) fclose(out_fp);
            cli_opt_free(&parser);
            return 1;
        }
    }

    uint64_t sample_count = 0;
    double last_emit_time = cli_get_time_sec();

    for (int f = 0; f < nfiles; ++f) {
        FILE *in_fp = NULL;
        if (strcmp(files[f], "-") == 0) {
            in_fp = stdin;
        } else {
            in_fp = fopen(files[f], binary_input || merge_mode ? "rb" : "r");
            if (!in_fp) {
                fprintf(stderr, "Warning: Cannot open input file '%s'\n", files[f]);
                continue;
            }
        }

        if (merge_mode) {
            histo_t *incoming = NULL;
            while (cli_read_histogram_from_stream(in_fp, &incoming) == HISTO_OK) {
                if (!h) {
                    h = incoming;
                } else {
                    histo_add(h, incoming);
                    histo_destroy(incoming);
                }
            }
        } else if (binary_input) {
            double val_buf[2];
            size_t needed = has_weights ? 2 : 1;
            while (fread(val_buf, sizeof(double), needed, in_fp) == needed) {
                double x = val_buf[0] * (scale_input > 0.0 ? scale_input : 1.0);
                double w = has_weights ? val_buf[1] : 1.0;
                if (auto_range) {
                    if (auto_count >= auto_cap) {
                        auto_cap = auto_cap == 0 ? 1024 : auto_cap * 2;
                        auto_samples = (double *)realloc(auto_samples, auto_cap * sizeof(double));
                        if (has_weights) auto_weights = (double *)realloc(auto_weights, auto_cap * sizeof(double));
                    }
                    auto_samples[auto_count] = x;
                    if (has_weights) auto_weights[auto_count] = w;
                    auto_count++;
                } else {
                    histo_fill_w(h, x, w);
                    sample_count++;
                    if ((emit_every > 0 && sample_count % emit_every == 0) ||
                        (emit_interval > 0.0 && (cli_get_time_sec() - last_emit_time) >= emit_interval)) {
                        emit_histogram(h, out_format, out_fp, rebin_factor, do_cdf, norm_area);
                        last_emit_time = cli_get_time_sec();
                    }
                }
            }
        } else {
            /* Check if input stream is a pre-formatted histogram (e.g. bpftrace table or JSON) */
            cli_input_format_t fmt = cli_detect_stream_format(in_fp);
            if (fmt == CLI_INPUT_BPFTRACE_HISTO || fmt == CLI_INPUT_JSON_HISTO || fmt == CLI_INPUT_BINARY_HISTO) {
                histo_t *incoming = NULL;
                while (cli_read_histogram_from_stream(in_fp, &incoming) == HISTO_OK) {
                    if (!h) {
                        h = incoming;
                    } else {
                        histo_add(h, incoming);
                        histo_destroy(incoming);
                    }
                }
                auto_range = false;
            } else {
                /* Text line parsing with delimiter auto-detection */
                char line[2048];
                char detected_delim = delim;

                while (fgets(line, sizeof(line), in_fp)) {
                    char *p = line;
                    while (*p && isspace((unsigned char)*p)) p++;
                    if (*p == '\0' || *p == '#') continue;

                    if (detected_delim == '\0') {
                        detected_delim = auto_detect_delimiter(p);
                    }

                    double x = 0.0, w = 1.0;
                    bool parsed_x = false;

                    if (detected_delim != ' ') {
                        int col = 1;
                        char *tok = strtok(p, (char[]){detected_delim, '\0'});
                        while (tok) {
                            if (col == val_col) {
                                x = atof(tok);
                                parsed_x = true;
                            } else if (has_weights && col == w_col) {
                                w = atof(tok);
                            }
                            tok = strtok(NULL, (char[]){detected_delim, '\0'});
                            col++;
                        }
                    } else {
                        int col = 1;
                        char *tok = strtok(p, " \t\r\n");
                        while (tok) {
                            if (col == val_col) {
                                x = atof(tok);
                                parsed_x = true;
                            } else if (has_weights && col == w_col) {
                                w = atof(tok);
                            }
                            tok = strtok(NULL, " \t\r\n");
                            col++;
                        }
                    }

                    if (!parsed_x) continue;
                    if (scale_input > 0.0 && scale_input != 1.0) {
                        x *= scale_input;
                    }

                    if (auto_range) {
                        if (auto_count >= auto_cap) {
                            auto_cap = auto_cap == 0 ? 1024 : auto_cap * 2;
                            auto_samples = (double *)realloc(auto_samples, auto_cap * sizeof(double));
                            if (has_weights) auto_weights = (double *)realloc(auto_weights, auto_cap * sizeof(double));
                        }
                        auto_samples[auto_count] = x;
                        if (has_weights) auto_weights[auto_count] = w;
                        auto_count++;
                    } else {
                        histo_fill_w(h, x, w);
                        sample_count++;
                        if ((emit_every > 0 && sample_count % emit_every == 0) ||
                            (emit_interval > 0.0 && (cli_get_time_sec() - last_emit_time) >= emit_interval)) {
                            emit_histogram(h, out_format, out_fp, rebin_factor, do_cdf, norm_area);
                            last_emit_time = cli_get_time_sec();
                        }
                    }
                }
            }
        }

        if (in_fp != stdin) fclose(in_fp);
    }

    if (auto_range) {
        if (auto_count == 0) {
            range_min = 0.0;
            range_max = 100.0;
        } else if (auto_bins_rule >= 0) {
            uint32_t opt_nbins = 0;
            double opt_min = 0.0, opt_max = 0.0;
            histo_status_t st = histo_estimate_bins(auto_count, auto_samples, (histo_bin_rule_t)auto_bins_rule, &opt_nbins, &opt_min, &opt_max);
            if (st == HISTO_OK && opt_nbins > 0) {
                nbins = opt_nbins;
                range_min = opt_min;
                range_max = opt_max;
            }
            double pad = ((range_max - range_min) / (double)nbins) * 1e-6;
            if (pad <= 0.0) pad = 1e-6;
            range_max += pad;
        } else {
            range_min = auto_samples[0];
            range_max = auto_samples[0];
            for (size_t i = 1; i < auto_count; ++i) {
                if (auto_samples[i] < range_min) range_min = auto_samples[i];
                if (auto_samples[i] > range_max) range_max = auto_samples[i];
            }
            if (fabs(range_max - range_min) < 1e-12) {
                range_min -= 1.0;
                range_max += 1.0;
            } else {
                double pad = (range_max - range_min) * 1e-6;
                range_max += pad;
            }
        }

        h = histo_create_uniform(nbins, range_min, range_max, flags);
        if (h) {
            if (has_weights && auto_weights) {
                histo_fill_n(h, auto_count, auto_samples, auto_weights);
            } else {
                histo_fill_n(h, auto_count, auto_samples, NULL);
            }
        }
        if (auto_samples) free(auto_samples);
        if (auto_weights) free(auto_weights);
    }

    if (h) {
        emit_histogram(h, out_format, out_fp, rebin_factor, do_cdf, norm_area);
        histo_destroy(h);
    }

    if (var_edges) free(var_edges);
    if (out_fp != out && out_fp != stdout) fclose(out_fp);
    cli_opt_free(&parser);
    return 0;
}
