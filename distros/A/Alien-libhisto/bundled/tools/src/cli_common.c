/*
 * Implementation of CLI stream readers, file format decoders, and formatting.
 */

#include "cli_common.h"
#include <ctype.h>
#include <math.h>

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#else
#include <sys/ioctl.h>
#include <sys/time.h>
#endif

int cli_get_terminal_width(int default_width) {
    const char *col_env = getenv("COLUMNS");
    if (col_env && *col_env) {
        int val = atoi(col_env);
        if (val > 10) return val;
    }
#if defined(_WIN32)
    HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hOut != INVALID_HANDLE_VALUE) {
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        if (GetConsoleScreenBufferInfo(hOut, &csbi)) {
            int w = csbi.srWindow.Right - csbi.srWindow.Left + 1;
            if (w > 10) return w;
        }
    }
#elif defined(TIOCGWINSZ)
    struct winsize ws;
    if (isatty(STDOUT_FILENO) && ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0) {
        if (ws.ws_col > 10) return (int)ws.ws_col;
    }
#endif
    return default_width > 10 ? default_width : 80;
}

int cli_get_terminal_height(int default_height) {
    const char *lines_env = getenv("LINES");
    if (lines_env && *lines_env) {
        int val = atoi(lines_env);
        if (val > 4) return val;
    }
#if defined(_WIN32)
    HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hOut != INVALID_HANDLE_VALUE) {
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        if (GetConsoleScreenBufferInfo(hOut, &csbi)) {
            int h = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
            if (h > 4) return h;
        }
    }
#elif defined(TIOCGWINSZ)
    struct winsize ws;
    if (isatty(STDOUT_FILENO) && ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0) {
        if (ws.ws_row > 4) return (int)ws.ws_row;
    }
#endif
    return default_height > 4 ? default_height : 24;
}

bool cli_is_stdout_tty(void) {
    return isatty(STDOUT_FILENO) != 0;
}

double cli_get_time_sec(void) {
#if defined(_WIN32)
    static LARGE_INTEGER freq;
    static bool init_freq = false;
    if (!init_freq) {
        QueryPerformanceFrequency(&freq);
        init_freq = true;
    }
    LARGE_INTEGER count;
    QueryPerformanceCounter(&count);
    return (double)count.QuadPart / (double)freq.QuadPart;
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec * 1e-6;
#endif
}

/* ========================================================================= */
/* bpftrace Output Stream Parser & Geometry Reconstruction                    */
/* ========================================================================= */

typedef struct {
    double low;
    double high;
    double count;
} bpftrace_bucket_t;

static bool parse_bpftrace_num(const char *str, char **endptr, double *out_val) {
    if (!str || !out_val) return false;
    while (*str && isspace((unsigned char)*str)) str++;
    if (*str == '\0') return false;

    char *end = NULL;
    double val = strtod(str, &end);
    if (end == str) return false;

    /* Check unit multiplier */
    double mult = 1.0;
    if (*end == 'K' || *end == 'k') {
        if (*(end + 1) == 'i' || *(end + 1) == 'I') {
            if (*(end + 2) == 'B' || *(end + 2) == 'b') end += 3;
            else end += 2;
        } else if (*(end + 1) == 'B' || *(end + 1) == 'b') {
            end += 2;
        } else {
            end += 1;
        }
        mult = 1024.0;
    } else if (*end == 'M' || *end == 'm') {
        if (*(end + 1) == 's' || *(end + 1) == 'S') {
            /* Milliseconds */
            end += 2;
            mult = 1e-3;
        } else {
            if (*(end + 1) == 'i' || *(end + 1) == 'I') {
                if (*(end + 2) == 'B' || *(end + 2) == 'b') end += 3;
                else end += 2;
            } else if (*(end + 1) == 'B' || *(end + 1) == 'b') {
                end += 2;
            } else {
                end += 1;
            }
            mult = 1024.0 * 1024.0;
        }
    } else if (*end == 'G' || *end == 'g') {
        if (*(end + 1) == 'i' || *(end + 1) == 'I') {
            if (*(end + 2) == 'B' || *(end + 2) == 'b') end += 3;
            else end += 2;
        } else if (*(end + 1) == 'B' || *(end + 1) == 'b') {
            end += 2;
        } else {
            end += 1;
        }
        mult = 1024.0 * 1024.0 * 1024.0;
    } else if (*end == 'T' || *end == 't') {
        if (*(end + 1) == 'i' || *(end + 1) == 'I') {
            if (*(end + 2) == 'B' || *(end + 2) == 'b') end += 3;
            else end += 2;
        } else if (*(end + 1) == 'B' || *(end + 1) == 'b') {
            end += 2;
        } else {
            end += 1;
        }
        mult = 1024.0 * 1024.0 * 1024.0 * 1024.0;
    } else if (*end == 'u' || *end == 'U') {
        if (*(end + 1) == 's' || *(end + 1) == 'S') end += 2;
        else end += 1;
        mult = 1e-6;
    } else if (*end == 'n' || *end == 'N') {
        if (*(end + 1) == 's' || *(end + 1) == 'S') end += 2;
        else end += 1;
        mult = 1e-9;
    } else if (*end == 's' && !isalnum((unsigned char)*(end + 1))) {
        end += 1;
        mult = 1.0;
    }

    *out_val = val * mult;
    if (endptr) *endptr = end;
    return true;
}

