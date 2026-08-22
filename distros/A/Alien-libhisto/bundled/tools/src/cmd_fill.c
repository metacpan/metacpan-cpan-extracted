/*
 * CLI subcommand histo fill: ingest data streams and serialize histograms.
 */

#include "cli_common.h"
#include "histo/histo2d.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdbool.h>
#include <ctype.h>
#include <math.h>
#include <unistd.h>


static void print_fill_usage(FILE *out) {
    if (!out) out = stdout;
    fprintf(out, "Usage: histo-fill [OPTIONS] [FILE...]\n");
    fprintf(out, "       histo fill [OPTIONS] [FILE...]\n\n");
    fprintf(out, "Reads streaming data, aggregates into a histogram (1D or 2D), and emits the serialized result.\n\n");
    fprintf(out, "1D Geometry Options:\n");
    fprintf(out, "  -n, --bins=<N>           Number of uniform bins (default: 50)\n");
    fprintf(out, "      --min=<X>            Lower boundary (required unless --auto-range)\n");
    fprintf(out, "      --max=<X>            Upper boundary (required unless --auto-range)\n");
    fprintf(out, "      --edges=<E0,E1,...>  Variable bin edges (comma-separated)\n");
    fprintf(out, "      --auto-range         Buffer input to determine min/max automatically\n");
    fprintf(out, "  -a, --auto-bins[=RULE]   Buffer input and estimate optimal bins (fd, scott, sturges, doane, knuth)\n\n");
    fprintf(out, "2D Geometry Options:\n");
    fprintf(out, "      --2d                 Enable 2D bivariate histogramming mode\n");
    fprintf(out, "      --xbins=<N>          Number of bins along X axis (default: 50)\n");
    fprintf(out, "      --xmin=<X>, --xmax=<X> X axis bounds\n");
    fprintf(out, "      --ybins=<N>          Number of bins along Y axis (default: 50)\n");
    fprintf(out, "      --ymin=<Y>, --ymax=<Y> Y axis bounds\n\n");
    fprintf(out, "Input Parsing & Columns:\n");
    fprintf(out, "  -w, --weights            Input contains weights: reads 'x weight' pairs\n");
    fprintf(out, "      --value-col=<COL>    1-based column for sample coordinate (default: 1)\n");
    fprintf(out, "      --xcol=<COL>         1-based column for X coordinate in 2D mode (default: 1)\n");
    fprintf(out, "      --ycol=<COL>         1-based column for Y coordinate in 2D mode (default: 2)\n");
    fprintf(out, "      --weights-col=<COL>  1-based column for sample weight (default: 2 for 1D, 3 for 2D)\n");
    fprintf(out, "  -d, --delimiter=<CHAR>   Field delimiter character (default: auto-detect comma/tab/semicolon/space)\n");
    fprintf(out, "      --binary-f64         Read raw Little-Endian double binary stream\n");
    fprintf(out, "      --merge              Read and add/merge incoming serialized histograms\n\n");
    fprintf(out, "Histogram Features & Transformations:\n");
    fprintf(out, "      --sumw2              Enable sum_w2 error tracking (default: ON)\n");
    fprintf(out, "      --no-sumw2           Disable sum_w2 error tracking\n");
    fprintf(out, "      --exact-moments      Enable online exact Welford moments\n");
    fprintf(out, "      --rebin=<FACTOR>     Rebin uniform histogram by integer factor (1D only)\n");
    fprintf(out, "      --slice=<MIN:MAX>    Slice bin sub-range [MIN, MAX]\n");
    fprintf(out, "      --cdf                Generate Cumulative Distribution Function (CDF)\n");
    fprintf(out, "      --normalize=<AREA>   Scale histogram total weight to target area\n\n");
    fprintf(out, "Output & Streaming Options:\n");
    fprintf(out, "  -o, --output=<FORMAT>    Output format: binary (default for pipes), json, tsv, table\n");
    fprintf(out, "  -f, --output-file=<FILE> Output destination (default: stdout)\n");
    fprintf(out, "      --emit-every=<N>     Emit intermediate snapshot every N samples\n");
    fprintf(out, "      --emit-interval=<S>  Emit intermediate snapshot every S seconds\n");
    fprintf(out, "  -h, --help               Show this help message\n");
}


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

