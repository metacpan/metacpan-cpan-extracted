#include "cli_common.h"
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <ctype.h>

int cli_get_terminal_width(int default_width) {
    const char *col_env = getenv("COLUMNS");
    if (col_env && *col_env) {
        int val = atoi(col_env);
        if (val > 10) return val;
    }
#ifdef TIOCGWINSZ
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
#ifdef TIOCGWINSZ
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
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec * 1e-6;
}

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

    /* Skip leading whitespace to detect JSON '{' */
    int ch;
    long offset = 0;
    while ((ch = fgetc(fp)) != EOF && isspace(ch)) {
        offset++;
    }
    if (ch == '{') {
        ungetc(ch, fp);
        return CLI_INPUT_JSON_HISTO;
    }
    if (ch != EOF) {
        ungetc(ch, fp);
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