static bool parse_bpftrace_bucket_line(const char *line, double *out_low, double *out_high, double *out_count) {
    if (!line || !out_low || !out_high || !out_count) return false;
    const char *p = line;
    while (*p && isspace((unsigned char)*p)) p++;
    if (*p == '\0' || *p == '#' || *p == '@') return false;

    /* Format 1: [low, high) count or [val] count or (low, high] count */
    if (*p == '[' || *p == '(') {
        p++;
        while (*p && isspace((unsigned char)*p)) p++;

        double low = 0.0, high = 0.0;
        if (*p == '<' || strncmp(p, "...", 3) == 0 || strncmp(p, "-inf", 4) == 0) {
            if (*p == '<') p++;
            else if (strncmp(p, "...", 3) == 0) p += 3;
            else p += 4;
            while (*p && (isspace((unsigned char)*p) || *p == ',')) p++;
            char *end = NULL;
            if (!parse_bpftrace_num(p, &end, &high)) return false;
            p = end;
            low = (high > 0.0) ? 0.0 : high - 1.0;
        } else {
            char *end = NULL;
            if (!parse_bpftrace_num(p, &end, &low)) return false;
            p = end;
            while (*p && isspace((unsigned char)*p)) p++;

            if (*p == ',') {
                p++;
                while (*p && isspace((unsigned char)*p)) p++;
                if (strncmp(p, "...", 3) == 0 || strncmp(p, "+inf", 4) == 0) {
                    if (strncmp(p, "...", 3) == 0) p += 3;
                    else p += 4;
                    high = (low > 0.0) ? low * 2.0 : low + 1.0;
                } else {
                    if (!parse_bpftrace_num(p, &end, &high)) return false;
                    p = end;
                }
            } else if (*p == ']' || *p == ')') {
                /* Single value: [0] -> [0, 1), [1] -> [1, 2), [X] -> [X, X+1) */
                high = low + 1.0;
            } else {
                return false;
            }
        }

        while (*p && isspace((unsigned char)*p)) p++;
        if (*p != ']' && *p != ')') return false;
        p++; /* Skip closing bracket */

        while (*p && isspace((unsigned char)*p)) p++;
        char *end = NULL;
        double count = strtod(p, &end);
        if (end == p) return false;

        *out_low = low;
        *out_high = high;
        *out_count = count;
        return true;
    }

    /* Format 2: BCC style: "  0 -> 1 : 10 |***|" */
    char *end = NULL;
    double low = 0.0, high = 0.0;
    if (parse_bpftrace_num(p, &end, &low)) {
        p = end;
        while (*p && isspace((unsigned char)*p)) p++;
        if (p[0] == '-' && p[1] == '>') {
            p += 2;
            while (*p && isspace((unsigned char)*p)) p++;
            if (parse_bpftrace_num(p, &end, &high)) {
                p = end;
                while (*p && isspace((unsigned char)*p)) p++;
                if (*p == ':') {
                    p++;
                    while (*p && isspace((unsigned char)*p)) p++;
                    double count = strtod(p, &end);
                    if (end != p) {
                        *out_low = low;
                        *out_high = high + 1.0;
                        *out_count = count;
                        return true;
                    }
                }
            }
        }
    }

    return false;
}