int histo_cli_fill(int argc, char **argv, FILE *out, FILE *err) {
    if (!out) out = stdout;
    if (!err) err = stderr;
    optind = 1;

    bool is_2d = false;
    uint32_t nbins = 50;
    double range_min = 0.0, range_max = 0.0;
    bool has_min = false, has_max = false;
    bool auto_range = false;
    int auto_bins_rule = -1;

    uint32_t xbins = 50, ybins = 50;
    double xmin = 0.0, xmax = 0.0, ymin = 0.0, ymax = 0.0;
    bool has_xmin = false, has_xmax = false, has_ymin = false, has_ymax = false;

    double *var_edges = NULL;
    size_t n_edges = 0;
    bool has_weights = false;
    int val_col = 1;
    int x_col = 1, y_col = 2;
    int w_col = 2;
    bool w_col_set = false;
    char delim = '\0';
    bool binary_input = false;
    bool merge_mode = false;
    uint32_t flags = HISTO_FLAG_TRACK_SUMW2;
    uint32_t rebin_factor = 1;
    bool do_cdf = false;
    double norm_area = 0.0;
    const char *out_format = NULL;
    const char *out_file = NULL;
    uint64_t emit_every = 0;
    double emit_interval = 0.0;

    int file_start = argc;

    for (int i = 1; i < argc; ++i) {
        const char *arg = argv[i];
        if (strcmp(arg, "-h") == 0 || strcmp(arg, "--help") == 0) {
            print_fill_usage(out);
            if (var_edges) free(var_edges);
            return 0;
        } else if (strcmp(arg, "--2d") == 0) {
            is_2d = true;
            if (!w_col_set) w_col = 3;
        }
 else if (strncmp(arg, "-n=", 3) == 0 || strncmp(arg, "--bins=", 7) == 0 || strcmp(arg, "-n") == 0 || strcmp(arg, "--bins") == 0) {
            const char *val = (arg[1] == 'n' && arg[2] == '=') ? arg + 3 :
                              (strncmp(arg, "--bins=", 7) == 0) ? arg + 7 :
                              (i + 1 < argc) ? argv[++i] : NULL;
            if (val) nbins = (uint32_t)atoi(val);
        } else if (strncmp(arg, "--xbins=", 8) == 0 || strcmp(arg, "--xbins") == 0) {
            const char *val = (strncmp(arg, "--xbins=", 8) == 0) ? arg + 8 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) xbins = (uint32_t)atoi(val);
            is_2d = true;
        } else if (strncmp(arg, "--ybins=", 8) == 0 || strcmp(arg, "--ybins") == 0) {
            const char *val = (strncmp(arg, "--ybins=", 8) == 0) ? arg + 8 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) ybins = (uint32_t)atoi(val);
            is_2d = true;
        } else if (strncmp(arg, "--xmin=", 7) == 0 || strcmp(arg, "--xmin") == 0) {
            const char *val = (strncmp(arg, "--xmin=", 7) == 0) ? arg + 7 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) { xmin = atof(val); has_xmin = true; is_2d = true; }
        } else if (strncmp(arg, "--xmax=", 7) == 0 || strcmp(arg, "--xmax") == 0) {
            const char *val = (strncmp(arg, "--xmax=", 7) == 0) ? arg + 7 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) { xmax = atof(val); has_xmax = true; is_2d = true; }
        } else if (strncmp(arg, "--ymin=", 7) == 0 || strcmp(arg, "--ymin") == 0) {
            const char *val = (strncmp(arg, "--ymin=", 7) == 0) ? arg + 7 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) { ymin = atof(val); has_ymin = true; is_2d = true; }
        } else if (strncmp(arg, "--ymax=", 7) == 0 || strcmp(arg, "--ymax") == 0) {
            const char *val = (strncmp(arg, "--ymax=", 7) == 0) ? arg + 7 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) { ymax = atof(val); has_ymax = true; is_2d = true; }
        } else if (strncmp(arg, "--min=", 6) == 0 || strcmp(arg, "--min") == 0) {
            const char *val = (strncmp(arg, "--min=", 6) == 0) ? arg + 6 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) { range_min = atof(val); has_min = true; }
        } else if (strncmp(arg, "--max=", 6) == 0 || strcmp(arg, "--max") == 0) {
            const char *val = (strncmp(arg, "--max=", 6) == 0) ? arg + 6 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) { range_max = atof(val); has_max = true; }
        } else if (strcmp(arg, "--auto-range") == 0) {
            auto_range = true;
        } else if (strncmp(arg, "--auto-bins=", 12) == 0 || strcmp(arg, "--auto-bins") == 0 || strcmp(arg, "-a") == 0) {
            auto_range = true;
            const char *val = (strncmp(arg, "--auto-bins=", 12) == 0) ? arg + 12 :
                              (strcmp(arg, "--auto-bins") == 0 || strcmp(arg, "-a") == 0) ?
                              ((i + 1 < argc && argv[i + 1][0] != '-') ? argv[++i] : "auto") : "auto";
            if (val) {
                if (strcasecmp(val, "fd") == 0) auto_bins_rule = HISTO_BIN_RULE_FD;
                else if (strcasecmp(val, "scott") == 0) auto_bins_rule = HISTO_BIN_RULE_SCOTT;
                else if (strcasecmp(val, "sturges") == 0) auto_bins_rule = HISTO_BIN_RULE_STURGES;
                else if (strcasecmp(val, "doane") == 0) auto_bins_rule = HISTO_BIN_RULE_DOANE;
                else if (strcasecmp(val, "knuth") == 0) auto_bins_rule = HISTO_BIN_RULE_KNUTH;
                else auto_bins_rule = HISTO_BIN_RULE_AUTO;
            }
        } else if (strcmp(arg, "-w") == 0 || strcmp(arg, "--weights") == 0) {
            has_weights = true;
        } else if (strncmp(arg, "--value-col=", 12) == 0 || strcmp(arg, "--value-col") == 0) {
            const char *val = (strncmp(arg, "--value-col=", 12) == 0) ? arg + 12 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) val_col = atoi(val);
        } else if (strncmp(arg, "--xcol=", 7) == 0 || strcmp(arg, "--xcol") == 0) {
            const char *val = (strncmp(arg, "--xcol=", 7) == 0) ? arg + 7 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) { x_col = atoi(val); is_2d = true; }
        } else if (strncmp(arg, "--ycol=", 7) == 0 || strcmp(arg, "--ycol") == 0) {
            const char *val = (strncmp(arg, "--ycol=", 7) == 0) ? arg + 7 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) { y_col = atoi(val); is_2d = true; }
        } else if (strncmp(arg, "--weights-col=", 14) == 0 || strcmp(arg, "--weights-col") == 0) {
            const char *val = (strncmp(arg, "--weights-col=", 14) == 0) ? arg + 14 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) { w_col = atoi(val); has_weights = true; w_col_set = true; }

        } else if (strncmp(arg, "-d=", 3) == 0 || strncmp(arg, "--delimiter=", 12) == 0 || strcmp(arg, "-d") == 0) {
            const char *val = (arg[1] == 'd' && arg[2] == '=') ? arg + 3 :
                              (strncmp(arg, "--delimiter=", 12) == 0) ? arg + 12 :
                              (i + 1 < argc) ? argv[++i] : NULL;
            if (val && *val) delim = val[0];
        } else if (strcmp(arg, "--binary-f64") == 0) {
            binary_input = true;
        } else if (strcmp(arg, "--merge") == 0) {
            merge_mode = true;
        } else if (strcmp(arg, "--sumw2") == 0) {
            flags |= HISTO_FLAG_TRACK_SUMW2;
        } else if (strcmp(arg, "--no-sumw2") == 0) {
            flags &= ~HISTO_FLAG_TRACK_SUMW2;
        } else if (strcmp(arg, "--exact-moments") == 0) {
            flags |= HISTO_FLAG_EXACT_MOMENTS;
        } else if (strncmp(arg, "--rebin=", 8) == 0) {
            rebin_factor = (uint32_t)atoi(arg + 8);
        } else if (strcmp(arg, "--cdf") == 0) {
            do_cdf = true;
        } else if (strncmp(arg, "--normalize=", 12) == 0) {
            norm_area = atof(arg + 12);
        } else if (strncmp(arg, "-o=", 3) == 0) {
            out_format = arg + 3;
        } else if (strcmp(arg, "-o") == 0 && i + 1 < argc) {
            out_format = argv[++i];
        } else if (strncmp(arg, "--output=", 9) == 0) {
            out_format = arg + 9;
        } else if (strncmp(arg, "-f=", 3) == 0) {
            out_file = arg + 3;
        } else if (strcmp(arg, "-f") == 0 && i + 1 < argc) {
            out_file = argv[++i];
        } else if (strncmp(arg, "--output-file=", 14) == 0) {
            out_file = arg + 14;
        } else if (strncmp(arg, "--emit-every=", 13) == 0 || strcmp(arg, "--emit-every") == 0) {
            const char *val = (strncmp(arg, "--emit-every=", 13) == 0) ? arg + 13 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) emit_every = (uint64_t)strtoull(val, NULL, 10);
        } else if (strncmp(arg, "--emit-interval=", 16) == 0 || strcmp(arg, "--emit-interval") == 0) {
            const char *val = (strncmp(arg, "--emit-interval=", 16) == 0) ? arg + 16 : (i + 1 < argc) ? argv[++i] : NULL;
            if (val) emit_interval = atof(val);
        } else if (strncmp(arg, "--edges=", 8) == 0) {

            const char *p = arg + 8;
            size_t edge_cap = 16;
            var_edges = (double *)malloc(edge_cap * sizeof(double));
            n_edges = 0;
            while (*p) {
                if (n_edges >= edge_cap) {
                    edge_cap *= 2;
                    var_edges = (double *)realloc(var_edges, edge_cap * sizeof(double));
                }
                char *endp = NULL;
                var_edges[n_edges++] = strtod(p, &endp);
                if (endp == p) break;
                if (*endp == ',') p = endp + 1;
                else p = endp;
            }
        } else if (arg[0] == '-' && arg[1] != '\0') {
            fprintf(stderr, "Unknown option '%s'. Run 'histo-fill --help' for usage.\n", arg);
            if (var_edges) free(var_edges);
            return 1;
        } else {
            file_start = i;
            break;
        }
    }

    if (!out_format) {
        out_format = ((out == stdout) && cli_is_stdout_tty() && !out_file) ? "json" : "binary";
    }

    FILE *out_fp = out;
    if (out_file && strcmp(out_file, "-") != 0) {
        out_fp = fopen(out_file, "wb");
        if (!out_fp) {
            fprintf(err, "Error: Cannot open output file '%s'\n", out_file);
            if (var_edges) free(var_edges);
            return 1;
        }
    }


    int num_files = argc - file_start;
    const char *default_files[] = {"-"};
    const char **files = (num_files > 0) ? (const char **)(argv + file_start) : default_files;
    int nfiles = (num_files > 0) ? num_files : 1;

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
            h = histo_create_variable(n_edges - 1, var_edges, flags);
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
                double x = val_buf[0];
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
    return 0;
}