static int bpftrace_bucket_cmp(const void *a, const void *b) {
    const bpftrace_bucket_t *ba = (const bpftrace_bucket_t *)a;
    const bpftrace_bucket_t *bb = (const bpftrace_bucket_t *)b;
    if (ba->low < bb->low) return -1;
    if (ba->low > bb->low) return 1;
    return 0;
}

histo_status_t cli_parse_bpftrace_histogram_str(const char *text, histo_t **out_h) {
    if (!text || !out_h) return HISTO_ERR_INVALID_ARG;
    *out_h = NULL;

    size_t cap = 32;
    size_t num_buckets = 0;
    bpftrace_bucket_t *buckets = (bpftrace_bucket_t *)malloc(cap * sizeof(bpftrace_bucket_t));
    if (!buckets) return HISTO_ERR_NOMEM;

    const char *p = text;
    char line[1024];

    while (*p) {
        size_t lidx = 0;
        while (*p && *p != '\n' && *p != '\r' && lidx + 1 < sizeof(line)) {
            line[lidx++] = *p++;
        }
        line[lidx] = '\0';
        while (*p == '\n' || *p == '\r') p++;

        double low = 0.0, high = 0.0, count = 0.0;
        if (parse_bpftrace_bucket_line(line, &low, &high, &count)) {
            if (num_buckets >= cap) {
                cap *= 2;
                bpftrace_bucket_t *new_b = (bpftrace_bucket_t *)realloc(buckets, cap * sizeof(bpftrace_bucket_t));
                if (!new_b) {
                    free(buckets);
                    return HISTO_ERR_NOMEM;
                }
                buckets = new_b;
            }
            buckets[num_buckets].low = low;
            buckets[num_buckets].high = high;
            buckets[num_buckets].count = count;
            num_buckets++;
        }
    }

    if (num_buckets == 0) {
        free(buckets);
        return HISTO_ERR_DESERIALIZATION;
    }

    /* Sort buckets by lower edge */
    qsort(buckets, num_buckets, sizeof(bpftrace_bucket_t), bpftrace_bucket_cmp);

    /* Construct edges array */
    double *edges = (double *)malloc((num_buckets + 1) * sizeof(double));
    if (!edges) {
        free(buckets);
        return HISTO_ERR_NOMEM;
    }

    edges[0] = buckets[0].low;
    bool is_contiguous = true;
    for (size_t i = 0; i < num_buckets; ++i) {
        edges[i + 1] = buckets[i].high;
        if (i > 0 && fabs(buckets[i].low - buckets[i - 1].high) > 1e-9) {
            is_contiguous = false;
        }
    }

    histo_t *h = NULL;
    uint32_t flags = HISTO_FLAG_TRACK_SUMW2 | HISTO_FLAG_EXACT_MOMENTS;

    /* Check if bins are uniform width */
    bool is_uniform = is_contiguous;
    if (is_contiguous && num_buckets > 1) {
        double width0 = edges[1] - edges[0];
        for (size_t i = 1; i < num_buckets; ++i) {
            double w = edges[i + 1] - edges[i];
            if (fabs(w - width0) > 1e-6 * (fabs(width0) + 1.0)) {
                is_uniform = false;
                break;
            }
        }
    }

    if (is_uniform && num_buckets > 0 && edges[num_buckets] > edges[0]) {
        h = histo_create_uniform((uint32_t)num_buckets, edges[0], edges[num_buckets], flags);
    } else {
        /* Ensure strict monotonicity */
        bool monotonic = true;
        for (size_t i = 0; i < num_buckets; ++i) {
            if (edges[i + 1] <= edges[i]) {
                monotonic = false;
                break;
            }
        }
        if (monotonic) {
            h = histo_create_variable((uint32_t)num_buckets, edges, flags);
        }
    }

    if (!h) {
        free(edges);
        free(buckets);
        return HISTO_ERR_DESERIALIZATION;
    }

    /* Fill bin contents */
    for (size_t i = 0; i < num_buckets; ++i) {
        if (buckets[i].count > 0.0) {
            histo_fill_bin(h, (uint32_t)i, buckets[i].count);
        }
    }

    free(edges);
    free(buckets);
    *out_h = h;
    return HISTO_OK;
}

histo_status_t cli_parse_bpftrace_histogram(FILE *fp, histo_t **out_h) {
    if (!fp || !out_h) return HISTO_ERR_INVALID_ARG;
    *out_h = NULL;

    size_t cap = 2048;
    size_t len = 0;
    char *buf = (char *)malloc(cap);
    if (!buf) return HISTO_ERR_NOMEM;

    char line[1024];
    size_t buckets_seen = 0;

    while (fgets(line, sizeof(line), fp)) {
        double low, high, count;
        if (parse_bpftrace_bucket_line(line, &low, &high, &count)) {
            buckets_seen++;
        } else {
            /* If we were in a table and hit an empty line or next map header '@' */
            const char *p = line;
            while (*p && isspace((unsigned char)*p)) p++;
            if (buckets_seen > 0 && (*p == '@' || *p == '\0')) {
                if (*p == '@') {
                    for (int i = (int)strlen(line) - 1; i >= 0; --i) {
                        ungetc(line[i], fp);
                    }
                }
                break;
            }
        }

        size_t line_len = strlen(line);
        if (len + line_len + 1 >= cap) {
            cap = (cap + line_len + 1) * 2;
            char *new_buf = (char *)realloc(buf, cap);
            if (!new_buf) {
                free(buf);
                return HISTO_ERR_NOMEM;
            }
            buf = new_buf;
        }
        memcpy(buf + len, line, line_len);
        len += line_len;
        buf[len] = '\0';
    }

    if (buckets_seen == 0) {
        free(buf);
        return HISTO_ERR_DESERIALIZATION;
    }

    histo_status_t st = cli_parse_bpftrace_histogram_str(buf, out_h);
    free(buf);
    return st;
}

/* ========================================================================= */
/* Stream Format Detection                                                   */
/* ========================================================================= */

cli_input_format_t cli_detect_stream_format(FILE *fp) {
    if (!fp) return CLI_INPUT_UNKNOWN;
    int c1 = fgetc(fp);
    if (c1 == EOF) return CLI_INPUT_UNKNOWN;
    int c2 = fgetc(fp);
    if (c2 == EOF) {
        ungetc(c1, fp);
        return CLI_INPUT_TEXT_NUMBERS;
    }
    int c3 = fgetc(fp);
    int c4 = fgetc(fp);

    /* Check for libhisto binary magic 0x89, 'L', 'H', 'I' */
    if ((uint8_t)c1 == 0x89 && c2 == 'L' && c3 == 'H' && c4 == 'I') {
        ungetc(c4, fp);
        ungetc(c3, fp);
        ungetc(c2, fp);
        ungetc(c1, fp);
        return CLI_INPUT_BINARY_HISTO;
    }

    /* Unget characters */
    if (c4 != EOF) ungetc(c4, fp);
    if (c3 != EOF) ungetc(c3, fp);
    ungetc(c2, fp);
    ungetc(c1, fp);

    /* Skip leading whitespace to detect JSON '{' or bpftrace '@' / '[' */
    int ch;
    int peek_buf[512];
    int peek_len = 0;
    while ((ch = fgetc(fp)) != EOF && peek_len < 500) {
        peek_buf[peek_len++] = ch;
        if (!isspace(ch)) break;
    }

    if (peek_len > 0) {
        int first_non_space = peek_buf[peek_len - 1];
        if (first_non_space == '{') {
            for (int i = peek_len - 1; i >= 0; --i) ungetc(peek_buf[i], fp);
            return CLI_INPUT_JSON_HISTO;
        }
        if (first_non_space == '@' || first_non_space == '[') {
            for (int i = peek_len - 1; i >= 0; --i) ungetc(peek_buf[i], fp);
            return CLI_INPUT_BPFTRACE_HISTO;
        }
    }

    for (int i = peek_len - 1; i >= 0; --i) {
        ungetc(peek_buf[i], fp);
    }
    return CLI_INPUT_TEXT_NUMBERS;
}

histo_status_t cli_read_any_histogram_from_stream(FILE *fp, histo_t **out_1d, histo2d_t **out_2d) {
    if (!fp || (!out_1d && !out_2d)) return HISTO_ERR_INVALID_ARG;
    if (out_1d) *out_1d = NULL;
    if (out_2d) *out_2d = NULL;

    cli_input_format_t fmt = cli_detect_stream_format(fp);
    if (fmt == CLI_INPUT_BINARY_HISTO) {
        uint8_t header[256];
        size_t nread = fread(header, 1, sizeof(header), fp);
        if (nread < sizeof(header)) {
            return HISTO_ERR_DESERIALIZATION;
        }

        uint16_t version = (uint16_t)header[0x08] | ((uint16_t)header[0x09] << 8);
        if (version == 3) {
            /* 2D Histogram */
            uint32_t flags = (uint32_t)header[0x0C] | ((uint32_t)header[0x0D] << 8) |
                             ((uint32_t)header[0x0E] << 16) | ((uint32_t)header[0x0F] << 24);
            uint32_t nx = (uint32_t)header[0x10] | ((uint32_t)header[0x11] << 8) |
                          ((uint32_t)header[0x12] << 16) | ((uint32_t)header[0x13] << 24);
            uint32_t ny = (uint32_t)header[0x14] | ((uint32_t)header[0x15] << 8) |
                          ((uint32_t)header[0x16] << 16) | ((uint32_t)header[0x17] << 24);

            size_t payload_size = 0;
            if (flags & 0x01) payload_size += (size_t)(nx + 1) * sizeof(double);
            if (flags & 0x02) payload_size += (size_t)(ny + 1) * sizeof(double);
            size_t total_cells = (size_t)nx * (size_t)ny;
            payload_size += total_cells * sizeof(double);
            if (flags & 0x04) payload_size += total_cells * sizeof(double);
            payload_size += 9 * sizeof(double);
            if (flags & 0x04) payload_size += 9 * sizeof(double);
            payload_size += 9 * sizeof(uint64_t);

            size_t total_size = sizeof(header) + payload_size;
            uint8_t *full_buf = (uint8_t*)malloc(total_size);
            if (!full_buf) return HISTO_ERR_NOMEM;

            memcpy(full_buf, header, sizeof(header));
            if (payload_size > 0) {
                size_t payload_read = fread(full_buf + sizeof(header), 1, payload_size, fp);
                if (payload_read < payload_size) {
                    free(full_buf);
                    return HISTO_ERR_DESERIALIZATION;
                }
            }

            if (out_2d) {
                histo_status_t st = histo2d_deserialize_binary(full_buf, total_size, out_2d);
                free(full_buf);
                return st;
            } else {
                free(full_buf);
                return HISTO_ERR_INVALID_ARG;
            }
        } else {
            /* 1D Histogram (v1 or v2) */
            uint32_t flags = (uint32_t)header[0x0C] | ((uint32_t)header[0x0D] << 8) |
                             ((uint32_t)header[0x0E] << 16) | ((uint32_t)header[0x0F] << 24);
            uint32_t nbins = (uint32_t)header[0x10] | ((uint32_t)header[0x11] << 8) |
                             ((uint32_t)header[0x12] << 16) | ((uint32_t)header[0x13] << 24);
            size_t payload_size = (size_t)nbins * sizeof(double);
            if (flags & 0x01) { /* Variable edges */
                payload_size += (size_t)(nbins + 1) * sizeof(double);
            }
            if (flags & 0x02) { /* Sum_w2 */
                payload_size += (size_t)nbins * sizeof(double);
            }

            size_t total_size = sizeof(header) + payload_size;
            uint8_t *full_buf = (uint8_t *)malloc(total_size);
            if (!full_buf) return HISTO_ERR_NOMEM;

            memcpy(full_buf, header, sizeof(header));
            if (payload_size > 0) {
                size_t payload_read = fread(full_buf + sizeof(header), 1, payload_size, fp);
                if (payload_read < payload_size) {
                    free(full_buf);
                    return HISTO_ERR_DESERIALIZATION;
                }
            }

            if (out_1d) {
                histo_status_t st = histo_deserialize_binary(full_buf, total_size, out_1d);
                free(full_buf);
                return st;
            } else {
                free(full_buf);
                return HISTO_ERR_INVALID_ARG;
            }
        }
    }

    if (fmt == CLI_INPUT_JSON_HISTO) {
        size_t cap = 4096;
        size_t len = 0;
        char *buf = (char *)malloc(cap);
        if (!buf) return HISTO_ERR_NOMEM;

        int ch;
        int brace_depth = 0;
        bool started = false;
        while ((ch = fgetc(fp)) != EOF) {
            if (len + 2 >= cap) {
                cap *= 2;
                char *new_buf = (char *)realloc(buf, cap);
                if (!new_buf) {
                    free(buf);
                    return HISTO_ERR_NOMEM;
                }
                buf = new_buf;
            }
            buf[len++] = (char)ch;
            if (ch == '{') {
                brace_depth++;
                started = true;
            } else if (ch == '}') {
                brace_depth--;
                if (started && brace_depth == 0) {
                    break;
                }
            }
        }
        buf[len] = '\0';

        if (strstr(buf, "\"libhisto2d") != NULL || strstr(buf, "\"nx\"") != NULL) {
            if (out_2d) {
                histo_status_t st = histo2d_deserialize_json(buf, out_2d);
                free(buf);
                return st;
            } else {
                free(buf);
                return HISTO_ERR_INVALID_ARG;
            }
        } else {
            if (out_1d) {
                histo_status_t st = histo_deserialize_json(buf, out_1d);
                free(buf);
                return st;
            } else {
                free(buf);
                return HISTO_ERR_INVALID_ARG;
            }
        }
    }

    if (fmt == CLI_INPUT_BPFTRACE_HISTO || fmt == CLI_INPUT_TEXT_NUMBERS) {
        if (out_1d) {
            histo_status_t st = cli_parse_bpftrace_histogram(fp, out_1d);
            if (st == HISTO_OK) {
                return HISTO_OK;
            }
        }
    }

    return HISTO_ERR_DESERIALIZATION;
}

histo_status_t cli_read_any_histogram_from_file(const char *path, histo_t **out_1d, histo2d_t **out_2d) {
    if (!path) return HISTO_ERR_INVALID_ARG;
    FILE *fp = NULL;
    if (strcmp(path, "-") == 0) {
        fp = stdin;
    } else {
        fp = fopen(path, "rb");
        if (!fp) return HISTO_ERR_INVALID_ARG;
    }

    histo_status_t st = cli_read_any_histogram_from_stream(fp, out_1d, out_2d);
    if (fp != stdin) {
        fclose(fp);
    }
    return st;
}

histo_status_t cli_read_histogram_from_stream(FILE *fp, histo_t **out_h) {
    return cli_read_any_histogram_from_stream(fp, out_h, NULL);
}

histo_status_t cli_read_histogram_from_file(const char *path, histo_t **out_h) {
    return cli_read_any_histogram_from_file(path, out_h, NULL);
}

histo_status_t cli_read_histo2d_from_stream(FILE *fp, histo2d_t **out_h) {
    return cli_read_any_histogram_from_stream(fp, NULL, out_h);
}

histo_status_t cli_read_histo2d_from_file(const char *path, histo2d_t **out_h) {
    return cli_read_any_histogram_from_file(path, NULL, out_h);
}
